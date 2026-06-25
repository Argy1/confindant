@extends('reports.pdf-layout')

@section('title', 'LAPORAN AKTIVITAS (STATEMENT OF ACTIVITIES)')
@section('subtitle', 'Periode ' . \Carbon\Carbon::parse($from)->translatedFormat('d F Y') . ' s.d. ' . \Carbon\Carbon::parse($to)->translatedFormat('d F Y'))

@section('content')
<table>
  <thead>
    <tr>
      <th style="width:60px">Kode</th>
      <th>Nama Akun</th>
      <th class="text-right" style="width:120px">Jumlah (Rp)</th>
    </tr>
  </thead>
  <tbody>
    {{-- PENDAPATAN --}}
    <tr class="section-header">
      <td colspan="3">PENDAPATAN</td>
    </tr>
    @foreach($revenue['accounts'] ?? [] as $acc)
    <tr>
      <td class="font-mono">{{ $acc['code'] }}</td>
      <td class="indent">{{ $acc['name'] }}</td>
      <td class="text-right amount">{{ number_format($acc['amount'], 0, ',', '.') }}</td>
    </tr>
    @endforeach
    <tr class="subtotal-row">
      <td colspan="2">Total Pendapatan</td>
      <td class="text-right amount">{{ number_format($totals['total_revenue'], 0, ',', '.') }}</td>
    </tr>

    {{-- BEBAN --}}
    <tr><td colspan="3" style="padding:6px 0;"></td></tr>
    <tr class="section-header">
      <td colspan="3">BEBAN</td>
    </tr>
    @foreach($expense['accounts'] ?? [] as $acc)
    <tr>
      <td class="font-mono">{{ $acc['code'] }}</td>
      <td class="indent">{{ $acc['name'] }}</td>
      <td class="text-right amount">{{ number_format($acc['amount'], 0, ',', '.') }}</td>
    </tr>
    @endforeach
    <tr class="subtotal-row">
      <td colspan="2">Total Beban</td>
      <td class="text-right amount">{{ number_format($totals['total_expense'], 0, ',', '.') }}</td>
    </tr>

    {{-- SURPLUS/DEFISIT --}}
    <tr><td colspan="3" style="padding:4px 0;"></td></tr>
    <tr class="total-row">
      <td colspan="2">
        {{ $totals['change_in_net_assets'] >= 0 ? 'SURPLUS (Kenaikan Aset Bersih)' : 'DEFISIT (Penurunan Aset Bersih)' }}
      </td>
      <td class="text-right amount" style="{{ $totals['change_in_net_assets'] >= 0 ? 'color:#16a34a' : 'color:#dc2626' }}">
        {{ number_format($totals['change_in_net_assets'], 0, ',', '.') }}
      </td>
    </tr>
  </tbody>
</table>
@endsection
