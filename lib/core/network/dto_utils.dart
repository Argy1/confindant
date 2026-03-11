String normalizeId(Map<String, dynamic> dto) {
  final id = dto['id']?.toString();
  if (id != null && id.isNotEmpty) return id;
  return dto['_id']?.toString() ?? '';
}

double asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
