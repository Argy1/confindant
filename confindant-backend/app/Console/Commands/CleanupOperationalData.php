<?php

namespace App\Console\Commands;

use App\Models\AiFeedback;
use App\Models\ReceiptOcrJob;
use App\Models\UserNotification;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class CleanupOperationalData extends Command
{
    protected $signature = 'maintenance:cleanup
        {--notifications-days=180 : Retention window for notifications}
        {--ocr-days=60 : Retention window for OCR jobs}
        {--ai-feedback-days=365 : Retention window for AI feedback}';

    protected $description = 'Cleanup old operational data (notifications, OCR jobs, AI feedback)';

    public function handle(): int
    {
        $notificationDays = max(1, (int) $this->option('notifications-days'));
        $ocrDays = max(1, (int) $this->option('ocr-days'));
        $aiFeedbackDays = max(1, (int) $this->option('ai-feedback-days'));

        $notificationCutoff = Carbon::now()->subDays($notificationDays);
        $ocrCutoff = Carbon::now()->subDays($ocrDays);
        $aiFeedbackCutoff = Carbon::now()->subDays($aiFeedbackDays);

        $deletedNotifications = UserNotification::where('created_at', '<', $notificationCutoff)->delete();

        $oldOcrJobs = ReceiptOcrJob::where('created_at', '<', $ocrCutoff)->get();
        $deletedOcrImages = 0;
        foreach ($oldOcrJobs as $job) {
            $url = (string) ($job->receipt_image_url ?? '');
            if ($url !== '' && str_contains($url, '/storage/')) {
                $relativePath = ltrim(substr($url, strpos($url, '/storage/') + 9), '/');
                if ($relativePath !== '' && Storage::disk('public')->exists($relativePath)) {
                    Storage::disk('public')->delete($relativePath);
                    $deletedOcrImages++;
                }
            }
        }
        $deletedOcrJobs = ReceiptOcrJob::where('created_at', '<', $ocrCutoff)->delete();

        $deletedAiFeedback = AiFeedback::where('created_at', '<', $aiFeedbackCutoff)->delete();

        $this->info("Deleted notifications: {$deletedNotifications} (>{$notificationDays} days)");
        $this->info("Deleted OCR jobs: {$deletedOcrJobs} (>{$ocrDays} days)");
        $this->info("Deleted OCR images: {$deletedOcrImages}");
        $this->info("Deleted AI feedback rows: {$deletedAiFeedback} (>{$aiFeedbackDays} days)");

        return self::SUCCESS;
    }
}

