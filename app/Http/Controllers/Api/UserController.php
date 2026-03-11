<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash; // Untuk enkripsi password

class UserController extends Controller
{
    // ==========================================
    // 1. REGISTER (Daftar Akun Baru)
    // ==========================================
    public function register(Request $request)
    {
        $request->validate([
            'username' => 'required|string|max:255',
            'email'    => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
        ]);

        // Buat user baru (Password otomatis di-hash karena setingan 'casts' di Model)
        $user = User::create([
            'username' => $request->username,
            'email'    => $request->email,
            'password' => Hash::make($request->password), // Enkripsi password!
        ]);

        // Langsung cetak Token API untuk user ini
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success'      => true,
            'message'      => 'Register Berhasil',
            'data'         => $user,
            'access_token' => $token,
            'token_type'   => 'Bearer',
        ], 201);
    }

    // ==========================================
    // 2. LOGIN (Masuk Akun)
    // ==========================================
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|string|email',
            'password' => 'required|string',
        ]);

        // Cari user berdasarkan email
        $user = User::where('email', $request->email)->first();

        // Cek apakah user ada DAN passwordnya cocok
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau Password salah!'
            ], 401);
        }

        // Cetak Token API
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success'      => true,
            'message'      => 'Login Berhasil',
            'data'         => $user,
            'access_token' => $token, // INI DIA TOKEN-NYA!
            'token_type'   => 'Bearer',
        ], 200);
    }

    // ==========================================
    // 3. LOGOUT (Hapus Token)
    // ==========================================
    public function logout(Request $request)
    {
        // Hapus token yang sedang dipakai oleh user ini
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout Berhasil, Token dihapus'
        ], 200);
    }
}