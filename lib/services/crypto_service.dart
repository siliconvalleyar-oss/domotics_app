import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoPriceData {
  final String label;
  final double value;
  final double change24h;
  final String subtitle;

  CryptoPriceData({
    required this.label,
    required this.value,
    required this.change24h,
    this.subtitle = '',
  });

  bool get isPositive => change24h >= 0;

  String get formattedPrice {
    if (value < 1) return '\$${value.toStringAsFixed(4)}';
    if (value >= 10000) {
      final whole = value ~/ 1000;
      final frac = (value % 1000).toStringAsFixed(0).padLeft(3, '0');
      return '\$$whole,$frac';
    }
    return '\$${value.toStringAsFixed(value >= 100 ? 0 : 2)}';
  }

  String get formattedArs {
    return '\$${value.toStringAsFixed(0)}';
  }
}

class CryptoService {
  static Future<List<CryptoPriceData>> fetchAll() async {
    try {
      final results = await Future.wait([
        _fetchCrypto(),
        _fetchDolar(),
      ]);
      return [...results[0], ...results[1]];
    } catch (_) {
      return _fallbackAll();
    }
  }

  static Future<List<CryptoPriceData>> _fetchCrypto() async {
    final url = Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price'
      '?ids=bitcoin,ethereum,ripple'
      '&vs_currencies=usd'
      '&include_24hr_change=true',
    );

    final response = await http.get(url, headers: {
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return _fallbackCrypto();

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return [
      _parseCrypto(data, 'bitcoin', 'Bitcoin'),
      _parseCrypto(data, 'ethereum', 'Ethereum'),
      _parseCrypto(data, 'ripple', 'XRP'),
    ];
  }

  static CryptoPriceData _parseCrypto(Map<String, dynamic> data, String id, String label) {
    final coin = data[id] as Map<String, dynamic>?;
    return CryptoPriceData(
      label: label,
      value: (coin?['usd'] as num?)?.toDouble() ?? 0,
      change24h: (coin?['usd_24h_change'] as num?)?.toDouble() ?? 0,
    );
  }

  static Future<List<CryptoPriceData>> _fetchDolar() async {
    final url = Uri.parse('https://api.bluelytics.com.ar/v2/latest');
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return _fallbackDolar();

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final oficial = data['oficial'] as Map<String, dynamic>;
    final blue = data['blue'] as Map<String, dynamic>;

    return [
      CryptoPriceData(
        label: 'Dólar Oficial',
        value: (oficial['value_buy'] as num).toDouble(),
        change24h: 0,
        subtitle: 'AR\$',
      ),
      CryptoPriceData(
        label: 'Dólar Blue',
        value: (blue['value_buy'] as num).toDouble(),
        change24h: 0,
        subtitle: 'AR\$',
      ),
    ];
  }

  static List<CryptoPriceData> _fallbackCrypto() => [
    CryptoPriceData(label: 'Bitcoin', value: 67450, change24h: 1.2),
    CryptoPriceData(label: 'Ethereum', value: 3520, change24h: -0.5),
    CryptoPriceData(label: 'XRP', value: 0.62, change24h: 2.1),
  ];

  static List<CryptoPriceData> _fallbackDolar() => [
    CryptoPriceData(label: 'Dólar Oficial', value: 950, change24h: 0, subtitle: 'AR\$'),
    CryptoPriceData(label: 'Dólar Blue', value: 1350, change24h: 0, subtitle: 'AR\$'),
  ];

  static List<CryptoPriceData> _fallbackAll() => [..._fallbackCrypto(), ..._fallbackDolar()];
}
