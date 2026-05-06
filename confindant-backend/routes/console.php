<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command(sprintf(
    'maintenance:cleanup --notifications-days=%d --ocr-days=%d --ai-feedback-days=%d',
    (int) env('NOTIFICATION_RETENTION_DAYS', 180),
    (int) env('OCR_JOB_RETENTION_DAYS', 60),
    (int) env('AI_FEEDBACK_RETENTION_DAYS', 365),
))->dailyAt('02:00');
Schedule::command(sprintf(
    'queue:prune-failed --hours=%d',
    (int) env('FAILED_JOB_RETENTION_HOURS', 168),
))->dailyAt('02:10');
Schedule::command('recurring:process')->everyFiveMinutes();
