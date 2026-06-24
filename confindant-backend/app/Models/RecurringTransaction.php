<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RecurringTransaction extends Model
{
    protected $fillable = [
        'user_id',
        'wallet_id',
        'type',
        'source',
        'category',
        'amount',
        'merchant_name',
        'notes',
        'is_verified',
        'tags',
        'frequency',
        'interval',
        'start_date',
        'next_run_at',
        'last_run_at',
        'end_date',
        'active',
        'total_runs',
        'last_error_code',
        'last_error_message',
    ];

    protected $casts = [
        'amount' => 'float',
        'is_verified' => 'boolean',
        'tags' => 'array',
        'active' => 'boolean',
        'interval' => 'integer',
        'total_runs' => 'integer',
        'start_date' => 'datetime',
        'next_run_at' => 'datetime',
        'last_run_at' => 'datetime',
        'end_date' => 'datetime',
    ];
}
