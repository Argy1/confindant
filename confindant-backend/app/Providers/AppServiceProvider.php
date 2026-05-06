<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\RateLimiter;
use Laravel\Sanctum\Sanctum;

use App\Models\PersonalAccessToken; 

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        Sanctum::usePersonalAccessTokenModel(PersonalAccessToken::class);

        RateLimiter::for('auth-api', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip());
        });

        RateLimiter::for('scan-upload', function (Request $request) {
            $userKey = $request->user()?->getAuthIdentifier() ?? $request->ip();
            return Limit::perMinute(20)->by((string) $userKey);
        });

        RateLimiter::for('ocr-poll', function (Request $request) {
            $userKey = $request->user()?->getAuthIdentifier() ?? $request->ip();
            return Limit::perMinute(30)->by((string) $userKey);
        });

        RateLimiter::for('ai-inference', function (Request $request) {
            $userKey = $request->user()?->getAuthIdentifier() ?? $request->ip();
            return Limit::perMinute(20)->by((string) $userKey);
        });

        $this->ensureMongoIndexes();
    }

    private function ensureMongoIndexes(): void
    {
        try {
            $database = DB::connection('mongodb')->getMongoDB();
            $database->selectCollection('transactions')->createIndex([
                'user_id' => 1,
                'wallet_id' => 1,
                'date' => -1,
                'created_at' => -1,
                'type' => 1,
                'is_internal_transfer' => 1,
            ]);
            $database->selectCollection('transactions')->createIndex([
                'user_id' => 1,
                'tags' => 1,
                'date' => -1,
            ]);
            $database->selectCollection('transactions')->createIndex([
                'user_id' => 1,
                'ai_category' => 1,
                'date' => -1,
            ]);
            $database->selectCollection('transactions')->updateMany(
                [
                    'type' => 'income',
                    '$or' => [
                        ['source' => ['$exists' => false]],
                        ['source' => null],
                        ['source' => ''],
                    ],
                ],
                ['$set' => ['source' => 'Other']]
            );
            $database->selectCollection('goals')->updateMany(
                [
                    '$or' => [
                        ['auto_topup_enabled' => ['$exists' => false]],
                        ['auto_topup_percent' => ['$exists' => false]],
                    ],
                ],
                [
                    '$set' => [
                        'auto_topup_enabled' => false,
                        'auto_topup_percent' => 0,
                    ],
                ]
            );
            $database->selectCollection('wallets')->createIndex(['user_id' => 1]);
            $database->selectCollection('budgets')->createIndex(['user_id' => 1]);
            $database->selectCollection('user_notifications')->createIndex([
                'user_id' => 1,
                'created_at' => -1,
            ]);
            $database->selectCollection('ai_feedback')->createIndex([
                'user_id' => 1,
                'created_at' => -1,
            ]);
            $database->selectCollection('ai_feedback')->createIndex([
                'transaction_id' => 1,
                'created_at' => -1,
            ]);
            $database->selectCollection('ai_finance_query_history')->createIndex([
                'user_id' => 1,
                'created_at' => -1,
            ]);
            $database->selectCollection('user_notifications')->createIndex([
                'user_id' => 1,
                'event_key' => 1,
            ]);
            $database->selectCollection('receipt_ocr_jobs')->createIndex([
                'user_id' => 1,
                'created_at' => -1,
            ]);
            $database->selectCollection('receipt_ocr_jobs')->createIndex([
                'status' => 1,
                'updated_at' => -1,
            ]);
            $database->selectCollection('receipt_ocr_feedback')->createIndex([
                'user_id' => 1,
                'created_at' => -1,
            ]);
            $database->selectCollection('receipt_ocr_feedback')->createIndex([
                'ocr_job_id' => 1,
                'created_at' => -1,
            ]);
            $database->selectCollection('recurring_transactions')->createIndex([
                'user_id' => 1,
                'active' => 1,
                'next_run_at' => 1,
            ]);
        } catch (\Throwable $e) {
            // Ignore index bootstrap failures in local environments.
        }
    }
}
