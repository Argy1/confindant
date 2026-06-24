<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Habit extends Model
{
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
