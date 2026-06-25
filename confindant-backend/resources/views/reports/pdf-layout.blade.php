<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'DejaVu Sans', sans-serif; font-size: 10px; color: #1e293b; background: #fff; }
  .page { padding: 32px 36px; }
  .header { border-bottom: 2px solid #1e3a5f; padding-bottom: 12px; margin-bottom: 20px; }
  .org-name { font-size: 15px; font-weight: bold; color: #1e3a5f; }
  .report-title { font-size: 12px; font-weight: bold; margin-top: 2px; }
  .report-subtitle { font-size: 9px; color: #64748b; margin-top: 2px; }
  .footer { margin-top: 24px; padding-top: 10px; border-top: 1px solid #e2e8f0; font-size: 8px; color: #94a3b8; display: flex; justify-content: space-between; }
  h3 { font-size: 10px; font-weight: bold; color: #1e3a5f; margin-bottom: 6px; margin-top: 16px; text-transform: uppercase; letter-spacing: 0.05em; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }
  th { background: #f1f5f9; font-weight: bold; text-align: left; padding: 5px 8px; font-size: 9px; color: #475569; }
  td { padding: 4px 8px; border-bottom: 1px solid #f1f5f9; font-size: 9.5px; }
  .text-right { text-align: right; }
  .text-center { text-align: center; }
  .font-mono { font-family: 'Courier New', monospace; font-size: 9px; }
  .total-row td { font-weight: bold; border-top: 1.5px solid #cbd5e1; border-bottom: 2px double #94a3b8; background: #f8fafc; }
  .subtotal-row td { font-weight: 600; border-top: 1px solid #e2e8f0; background: #f8fafc; }
  .section-header td { font-weight: bold; background: #eff6ff; color: #1e40af; font-size: 10px; }
  .amount { font-family: 'Courier New', monospace; }
  .badge-balanced { color: #16a34a; font-weight: bold; }
  .badge-unbalanced { color: #dc2626; font-weight: bold; }
  .grid-2 { display: table; width: 100%; }
  .col { display: table-cell; width: 50%; vertical-align: top; padding-right: 16px; }
  .col:last-child { padding-right: 0; padding-left: 8px; }
  .indent { padding-left: 20px !important; }
</style>
</head>
<body>
<div class="page">
  <div class="header">
    <div class="org-name">{{ $orgName }}</div>
    <div class="report-title">@yield('title')</div>
    <div class="report-subtitle">@yield('subtitle')</div>
  </div>

  @yield('content')

  <div class="footer">
    <span>Dicetak: {{ now()->setTimezone('Asia/Jakarta')->format('d M Y, H:i') }} WIB</span>
    <span>Confindant — Sistem Akuntansi Organisasi</span>
  </div>
</div>
</body>
</html>
