<?php

namespace App\Models;

// 1. Kita warisi model asli milik Sanctum (yang berbasis SQL)
use Laravel\Sanctum\PersonalAccessToken as SanctumToken;

// 2. Kita panggil "kekuatan" MongoDB
use MongoDB\Laravel\Eloquent\DocumentModel;

class PersonalAccessToken extends SanctumToken
{
    // 3. Suntikkan kekuatan MongoDB ke dalam model SQL ini!
    use DocumentModel;

    protected $connection = 'mongodb';
    protected $collection = 'personal_access_tokens';
    protected $primaryKey = '_id'; // Wajib didefinisikan untuk MongoDB
}