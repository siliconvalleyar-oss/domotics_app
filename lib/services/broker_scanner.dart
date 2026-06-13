import 'dart:io';
import 'dart:async';

class ScanResult {
  final String host;
  final int port;
  final bool isOpen;
  final int responseTimeMs;

  ScanResult({
    required this.host,
    required this.port,
    required this.isOpen,
    this.responseTimeMs = 0,
  });

  String get display => '$host:$port';
}

class BrokerScanner {
  static const int defaultPort = 1883;
  static const Duration scanTimeout = Duration(milliseconds: 800);
  static const int maxConcurrent = 50;

  /// Obtiene la IP local no-loopback (IPv4)
  static Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      // Preferir interfaces wifi/ethernet (no virtual)
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          // Ignorar direcciones APIPA (169.254.x.x) y enlaces locales
          if (!ip.startsWith('169.254') && !ip.startsWith('127.')) {
            return ip;
          }
        }
      }
      return interfaces.isNotEmpty
          ? interfaces.first.addresses.first.address
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el prefijo de subred (ej: "192.168.1.")
  static String? getSubnetPrefix(String ip) {
    final lastDot = ip.lastIndexOf('.');
    if (lastDot == -1) return null;
    return ip.substring(0, lastDot + 1);
  }

  /// Verifica si un puerto está abierto en un host
  static Future<ScanResult> checkPort(
    String host,
    int port, {
    Duration timeout = scanTimeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: timeout,
      );
      socket.destroy();
      stopwatch.stop();
      return ScanResult(
        host: host,
        port: port,
        isOpen: true,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (_) {
      return ScanResult(
        host: host,
        port: port,
        isOpen: false,
      );
    }
  }

  /// Escanea la subred local para encontrar brokers MQTT (puerto 1883)
  static Future<List<ScanResult>> scanSubnet({
    int port = defaultPort,
    Duration timeout = scanTimeout,
  }) async {
    final localIp = await getLocalIp();
    if (localIp == null) return [];

    final prefix = getSubnetPrefix(localIp);
    if (prefix == null) return [];

    final results = <ScanResult>[];
    final futures = <Future<ScanResult>>[];

    for (int i = 1; i < 255; i++) {
      final host = '$prefix$i';
      futures.add(checkPort(host, port, timeout: timeout));

      // Procesar en lotes para no saturar el sistema
      if (futures.length >= maxConcurrent || i == 254) {
        final batch = await Future.wait(futures);
        results.addAll(batch.where((r) => r.isOpen));
        futures.clear();
      }
    }

    // También intentar hostnames comunes
    final commonHosts = ['broker', 'mqtt', 'mosquitto', 'localhost'];
    for (final host in commonHosts) {
      final result = await checkPort(host, port, timeout: timeout);
      if (result.isOpen) {
        results.add(result);
      }
    }

    return results..sort((a, b) => a.responseTimeMs.compareTo(b.responseTimeMs));
  }

  /// Escanea múltiples puertos MQTT comunes en un host específico
  static Future<List<ScanResult>> scanHostPorts(String host, {
    Duration timeout = scanTimeout,
  }) async {
    final ports = [1883, 8883, 1884, 8884, 8080, 8081];
    final futures = ports.map((port) => checkPort(host, port, timeout: timeout));
    final results = await Future.wait(futures);
    return results.where((r) => r.isOpen).toList();
  }
}
