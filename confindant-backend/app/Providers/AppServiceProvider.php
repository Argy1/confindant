<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\ServiceProvider;
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
    }
}
