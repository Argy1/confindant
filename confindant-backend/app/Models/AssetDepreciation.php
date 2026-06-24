<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AssetDepreciation extends Model
{
    protected $fillable = [
        'fixed_asset_id',
        'accounting_period_id',
        'journal_entry_id',
        'year',
        'amount',
        'accumulated_after',
        'book_value_after',
    ];

    protected $casts = [
        'year' => 'integer',
        'amount' => 'float',
        'accumulated_after' => 'float',
        'book_value_after' => 'float',
    ];

    public function fixedAsset(): BelongsTo
    {
        return $this->belongsTo(FixedAsset::class);
    }
}
