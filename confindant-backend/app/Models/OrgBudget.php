<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrgBudget extends Model
{
    protected $fillable = [
        'organization_id',
        'fiscal_year',
        'name',
        'category',
        'account_id',
        'amount_planned',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'amount_planned' => 'float',
        'fiscal_year'    => 'integer',
    ];

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function account(): BelongsTo
    {
        return $this->belongsTo(Account::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
