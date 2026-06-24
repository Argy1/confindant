<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FixedAsset extends Model
{
    protected $fillable = [
        'organization_id',
        'name',
        'group',
        'acquisition_date',
        'acquisition_cost',
        'depreciation_rate',
        'method',
        'salvage_value',
        'asset_account_id',
        'accumulated_depreciation_account_id',
        'depreciation_expense_account_id',
        'accumulated_depreciation',
        'book_value',
        'is_active',
        'notes',
    ];

    protected $casts = [
        'acquisition_date' => 'date',
        'acquisition_cost' => 'float',
        'depreciation_rate' => 'float',
        'salvage_value' => 'float',
        'accumulated_depreciation' => 'float',
        'book_value' => 'float',
        'is_active' => 'boolean',
    ];

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function depreciations(): HasMany
    {
        return $this->hasMany(AssetDepreciation::class);
    }
}
