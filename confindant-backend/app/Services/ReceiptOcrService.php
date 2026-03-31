<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;

class ReceiptOcrService
{
    public function extract(string $imagePath): array
    {
        if (app()->environment('testing')) {
            return $this->fallbackResult('testing-environment');
        }

        $apiKey = (string) config('services.gemini.api_key');
        if ($apiKey === '') {
            return $this->fallbackResult('gemini-api-key-missing');
        }

        [$imageBytes, $mimeType] = $this->loadImageForGemini($imagePath);
        if ($imageBytes === null) {
            return $this->fallbackResult('image-unreadable');
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
                        ['text' => $this->prompt()],
                        [
                            'inline_data' => [
                                'mime_type' => $mimeType,
                                'data' => base64_encode($imageBytes),
                            ],
                        ],
                    ],
                ]],
                'generationConfig' => [
                    'temperature' => 0.1,
                    'responseMimeType' => 'application/json',
                ],
            ]);

        if (!$response->successful()) {
            throw new \RuntimeException('Gemini request failed: '.$response->status().' '.$response->body());
        }

        $raw = $response->json();
        $text = data_get($raw, 'candidates.0.content.parts.0.text');
        if (!is_string($text) || trim($text) === '') {
            throw new \RuntimeException('Gemini response does not contain text output');
        }

        $decoded = $this->decodeJsonText($text);
        if (!is_array($decoded)) {
            throw new \RuntimeException('Gemini response JSON parse failed');
        }

        $extracted = $this->normalizeExtracted($decoded);
        $confidence = $this->normalizeConfidence($decoded['confidence'] ?? null);

        return [
            'extracted' => $extracted,
            'confidence' => $confidence,
            'raw' => $raw,
        ];
    }

    private function prompt(): string
    {
        return <<<'PROMPT'
Extract financial transaction data from the image and return strict JSON only.
Required JSON schema:
{
  "merchant_name": "string",
  "date": "ISO-8601 datetime string",
  "total_amount": number,
  "tax_amount": number,
  "service_amount": number,
  "need_want": "needs|wants|mixed|unknown",
  "category": "string",
  "type": "expense|income",
  "field_confidence": {
    "merchant_name": number,
    "date": number,
    "total_amount": number,
    "tax_amount": number,
    "service_amount": number,
    "need_want": number,
    "category": number
  },
  "items": [
    {
      "name": "string",
      "qty": number,
      "price": number,
      "subtotal": number
    }
  ],
  "transactions": [
    {
      "merchant_name": "string",
      "date": "ISO-8601 datetime string",
      "total_amount": number,
      "category": "string",
      "type": "expense|income",
      "notes": "string"
    }
  ],
  "confidence": number
}
Rules:
- If uncertain, still return best estimate.
- If image contains multiple transaction rows/history, fill "transactions" with each row.
- For single receipt image, "transactions" can contain one item or be empty.
- Do not include markdown.
- Ensure valid JSON.
PROMPT;
    }

    private function loadImageForGemini(string $imagePath): array
    {
        // Handle public storage URL path such as /storage/receipts/xxx.jpg.
        $path = parse_url($imagePath, PHP_URL_PATH) ?: $imagePath;
        $relative = ltrim((string) $path, '/');
        if (str_starts_with($relative, 'storage/')) {
            $relative = substr($relative, strlen('storage/'));
        }

        $bytes = null;
        if ($relative !== '' && Storage::disk('public')->exists($relative)) {
            $bytes = Storage::disk('public')->get($relative);
        } elseif (is_file($imagePath)) {
            $bytes = file_get_contents($imagePath) ?: null;
        }

        if ($bytes === null) {
            return [null, null];
        }

        $finfo = new \finfo(FILEINFO_MIME_TYPE);
        $mimeType = $finfo->buffer($bytes) ?: 'image/jpeg';
        if (!str_starts_with($mimeType, 'image/')) {
            $mimeType = 'image/jpeg';
        }

        return [$bytes, $mimeType];
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

    private function normalizeExtracted(array $raw): array
    {
        [$date, $dateConfidence] = $this->normalizeDateWithConfidence((string) ($raw['date'] ?? ''));
        $items = [];
        foreach (($raw['items'] ?? []) as $item) {
            if (!is_array($item)) {
                continue;
            }
            $qty = $this->parseAmount($item['qty'] ?? 0);
            $price = $this->parseAmount($item['price'] ?? 0);
            $subtotal = $this->parseAmount($item['subtotal'] ?? ($qty * $price));
            $items[] = [
                'name' => (string) ($item['name'] ?? ''),
                'qty' => $qty,
                'price' => $price,
                'subtotal' => $subtotal,
            ];
        }

        $type = (string) ($raw['type'] ?? 'expense');
        if (!in_array($type, ['expense', 'income'], true)) {
            $type = 'expense';
        }

        $totalAmount = $this->parseAmount($raw['total_amount'] ?? 0);
        if ($totalAmount <= 0 && $items !== []) {
            $totalAmount = array_reduce($items, function (float $carry, array $item): float {
                return $carry + (float) ($item['subtotal'] ?? 0);
            }, 0.0);
        }
        $taxAmount = $this->parseAmount($raw['tax_amount'] ?? 0);
        $serviceAmount = $this->parseAmount($raw['service_amount'] ?? 0);
        $needWant = strtolower(trim((string) ($raw['need_want'] ?? 'unknown')));
        if (!in_array($needWant, ['needs', 'wants', 'mixed', 'unknown'], true)) {
            $needWant = 'unknown';
        }

        $fieldConfidence = $this->normalizeFieldConfidence($raw['field_confidence'] ?? null, [
            'merchant_name' => strlen(trim((string) ($raw['merchant_name'] ?? ''))) >= 3 ? 0.84 : 0.42,
            'date' => $dateConfidence,
            'total_amount' => $totalAmount > 0 ? 0.86 : 0.38,
            'tax_amount' => $taxAmount > 0 ? 0.76 : 0.5,
            'service_amount' => $serviceAmount > 0 ? 0.76 : 0.5,
            'need_want' => $needWant === 'unknown' ? 0.52 : 0.74,
            'category' => strlen(trim((string) ($raw['category'] ?? ''))) >= 3 ? 0.8 : 0.5,
        ]);

        $transactions = $this->normalizeTransactions($raw['transactions'] ?? null, [
            'merchant_name' => (string) ($raw['merchant_name'] ?? ''),
            'date' => $date,
            'total_amount' => $totalAmount,
            'category' => (string) ($raw['category'] ?? 'Shopping'),
            'type' => $type,
            'notes' => '',
        ]);

        return [
            'merchant_name' => (string) ($raw['merchant_name'] ?? ''),
            'date' => $date,
            'total_amount' => $totalAmount,
            'tax_amount' => $taxAmount,
            'service_amount' => $serviceAmount,
            'need_want' => $needWant,
            'category' => (string) ($raw['category'] ?? 'Shopping'),
            'type' => $type,
            'items' => $items,
            'field_confidence' => $fieldConfidence,
            'transactions' => $transactions,
        ];
    }

    private function normalizeTransactions(mixed $raw, array $fallbackSingle): array
    {
        $list = [];
        if (is_array($raw)) {
            foreach ($raw as $item) {
                if (!is_array($item)) {
                    continue;
                }
                [$itemDate] = $this->normalizeDateWithConfidence((string) ($item['date'] ?? ''));
                $itemType = (string) ($item['type'] ?? 'expense');
                if (!in_array($itemType, ['expense', 'income'], true)) {
                    $itemType = 'expense';
                }
                $amount = $this->parseAmount($item['total_amount'] ?? 0);
                $category = trim((string) ($item['category'] ?? ''));
                if ($category === '') {
                    $category = $itemType === 'income' ? 'Other Income' : 'Other Expense';
                }
                $list[] = [
                    'merchant_name' => (string) ($item['merchant_name'] ?? ''),
                    'date' => $itemDate,
                    'total_amount' => $amount,
                    'category' => $category,
                    'type' => $itemType,
                    'notes' => (string) ($item['notes'] ?? ''),
                ];
            }
        }

        if ($list === []) {
            $fallbackAmount = (float) ($fallbackSingle['total_amount'] ?? 0);
            if ($fallbackAmount > 0 || trim((string) ($fallbackSingle['merchant_name'] ?? '')) !== '') {
                $list[] = [
                    'merchant_name' => (string) ($fallbackSingle['merchant_name'] ?? ''),
                    'date' => (string) ($fallbackSingle['date'] ?? now()->toIso8601String()),
                    'total_amount' => $fallbackAmount,
                    'category' => (string) ($fallbackSingle['category'] ?? 'Other Expense'),
                    'type' => (string) ($fallbackSingle['type'] ?? 'expense'),
                    'notes' => (string) ($fallbackSingle['notes'] ?? ''),
                ];
            }
        }

        return $list;
    }

    private function parseAmount(mixed $value): float
    {
        if (is_numeric($value)) {
            return (float) $value;
        }

        $raw = trim((string) $value);
        if ($raw === '') {
            return 0.0;
        }

        if (preg_match('/-?\d+(?:[.,]\d+)?/', $raw, $match) !== 1) {
            return 0.0;
        }

        $raw = $match[0];
        $raw = str_replace([' ', "\u{00A0}"], '', $raw);

        $hasComma = str_contains($raw, ',');
        $hasDot = str_contains($raw, '.');

        if ($hasComma && $hasDot) {
            $lastComma = strrpos($raw, ',');
            $lastDot = strrpos($raw, '.');
            if ($lastComma !== false && $lastDot !== false && $lastComma > $lastDot) {
                $normalized = str_replace('.', '', $raw);
                $normalized = str_replace(',', '.', $normalized);
            } else {
                $normalized = str_replace(',', '', $raw);
            }

            return is_numeric($normalized) ? (float) $normalized : 0.0;
        }

        if ($hasComma) {
            if (preg_match('/,\d{1,2}$/', $raw) === 1) {
                $normalized = str_replace(',', '.', $raw);
            } else {
                $normalized = str_replace(',', '', $raw);
            }

            return is_numeric($normalized) ? (float) $normalized : 0.0;
        }

        if ($hasDot) {
            if (preg_match('/\.\d{1,2}$/', $raw) === 1) {
                $normalized = $raw;
            } else {
                $normalized = str_replace('.', '', $raw);
            }

            return is_numeric($normalized) ? (float) $normalized : 0.0;
        }

        return is_numeric($raw) ? (float) $raw : 0.0;
    }

    private function normalizeDateWithConfidence(string $raw): array
    {
        $trimmed = trim($raw);
        if ($trimmed === '') {
            return [now()->toIso8601String(), 0.42];
        }

        $formats = [
            'Y-m-d\TH:i:sP',
            'Y-m-d H:i:s',
            'Y-m-d',
            'd/m/Y',
            'd-m-Y',
            'd.m.Y',
            'd/m/y',
            'd-m-y',
        ];

        foreach ($formats as $format) {
            try {
                $parsed = Carbon::createFromFormat($format, $trimmed);
                return [$parsed->toIso8601String(), 0.84];
            } catch (\Throwable $e) {
            }
        }

        try {
            return [Carbon::parse($trimmed)->toIso8601String(), 0.74];
        } catch (\Throwable $e) {
            return [now()->toIso8601String(), 0.4];
        }
    }

    private function normalizeDate(string $raw): string
    {
        [$date] = $this->normalizeDateWithConfidence($raw);
        return (string) $date;
    }

    private function normalizeFieldConfidence(mixed $raw, array $fallback): array
    {
        $source = is_array($raw) ? $raw : [];
        $keys = ['merchant_name', 'date', 'total_amount', 'tax_amount', 'service_amount', 'need_want', 'category'];

        $normalized = [];
        foreach ($keys as $key) {
            if (array_key_exists($key, $source) && is_numeric($source[$key])) {
                $normalized[$key] = $this->normalizeConfidence($source[$key]);
                continue;
            }
            $normalized[$key] = $this->normalizeConfidence($fallback[$key] ?? 0.5);
        }

        return $normalized;
    }

    private function normalizeConfidence(mixed $confidence): float
    {
        $value = is_numeric($confidence) ? (float) $confidence : 0.72;
        if ($value < 0) {
            return 0;
        }
        if ($value > 1) {
            return 1;
        }

        return $value;
    }

    private function fallbackResult(string $reason): array
    {
        return [
            'extracted' => [
                'merchant_name' => 'Scanned Merchant',
                'date' => now()->toIso8601String(),
                'total_amount' => 0,
                'tax_amount' => 0,
                'service_amount' => 0,
                'need_want' => 'unknown',
                'category' => 'Shopping',
                'type' => 'expense',
                'items' => [],
                'field_confidence' => [
                    'merchant_name' => 0.5,
                    'date' => 0.5,
                    'total_amount' => 0.45,
                    'tax_amount' => 0.5,
                    'service_amount' => 0.5,
                    'need_want' => 0.5,
                    'category' => 0.55,
                ],
                'transactions' => [],
            ],
            'confidence' => 0.55,
            'raw' => ['provider' => 'fallback', 'reason' => $reason],
        ];
    }
}
