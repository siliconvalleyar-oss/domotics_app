import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/bitcoin_data.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  late List<CryptoPrice> _prices;
  late int _seed;

  @override
  void initState() {
    super.initState();
    _prices = CryptoPrice.generate();
    _seed = DateTime.now().millisecondsSinceEpoch;
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _prices = CryptoPrice.generate();
          _seed = DateTime.now().millisecondsSinceEpoch;
        });
        _startTimer();
      }
    });
  }

  double _ringValue(CryptoPrice coin) {
    const refs = {'Bitcoin': 150000.0, 'Ethereum': 5000.0, 'XRP': 3.0};
    final max = refs[coin.label] ?? 100.0;
    return (coin.value / max * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [const Color(0xFF4EF2FF), const Color(0xFFB05CFF)],
      [const Color(0xFFFFC14D), const Color(0xFFFF5EA8)],
      [const Color(0xFF64FFC8), const Color(0xFF5DAEFF)],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Precio Crypto',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppTheme.darkText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mercado Crypto',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: List.generate(_prices.length, (i) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < _prices.length - 1 ? 12 : 0),
                            child: _buildRing(_prices[i], gradients[i]),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Actualizado cada 4 segundos',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.deactivatedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRing(CryptoPrice coin, List<Color> gradientColors) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: TweenAnimationBuilder<double>(
            key: ValueKey('${coin.label}_$_seed'),
            tween: Tween(begin: 0, end: _ringValue(coin)),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _RingPainter(
                  progress: value / 100,
                  gradientColors: gradientColors,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          coin.formattedPrice,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: gradientColors.first,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              coin.isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 12,
              color: coin.isPositive ? AppTheme.success : AppTheme.error,
            ),
            const SizedBox(width: 2),
            Text(
              '${coin.change.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: coin.isPositive ? AppTheme.success : AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          coin.label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.lightText,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;

  _RingPainter({required this.progress, required this.gradientColors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFE8EAF0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint,
      );

      final endAngle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);
      final glowPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dotX, dotY), 4, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
