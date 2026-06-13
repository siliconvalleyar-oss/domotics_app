enum MqttDirection { published, received }

class MqttLogEntry {
  final DateTime timestamp;
  final String topic;
  final String payload;
  final MqttDirection direction;

  MqttLogEntry({
    required this.timestamp,
    required this.topic,
    required this.payload,
    required this.direction,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool get isRgb => topic == 'domotics/rgb';
}
