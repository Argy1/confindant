<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiFinanceQueryHistory extends Model
{
    protected $fillable = [
        'user_id',
        'query',
        'locale',
        'period',
        'answer',
        'insight',
        'suggested_actions',
        'metrics',
        'provider',
        'fallback',
    ];

    protected $casts = [
        'period' => 'array',
        'suggested_actions' => 'array',
        'metrics' => 'array',
        'fallback' => 'boolean',
    ];
}
