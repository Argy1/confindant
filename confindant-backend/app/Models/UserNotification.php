<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserNotification extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'subtitle',
        'time_label',
        'read',
        'event_key',
    ];

    protected $casts = [
        'read' => 'boolean',
    ];
}
