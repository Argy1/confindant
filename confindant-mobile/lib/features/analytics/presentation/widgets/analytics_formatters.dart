String formatRupiah(double value) {
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
