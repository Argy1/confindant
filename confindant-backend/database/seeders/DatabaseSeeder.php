<?php

namespace Database\Seeders;

use App\Models\Organization;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $user = User::factory()->create([
            'username' => 'Test User',
            'email' => 'test@example.com',
        ]);

        // Seed PDPI organization with its full Chart of Accounts.
        $this->call(PdpiChartOfAccountsSeeder::class);

        // Give the test user bendahara access to PDPI so the org workspace works.
        $pdpi = Organization::where('slug', 'pdpi')->first();
        if ($pdpi) {
            $pdpi->users()->syncWithoutDetaching([
                $user->id => ['role' => 'bendahara'],
            ]);
        }
    }
}
