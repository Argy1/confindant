<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class ReceiptOcrFeedback extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'receipt_ocr_feedback';

    protected $fillable = [
        'user_id',
        'ocr_job_id',
        'transaction_id',
        'accepted',
        'source_mode',
        'changed_fields',
        'edited_field_count',
        'field_confidence',
        'meta',
        'created_at_client',
    ];

    protected $casts = [
        'accepted' => 'boolean',
        'changed_fields' => 'array',
        'field_confidence' => 'array',
        'meta' => 'array',
    ];
}

