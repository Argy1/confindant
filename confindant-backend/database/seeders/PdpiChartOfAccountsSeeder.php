<?php

namespace Database\Seeders;

use App\Models\Account;
use App\Models\AccountingPeriod;
use App\Models\Organization;
use Illuminate\Database\Seeder;

/**
 * Seeds the PDPI organization with its Chart of Accounts, derived from the
 * 2025 Neraca + Laporan Aktivitas + Buku Besar structure.
 *
 * Account codes follow the common nonprofit numbering:
 *   1-xxxx Aset, 2-xxxx Kewajiban, 3-xxxx Aset Bersih,
 *   4-xxxx Pendapatan, 5-xxxx Beban
 */
class PdpiChartOfAccountsSeeder extends Seeder
{
    public function run(): void
    {
        $org = Organization::firstOrCreate(
            ['slug' => 'pdpi'],
            [
                'name' => 'Perhimpunan Dokter Paru Indonesia',
                'legal_name' => 'Lembaga Perhimpunan Dokter Paru Indonesia',
                'bank_account' => '1000151651',
                'currency' => 'IDR',
                'fiscal_year_start' => '01-01',
            ]
        );

        AccountingPeriod::firstOrCreate(
            ['organization_id' => $org->id, 'year' => 2025],
            [
                'name' => '2025',
                'start_date' => '2025-01-01',
                'end_date' => '2025-12-31',
                'status' => 'open',
                'opening_cash_balance' => 705926775.71,
            ]
        );

        foreach ($this->accounts() as $sort => $acc) {
            Account::updateOrCreate(
                ['organization_id' => $org->id, 'code' => $acc['code']],
                [
                    'name' => $acc['name'],
                    'type' => $acc['type'],
                    'subtype' => $acc['subtype'] ?? null,
                    'normal_balance' => $acc['normal_balance']
                        ?? Account::normalBalanceForType($acc['type']),
                    'is_contra' => $acc['is_contra'] ?? false,
                    'is_active' => true,
                    'sort_order' => $sort,
                ]
            );
        }
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function accounts(): array
    {
        return [
            // ================= ASET (1-xxxx) =================
            // Aset Lancar
            ['code' => '1-1000', 'name' => 'Kas dan Setara Kas', 'type' => 'asset', 'subtype' => 'current_asset'],
            ['code' => '1-1100', 'name' => 'Piutang Kegiatan', 'type' => 'asset', 'subtype' => 'current_asset'],
            ['code' => '1-1200', 'name' => 'Piutang Lain', 'type' => 'asset', 'subtype' => 'current_asset'],
            // Aset Tidak Lancar
            ['code' => '1-2000', 'name' => 'Tanah', 'type' => 'asset', 'subtype' => 'fixed_asset'],
            ['code' => '1-2100', 'name' => 'Bangunan', 'type' => 'asset', 'subtype' => 'fixed_asset'],
            ['code' => '1-2150', 'name' => 'Akumulasi Penyusutan Bangunan', 'type' => 'asset', 'subtype' => 'fixed_asset', 'is_contra' => true],
            ['code' => '1-2200', 'name' => 'Peralatan Kantor', 'type' => 'asset', 'subtype' => 'fixed_asset'],
            ['code' => '1-2250', 'name' => 'Akumulasi Penyusutan Peralatan Kantor', 'type' => 'asset', 'subtype' => 'fixed_asset', 'is_contra' => true],

            // ================= KEWAJIBAN (2-xxxx) =================
            ['code' => '2-1000', 'name' => 'Hutang Kegiatan', 'type' => 'liability', 'subtype' => 'current_liability'],
            ['code' => '2-1100', 'name' => 'Hutang Pajak', 'type' => 'liability', 'subtype' => 'current_liability'],
            ['code' => '2-1200', 'name' => 'Hutang Iuran Anggota APSR', 'type' => 'liability', 'subtype' => 'current_liability'],
            ['code' => '2-1300', 'name' => 'Hutang Iuran Anggota ERS', 'type' => 'liability', 'subtype' => 'current_liability'],
            ['code' => '2-1400', 'name' => 'Dana Titipan Cabang', 'type' => 'liability', 'subtype' => 'restricted_fund'],
            ['code' => '2-1500', 'name' => 'Dana Titipan Kegiatan Ilmiah', 'type' => 'liability', 'subtype' => 'restricted_fund'],
            ['code' => '2-1900', 'name' => 'Hutang Lain-Lain', 'type' => 'liability', 'subtype' => 'current_liability'],

            // ================= ASET BERSIH (3-xxxx) =================
            ['code' => '3-1000', 'name' => 'Aset Bersih Tanpa Pembatasan', 'type' => 'net_asset', 'subtype' => 'unrestricted'],
            ['code' => '3-2000', 'name' => 'Aset Bersih Dengan Pembatasan', 'type' => 'net_asset', 'subtype' => 'restricted'],

            // ================= PENDAPATAN (4-xxxx) =================
            ['code' => '4-1000', 'name' => 'Iuran Anggota PDPI', 'type' => 'revenue', 'subtype' => 'operating_revenue'],
            ['code' => '4-1100', 'name' => 'Iuran Anggota APSR', 'type' => 'revenue', 'subtype' => 'operating_revenue'],
            ['code' => '4-1200', 'name' => 'Iuran Anggota ERS', 'type' => 'revenue', 'subtype' => 'operating_revenue'],
            ['code' => '4-2000', 'name' => 'Donasi Kegiatan', 'type' => 'revenue', 'subtype' => 'operating_revenue'],
            ['code' => '4-3000', 'name' => 'SHU WCBIP', 'type' => 'revenue', 'subtype' => 'operating_revenue'],
            ['code' => '4-3100', 'name' => 'SHU POTI', 'type' => 'revenue', 'subtype' => 'operating_revenue'],
            ['code' => '4-3200', 'name' => 'SHU Perbronki', 'type' => 'revenue', 'subtype' => 'operating_revenue'],
            ['code' => '4-3300', 'name' => 'SHU Konas', 'type' => 'revenue', 'subtype' => 'operating_revenue'],
            ['code' => '4-9000', 'name' => 'Pemasukan Lain', 'type' => 'revenue', 'subtype' => 'other_revenue'],

            // ================= BEBAN (5-xxxx) =================
            // Beban Kegiatan
            ['code' => '5-1000', 'name' => 'Biaya Akomodasi & Transportasi', 'type' => 'expense', 'subtype' => 'program_expense'],
            ['code' => '5-1100', 'name' => 'Biaya Honor', 'type' => 'expense', 'subtype' => 'program_expense'],
            ['code' => '5-1200', 'name' => 'Biaya Pembuatan Buku', 'type' => 'expense', 'subtype' => 'program_expense'],
            ['code' => '5-1300', 'name' => 'Biaya Seminar & SKP', 'type' => 'expense', 'subtype' => 'program_expense'],
            ['code' => '5-1400', 'name' => 'Biaya Webinar & SKP', 'type' => 'expense', 'subtype' => 'program_expense'],
            ['code' => '5-1500', 'name' => 'Biaya Workshop & SKP', 'type' => 'expense', 'subtype' => 'program_expense'],
            ['code' => '5-1600', 'name' => 'Biaya Iuran APSR Pengurus Pusat', 'type' => 'expense', 'subtype' => 'program_expense'],
            ['code' => '5-1700', 'name' => 'Biaya Iuran ERS', 'type' => 'expense', 'subtype' => 'program_expense'],
            ['code' => '5-1900', 'name' => 'Biaya Kegiatan Lain', 'type' => 'expense', 'subtype' => 'program_expense'],
            // Beban Kesekretariatan
            ['code' => '5-2000', 'name' => 'Biaya Gaji', 'type' => 'expense', 'subtype' => 'admin_expense'],
            ['code' => '5-2100', 'name' => 'Biaya THR', 'type' => 'expense', 'subtype' => 'admin_expense'],
            ['code' => '5-2200', 'name' => 'Biaya Kesekretariatan Lainnya', 'type' => 'expense', 'subtype' => 'admin_expense'],
            ['code' => '5-2300', 'name' => 'Biaya Pembelian Perlengkapan Kantor', 'type' => 'expense', 'subtype' => 'admin_expense'],
            // Beban Lain-Lain
            ['code' => '5-3000', 'name' => 'Biaya Penyusutan Bangunan', 'type' => 'expense', 'subtype' => 'other_expense'],
            ['code' => '5-3100', 'name' => 'Biaya Penyusutan Peralatan Kantor', 'type' => 'expense', 'subtype' => 'other_expense'],
            ['code' => '5-3200', 'name' => 'Biaya Administrasi Bank', 'type' => 'expense', 'subtype' => 'other_expense'],
            ['code' => '5-3300', 'name' => 'Biaya Pajak', 'type' => 'expense', 'subtype' => 'other_expense'],
            ['code' => '5-3400', 'name' => 'Biaya Renovasi Rumah', 'type' => 'expense', 'subtype' => 'other_expense'],
            ['code' => '5-9000', 'name' => 'Biaya Pengeluaran Lain', 'type' => 'expense', 'subtype' => 'other_expense'],
        ];
    }
}
