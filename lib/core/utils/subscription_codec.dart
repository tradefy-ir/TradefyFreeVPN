import 'dart:convert';

String decodeSubscriptionBody(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.contains('://')) return trimmed;

  final compact = trimmed.replaceAll(RegExp(r'\s'), '');
  try {
    final decoded = utf8.decode(base64.decode(_normalizeBase64(compact)));
    if (decoded.contains('://')) return decoded;
  } catch (_) {}
  return trimmed;
}

String _normalizeBase64(String value) {
  var output = value.replaceAll('-', '+').replaceAll('_', '/');
  final remainder = output.length % 4;
  if (remainder > 0) {
    output = output.padRight(output.length + (4 - remainder), '=');
  }
  return output;
}
