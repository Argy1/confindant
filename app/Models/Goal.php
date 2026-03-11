<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Goal extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'goals';

    protected $fillable = [
        'user_id',
        'name',
        'target_amount',
        'current_amount',
        'target_date_label',
        'linked_wallet',
        'contributions',
    ];

    protected $casts = [
        'target_amount' => 'float',
        'current_amount' => 'float',
        'contributions' => 'array',
    ];
}
