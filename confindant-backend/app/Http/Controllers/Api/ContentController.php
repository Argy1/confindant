<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;

class ContentController extends Controller
{
    use ApiResponse;

    public function privacy()
    {
        return $this->ok([
            'title' => 'Privacy Policy',
            'content' => 'Confindant mengumpulkan data akun dan transaksi untuk menampilkan dashboard, analytics, dan fitur budgeting. Data tidak dijual ke pihak ketiga, serta diproses untuk kebutuhan operasional aplikasi.',
            'version' => '1.0.0',
            'effective_date' => '2026-03-01',
        ], 'Konten privacy policy berhasil diambil');
    }

    public function terms()
    {
        return $this->ok([
            'title' => 'Terms of Service',
            'content' => 'Dengan menggunakan Confindant, pengguna bertanggung jawab atas input data keuangan yang dimasukkan. Fitur analitik dan OCR bersifat asistif dan bukan nasihat finansial resmi.',
            'version' => '1.0.0',
            'effective_date' => '2026-03-01',
        ], 'Konten terms berhasil diambil');
    }

    public function supportChannels()
    {
        return $this->ok([
            'email' => 'support@confindant.app',
            'whatsapp' => '+628112345678',
            'report_hint' => 'Kirim detail issue, screenshot, waktu kejadian, dan versi app.',
        ], 'Channel support berhasil diambil');
    }
}

