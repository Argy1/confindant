<?php

namespace App\Console\Commands;

use App\Models\UserNotification;
use Carbon\Carbon;
use Illuminate\Console\Command;

class CleanupNotifications extends Command
{
    protected $signature = 'notifications:cleanup {--days=180 : Retention window in days}';
    protected $description = 'Delete old user notifications based on retention policy';

    public function handle(): int
    {
        $days = max(1, (int) $this->option('days'));
        $cutoff = Carbon::now()->subDays($days);

        $deleted = UserNotification::where('created_at', '<', $cutoff)->delete();
        $this->info("Deleted {$deleted} notifications older than {$days} days.");

        return self::SUCCESS;
    }
}

