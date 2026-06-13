import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app_theme.dart';
import 'models/broker_config.dart';
import 'services/mqtt_service.dart';
import 'services/config_persistence.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scenes_screen.dart';
import 'screens/crypto_screen.dart';
import 'screens/energy_screen.dart';
import 'screens/monitor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final savedConfig = await ConfigPersistence.loadConfig();
  final config = savedConfig ?? BrokerConfig(
    host: 'raspberry.local',
    port: 1883,
  );

  runApp(DomoticsApp(config: config));
}

class DomoticsApp extends StatelessWidget {
  final BrokerConfig config;

  const DomoticsApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppTheme.background,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }

    final mqttService = MqttService(config: config);

    return MaterialApp(
      title: 'Domótica App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightTheme(),
      home: MainShell(mqttService: mqttService),
    );
  }
}

class MainShell extends StatefulWidget {
  final MqttService mqttService;

  const MainShell({super.key, required this.mqttService});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(mqttService: widget.mqttService),
      ScenesScreen(mqttService: widget.mqttService),
      EnergyScreen(mqttService: widget.mqttService),
      const CryptoScreen(),
      MonitorScreen(mqttService: widget.mqttService),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.cardShadow,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primaryAccent,
          unselectedItemColor: AppTheme.deactivatedText,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Escenas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt),
              label: 'Energía',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.currency_bitcoin_outlined),
              activeIcon: Icon(Icons.currency_bitcoin),
              label: 'Crypto',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_outlined),
              activeIcon: Icon(Icons.monitor_heart),
              label: 'Monitor',
            ),
          ],
        ),
      ),
    );
  }
}
