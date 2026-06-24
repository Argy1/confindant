<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReceiptOcrFeedback extends Model
{
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
        'edited_field_count' => 'integer',
        'created_at_client' => 'datetime',
    ];
}
