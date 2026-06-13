import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/mqtt_log_entry.dart';
import '../services/mqtt_service.dart';

class MonitorScreen extends StatefulWidget {
  final MqttService mqttService;

  const MonitorScreen({super.key, required this.mqttService});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final List<MqttLogEntry> _logs = [];
  StreamSubscription? _logSub;
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _logSub = widget.mqttService.logStream.listen(_addLog);
  }

  void _addLog(MqttLogEntry entry) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, entry);
      if (_logs.length > 500) _logs.removeLast();
    });
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monitor MQTT',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppTheme.darkText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_top : Icons.vertical_align_center,
              color: _autoScroll ? AppTheme.primaryAccent : AppTheme.deactivatedText,
            ),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
            tooltip: 'Auto-scroll',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: () => setState(() => _logs.clear()),
            tooltip: 'Limpiar',
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_heart_outlined, size: 64, color: AppTheme.deactivatedText),
                  SizedBox(height: 16),
                  Text(
                    'Esperando mensajes MQTT...',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 16,
                      color: AppTheme.lightText,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Interactuá con los dispositivos\ndel dashboard para ver los topics',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 13,
                      color: AppTheme.deactivatedText,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _logs.length,
              itemBuilder: (context, index) => _buildLogTile(_logs[index]),
            ),
    );
  }

  Widget _buildLogTile(MqttLogEntry entry) {
    final isSent = entry.direction == MqttDirection.published;
    final color = isSent ? AppTheme.primaryAccent : AppTheme.secondaryAccent;
    final label = isSent ? 'ENVIADO' : 'RECIBIDO';
    final icon = isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.topic,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  entry.formattedTime,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.deactivatedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.payload,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: AppTheme.darkText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
