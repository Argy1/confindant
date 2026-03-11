<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model; 

class Mahasiswa extends Model
{
    protected $connection = 'mongodb';
    protected $table = 'mahasiswa'; 
    protected $collection = 'mahasiswa'; 
    
    protected $primaryKey = '_id';

    protected $fillable = [
        'nim',
        'nama',
        'jenis_kelamin',
        'prodi',
        'usia'
    ];

    // HAPUS 'prodi' => 'array'
    protected $casts = [
        'usia' => 'integer', 
    ];
}