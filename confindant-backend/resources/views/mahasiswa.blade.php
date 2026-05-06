<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Data Mahasiswa</title>
    <style>
        body { font-family: sans-serif; margin: 20px; }
        h3 { text-align: left; margin-bottom: 10px; font-size: 16px; }
        table { width: 100%; border-collapse: collapse; font-size: 14px; margin-top: 15px; }
        th, td { border: 1px solid #000; padding: 8px; text-align: left; }
        th { background-color: transparent; }
        .btn { padding: 5px 10px; text-decoration: none; color: white; border-radius: 3px; border: none; cursor: pointer; font-size: 12px; }
        .btn-tambah { background-color: #28a745; margin-bottom: 15px; display: inline-block; font-size: 14px; }
        .btn-edit { background-color: #ffc107; color: #000; }
        .btn-hapus { background-color: #dc3545; }
    </style>
</head>
<body>

    <h3>Daftar Mahasiswa</h3>
    <a href="{{ route('mahasiswa.create') }}" class="btn btn-tambah">Tambah Data Baru</a>

    <table>
        <thead>
            <tr>
                <th>Nama</th>
                <th>NIM</th>
                <th>Jenis Kelamin</th>
                <th>Usia</th>
                <th>Prodi</th>
                <th>Aksi</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($mahasiswa as $mhs)
                <tr>
                    <td>{{ $mhs->nama }}</td>
                    <td>{{ $mhs->nim }}</td>
                    <td>{{ $mhs->jenis_kelamin }}</td>
                    <td>{{ $mhs->usia }}</td>
                    <td>{{ $mhs->prodi['kode'] ?? '' }}, {{ $mhs->prodi['nama'] ?? '' }}</td>
                    <td>
                        <a href="{{ route('mahasiswa.edit', $mhs->nim) }}" class="btn btn-edit">Edit</a>
                        <form action="{{ route('mahasiswa.destroy', $mhs->nim) }}" method="POST" style="display:inline;">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="btn btn-hapus" onclick="return confirm('Yakin ingin menghapus data ini?')">Hapus</button>
                        </form>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="6" style="text-align: center;">Belum ada data mahasiswa di database.</td>
                </tr>
            @endforelse
        </tbody>
    </table>

</body>
</html>