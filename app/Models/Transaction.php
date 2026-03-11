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
        'total_amount',
        'date',
        'merchant_name',
        'receipt_image_url',
        'notes',
        'is_verified',
        'items', // array-nya
    ];

    protected $casts = [
        'total_amount' => 'float',
        'is_verified' => 'boolean',
        'date' => 'datetime',
        'items' => 'array', // Beritahu Laravel ini adalah Array/Embedded
    ];
}