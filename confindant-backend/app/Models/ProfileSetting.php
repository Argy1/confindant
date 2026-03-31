<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class ProfileSetting extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'profile_settings';

    protected $fillable = [
        'user_id',
        'full_name',
        'username',
        'email',
        'phone',
        'currency',
        'avatar_path',
        'notification_settings',
        'faq_items',
        'about_info',
    ];

    protected $casts = [
        'notification_settings' => 'array',
        'faq_items' => 'array',
        'about_info' => 'array',
    ];
}
