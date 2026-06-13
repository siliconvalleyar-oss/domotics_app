import 'dart:math';

class CryptoPrice {
  final String label;
  final double value;
  final double change;
  final bool isPositive;

  CryptoPrice({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
  });

  String get formattedPrice {
    if (value < 1) return '\$${value.toStringAsFixed(4)}';
    if (value >= 10000) {
      final whole = value ~/ 1000;
      final frac = (value % 1000).toStringAsFixed(0).padLeft(3, '0');
      return '\$$whole,$frac';
    }
    return '\$${value.toStringAsFixed(value >= 100 ? 0 : 2)}';
  }

  static List<CryptoPrice> generate() {
    final rng = Random();
    return [
      CryptoPrice(
        label: 'Bitcoin',
        value: 60000 + rng.nextDouble() * 15000,
        change: -2 + rng.nextDouble() * 6,
        isPositive: rng.nextBool(),
      ),
      CryptoPrice(
        label: 'Ethereum',
        value: 2000 + rng.nextDouble() * 1000,
        change: -3 + rng.nextDouble() * 8,
        isPositive: rng.nextBool(),
      ),
      CryptoPrice(
        label: 'XRP',
        value: 0.5 + rng.nextDouble() * 2.0,
        change: -4 + rng.nextDouble() * 10,
        isPositive: rng.nextBool(),
      ),
    ];
  }
}
