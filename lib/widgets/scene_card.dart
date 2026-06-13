import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/scene.dart';
import '../services/mqtt_service.dart';

class SceneCard extends StatelessWidget {
  final Scene scene;
  final MqttService mqttService;

  const SceneCard({super.key, required this.scene, required this.mqttService});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _executeScene(context),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scene.color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scene.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(scene.icon, color: scene.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              scene.name,
              style: const TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppTheme.darkText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _executeScene(BuildContext context) {
    for (final action in scene.actions) {
      try {
        final payload = action.payload;
        if (payload.startsWith('{')) {
          final decoded = _parseJson(payload);
          if (decoded != null) {
            mqttService.publish(action.topic, decoded);
            continue;
          }
        }
        mqttService.publish(action.topic, {'raw': payload});
      } catch (_) {}
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Escena "${scene.name}" ejecutada'),
        backgroundColor: scene.color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Map<String, dynamic>? _parseJson(String json) {
    try {
      final Map<String, dynamic> result = {};
      final cleaned = json.replaceAll(RegExp(r'[{}"]'), '');
      for (final pair in cleaned.split(',')) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final val = parts[1].trim();
          result[key] = val;
        }
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }
}
