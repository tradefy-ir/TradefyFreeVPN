String flagEmoji(String countryCode) {
  final code = countryCode.trim().toUpperCase();
  if (code.length != 2) return '🌐';
  final first = code.codeUnitAt(0);
  final second = code.codeUnitAt(1);
  if (first < 65 || first > 90 || second < 65 || second > 90) {
    return '🌐';
  }
  return String.fromCharCodes(<int>[
    0x1F1E6 - 65 + first,
    0x1F1E6 - 65 + second,
  ]);
}
