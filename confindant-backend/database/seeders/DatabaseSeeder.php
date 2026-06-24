<?php

namespace Database\Seeders;

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
        User::factory()->create([
            'username' => 'Test User',
            'email' => 'test@example.com',
        ]);

        // Seed PDPI organization with its full Chart of Accounts.
        $this->call(PdpiChartOfAccountsSeeder::class);
    }
}
