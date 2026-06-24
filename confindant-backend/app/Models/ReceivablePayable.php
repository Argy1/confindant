<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ReceivablePayable extends Model
{
    protected $table = 'receivables_payables';

    public const TYPE_RECEIVABLE = 'receivable';
    public const TYPE_PAYABLE = 'payable';

    protected $fillable = [
        'organization_id',
        'type',
        'party_name',
        'category',
        'account_id',
        'description',
        'original_amount',
        'settled_amount',
        'outstanding_amount',
        'issued_date',
        'due_date',
        'status',
        'period_label',
    ];

    protected $casts = [
        'original_amount' => 'float',
        'settled_amount' => 'float',
        'outstanding_amount' => 'float',
        'issued_date' => 'date',
        'due_date' => 'date',
    ];

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function settlements(): HasMany
    {
        return $this->hasMany(Settlement::class, 'receivable_payable_id');
    }
}
