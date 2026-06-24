<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Account extends Model
{
    public const TYPE_ASSET = 'asset';
    public const TYPE_LIABILITY = 'liability';
    public const TYPE_NET_ASSET = 'net_asset';
    public const TYPE_REVENUE = 'revenue';
    public const TYPE_EXPENSE = 'expense';

    protected $fillable = [
        'organization_id',
        'code',
        'name',
        'type',
        'subtype',
        'normal_balance',
        'parent_id',
        'is_contra',
        'opening_balance',
        'is_active',
        'sort_order',
        'description',
    ];

    protected $casts = [
        'is_contra' => 'boolean',
        'is_active' => 'boolean',
        'opening_balance' => 'float',
        'sort_order' => 'integer',
    ];

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(Account::class, 'parent_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(Account::class, 'parent_id');
    }

    public function lines(): HasMany
    {
        return $this->hasMany(JournalLine::class);
    }

    /**
     * Normal balance side for a given account type.
     */
    public static function normalBalanceForType(string $type): string
    {
        return in_array($type, [self::TYPE_ASSET, self::TYPE_EXPENSE], true)
            ? 'debit'
            : 'credit';
    }

    /**
     * Signed balance respecting the account's normal balance.
     * Returns a positive number when the account has its expected balance.
     */
    public function signedBalance(float $debitSum, float $creditSum): float
    {
        $raw = $this->normal_balance === 'debit'
            ? $debitSum - $creditSum
            : $creditSum - $debitSum;

        // Contra accounts (e.g. Akumulasi Penyusutan) are presented as reductions.
        return $this->is_contra ? -1 * abs($raw) : $raw;
    }
}
