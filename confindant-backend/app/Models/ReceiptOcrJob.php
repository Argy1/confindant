<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class ReceiptOcrJob extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'receipt_ocr_jobs';

    protected $fillable = [
        'user_id',
        'status',
        'confidence',
        'error_code',
        'error_message',
        'receipt_image_url',
        'raw',
        'extracted',
    ];

    protected $casts = [
        'confidence' => 'float',
        'raw' => 'array',
        'extracted' => 'array',
    ];
}

