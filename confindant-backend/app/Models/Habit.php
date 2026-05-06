<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Habit extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'habits';

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'target_count',
        'current_count',
        'frequency',
        'active',
    ];

    protected $casts = [
        'target_count' => 'integer',
        'current_count' => 'integer',
        'active' => 'boolean',
    ];
}
