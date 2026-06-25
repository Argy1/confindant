<?php

namespace App\Services;

use App\Models\JournalLine;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Http;

class AiOrgQueryService
{
    public function answer(string $orgId, string $orgName, string $query, ?string $locale = null): array
    {
        [$from, $to, $label] = $this->resolveWindow($query);

        $lines = JournalLine::with('account')
            ->where('organization_id', $orgId)
            ->whereHas('journalEntry', fn ($q) => $q->where('status', 'posted'))
            ->where('date', '>=', $from->toDateString())
            ->where('date', '<=', $to->toDateString())
            ->get();

        $metrics = $this->buildMetrics($lines, $orgName);

        if (app()->environment('testing')) {
            return $this->fallbackAnswer($query, $label, $from, $to, $metrics, $orgName, 'testing-environment');
        }

        $apiKey = (string) config('services.gemini.api_key');
        if ($apiKey === '') {
            return $this->fallbackAnswer($query, $label, $from, $to, $metrics, $orgName, 'gemini-api-key-missing');
        }

        $model   = (string) config('services.gemini.model', 'gemini-2.5-flash');
        $apiBase = rtrim((string) config('services.gemini.api_base'), '/');
        $timeout = (int) config('services.gemini.timeout', 45);
        $endpoint = "{$apiBase}/models/{$model}:generateContent";

        $response = Http::timeout($timeout)
            ->acceptJson()
            ->withQueryParameters(['key' => $apiKey])
            ->post($endpoint, [
                'contents' => [[
                    'parts' => [
                        ['text' => $this->prompt($query, $locale ?? 'id', $label, $from, $to, $metrics, $orgName)],
                    ],
                ]],
                'generationConfig' => [
                    'temperature'     => 0.2,
                    'responseMimeType' => 'application/json',
                ],
            ]);

        if (!$response->successful()) {
            return $this->fallbackAnswer($query, $label, $from, $to, $metrics, $orgName, 'provider_error');
        }

        $text    = data_get($response->json(), 'candidates.0.content.parts.0.text');
        $decoded = is_string($text) ? $this->decodeJsonText($text) : null;
        if (!is_array($decoded)) {
            return $this->fallbackAnswer($query, $label, $from, $to, $metrics, $orgName, 'invalid_response');
        }

        return [
            'query'   => $query,
            'period'  => ['label' => $label, 'from' => $from->toIso8601String(), 'to' => $to->toIso8601String()],
            'answer'  => (string) ($decoded['answer'] ?? ''),
            'insight' => (string) ($decoded['insight'] ?? ''),
            'suggested_actions' => array_values(array_filter(
                array_map(fn ($s) => trim((string) $s), (array) ($decoded['suggested_actions'] ?? [])),
                fn ($s) => $s !== ''
            )),
            'metrics'  => $metrics,
            'provider' => 'gemini',
            'fallback' => false,
        ];
    }

    private function prompt(
        string $query,
        string $locale,
        string $label,
        Carbon $from,
        Carbon $to,
        array $metrics,
        string $orgName,
    ): string {
        $lang    = $locale === 'en' ? 'English' : 'Bahasa Indonesia';
        $encoded = json_encode($metrics, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) ?: '{}';

        return <<<PROMPT
You are an accounting assistant for {$orgName}, a nonprofit organization using double-entry bookkeeping.
Answer the user question based on the financial metrics below.
Return strict JSON only with shape:
{
  "answer": "string",
  "insight": "string",
  "suggested_actions": ["string", "string", "string"]
}
Rules:
- Language must be {$lang}.
- Keep answer concise and data-backed.
- Use nonprofit accounting terminology (pendapatan, beban, aset bersih).
- If data is empty, explicitly say insufficient data.

User query: "{$query}"
Analysis window: {$label} ({$from->toDateString()} to {$to->toDateString()})
Financial metrics JSON:
{$encoded}
PROMPT;
    }

    private function buildMetrics(Collection $lines, string $orgName): array
    {
        $revenue  = 0.0;
        $expenses = 0.0;
        $expenseByAccount = [];
        $revenueByAccount = [];

        foreach ($lines as $line) {
            $type = $line->account?->type ?? '';
            $name = $line->account?->name ?? 'Unknown';

            if ($type === 'revenue') {
                $net = (float) $line->credit - (float) $line->debit;
                $revenue += $net;
                $revenueByAccount[$name] = ($revenueByAccount[$name] ?? 0.0) + $net;
            } elseif ($type === 'expense') {
                $net = (float) $line->debit - (float) $line->credit;
                $expenses += $net;
                $expenseByAccount[$name] = ($expenseByAccount[$name] ?? 0.0) + $net;
            }
        }

        arsort($expenseByAccount);
        arsort($revenueByAccount);

        $topExpense = array_map(
            fn ($name, $amount) => ['account' => $name, 'amount' => round($amount, 2)],
            array_keys(array_slice($expenseByAccount, 0, 5, true)),
            array_slice($expenseByAccount, 0, 5, true)
        );

        $topRevenue = array_map(
            fn ($name, $amount) => ['account' => $name, 'amount' => round($amount, 2)],
            array_keys(array_slice($revenueByAccount, 0, 5, true)),
            array_slice($revenueByAccount, 0, 5, true)
        );

        return [
            'org_name'         => $orgName,
            'journal_lines'    => $lines->count(),
            'total_revenue'    => round($revenue, 2),
            'total_expenses'   => round($expenses, 2),
            'net_surplus'      => round($revenue - $expenses, 2),
            'top_expense_accounts' => array_values($topExpense),
            'top_revenue_accounts' => array_values($topRevenue),
        ];
    }

    private function fallbackAnswer(
        string $query,
        string $label,
        Carbon $from,
        Carbon $to,
        array $metrics,
        string $orgName,
        string $reason
    ): array {
        $revenue  = (float) ($metrics['total_revenue'] ?? 0);
        $expenses = (float) ($metrics['total_expenses'] ?? 0);
        $net      = $revenue - $expenses;

        $answer = "Periode {$label}: pendapatan Rp " . number_format($revenue, 0, ',', '.')
            . ", beban Rp " . number_format($expenses, 0, ',', '.')
            . ", surplus/defisit Rp " . number_format($net, 0, ',', '.') . ".";

        return [
            'query'   => $query,
            'period'  => ['label' => $label, 'from' => $from->toIso8601String(), 'to' => $to->toIso8601String()],
            'answer'  => $answer,
            'insight' => $net < 0
                ? 'Organisasi mengalami defisit pada periode ini. Perlu evaluasi pos beban terbesar.'
                : 'Organisasi mencatat surplus pada periode ini. Pertahankan efisiensi anggaran.',
            'suggested_actions' => [
                'Cek pos beban terbesar dan bandingkan dengan anggaran.',
                'Pastikan semua pendapatan sudah dicatat sebagai jurnal.',
                'Review piutang yang belum dilunasi.',
            ],
            'metrics'      => $metrics,
            'provider'     => 'fallback',
            'fallback'     => true,
            'meta_reason'  => $reason,
        ];
    }

    private function resolveWindow(string $query): array
    {
        $q   = mb_strtolower($query);
        $now = now();
        if (str_contains($q, '2 minggu') || str_contains($q, '14 hari')) {
            return [$now->copy()->subDays(13)->startOfDay(), $now->copy()->endOfDay(), '14 hari terakhir'];
        }
        if (str_contains($q, 'minggu ini') || str_contains($q, 'week')) {
            return [$now->copy()->startOfWeek(), $now->copy()->endOfWeek(), 'minggu ini'];
        }
        if (str_contains($q, 'bulan ini') || str_contains($q, 'month')) {
            return [$now->copy()->startOfMonth(), $now->copy()->endOfMonth(), 'bulan ini'];
        }
        if (str_contains($q, 'tahun ini') || str_contains($q, 'year')) {
            return [$now->copy()->startOfYear(), $now->copy()->endOfYear(), 'tahun ini'];
        }
        return [$now->copy()->subDays(29)->startOfDay(), $now->copy()->endOfDay(), '30 hari terakhir'];
    }

    private function decodeJsonText(string $text): ?array
    {
        $decoded = json_decode($text, true);
        if (is_array($decoded)) {
            return $decoded;
        }
        $trimmed = trim($text);
        $trimmed = preg_replace('/^```json\s*/i', '', $trimmed) ?? $trimmed;
        $trimmed = preg_replace('/^```\s*/', '', $trimmed) ?? $trimmed;
        $trimmed = preg_replace('/\s*```$/', '', $trimmed) ?? $trimmed;
        $decoded = json_decode($trimmed, true);
        return is_array($decoded) ? $decoded : null;
    }
}
