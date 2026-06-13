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

  @override
  void initState() {
    super.initState();
    _prices = CryptoPrice.generate();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _prices = CryptoPrice.generate());
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
                            child: _AnimatedRing(
                              coin: _prices[i],
                              ringValue: _ringValue(_prices[i]),
                              gradientColors: gradients[i],
                            ),
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
}

class _AnimatedRing extends StatefulWidget {
  final CryptoPrice coin;
  final double ringValue;
  final List<Color> gradientColors;

  const _AnimatedRing({
    required this.coin,
    required this.ringValue,
    required this.gradientColors,
  });

  @override
  State<_AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<_AnimatedRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.ringValue;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(_AnimatedRing old) {
    super.didUpdateWidget(old);
    if (old.ringValue != widget.ringValue) {
      _previousValue = old.ringValue;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final value = _previousValue +
                  (widget.ringValue - _previousValue) * _animation.value;
              return CustomPaint(
                painter: _RingPainter(
                  progress: value / 100,
                  gradientColors: widget.gradientColors,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.coin.formattedPrice,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: widget.gradientColors.first,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.coin.isPositive
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 12,
              color: widget.coin.isPositive ? AppTheme.success : AppTheme.error,
            ),
            const SizedBox(width: 2),
            Text(
              '${widget.coin.change.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: widget.coin.isPositive ? AppTheme.success : AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.coin.label,
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
