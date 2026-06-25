@extends('reports.pdf-layout')

@section('title', 'NERACA SALDO (TRIAL BALANCE)')
@section('subtitle', 'Per ' . \Carbon\Carbon::parse($asOf)->translatedFormat('d F Y'))

@section('content')
<table>
  <thead>
    <tr>
      <th style="width:70px">Kode</th>
      <th>Nama Akun</th>
      <th class="text-right" style="width:120px">Debit (Rp)</th>
      <th class="text-right" style="width:120px">Kredit (Rp)</th>
    </tr>
  </thead>
  <tbody>
    @foreach($accounts as $acc)
    <tr>
      <td class="font-mono">{{ $acc['code'] }}</td>
      <td>{{ $acc['name'] }}</td>
      <td class="text-right amount">{{ $acc['debit'] > 0 ? number_format($acc['debit'], 0, ',', '.') : '—' }}</td>
      <td class="text-right amount">{{ $acc['credit'] > 0 ? number_format($acc['credit'], 0, ',', '.') : '—' }}</td>
    </tr>
    @endforeach
    <tr class="total-row">
      <td colspan="2">TOTAL</td>
      <td class="text-right amount">{{ number_format($totalDebit, 0, ',', '.') }}</td>
      <td class="text-right amount">{{ number_format($totalCredit, 0, ',', '.') }}</td>
    </tr>
    <tr>
      <td colspan="4" class="text-right" style="padding-top:6px; font-size:9px; color:{{ $isBalanced ? '#16a34a' : '#dc2626' }}; font-weight:bold;">
        {{ $isBalanced ? '✓ Neraca Saldo Seimbang' : '✗ Tidak Seimbang — Selisih: Rp ' . number_format(abs($totalDebit - $totalCredit), 0, ',', '.') }}
      </td>
    </tr>
  </tbody>
</table>
@endsection
