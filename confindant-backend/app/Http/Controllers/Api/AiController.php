<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\AiFeedback;
use App\Models\AiFinanceQueryHistory;
use App\Models\ReceiptOcrFeedback;
use App\Models\ReceiptOcrJob;
use App\Models\Transaction;
use App\Services\AiCategorizationService;
use App\Services\AiFinanceInsightService;
use App\Services\AiFinanceQueryService;
use App\Services\AiTransactionParseService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AiController extends Controller
{
    use ApiResponse;

    public function categorizeTransaction(Request $request, AiCategorizationService $service)
    {
        $validated = $request->validate([
            'type' => 'required|in:income,expense',
            'merchant_name' => 'nullable|string|max:255',
            'source' => 'nullable|string|max:255',
            'notes' => 'nullable|string|max:1000',
            'total_amount' => 'nullable|numeric|min:0',
        ]);

        $result = $service->categorize($validated);

        return $this->ok([
            'category' => $result['category'],
            'confidence' => $result['confidence'],
            'suggested' => true,
            'provider' => $result['provider'],
        ], 'AI kategori transaksi berhasil dibuat', [
            'fallback' => (bool) ($result['fallback'] ?? false),
        ]);
    }

    public function feedbackTransactionCategory(Request $request)
    {
        $validated = $request->validate([
            'transaction_id' => 'nullable|string',
            'input_context' => 'nullable|array',
            'suggested_category' => 'required|string|max:255',
            'final_category' => 'required|string|max:255',
            'accepted' => 'required|boolean',
            'confidence' => 'nullable|numeric|min:0|max:1',
            'provider' => 'nullable|string|max:64',
            'created_at_client' => 'nullable|date',
        ]);

        $transactionId = $validated['transaction_id'] ?? null;
        if ($transactionId) {
            $transaction = Transaction::where('_id', (string) $transactionId)
                ->where('user_id', (string) $request->user()->_id)
                ->first();
            if (!$transaction) {
                return $this->fail('Transaksi tidak ditemukan', [], 404);
            }
        }

        $feedback = AiFeedback::create([
            'user_id' => (string) $request->user()->_id,
            'transaction_id' => $transactionId,
            'input_context' => $validated['input_context'] ?? null,
            'suggested_category' => $validated['suggested_category'],
            'final_category' => $validated['final_category'],
            'accepted' => (bool) $validated['accepted'],
            'confidence' => isset($validated['confidence']) ? (float) $validated['confidence'] : null,
            'provider' => $validated['provider'] ?? 'unknown',
            'created_at_client' => $validated['created_at_client'] ?? null,
        ]);

        return $this->ok($feedback, 'Feedback AI kategori berhasil disimpan', [], 201);
    }

    public function cashflowForecast(Request $request, AiFinanceInsightService $service)
    {
        $validated = $request->validate([
            'days' => 'nullable|integer|min:1|max:90',
            'wallet_id' => 'nullable|string',
        ]);

        $forecast = $service->cashflowForecast(
            (string) $request->user()->_id,
            (int) ($validated['days'] ?? 30),
            $validated['wallet_id'] ?? null
        );

        return $this->ok($forecast, 'AI cashflow forecast berhasil diambil');
    }

    public function budgetRecommendations(Request $request, AiFinanceInsightService $service)
    {
        $validated = $request->validate([
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
            'wallet_id' => 'nullable|string',
        ]);

        $fromDate = isset($validated['from_date'])
            ? Carbon::parse($validated['from_date'])->startOfDay()
            : null;
        $toDate = isset($validated['to_date'])
            ? Carbon::parse($validated['to_date'])->endOfDay()
            : null;

        $recommendations = $service->budgetRecommendations(
            (string) $request->user()->_id,
            $fromDate,
            $toDate,
            $validated['wallet_id'] ?? null
        );

        return $this->ok($recommendations, 'AI budget recommendations berhasil diambil');
    }

    public function ocrMetrics(Request $request)
    {
        $validated = $request->validate([
            'days' => 'nullable|integer|min:1|max:365',
        ]);

        $days = (int) ($validated['days'] ?? 30);
        $userId = (string) $request->user()->_id;
        $from = now()->subDays($days);

        $jobs = ReceiptOcrJob::where('user_id', $userId)
            ->where('created_at', '>=', $from)
            ->get();
        $feedback = ReceiptOcrFeedback::where('user_id', $userId)
            ->where('created_at', '>=', $from)
            ->get();

        $totalJobs = $jobs->count();
        $successJobs = $jobs->where('status', 'success')->count();
        $failedJobs = $jobs->where('status', 'failed')->count();
        $pendingJobs = $jobs->where('status', 'pending')->count()
            + $jobs->where('status', 'processing')->count();

        $successRate = $totalJobs > 0 ? round(($successJobs / $totalJobs) * 100, 2) : 0.0;
        $avgConfidence = round(
            (float) $jobs->where('status', 'success')->avg(function ($item) {
                return (float) ($item->confidence ?? 0);
            }),
            4
        );

        $errorCodeBreakdown = $jobs
            ->where('status', 'failed')
            ->groupBy(fn ($item) => (string) ($item->error_code ?? 'unknown'))
            ->map(fn ($rows, $code) => [
                'error_code' => $code,
                'count' => $rows->count(),
            ])
            ->values()
            ->sortByDesc('count')
            ->values();

        $changedFieldScores = [];
        foreach ($feedback as $item) {
            foreach ((array) ($item->changed_fields ?? []) as $field) {
                $key = (string) $field;
                if ($key === '') {
                    continue;
                }
                if (!isset($changedFieldScores[$key])) {
                    $changedFieldScores[$key] = 0;
                }
                $changedFieldScores[$key]++;
            }
        }
        arsort($changedFieldScores);
        $topChangedFields = collect($changedFieldScores)->map(
            fn ($count, $field) => [
                'field' => (string) $field,
                'count' => (int) $count,
            ]
        )->values()->take(5)->values();

        $acceptedCount = $feedback->where('accepted', true)->count();
        $feedbackCount = $feedback->count();
        $acceptanceRate = $feedbackCount > 0
            ? round(($acceptedCount / $feedbackCount) * 100, 2)
            : 0.0;

        return $this->ok([
            'window_days' => $days,
            'jobs' => [
                'total' => $totalJobs,
                'success' => $successJobs,
                'failed' => $failedJobs,
                'pending_or_processing' => $pendingJobs,
                'success_rate_percent' => $successRate,
                'avg_confidence' => $avgConfidence,
            ],
            'feedback' => [
                'total' => $feedbackCount,
                'accepted' => $acceptedCount,
                'acceptance_rate_percent' => $acceptanceRate,
            ],
            'top_changed_fields' => $topChangedFields,
            'error_code_breakdown' => $errorCodeBreakdown,
        ], 'AI OCR metrics berhasil diambil');
    }

    public function budgetSimulation(Request $request, AiFinanceInsightService $service)
    {
        $validated = $request->validate([
            'category' => 'required|string|max:255',
            'change_percent' => 'required|numeric|min:-50|max:50',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
            'wallet_id' => 'nullable|string',
        ]);

        $fromDate = isset($validated['from_date'])
            ? Carbon::parse($validated['from_date'])->startOfDay()
            : null;
        $toDate = isset($validated['to_date'])
            ? Carbon::parse($validated['to_date'])->endOfDay()
            : null;

        $simulation = $service->simulateBudgetAdjustment(
            (string) $request->user()->_id,
            (string) $validated['category'],
            (float) $validated['change_percent'],
            $fromDate,
            $toDate,
            $validated['wallet_id'] ?? null
        );

        if (($simulation['error'] ?? null) === 'budget_not_found') {
            return $this->fail((string) ($simulation['message'] ?? 'Budget tidak ditemukan'), [], 404);
        }

        return $this->ok($simulation, 'AI budget simulation berhasil diambil');
    }

    public function financeQuery(Request $request, AiFinanceQueryService $service)
    {
        $validated = $request->validate([
            'query' => 'required|string|max:1000',
            'locale' => 'nullable|in:id,en',
        ]);

        $result = $service->answer(
            (string) $request->user()->_id,
            (string) $validated['query'],
            $validated['locale'] ?? null
        );

        $saved = AiFinanceQueryHistory::create([
            'user_id' => (string) $request->user()->_id,
            'query' => (string) $result['query'],
            'locale' => $validated['locale'] ?? null,
            'period' => $result['period'] ?? null,
            'answer' => (string) ($result['answer'] ?? ''),
            'insight' => (string) ($result['insight'] ?? ''),
            'suggested_actions' => $result['suggested_actions'] ?? [],
            'metrics' => $result['metrics'] ?? [],
            'provider' => (string) ($result['provider'] ?? 'unknown'),
            'fallback' => (bool) ($result['fallback'] ?? false),
        ]);

        $result['history_id'] = (string) ($saved->_id ?? '');

        return $this->ok($result, 'AI finance query berhasil diproses');
    }

    public function parseTransactionInput(Request $request, AiTransactionParseService $service)
    {
        $validated = $request->validate([
            'transcript' => 'required|string|max:2000',
            'locale' => 'nullable|in:id,en',
        ]);

        $result = $service->parse([
            'transcript' => (string) $validated['transcript'],
            'locale' => $validated['locale'] ?? null,
        ]);

        return $this->ok([
            'type' => $result['type'],
            'amount' => $result['amount'],
            'category' => $result['category'],
            'source' => $result['source'],
            'merchant_name' => $result['merchant_name'],
            'notes' => $result['notes'],
            'date' => $result['date'],
            'confidence' => $result['confidence'],
            'provider' => $result['provider'],
            'fallback' => $result['fallback'],
        ], 'AI voice transaction parse berhasil');
    }

    public function financeQueryHistory(Request $request)
    {
        $validated = $request->validate([
            'limit' => 'nullable|integer|min:1|max:100',
        ]);

        $limit = (int) ($validated['limit'] ?? 20);
        $items = AiFinanceQueryHistory::where('user_id', (string) $request->user()->_id)
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get();

        return $this->ok($items, 'Riwayat AI finance query berhasil diambil');
    }

    public function clearFinanceQueryHistory(Request $request)
    {
        AiFinanceQueryHistory::where('user_id', (string) $request->user()->_id)->delete();

        return $this->ok(null, 'Riwayat AI finance query berhasil dihapus');
    }

    public function renameFinanceQueryHistoryItem(Request $request, string $id)
    {
        $validated = $request->validate([
            'query' => 'required|string|max:1000',
        ]);

        $item = AiFinanceQueryHistory::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();
        if (!$item) {
            return $this->fail('Riwayat AI tidak ditemukan', [], 404);
        }

        $item->update([
            'query' => trim((string) $validated['query']),
        ]);

        return $this->ok($item->fresh(), 'Riwayat AI berhasil diubah');
    }

    public function deleteFinanceQueryHistoryItem(Request $request, string $id)
    {
        $item = AiFinanceQueryHistory::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();
        if (!$item) {
            return $this->fail('Riwayat AI tidak ditemukan', [], 404);
        }

        $item->delete();

        return $this->ok(null, 'Riwayat AI berhasil dihapus');
    }
}
