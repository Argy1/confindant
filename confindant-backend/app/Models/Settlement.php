<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Settlement extends Model
{
    protected $fillable = [
        'receivable_payable_id',
        'journal_entry_id',
        'date',
        'amount',
        'notes',
    ];

    protected $casts = [
        'date' => 'date',
        'amount' => 'float',
    ];

    public function receivablePayable(): BelongsTo
    {
        return $this->belongsTo(ReceivablePayable::class, 'receivable_payable_id');
    }
}
