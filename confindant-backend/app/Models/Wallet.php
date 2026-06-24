<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    protected $fillable = [
        'user_id',
        'wallet_name',
        'balance',
        'wallet_color',
    ];

    protected $casts = [
        'balance' => 'float',
    ];
}
