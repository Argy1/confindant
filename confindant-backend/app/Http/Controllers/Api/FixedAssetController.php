<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Models\FixedAsset;
use App\Services\Accounting\DepreciationService;
use Illuminate\Http\Request;
use InvalidArgumentException;

class FixedAssetController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    /**
     * Default account mapping per asset group, by account code.
     */
    private const GROUP_ACCOUNTS = [
        'PERLENGKAPAN' => [
            'asset' => '1-2200',
            'accumulated' => '1-2250',
            'expense' => '5-3100',
            'rate' => 0.25,
        ],
        'BANGUNAN' => [
            'asset' => '1-2100',
            'accumulated' => '1-2150',
            'expense' => '5-3000',
            'rate' => 0.05,
        ],
    ];

    public function __construct(private readonly DepreciationService $depreciation)
    {
    }

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $assets = FixedAsset::where('organization_id', $org->id)
            ->orderBy('group')
            ->orderBy('acquisition_date')
            ->get();

        $summary = [
            'total_acquisition_cost' => round((float) $assets->sum('acquisition_cost'), 2),
            'total_accumulated_depreciation' => round((float) $assets->sum('accumulated_depreciation'), 2),
            'total_book_value' => round((float) $assets->sum('book_value'), 2),
            'count' => $assets->count(),
        ];

        return $this->ok($assets, 'Daftar aktiva tetap berhasil diambil', $summary);
    }

    public function store(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk menambah aset', [], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'group' => 'required|string|in:PERLENGKAPAN,BANGUNAN,TANAH',
            'acquisition_date' => 'required|date',
            'acquisition_cost' => 'required|numeric|min:0',
            'depreciation_rate' => 'nullable|numeric|min:0|max:1',
            'salvage_value' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string|max:500',
        ]);

        $group = $validated['group'];
        $mapping = self::GROUP_ACCOUNTS[$group] ?? null;

        $assetAccountId = null;
        $accumulatedAccountId = null;
        $expenseAccountId = null;
        $rate = $validated['depreciation_rate'] ?? ($mapping['rate'] ?? 0);

        if ($mapping) {
            $assetAccountId = $this->accountId($org->id, $mapping['asset']);
            $accumulatedAccountId = $this->accountId($org->id, $mapping['accumulated']);
            $expenseAccountId = $this->accountId($org->id, $mapping['expense']);
        }
        // TANAH tidak disusutkan (rate 0, tanpa akun akumulasi/beban).

        $asset = FixedAsset::create([
            'organization_id' => $org->id,
            'name' => $validated['name'],
            'group' => $group,
            'acquisition_date' => $validated['acquisition_date'],
            'acquisition_cost' => $validated['acquisition_cost'],
            'depreciation_rate' => $group === 'TANAH' ? 0 : $rate,
            'method' => 'straight_line',
            'salvage_value' => $validated['salvage_value'] ?? 0,
            'asset_account_id' => $assetAccountId,
            'accumulated_depreciation_account_id' => $accumulatedAccountId,
            'depreciation_expense_account_id' => $expenseAccountId,
            'accumulated_depreciation' => 0,
            'book_value' => $validated['acquisition_cost'],
            'is_active' => true,
            'notes' => $validated['notes'] ?? null,
        ]);

        return $this->ok($asset, 'Aktiva tetap berhasil ditambahkan', [], 201);
    }

    public function show(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $asset = FixedAsset::with('depreciations')
            ->where('organization_id', $org->id)
            ->where('id', $id)
            ->first();
        if (!$asset) {
            return $this->fail('Aset tidak ditemukan', [], 404);
        }

        return $this->ok($asset, 'Detail aset berhasil diambil', [
            'annual_depreciation' => round($this->depreciation->annualAmount($asset), 2),
        ]);
    }

    public function destroy(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk menghapus aset', [], 403);
        }

        $asset = FixedAsset::where('organization_id', $org->id)->where('id', $id)->first();
        if (!$asset) {
            return $this->fail('Aset tidak ditemukan', [], 404);
        }

        $asset->update(['is_active' => false]);

        return $this->ok(null, 'Aset dinonaktifkan');
    }

    /**
     * Run depreciation for all assets for a given year.
     */
    public function runDepreciation(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk menjalankan penyusutan', [], 403);
        }

        $validated = $request->validate([
            'year' => 'required|integer|min:2000|max:2100',
        ]);

        try {
            $result = $this->depreciation->runForOrganization(
                $org->id,
                (int) $validated['year'],
                $request->user()->id
            );
        } catch (InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), [], 422);
        }

        return $this->ok($result, "Penyusutan tahun {$validated['year']} berhasil dijalankan");
    }

    private function accountId(int $organizationId, string $code): ?int
    {
        return Account::where('organization_id', $organizationId)
            ->where('code', $code)
            ->value('id');
    }
}
