// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

bool isLoopbackOrPrivateHost(String host) {
  final clean = host.trim().toLowerCase();
  if (clean.isEmpty) return false;
  if (clean == 'localhost' ||
      clean == '127.0.0.1' ||
      clean == '::1' ||
      clean == '[::1]') {
    return true;
  }
  final unbracketed = clean.startsWith('[') && clean.endsWith(']')
      ? clean.substring(1, clean.length - 1)
      : clean;
  final address = InternetAddress.tryParse(unbracketed);
  if (address == null) {
    return false;
  }
  if (address.isLoopback) {
    return true;
  }
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4 && bytes.length == 4) {
    if (bytes[0] == 10 || bytes[0] == 127) return true;
    if (bytes[0] == 192 && bytes[1] == 168) return true;
    if (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) return true;
  }
  return false;
}

HttpClient createLoopbackBypassHttpClient({Duration? connectionTimeout}) {
  final client = HttpClient();
  if (connectionTimeout != null) {
    client.connectionTimeout = connectionTimeout;
  }
  client.findProxy = (uri) => isLoopbackOrPrivateHost(uri.host)
      ? 'DIRECT'
      : HttpClient.findProxyFromEnvironment(uri);
  return client;
}

http.Client createResilientHttpClient() =>
    IOClient(createLoopbackBypassHttpClient());
