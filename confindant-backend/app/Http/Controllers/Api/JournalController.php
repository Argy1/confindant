<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\JournalEntry;
use App\Services\Accounting\AccountingService;
use Illuminate\Http\Request;
use InvalidArgumentException;

class JournalController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function __construct(private readonly AccountingService $accounting)
    {
    }

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
            'status' => 'nullable|in:draft,posted,void',
            'per_page' => 'nullable|integer|min:1|max:100',
            'page' => 'nullable|integer|min:1',
        ]);

        $perPage = (int) ($validated['per_page'] ?? 25);
        $page = (int) ($validated['page'] ?? 1);

        $query = JournalEntry::with('lines.account')
            ->where('organization_id', $org->id)
            ->orderBy('date', 'desc')
            ->orderBy('id', 'desc');

        if (!empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }
        if (!empty($validated['from_date'])) {
            $query->whereDate('date', '>=', $validated['from_date']);
        }
        if (!empty($validated['to_date'])) {
            $query->whereDate('date', '<=', $validated['to_date']);
        }

        $total = $query->count();
        $entries = $query->skip(($page - 1) * $perPage)->take($perPage)->get();

        return $this->ok($entries, 'Daftar jurnal berhasil diambil', [
            'page' => $page,
            'per_page' => $perPage,
            'total' => $total,
            'has_more' => ($page * $perPage) < $total,
        ]);
    }

    public function show(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $entry = JournalEntry::with('lines.account')
            ->where('organization_id', $org->id)
            ->where('id', $id)
            ->first();
        if (!$entry) {
            return $this->fail('Jurnal tidak ditemukan', [], 404);
        }

        return $this->ok($entry, 'Detail jurnal berhasil diambil');
    }

    public function store(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk membuat jurnal', [], 403);
        }

        $validated = $request->validate([
            'date' => 'required|date',
            'description' => 'required|string|max:1000',
            'reference' => 'nullable|string|max:128',
            'category' => 'nullable|string|max:64',
            'classification' => 'nullable|string|max:64',
            'lines' => 'required|array|min:2',
            'lines.*.account_id' => 'required|integer',
            'lines.*.debit' => 'nullable|numeric|min:0',
            'lines.*.credit' => 'nullable|numeric|min:0',
            'lines.*.memo' => 'nullable|string|max:255',
        ]);

        try {
            $entry = $this->accounting->createEntry([
                'organization_id' => $org->id,
                'date' => $validated['date'],
                'description' => $validated['description'],
                'reference' => $validated['reference'] ?? null,
                'category' => $validated['category'] ?? null,
                'classification' => $validated['classification'] ?? null,
                'source' => 'manual',
                'created_by' => $request->user()->id,
                'posted_by' => $request->user()->id,
            ], $validated['lines']);
        } catch (InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), [], 422);
        }

        return $this->ok($entry, 'Jurnal berhasil dibuat dan diposting', [], 201);
    }

    public function void(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk membatalkan jurnal', [], 403);
        }

        $entry = JournalEntry::with('lines')
            ->where('organization_id', $org->id)
            ->where('id', $id)
            ->first();
        if (!$entry) {
            return $this->fail('Jurnal tidak ditemukan', [], 404);
        }

        $this->accounting->voidEntry($entry, $request->user()->id);

        return $this->ok($entry->fresh('lines'), 'Jurnal berhasil dibatalkan (dibuat pembalik)');
    }
}
