<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RecurringOrgEntry extends Model
{
    protected $fillable = [
        'organization_id',
        'debit_account_id',
        'credit_account_id',
        'description',
        'category',
        'amount',
        'frequency',
        'interval',
        'start_date',
        'next_run_at',
        'last_run_at',
        'end_date',
        'active',
        'total_runs',
        'created_by',
    ];

    protected $casts = [
        'amount'      => 'float',
        'interval'    => 'integer',
        'total_runs'  => 'integer',
        'active'      => 'boolean',
        'start_date'  => 'date',
        'end_date'    => 'date',
        'next_run_at' => 'datetime',
        'last_run_at' => 'datetime',
    ];

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function debitAccount(): BelongsTo
    {
        return $this->belongsTo(Account::class, 'debit_account_id');
    }

    public function creditAccount(): BelongsTo
    {
        return $this->belongsTo(Account::class, 'credit_account_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
