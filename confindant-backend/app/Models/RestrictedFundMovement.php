<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RestrictedFundMovement extends Model
{
    protected $fillable = [
        'restricted_fund_id',
        'journal_entry_id',
        'date',
        'direction',
        'amount',
        'balance_after',
        'description',
    ];

    protected $casts = [
        'date' => 'date',
        'amount' => 'float',
        'balance_after' => 'float',
    ];

    public function restrictedFund(): BelongsTo
    {
        return $this->belongsTo(RestrictedFund::class);
    }
}
