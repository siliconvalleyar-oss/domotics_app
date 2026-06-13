import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_theme.dart';
import '../models/energy_data.dart';
import '../models/device.dart';

class EnergyMonitorWidget extends StatelessWidget {
  final List<Device> devices;

  const EnergyMonitorWidget({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    final data = EnergyData.fromDevices(devices);
    final totalKwh = EnergyData.totalDailyKwh(data);
    final totalMonth = EnergyData.totalMonthlyKwh(data);
    final totalCost = EnergyData.totalCost(data);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummary(totalKwh, totalMonth, totalCost),
          const SizedBox(height: 20),
          const Text(
            'Consumo por Dispositivo',
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          ...data.map((e) => _buildEnergyBar(e)),
        ],
      ),
    );
  }

  Widget _buildSummary(double daily, double monthly, double cost) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consumo Energético',
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStat('Hoy', '${daily.toStringAsFixed(1)} kWh', Icons.today),
              const SizedBox(width: 16),
              _buildStat('Mes', '${monthly.toStringAsFixed(0)} kWh', Icons.calendar_month),
              const SizedBox(width: 16),
              _buildStat('Costo', '\$${cost.toStringAsFixed(2)}', Icons.attach_money),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.white60),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyBar(EnergyData data) {
    final maxKwh = 9.0;
    final ratio = (data.dailyKwh / maxKwh).clamp(0.0, 1.0);
    final pct = (data.dailyKwh / EnergyData.totalDailyKwh(EnergyData.fromDevices(devices)) * 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(data.deviceType.icon, size: 14, color: data.color),
                  const SizedBox(width: 6),
                  Text(
                    data.deviceName,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),
              Text(
                '${data.dailyKwh.toStringAsFixed(2)} kWh  •  ${data.hoursOn}h',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              width: double.infinity,
              color: const Color(0xFFF0F2F5),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: ratio > 0.7
                              ? [AppTheme.error, const Color(0xFFFF6B6B)]
                              : [data.color, data.color.withValues(alpha: 0.6)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${pct.toStringAsFixed(1)}% del total',
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.deactivatedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
