// Currency formatters for the organization accounting module.

String formatOrgRupiah(double value) {
  final isNegative = value < 0;
  final digits = value.abs().round().toString();
  final grouped = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final indexFromRight = digits.length - i;
    grouped.write(digits[i]);
    if (indexFromRight > 1 && indexFromRight % 3 == 1) {
      grouped.write('.');
    }
  }

  final prefix = isNegative ? '-Rp ' : 'Rp ';
  return '$prefix$grouped';
}

/// Compact currency for dashboard cards: Rp 7,29 M / Rp 550 jt / Rp 12 rb.
String formatOrgRupiahCompact(double value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1000000000) {
    return '${sign}Rp ${(abs / 1000000000).toStringAsFixed(2)} M';
  }
  if (abs >= 1000000) {
    return '${sign}Rp ${(abs / 1000000).toStringAsFixed(1)} jt';
  }
  if (abs >= 1000) {
    return '${sign}Rp ${(abs / 1000).toStringAsFixed(0)} rb';
  }
  return '${sign}Rp ${abs.toStringAsFixed(0)}';
}

/// Indonesian label for an account subtype used in report grouping.
String orgSubtypeLabel(String? subtype) {
  switch (subtype) {
    case 'current_asset':
      return 'Aset Lancar';
    case 'fixed_asset':
      return 'Aset Tidak Lancar';
    case 'current_liability':
      return 'Kewajiban Lancar';
    case 'restricted_fund':
      return 'Dana Titipan';
    case 'unrestricted':
      return 'Tanpa Pembatasan';
    case 'restricted':
      return 'Dengan Pembatasan';
    case 'operating_revenue':
      return 'Pendapatan Operasi';
    case 'other_revenue':
      return 'Pendapatan Lain';
    case 'program_expense':
      return 'Beban Kegiatan';
    case 'admin_expense':
      return 'Beban Kesekretariatan';
    case 'other_expense':
      return 'Beban Lain-Lain';
    default:
      return 'Lainnya';
  }
}

String orgFormatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
}
