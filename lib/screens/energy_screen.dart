import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_theme.dart';
import '../models/device.dart';
import '../services/mqtt_service.dart';
import '../widgets/energy_monitor_widget.dart';

class EnergyScreen extends StatefulWidget {
  final MqttService mqttService;

  const EnergyScreen({super.key, required this.mqttService});

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> {
  late List<Device> _devices;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _devices = Device.sampleDevices;

    widget.mqttService.connectionStream.listen((connected) {
      if (mounted) setState(() => _isConnected = connected);
    });

    widget.mqttService.messageStream.listen((message) {
      final topic = message['topic'] as String? ?? '';
      final msgDeviceId = message['deviceId'] as String?;
      for (final device in _devices) {
        bool matches;
        if (msgDeviceId != null) {
          matches = device.id == msgDeviceId;
        } else {
          matches = topic.startsWith(device.type.mqttTopic);
        }
        if (matches) {
          setState(() {
            device.isConnected = true;
            if (message.containsKey('isOn')) device.isOn = message['isOn'] as bool;
            if (message.containsKey('value')) {
              device.value = (message['value'] as num).toDouble();
            }
          });
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Energía',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppTheme.darkText,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isConnected ? AppTheme.success : AppTheme.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isConnected ? AppTheme.success : AppTheme.error).withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: EnergyMonitorWidget(devices: _devices),
      ),
    );
  }
}
