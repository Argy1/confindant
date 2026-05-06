<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class AiTransactionParseService
{
    public function parse(array $context): array
    {
        if (app()->environment('testing')) {
            return $this->fallbackParse($context, 'testing-environment');
        }

        $apiKey = (string) config('services.gemini.api_key');
        if ($apiKey === '') {
            return $this->fallbackParse($context, 'gemini-api-key-missing');
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
                        ['text' => $this->prompt($context)],
                    ],
                ]],
                'generationConfig' => [
                    'temperature' => 0.1,
                    'responseMimeType' => 'application/json',
                ],
            ]);

        if (!$response->successful()) {
            return $this->fallbackParse($context, 'provider_error');
        }

        $raw = $response->json();
        $text = data_get($raw, 'candidates.0.content.parts.0.text');
        if (!is_string($text) || trim($text) === '') {
            return $this->fallbackParse($context, 'invalid_response');
        }

        $decoded = $this->decodeJsonText($text);
        if (!is_array($decoded)) {
            return $this->fallbackParse($context, 'invalid_json');
        }

        return $this->normalize($decoded, false, 'gemini', $raw);
    }

    private function prompt(array $context): string
    {
        $transcript = (string) ($context['transcript'] ?? '');
        $locale = (string) ($context['locale'] ?? 'id');
        $lang = $locale === 'en' ? 'English' : 'Bahasa Indonesia';
        $today = now()->toDateString();

        return <<<PROMPT
Parse this spoken finance input into a transaction draft.
Return STRICT JSON only, shape:
{
  "type": "income|expense",
  "amount": number,
  "category": "string",
  "source": "string",
  "merchant_name": "string",
  "notes": "string",
  "date": "YYYY-MM-DD",
  "confidence": number
}

Rules:
- Language context: {$lang}
- If ambiguous, keep safest defaults:
  - type: expense
  - category: Other Expense
  - source: ""
  - merchant_name: ""
- amount must be plain number without separators (e.g. 150000).
- date defaults to {$today} if not mentioned.
- confidence 0..1.

Input transcript:
{$transcript}
PROMPT;
    }

    private function normalize(array $decoded, bool $fallback, string $provider, mixed $raw): array
    {
        $type = (string) ($decoded['type'] ?? 'expense');
        if (!in_array($type, ['income', 'expense'], true)) {
            $type = 'expense';
        }
        $amount = is_numeric($decoded['amount'] ?? null) ? (float) $decoded['amount'] : 0.0;
        $amount = max(0, $amount);

        $category = trim((string) ($decoded['category'] ?? ''));
        if ($category === '') {
            $category = $type === 'income' ? 'Other Income' : 'Other Expense';
        }

        $source = trim((string) ($decoded['source'] ?? ''));
        if ($type === 'income' && $source === '') {
            $source = 'Other';
        }

        $merchant = trim((string) ($decoded['merchant_name'] ?? ''));
        $notes = trim((string) ($decoded['notes'] ?? ''));
        $date = trim((string) ($decoded['date'] ?? now()->toDateString()));
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            $date = now()->toDateString();
        }

        $confidence = is_numeric($decoded['confidence'] ?? null)
            ? (float) $decoded['confidence']
            : 0.6;
        $confidence = max(0, min(1, $confidence));

        return [
            'type' => $type,
            'amount' => $amount,
            'category' => $category,
            'source' => $source,
            'merchant_name' => $merchant,
            'notes' => $notes,
            'date' => $date,
            'confidence' => $confidence,
            'provider' => $provider,
            'fallback' => $fallback,
            'raw' => $raw,
        ];
    }

    private function fallbackParse(array $context, string $reason): array
    {
        $transcript = trim((string) ($context['transcript'] ?? ''));
        $lower = mb_strtolower($transcript);

        $type = str_contains($lower, 'income')
            || str_contains($lower, 'pemasukan')
            || str_contains($lower, 'gaji')
            ? 'income'
            : 'expense';

        $amount = 0.0;
        if (preg_match('/(\d[\d\.\,]{2,})/', $transcript, $matches) === 1) {
            $normalized = preg_replace('/[^\d]/', '', $matches[1]) ?? '';
            if ($normalized !== '') {
                $amount = (float) $normalized;
            }
        }

        $category = $type === 'income' ? 'Other Income' : 'Other Expense';
        if ($type === 'income') {
            if (str_contains($lower, 'gaji') || str_contains($lower, 'salary')) {
                $category = 'Salary';
            } elseif (str_contains($lower, 'bonus')) {
                $category = 'Bonus';
            } elseif (str_contains($lower, 'freelance')) {
                $category = 'Freelance';
            }
        } else {
            $rules = [
                'Food' => ['makan', 'food', 'coffee', 'cafe', 'restaurant'],
                'Transport' => ['transport', 'taxi', 'grab', 'gojek', 'bensin'],
                'Shopping' => ['belanja', 'shopping', 'shop', 'mall'],
                'Bills' => ['tagihan', 'bill', 'listrik', 'internet', 'air'],
            ];
            foreach ($rules as $candidate => $needles) {
                foreach ($needles as $needle) {
                    if (str_contains($lower, $needle)) {
                        $category = $candidate;
                        break 2;
                    }
                }
            }
        }

        return $this->normalize([
            'type' => $type,
            'amount' => $amount,
            'category' => $category,
            'source' => $type === 'income' ? 'Other' : '',
            'merchant_name' => '',
            'notes' => $transcript,
            'date' => now()->toDateString(),
            'confidence' => 0.55,
        ], true, 'fallback', ['reason' => $reason]);
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

