import 'package:flutter/material.dart';
import '../app_theme.dart';

class AnimatedDeviceSlider extends StatefulWidget {
  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;
  final int divisions;

  const AnimatedDeviceSlider({
    super.key,
    required this.label,
    this.unit = '%',
    required this.value,
    this.min = 0,
    required this.max,
    required this.color,
    required this.onChanged,
    this.divisions = 100,
  });

  @override
  State<AnimatedDeviceSlider> createState() => _AnimatedDeviceSliderState();
}

class _AnimatedDeviceSliderState extends State<AnimatedDeviceSlider> {
  late double _currentValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(AnimatedDeviceSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _currentValue = widget.value;
    }
  }

  String get _displayValue {
    if (widget.unit == '°C') {
      return '${_currentValue.toStringAsFixed(1)}°C';
    }
    if (widget.unit.isEmpty && widget.max <= 5) {
      return 'Nivel ${_currentValue.toInt()}';
    }
    return '${_currentValue.toInt()}${widget.unit}';
  }

  double get _progress {
    final range = widget.max - widget.min;
    if (range <= 0) return 1.0;
    return ((_currentValue - widget.min) / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label and value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: AppTheme.darkText,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _displayValue,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Slider
          Stack(
            children: [
              // Track background
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  color: widget.color.withValues(alpha: 0.1),
                ),
              ),
              // Active track
              FractionallySizedBox(
                widthFactor: _progress,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Slider widget
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: widget.color,
                  overlayColor: widget.color.withValues(alpha: 0.12),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                    elevation: 3,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                ),
                child: Slider(
                  value: _currentValue.clamp(widget.min, widget.max),
                  min: widget.min,
                  max: widget.max,
                  divisions: widget.divisions,
                  onChanged: (value) {
                    setState(() {
                      _isDragging = true;
                      _currentValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    setState(() => _isDragging = false);
                    widget.onChanged(value);
                  },
                ),
              ),
            ],
          ),
          // Min/max labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.unit == '°C'
                    ? '${widget.min.toInt()}°C'
                    : '${widget.min.toInt()}',
                style: const TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 11,
                  color: AppTheme.deactivatedText,
                ),
              ),
              Text(
                widget.unit == '°C'
                    ? '${widget.max.toInt()}°C'
                    : '${widget.max.toInt()}',
                style: const TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 11,
                  color: AppTheme.deactivatedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
