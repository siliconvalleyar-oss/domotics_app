import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_theme.dart';
import '../models/scene.dart';
import '../services/mqtt_service.dart';

class ScenesScreen extends StatelessWidget {
  final MqttService mqttService;

  const ScenesScreen({super.key, required this.mqttService});

  @override
  Widget build(BuildContext context) {
    final scenes = Scene.defaults;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escenas',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppTheme.darkText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escenas inteligentes',
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: scenes.length,
                itemBuilder: (context, i) => _SceneTile(
                  scene: scenes[i],
                  onTap: () => _executeScene(context, scenes[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executeScene(BuildContext context, Scene scene) {
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
          result[parts[0].trim()] = parts[1].trim();
        }
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }
}

class _SceneTile extends StatelessWidget {
  final Scene scene;
  final VoidCallback onTap;

  const _SceneTile({required this.scene, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scene.color.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scene.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(scene.icon, color: scene.color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              scene.name,
              style: const TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${scene.actions.length} acción(es)',
              style: const TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 10,
                color: AppTheme.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
