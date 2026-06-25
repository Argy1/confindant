@extends('reports.pdf-layout')

@section('title', 'LAPORAN NERACA (BALANCE SHEET)')
@section('subtitle', 'Per ' . \Carbon\Carbon::parse($asOf)->translatedFormat('d F Y'))

@section('content')
<div style="margin-bottom:8px;">
  <span class="{{ $isBalanced ? 'badge-balanced' : 'badge-unbalanced' }}">
    {{ $isBalanced ? '✓ Neraca Seimbang' : '✗ Neraca Tidak Seimbang (Selisih: Rp ' . number_format(abs($difference), 0, ',', '.') . ')' }}
  </span>
</div>

<div class="grid-2">
  {{-- ASET --}}
  <div class="col">
    <h3>Aset</h3>
    <table>
      <thead>
        <tr>
          <th>Kode</th><th>Nama Akun</th><th class="text-right">Saldo</th>
        </tr>
      </thead>
      <tbody>
        @foreach($assets['accounts'] ?? [] as $acc)
        <tr>
          <td class="font-mono">{{ $acc['code'] }}</td>
          <td class="indent">{{ $acc['name'] }}</td>
          <td class="text-right amount">{{ number_format($acc['amount'], 0, ',', '.') }}</td>
        </tr>
        @endforeach
        <tr class="total-row">
          <td colspan="2">Total Aset</td>
          <td class="text-right amount">{{ number_format($totals['total_assets'], 0, ',', '.') }}</td>
        </tr>
      </tbody>
    </table>
  </div>

  {{-- KEWAJIBAN + ASET BERSIH --}}
  <div class="col">
    <h3>Kewajiban</h3>
    <table>
      <thead>
        <tr>
          <th>Kode</th><th>Nama Akun</th><th class="text-right">Saldo</th>
        </tr>
      </thead>
      <tbody>
        @foreach($liabilities['accounts'] ?? [] as $acc)
        <tr>
          <td class="font-mono">{{ $acc['code'] }}</td>
          <td class="indent">{{ $acc['name'] }}</td>
          <td class="text-right amount">{{ number_format($acc['amount'], 0, ',', '.') }}</td>
        </tr>
        @endforeach
        <tr class="subtotal-row">
          <td colspan="2">Total Kewajiban</td>
          <td class="text-right amount">{{ number_format($totals['total_liabilities'], 0, ',', '.') }}</td>
        </tr>
      </tbody>
    </table>

    <h3>Aset Bersih</h3>
    <table>
      <tbody>
        @foreach($netAssets['accounts'] ?? [] as $acc)
        <tr>
          <td class="font-mono">{{ $acc['code'] }}</td>
          <td class="indent">{{ $acc['name'] }}</td>
          <td class="text-right amount">{{ number_format($acc['amount'], 0, ',', '.') }}</td>
        </tr>
        @endforeach
        <tr>
          <td colspan="2" class="indent" style="color:#475569;">Perubahan Aset Bersih</td>
          <td class="text-right amount">{{ number_format($netAssets['change_in_net_assets'], 0, ',', '.') }}</td>
        </tr>
        <tr class="subtotal-row">
          <td colspan="2">Total Aset Bersih</td>
          <td class="text-right amount">{{ number_format($netAssets['total'], 0, ',', '.') }}</td>
        </tr>
      </tbody>
    </table>

    <table>
      <tbody>
        <tr class="total-row">
          <td>Total Kewajiban + Aset Bersih</td>
          <td class="text-right amount">{{ number_format($totals['total_liabilities_and_net_assets'], 0, ',', '.') }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
@endsection
