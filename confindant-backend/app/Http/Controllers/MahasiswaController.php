<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

use App\Models\Mahasiswa;
use function PHPUnit\Framework\returnArgument;

class MahasiswaController extends Controller
{
    // READ: Menampilkan semua data
    public function index() {
        $mahasiswa = Mahasiswa::all();
        
        return response()->json([
            'status' => 'success',
            'message' => 'Data mahasiswa berhasil diambil',
            'data' => $mahasiswa
        ], 200);
    }

    // CREATE: Menampilkan form tambah
    public function create() {
        return view('tambah_mahasiswa');
    }

    // CREATE: Menyimpan data ke database
    public function store(Request $request) {
        DB::connection('mongodb')->table('mahasiswa')->insert([
            'nama' => $request->nama,
            'nim' => $request->nim,
            'jenis_kelamin' => $request->jenis_kelamin,
            'usia' => (int) $request->usia,
            'prodi' => [
                'kode' => $request->kode_prodi,
                'nama' => $request->nama_prodi
            ]
        ]);
        return redirect()->route('mahasiswa.index');
    }

    // UPDATE: Menampilkan form edit
    public function edit($id) {
        $mhs = DB::connection('mongodb')->table('mahasiswa')->where('_id', $id)->first();
        return view('edit_mahasiswa', compact('mhs'));
    }

    // UPDATE: Menyimpan perubahan data
    public function update(Request $request, $id) {
        DB::connection('mongodb')->table('mahasiswa')->where('_id', $id)->update([
            'nama' => $request->nama,
            'nim' => $request->nim,
            'jenis_kelamin' => $request->jenis_kelamin,
            'usia' => (int) $request->usia,
            'prodi' => [
                'kode' => $request->kode_prodi,
                'nama' => $request->nama_prodi
            ]
        ]);
        return redirect()->route('mahasiswa.index');
    }

    // DELETE: Menghapus data
    public function destroy($id){
        $mahasiswa = Mahasiswa::find($id);
        if (!$mahasiswa) {
            return response()->json(['message' => 'Mahasiswa not found'], 404);
        }
        $mahasiswa->delete();
        return response()->json(['message' => 'Mahasiswa deleted']);
    }

    /// SHOW
    public function show($id)
    {
        return mahasiswa::find($id);
    }
}