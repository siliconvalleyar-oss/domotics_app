import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/crypto_service.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  List<CryptoPriceData> _prices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final data = await CryptoService.fetchAll();
    if (mounted) {
      setState(() { _prices = data; _loading = false; });
    }
    _scheduleNext();
  }

  void _scheduleNext() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) _fetch();
    });
  }

  double _ringValue(CryptoPriceData coin, double max) {
    return (coin.value / max * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final cryptoGradients = [
      [const Color(0xFF4EF2FF), const Color(0xFFB05CFF)],
      [const Color(0xFFFFC14D), const Color(0xFFFF5EA8)],
      [const Color(0xFF64FFC8), const Color(0xFF5DAEFF)],
    ];
    final dolarGradients = [
      [const Color(0xFF00B894), const Color(0xFF00CEC9)],
      [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
    ];

    final cryptos = _prices.where((p) => p.subtitle != 'AR\$').toList();
    final dolares = _prices.where((p) => p.subtitle == 'AR\$').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crypto & Dólar',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppTheme.darkText,
          ),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _fetch,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading && _prices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _buildSection(context, 'Mercado Crypto', cryptos, cryptoGradients, 150000, 'USD'),
                const SizedBox(height: 16),
                _buildSection(context, 'Dólar Argentina', dolares, dolarGradients, 2000, 'AR\$'),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Fuente: CoinGecko + BlueLytics',
                    style: TextStyle(fontSize: 11, color: AppTheme.deactivatedText),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Actualizado cada 30 segundos',
                    style: TextStyle(fontSize: 10, color: AppTheme.deactivatedText),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<CryptoPriceData> items, List<List<Color>> gradients, double maxRef, String currency) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: List.generate(items.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < items.length - 1 ? 12 : 0),
                    child: _AnimatedRing(
                      coin: items[i],
                      ringValue: _ringValue(items[i], maxRef),
                      gradientColors: gradients[i],
                      currency: currency,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRing extends StatefulWidget {
  final CryptoPriceData coin;
  final double ringValue;
  final List<Color> gradientColors;
  final String currency;

  const _AnimatedRing({
    required this.coin,
    required this.ringValue,
    required this.gradientColors,
    required this.currency,
  });

  @override
  State<_AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<_AnimatedRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.ringValue;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
    final displayPrice = widget.currency == 'AR\$'
        ? '\$${widget.coin.value.toStringAsFixed(0)}'
        : widget.coin.formattedPrice;

    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final animValue = _controller.isAnimating ? _controller.value : 1.0;
              final value = _previousValue + (widget.ringValue - _previousValue) * animValue;
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
          displayPrice,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: widget.gradientColors.first,
          ),
        ),
        if (widget.coin.change24h != 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.coin.isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12,
                color: widget.coin.isPositive ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(width: 2),
              Text(
                '${widget.coin.change24h.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.coin.isPositive ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Text(
          widget.coin.label,
          style: const TextStyle(fontSize: 11, color: AppTheme.lightText),
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

      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);

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
