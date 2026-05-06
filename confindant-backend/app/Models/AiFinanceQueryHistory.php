<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class AiFinanceQueryHistory extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'ai_finance_query_history';

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

