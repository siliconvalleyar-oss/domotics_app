import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_theme.dart';
import '../models/device.dart';
import 'animated_toggle.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Spacer(),
            GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeviceInfo(),
                  const SizedBox(height: 8),
                  _buildValueBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: device.isOn
                  ? device.type.color.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: FaIcon(
              device.type.icon,
              size: 22,
              color: device.isOn ? device.type.color : Colors.grey.shade400,
            ),
          ),
        ),
        if (device.type != DeviceType.temperature &&
            device.type != DeviceType.energy)
          AnimatedToggle(
            value: device.isOn,
            activeColor: device.type.color,
            width: 44,
            height: 24,
            thumbSize: 20,
            onChanged: (val) {
              device.isOn = val;
              onToggle?.call();
            },
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: device.type.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              device.valueDisplay,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: device.type.color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          device.name,
          style: const TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.darkText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          device.room,
          style: const TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: AppTheme.lightText,
          ),
        ),
      ],
    );
  }

  Widget _buildValueBar() {
    if (!device.hasSlider) return const SizedBox();

    final double progress = device.maxValue > 0
        ? (device.value / device.maxValue).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 4,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: device.isOn ? progress : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: device.type.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              device.statusText,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: device.isOn ? device.type.color : AppTheme.deactivatedText,
              ),
            ),
            if (device.type == DeviceType.temperature || device.type == DeviceType.energy)
              Text(
                device.valueDisplay,
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: device.type.color,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
