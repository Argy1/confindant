<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiFeedback extends Model
{
    protected $fillable = [
        'user_id',
        'transaction_id',
        'input_context',
        'suggested_category',
        'final_category',
        'accepted',
        'confidence',
        'provider',
        'created_at_client',
    ];

    protected $casts = [
        'input_context' => 'array',
        'accepted' => 'boolean',
        'confidence' => 'float',
        'created_at_client' => 'datetime',
    ];
}
