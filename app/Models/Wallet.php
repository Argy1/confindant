<?php

namespace App\Models;

// PERHATIKAN BARIS INI: Gunakan Model dari package MongoDB
use MongoDB\Laravel\Eloquent\Model; 

class Wallet extends Model
{
    // Tentukan koneksi dan nama collection
    protected $connection = 'mongodb';
    protected $collection = 'wallets';

    // Kolom apa saja yang boleh diisi (Mass Assignment)
    protected $fillable = [
        'user_id',
        'wallet_name',
        'balance',
    ];

    // Opsional: Casting tipe data agar selalu benar saat ditarik/disimpan
    protected $casts = [
        'balance' => 'float',
    ];
}