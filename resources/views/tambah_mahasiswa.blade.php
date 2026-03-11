<!DOCTYPE html>
<html>
<head><title>Tambah Mahasiswa</title></head>
<body style="font-family: sans-serif; margin: 20px;">
    <h3>Tambah Data Mahasiswa</h3>
    <form action="{{ route('mahasiswa.store') }}" method="POST">
        @csrf
        <label>Nama:</label><br>
        <input type="text" name="nama" required><br><br>

        <label>NIM:</label><br>
        <input type="text" name="nim" required><br><br>

        <label>Jenis Kelamin:</label><br>
        <select name="jenis_kelamin">
            <option value="Pria">Pria</option>
            <option value="Wanita">Wanita</option>
        </select><br><br>

        <label>Usia:</label><br>
        <input type="number" name="usia" required><br><br>

        <label>Kode Prodi:</label><br>
        <input type="text" name="kode_prodi" required><br><br>

        <label>Nama Prodi:</label><br>
        <input type="text" name="nama_prodi" required><br><br>

        <button type="submit">Simpan Data</button>
        <a href="{{ route('mahasiswa.index') }}">Batal</a>
    </form>
</body>
</html>