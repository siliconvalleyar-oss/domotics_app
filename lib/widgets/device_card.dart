import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animations/animations.dart';
import '../app_theme.dart';
import '../models/device.dart';
import 'animated_toggle.dart';

class DeviceCard extends StatefulWidget {
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
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final device = widget.device;

    return OpenContainer(
      openElevation: 0,
      closedElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      openShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      transitionDuration: const Duration(milliseconds: 500),
      openBuilder: (context, action) => widget.onTap != null
          ? const SizedBox.shrink()
          : const SizedBox.shrink(),
      closedBuilder: (context, action) => _buildCardContent(device, action),
      onClosed: (_) {},
    );
  }

  Widget _buildCardContent(Device device, VoidCallback action) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            action();
          }
        },
        child: Transform(
        transform: _isHovered
            ? (Matrix4.identity()..translateByDouble(0, -4, 0, 1))
            : Matrix4.identity(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isHovered ? AppTheme.elevatedShadow : AppTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header: icon + toggle or status
                _buildHeader(device),
                const Spacer(),
                // Device info
                _buildDeviceInfo(device),
                const SizedBox(height: 8),
                // Value indicator
                _buildValueBar(device),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(Device device) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icon with colored background
        AnimatedContainer(
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
        // Toggle switch or status indicator
        if (device.type != DeviceType.temperature &&
            device.type != DeviceType.energy)
          AnimatedToggle(
            value: device.isOn,
            activeColor: device.type.color,
            width: 44,
            height: 24,
            thumbSize: 20,
            onChanged: (val) {
              setState(() {
                device.isOn = val;
              });
              widget.onToggle?.call();
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

  Widget _buildDeviceInfo(Device device) {
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

  Widget _buildValueBar(Device device) {
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
