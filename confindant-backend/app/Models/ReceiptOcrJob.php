<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReceiptOcrJob extends Model
{
    protected $fillable = [
        'user_id',
        'status',
        'confidence',
        'error_code',
        'error_message',
        'receipt_image_url',
        'raw',
        'extracted',
        'queued_at',
        'started_at',
        'finished_at',
    ];

    protected $casts = [
        'confidence' => 'float',
        'raw' => 'array',
        'extracted' => 'array',
        'queued_at' => 'datetime',
        'started_at' => 'datetime',
        'finished_at' => 'datetime',
    ];
}
