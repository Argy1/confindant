<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Transaction extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'transactions';

    protected $fillable = [
        'user_id',
        'wallet_id',
        'type',
        'source',
        'category',
        'total_amount',
        'tax_amount',
        'service_amount',
        'need_want',
        'date',
        'merchant_name',
        'receipt_image_url',
        'notes',
        'is_verified',
        'items',
        'ocr_status',
        'ocr_confidence',
        'ocr_raw',
        'is_internal_transfer',
        'transfer_group_id',
        'tags',
        'ai_category',
        'ai_confidence',
        'ai_suggested',
        'ai_provider',
    ];

    protected $casts = [
        'total_amount' => 'float',
        'tax_amount' => 'float',
        'service_amount' => 'float',
        'need_want' => 'string',
        'is_verified' => 'boolean',
        'is_internal_transfer' => 'boolean',
        'date' => 'datetime',
        'source' => 'string',
        'tags' => 'array',
        'ai_confidence' => 'float',
        'ai_suggested' => 'boolean',
        'items' => 'array',
        'ocr_confidence' => 'float',
        'ocr_raw' => 'array',
    ];
}
