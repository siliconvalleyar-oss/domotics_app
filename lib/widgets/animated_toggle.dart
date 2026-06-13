import 'package:flutter/material.dart';

class AnimatedToggle extends StatelessWidget {
  final bool value;
  final Color activeColor;
  final ValueChanged<bool>? onChanged;
  final bool interactive;
  final double width;
  final double height;
  final double thumbSize;

  const AnimatedToggle({
    super.key,
    required this.value,
    required this.activeColor,
    this.onChanged,
    this.interactive = true,
    this.width = 48,
    this.height = 26,
    this.thumbSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final toggleVisual = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: value
            ? activeColor.withValues(alpha: 0.8)
            : Colors.grey.shade200,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: value
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.all(
            (height - thumbSize) / 2,
          ),
          width: thumbSize,
          height: thumbSize,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );

    if (interactive && onChanged != null) {
      return GestureDetector(
        onTap: () => onChanged!(!value),
        child: toggleVisual,
      );
    }

    return toggleVisual;
  }
}
