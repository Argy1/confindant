<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProfileSetting extends Model
{
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
