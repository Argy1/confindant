<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Budget extends Model
{
    protected $fillable = [
        'user_id',
        'category',
        'limit_amount',
        'period_month',
        'alert_threshold',
    ];

    protected $casts = [
        'limit_amount' => 'float',
        'alert_threshold' => 'float',
    ];
}
