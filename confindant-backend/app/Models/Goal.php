<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Goal extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'target_amount',
        'current_amount',
        'target_date_label',
        'linked_wallet',
        'contributions',
        'auto_topup_enabled',
        'auto_topup_percent',
    ];

    protected $casts = [
        'target_amount' => 'float',
        'current_amount' => 'float',
        'contributions' => 'array',
        'auto_topup_enabled' => 'boolean',
        'auto_topup_percent' => 'float',
    ];
}
