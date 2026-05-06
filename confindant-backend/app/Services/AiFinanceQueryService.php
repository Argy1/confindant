<?php

namespace App\Services;

use App\Models\Transaction;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Http;

class AiFinanceQueryService
{
    public function answer(string $userId, string $query, ?string $locale = null): array
    {
        [$from, $to, $label] = $this->resolveWindow($query);
        $transactions = Transaction::where('user_id', $userId)
            ->where('date', '>=', $from)
            ->where('date', '<=', $to)
            ->orderBy('date', 'desc')
            ->get();

        $metrics = $this->buildMetrics($transactions);
        if (app()->environment('testing')) {
            return $this->fallbackAnswer($query, $label, $from, $to, $metrics, 'testing-environment');
        }

        $apiKey = (string) config('services.gemini.api_key');
        if ($apiKey === '') {
            return $this->fallbackAnswer($query, $label, $from, $to, $metrics, 'gemini-api-key-missing');
        }

        $model = (string) config('services.gemini.model', 'gemini-2.5-flash');
        $apiBase = rtrim((string) config('services.gemini.api_base'), '/');
        $timeout = (int) config('services.gemini.timeout', 45);
        $endpoint = "{$apiBase}/models/{$model}:generateContent";

        $response = Http::timeout($timeout)
            ->acceptJson()
            ->withQueryParameters(['key' => $apiKey])
            ->post($endpoint, [
                'contents' => [[
                    'parts' => [
                        ['text' => $this->prompt($query, $locale ?? 'id', $label, $from, $to, $metrics)],
                    ],
                ]],
                'generationConfig' => [
                    'temperature' => 0.2,
                    'responseMimeType' => 'application/json',
                ],
            ]);

        if (!$response->successful()) {
            return $this->fallbackAnswer($query, $label, $from, $to, $metrics, 'provider_error');
        }

        $text = data_get($response->json(), 'candidates.0.content.parts.0.text');
        $decoded = is_string($text) ? $this->decodeJsonText($text) : null;
        if (!is_array($decoded)) {
            return $this->fallbackAnswer($query, $label, $from, $to, $metrics, 'invalid_response');
        }

        return [
            'query' => $query,
            'period' => [
                'label' => $label,
                'from' => $from->toIso8601String(),
                'to' => $to->toIso8601String(),
            ],
            'answer' => (string) ($decoded['answer'] ?? ''),
            'insight' => (string) ($decoded['insight'] ?? ''),
            'suggested_actions' => array_values(array_filter(
                array_map(fn ($item) => trim((string) $item), (array) ($decoded['suggested_actions'] ?? [])),
                fn ($item) => $item !== ''
            )),
            'metrics' => $metrics,
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
        array $metrics
    ): string {
        $lang = $locale === 'en' ? 'English' : 'Bahasa Indonesia';
        return <<<PROMPT
You are a personal finance assistant. Answer user question based on metrics only.
Return strict JSON only with shape:
{
  "answer": "string",
  "insight": "string",
  "suggested_actions": ["string", "string", "string"]
}
Rules:
- Language must be {$lang}.
- Keep answer concise and data-backed.
- If data is empty, explicitly say insufficient data.

User query: "{$query}"
Analysis window: {$label} ({$from->toDateString()} to {$to->toDateString()})
Metrics JSON:
{$this->encodeMetrics($metrics)}
PROMPT;
    }

    private function fallbackAnswer(
        string $query,
        string $label,
        Carbon $from,
        Carbon $to,
        array $metrics,
        string $reason
    ): array {
        $expense = (float) ($metrics['total_expense'] ?? 0);
        $income = (float) ($metrics['total_income'] ?? 0);
        $net = $income - $expense;
        $topCategory = $metrics['top_expense_category']['category'] ?? 'Tidak ada';
        $topAmount = (float) ($metrics['top_expense_category']['amount'] ?? 0);
        $answer = "Periode {$label}: pemasukan Rp ".number_format($income, 0, ',', '.')
            .", pengeluaran Rp ".number_format($expense, 0, ',', '.')
            .", arus bersih Rp ".number_format($net, 0, ',', '.').".";

        if ($topAmount > 0) {
            $answer .= " Kategori pengeluaran terbesar: {$topCategory} (Rp ".number_format($topAmount, 0, ',', '.').").";
        }

        return [
            'query' => $query,
            'period' => [
                'label' => $label,
                'from' => $from->toIso8601String(),
                'to' => $to->toIso8601String(),
            ],
            'answer' => $answer,
            'insight' => $net < 0
                ? 'Arus kas negatif. Prioritaskan menekan kategori terbesar dan tambah income rutin.'
                : 'Arus kas masih positif. Pertahankan pola saat ini dan tingkatkan alokasi ke goals.',
            'suggested_actions' => [
                'Review 3 transaksi terbesar minggu ini.',
                'Tetapkan budget limit pada kategori tertinggi.',
                'Jadwalkan transfer otomatis ke goal setelah income masuk.',
            ],
            'metrics' => $metrics,
            'provider' => 'fallback',
            'fallback' => true,
            'meta_reason' => $reason,
        ];
    }

    private function resolveWindow(string $query): array
    {
        $q = mb_strtolower($query);
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
        return [$now->copy()->subDays(29)->startOfDay(), $now->copy()->endOfDay(), '30 hari terakhir'];
    }

    private function buildMetrics(Collection $transactions): array
    {
        $income = (float) $transactions->where('type', 'income')->sum('total_amount');
        $expense = (float) $transactions->where('type', 'expense')->sum('total_amount');

        $expenseByCategory = $transactions
            ->where('type', 'expense')
            ->groupBy(fn ($t) => (string) ($t->category ?? 'Other'))
            ->map(fn ($rows, $category) => [
                'category' => (string) $category,
                'amount' => (float) $rows->sum('total_amount'),
            ])
            ->sortByDesc('amount')
            ->values()
            ->take(5)
            ->values()
            ->all();

        return [
            'transaction_count' => $transactions->count(),
            'total_income' => $income,
            'total_expense' => $expense,
            'net_flow' => $income - $expense,
            'top_expense_category' => $expenseByCategory[0] ?? ['category' => 'None', 'amount' => 0.0],
            'expense_by_category' => $expenseByCategory,
        ];
    }

    private function encodeMetrics(array $metrics): string
    {
        $encoded = json_encode($metrics, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        return is_string($encoded) ? $encoded : '{}';
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

