<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class RestrictedFund extends Model
{
    protected $fillable = [
        'organization_id',
        'name',
        'fund_type',
        'account_id',
        'balance',
        'status',
        'notes',
    ];

    protected $casts = [
        'balance' => 'float',
    ];

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function movements(): HasMany
    {
        return $this->hasMany(RestrictedFundMovement::class);
    }
}
