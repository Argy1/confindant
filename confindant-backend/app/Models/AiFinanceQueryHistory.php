<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiFinanceQueryHistory extends Model
{
    protected $table = 'ai_finance_query_history';

    protected $fillable = [
        'user_id',
        'organization_id',
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
