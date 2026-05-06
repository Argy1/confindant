<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class AiCategorizationService
{
    public function categorize(array $context): array
    {
        if (app()->environment('testing')) {
            return $this->fallbackCategorization($context, 'testing-environment');
        }

        $apiKey = (string) config('services.gemini.api_key');
        if ($apiKey === '') {
            return $this->fallbackCategorization($context, 'gemini-api-key-missing');
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
            return $this->fallbackCategorization($context, 'provider_error');
        }

        $raw = $response->json();
        $text = data_get($raw, 'candidates.0.content.parts.0.text');
        if (!is_string($text) || trim($text) === '') {
            return $this->fallbackCategorization($context, 'invalid_response');
        }

        $decoded = $this->decodeJsonText($text);
        if (!is_array($decoded)) {
            return $this->fallbackCategorization($context, 'invalid_json');
        }

        $category = trim((string) ($decoded['category'] ?? 'General Expense'));
        $confidence = is_numeric($decoded['confidence'] ?? null)
            ? (float) $decoded['confidence']
            : 0.65;

        if ($category === '') {
            return $this->fallbackCategorization($context, 'empty_category');
        }

        return [
            'category' => $category,
            'confidence' => max(0, min(1, $confidence)),
            'provider' => 'gemini',
            'raw' => $raw,
            'fallback' => false,
        ];
    }

    private function prompt(array $context): string
    {
        $type = (string) ($context['type'] ?? 'expense');
        $merchant = (string) ($context['merchant_name'] ?? '');
        $source = (string) ($context['source'] ?? '');
        $notes = (string) ($context['notes'] ?? '');
        $amount = (float) ($context['total_amount'] ?? 0);

        return <<<PROMPT
Classify this financial transaction into one concise category.
Return strict JSON only with shape:
{
  "category": "string",
  "confidence": number
}

Transaction context:
- type: {$type}
- merchant_name: {$merchant}
- source: {$source}
- notes: {$notes}
- total_amount: {$amount}

Rules:
- If type is income, choose income-style category (Salary/Freelance/Bonus/Gift/Other Income).
- If type is expense, choose expense-style category (Food, Transport, Bills, Shopping, Health, Education, Entertainment, Other Expense).
- confidence must be 0..1.
PROMPT;
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

    private function fallbackCategorization(array $context, string $reason): array
    {
        $type = (string) ($context['type'] ?? 'expense');
        $bag = mb_strtolower(trim(
            ((string) ($context['merchant_name'] ?? '')).' '.
            ((string) ($context['source'] ?? '')).' '.
            ((string) ($context['notes'] ?? ''))
        ));

        if ($type === 'income') {
            $category = str_contains($bag, 'salary') || str_contains($bag, 'gaji')
                ? 'Salary'
                : (str_contains($bag, 'bonus') ? 'Bonus' : 'Other Income');
        } else {
            $category = 'Other Expense';
            $rules = [
                'Food' => ['food', 'makan', 'coffee', 'cafe', 'restaurant'],
                'Transport' => ['transport', 'taxi', 'grab', 'gojek', 'fuel', 'bensin'],
                'Shopping' => ['shop', 'mall', 'belanja', 'store'],
                'Bills' => ['listrik', 'air', 'internet', 'bill', 'tagihan'],
                'Health' => ['hospital', 'klinik', 'obat', 'health'],
                'Education' => ['sekolah', 'course', 'education', 'kelas'],
            ];
            foreach ($rules as $candidate => $needles) {
                foreach ($needles as $needle) {
                    if (str_contains($bag, $needle)) {
                        $category = $candidate;
                        break 2;
                    }
                }
            }
        }

        return [
            'category' => $category,
            'confidence' => 0.55,
            'provider' => 'fallback',
            'raw' => ['reason' => $reason],
            'fallback' => true,
        ];
    }
}
