import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app_theme.dart';
import 'models/broker_config.dart';
import 'services/mqtt_service.dart';
import 'services/config_persistence.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cargar configuración guardada
  final savedConfig = await ConfigPersistence.loadConfig();
  final config = savedConfig ?? BrokerConfig(
    host: 'test.mosquitto.org',
    port: 1883,
  );

  runApp(DomoticsApp(config: config));
}

class DomoticsApp extends StatelessWidget {
  final BrokerConfig config;

  const DomoticsApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: !kIsWeb && Platform.isAndroid
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: AppTheme.background,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final mqttService = MqttService(config: config);

    return MaterialApp(
      title: 'Domótica App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightTheme(),
      home: DashboardScreen(mqttService: mqttService),
    );
  }
}
