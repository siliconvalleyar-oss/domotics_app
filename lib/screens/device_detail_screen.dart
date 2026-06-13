import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_theme.dart';
import '../models/device.dart';
import '../services/mqtt_service.dart';
import '../widgets/animated_slider.dart';
import '../widgets/animated_toggle.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  final MqttService mqttService;

  const DeviceDetailScreen({
    super.key,
    required this.device,
    required this.mqttService,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Device _device;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_device.name),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Container(
                width: 8 + (_pulseController.value * 4),
                height: 8 + (_pulseController.value * 4),
                decoration: BoxDecoration(
                  color: _device.isConnected
                      ? AppTheme.success
                      : AppTheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_device.isConnected
                              ? AppTheme.success
                              : AppTheme.error)
                          .withValues(alpha: 0.3 + (_pulseController.value * 0.3)),
                      blurRadius: 6 + (_pulseController.value * 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildDeviceHeader()),
          SliverToBoxAdapter(child: _buildMainControl()),
          SliverToBoxAdapter(child: _buildSliderControls()),
          SliverToBoxAdapter(child: _buildInfoCards()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildDeviceHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _device.type.color.withValues(alpha: 0.15),
            _device.type.color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          // Large icon with animated glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glow = _device.isOn ? _pulseController.value * 0.3 : 0.0;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _device.isOn
                      ? _device.type.color.withValues(alpha: 0.15 + glow)
                      : Colors.grey.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  boxShadow: _device.isOn
                      ? [
                          BoxShadow(
                            color: _device.type.color
                                .withValues(alpha: 0.2 + glow),
                            blurRadius: 20 + (glow * 30),
                            spreadRadius: 5 + (glow * 10),
                          ),
                        ]
                      : null,
                ),
                child: FaIcon(
                  _device.type.icon,
                  size: 56,
                  color: _device.isOn
                      ? _device.type.color
                      : Colors.grey.shade400,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Device name
          Text(
            _device.name,
            style: const TextStyle(
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _device.room,
            style: const TextStyle(
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _device.isConnected
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _device.isConnected ? 'Conectado' : 'Desconectado',
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color:
                    _device.isConnected ? AppTheme.success : AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControl() {
    if (_device.type == DeviceType.temperature ||
        _device.type == DeviceType.energy) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _toggleDevice,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(
              color: _device.isOn
                  ? _device.type.color.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _device.isOn
                      ? _device.type.color.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  _device.isOn
                      ? FontAwesomeIcons.powerOff
                      : FontAwesomeIcons.solidCircle,
                  color:
                      _device.isOn ? _device.type.color : Colors.grey.shade400,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encendido / Apagado',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _device.isOn ? 'Encendido' : 'Apagado',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: _device.isOn
                            ? _device.type.color
                            : AppTheme.deactivatedText,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedToggle(
                value: _device.isOn,
                activeColor: _device.type.color,
                width: 52,
                height: 28,
                thumbSize: 24,
                interactive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderControls() {
    if (!_device.hasSlider) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AnimatedDeviceSlider(
        label: _device.type.label,
        unit: _device.unit,
        value: _device.value,
        min: _device.minValue,
        max: _device.maxValue,
        color: _device.type.color,
        divisions: _device.type == DeviceType.temperature ? 140 : 100,
        onChanged: (value) {
          setState(() => _device.value = value);
          widget.mqttService.publish(
            _device.type.mqttTopic,
            {'deviceId': _device.id, 'value': value},
          );
        },
      ),
    );
  }

  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              icon: FontAwesomeIcons.bolt,
              label: 'Estado',
              value: _device.isOn ? 'Activo' : 'Inactivo',
              color: _device.isOn ? AppTheme.success : AppTheme.deactivatedText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: FontAwesomeIcons.gaugeHigh,
              label: 'Valor',
              value: _device.valueDisplay,
              color: _device.type.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: FontAwesomeIcons.tag,
              label: 'Tipo',
              value: _device.type.label,
              color: AppTheme.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required FaIconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.w400,
              fontSize: 10,
              color: AppTheme.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    if (_device.hasSlider) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Mínimo',
                icon: FontAwesomeIcons.arrowDown,
                onTap: () {
                  setState(() => _device.value = _device.minValue);
                  widget.mqttService.publish(
                    _device.type.mqttTopic,
                    {'deviceId': _device.id, 'value': _device.minValue},
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                label: 'Mitad',
                icon: FontAwesomeIcons.equals,
                onTap: () {
                  final mid = (_device.maxValue + _device.minValue) / 2;
                  setState(() => _device.value = mid);
                  widget.mqttService.publish(
                    _device.type.mqttTopic,
                    {'deviceId': _device.id, 'value': mid},
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                label: 'Máximo',
                icon: FontAwesomeIcons.arrowUp,
                onTap: () {
                  setState(() => _device.value = _device.maxValue);
                  widget.mqttService.publish(
                    _device.type.mqttTopic,
                    {'deviceId': _device.id, 'value': _device.maxValue},
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildActionButton({
    required String label,
    required FaIconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            FaIcon(icon, color: AppTheme.primaryAccent, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDevice() {
    setState(() {
      _device.isOn = !_device.isOn;
      if (_device.isOn && _device.hasSlider && _device.value == 0) {
        _device.value = _device.maxValue * 0.5;
      }
    });

    widget.mqttService.publish(
      _device.type.mqttTopic,
      {
        'command': _device.isOn ? 'on' : 'off',
        'deviceId': _device.id,
      },
    );
  }
}
