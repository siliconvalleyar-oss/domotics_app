import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/broker_config.dart';
import '../models/device.dart';

class ConfigPersistence {
  static const String _hostKey = 'mqtt_host';
  static const String _portKey = 'mqtt_port';
  static const String _usernameKey = 'mqtt_username';
  static const String _passwordKey = 'mqtt_password';
  static const String _devicesKey = 'custom_devices';

  static Future<void> saveConfig(BrokerConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, config.host);
    await prefs.setInt(_portKey, config.port);
    await prefs.setString(_usernameKey, config.username);
    await prefs.setString(_passwordKey, config.password);
  }

  static Future<BrokerConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString(_hostKey);
    if (host == null || host.isEmpty) return null;

    return BrokerConfig(
      host: host,
      port: prefs.getInt(_portKey) ?? 1883,
      username: prefs.getString(_usernameKey) ?? '',
      password: prefs.getString(_passwordKey) ?? '',
    );
  }

  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hostKey);
    await prefs.remove(_portKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
  }

  static Future<void> saveDevices(List<Device> devices) async {
    final prefs = await SharedPreferences.getInstance();
    final json = devices.map((d) => d.toJson()).toList();
    await prefs.setString(_devicesKey, jsonEncode(json));
  }

  static Future<List<Device>> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_devicesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
