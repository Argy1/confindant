<?php

namespace App\Models;

use Laravel\Sanctum\PersonalAccessToken as SanctumToken;

class PersonalAccessToken extends SanctumToken
{
    // Uses standard Sanctum SQL-based token storage (PostgreSQL)
}
