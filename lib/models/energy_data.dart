import '../app_theme.dart';
import 'package:flutter/material.dart';
import 'device.dart';

class EnergyData {
  final String deviceName;
  final String id;
  final double powerWatts;
  final double hoursOn;
  final Color color;
  final DeviceType deviceType;

  EnergyData({
    required this.deviceName,
    required this.id,
    required this.powerWatts,
    required this.hoursOn,
    required this.color,
    required this.deviceType,
  });

  double get dailyKwh => (powerWatts * hoursOn) / 1000;
  double get monthlyKwh => dailyKwh * 30;
  double get estimatedCost => monthlyKwh * 0.95;

  static List<EnergyData> fromDevices(List<Device> devices) {
    final powerMap = <DeviceType, double>{
      DeviceType.light: 60,
      DeviceType.temperature: 1500,
      DeviceType.fan: 75,
      DeviceType.lock: 5,
      DeviceType.energy: 0,
      DeviceType.curtain: 40,
    };

    return devices.where((d) => d.type != DeviceType.energy).map((d) {
      final watts = powerMap[d.type] ?? 0;
      final hours = d.isOn ? (d.value / d.maxValue) * 6.0 : 0.0;
      return EnergyData(
        deviceName: d.name,
        id: d.id,
        powerWatts: watts,
        hoursOn: double.parse(hours.toStringAsFixed(1)),
        color: d.type.color,
        deviceType: d.type,
      );
    }).toList()
      ..sort((a, b) => b.dailyKwh.compareTo(a.dailyKwh));
  }

  static double totalDailyKwh(List<EnergyData> data) {
    return data.fold(0.0, (sum, e) => sum + e.dailyKwh);
  }

  static double totalMonthlyKwh(List<EnergyData> data) {
    return data.fold(0.0, (sum, e) => sum + e.monthlyKwh);
  }

  static double totalCost(List<EnergyData> data) {
    return data.fold(0.0, (sum, e) => sum + e.estimatedCost);
  }
}
