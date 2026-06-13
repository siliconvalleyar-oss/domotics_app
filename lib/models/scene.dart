import 'package:flutter/material.dart';

class SceneAction {
  final String topic;
  final String payload;

  const SceneAction({required this.topic, required this.payload});

  Map<String, dynamic> toJson() => {'topic': topic, 'payload': payload};

  factory SceneAction.fromJson(Map<String, dynamic> json) => SceneAction(
    topic: json['topic'] as String,
    payload: json['payload'] as String,
  );
}

class Scene {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<SceneAction> actions;

  const Scene({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.actions,
  });

  static List<Scene> defaults = [
    Scene(
      id: 'buenos_dias',
      name: 'Buenos días',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFF9CA24),
      actions: [
        SceneAction(topic: 'domotics/light', payload: '{"command":"on","deviceId":"light_1"}'),
        SceneAction(topic: 'domotics/light', payload: '{"command":"on","deviceId":"light_2"}'),
      ],
    ),
    Scene(
      id: 'buenas_noches',
      name: 'Buenas noches',
      icon: Icons.nightlight_round,
      color: Color(0xFF2D3436),
      actions: [
        SceneAction(topic: 'domotics/light', payload: '{"command":"off","deviceId":"light_1"}'),
        SceneAction(topic: 'domotics/light', payload: '{"command":"off","deviceId":"light_2"}'),
        SceneAction(topic: 'domotics/lock', payload: '{"command":"on","deviceId":"lock_1"}'),
      ],
    ),
    Scene(
      id: 'cine',
      name: 'Cine',
      icon: Icons.movie_outlined,
      color: Color(0xFF6C5CE7),
      actions: [
        SceneAction(topic: 'domotics/light', payload: '{"command":"off","deviceId":"light_1"}'),
        SceneAction(topic: 'domotics/rgb', payload: '{"r":40,"g":0,"b":80}'),
      ],
    ),
    Scene(
      id: 'fiesta',
      name: 'Fiesta',
      icon: Icons.celebration_outlined,
      color: Color(0xFFFF6B6B),
      actions: [
        SceneAction(topic: 'domotics/rgb', payload: '{"effect":"rainbow"}'),
        SceneAction(topic: 'domotics/light', payload: '{"command":"on","deviceId":"light_3"}'),
      ],
    ),
  ];
}
