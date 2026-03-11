<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class UserNotification extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'user_notifications';

    protected $fillable = [
        'user_id',
        'title',
        'subtitle',
        'time_label',
        'read',
    ];

    protected $casts = [
        'read' => 'boolean',
    ];
}
