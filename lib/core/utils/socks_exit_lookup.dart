import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tradefy_vpn/data/geo_service.dart';

/// Resolves the public exit IP by fetching ip-api through the local SOCKS port.
Future<GeoResult?> lookupExitThroughSocks({
  String proxyHost = '127.0.0.1',
  int proxyPort = 10808,
  Duration timeout = const Duration(seconds: 12),
}) async {
  Socket? socket;
  StreamIterator<List<int>>? iterator;
  try {
    socket = await Socket.connect(proxyHost, proxyPort, timeout: timeout);
    iterator = StreamIterator(socket);
    final reader = _BufferedReader(iterator);
    await _socks5Connect(socket, reader, 'ip-api.com', 80);
    socket.write(
      'GET /json?fields=status,country,countryCode,query HTTP/1.0\r\n'
      'Host: ip-api.com\r\n'
      'Connection: close\r\n'
      'User-Agent: TradefyVPN\r\n\r\n',
    );
    final bytes = await reader.readRemaining().timeout(timeout);
    final text = utf8.decode(bytes);
    final split = text.indexOf('\r\n\r\n');
    final body = split >= 0 ? text.substring(split + 4) : text;
    return geoResultFromIpApi(jsonDecode(body));
  } catch (_) {
    return null;
  } finally {
    await iterator?.cancel();
    socket?.destroy();
  }
}

Future<void> _socks5Connect(
  Socket socket,
  _BufferedReader reader,
  String host,
  int port,
) async {
  socket.add(<int>[0x05, 0x01, 0x00]);
  final method = await reader.read(2);
  if (method[0] != 0x05 || method[1] != 0x00) {
    throw const SocketException('SOCKS5 not accepted');
  }

  final hostBytes = utf8.encode(host);
  socket.add(<int>[
    0x05,
    0x01,
    0x00,
    0x03,
    hostBytes.length,
    ...hostBytes,
    (port >> 8) & 0xff,
    port & 0xff,
  ]);

  final header = await reader.read(4);
  if (header[1] != 0x00) {
    throw SocketException('SOCKS5 connect failed (${header[1]})');
  }
  switch (header[3]) {
    case 0x01:
      await reader.read(6);
    case 0x03:
      final len = (await reader.read(1))[0];
      await reader.read(len + 2);
    case 0x04:
      await reader.read(18);
    default:
      throw const SocketException('Unknown SOCKS5 address type');
  }
}

class _BufferedReader {
  _BufferedReader(this._iterator);

  final StreamIterator<List<int>> _iterator;
  final List<int> _pending = <int>[];

  Future<Uint8List> read(int count) async {
    while (_pending.length < count) {
      if (!await _iterator.moveNext()) {
        throw const SocketException('SOCKS proxy closed');
      }
      _pending.addAll(_iterator.current);
    }
    final out = Uint8List.fromList(_pending.sublist(0, count));
    _pending.removeRange(0, count);
    return out;
  }

  Future<Uint8List> readRemaining() async {
    while (await _iterator.moveNext()) {
      _pending.addAll(_iterator.current);
    }
    final out = Uint8List.fromList(_pending);
    _pending.clear();
    return out;
  }
}
