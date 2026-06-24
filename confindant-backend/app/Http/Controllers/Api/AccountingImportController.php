<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Services\Accounting\ExcelImportService;
use Illuminate\Http\Request;

class AccountingImportController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function __construct(private readonly ExcelImportService $importer)
    {
    }

    /**
     * Import the PDPI HARIAN sheet from an uploaded Excel file.
     * Use dry_run=true first to preview mapping coverage.
     */
    public function importHarian(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk import data', [], 403);
        }

        $validated = $request->validate([
            'file' => 'required|file|mimes:xlsx,xls|max:20480',
            'sheet_name' => 'nullable|string|max:64',
            'dry_run' => 'nullable|boolean',
        ]);

        $path = $validated['file']->getRealPath();
        $sheetName = $validated['sheet_name'] ?? 'HARIAN 2025';
        $dryRun = (bool) ($validated['dry_run'] ?? false);

        try {
            $result = $this->importer->importHarian(
                $org,
                $path,
                $sheetName,
                $dryRun,
                $request->user()->id
            );
        } catch (\Throwable $e) {
            return $this->fail('Gagal memproses file: '.$e->getMessage(), [], 422);
        }

        $message = $dryRun
            ? 'Preview import berhasil (belum disimpan)'
            : 'Import jurnal harian berhasil';

        return $this->ok($result, $message);
    }
}
