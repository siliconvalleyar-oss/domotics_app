import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animations/animations.dart';
import '../app_theme.dart';
import '../models/device.dart';
import '../services/mqtt_service.dart';
import '../widgets/device_card.dart';
import '../widgets/bitcoin_ring.dart';
import 'device_detail_screen.dart';
import 'broker_config_screen.dart';

class DashboardScreen extends StatefulWidget {
  final MqttService mqttService;

  const DashboardScreen({super.key, required this.mqttService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late List<Device> _devices;
  late AnimationController _fabAnimationController;
  bool _isConnected = false;
  String _selectedRoom = 'Todos';

  final List<String> _rooms = ['Todos', 'Sala', 'Dormitorio', 'Cocina', 'Entrada', 'Exterior', 'General'];

  @override
  void initState() {
    super.initState();
    _devices = Device.sampleDevices;
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    widget.mqttService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() => _isConnected = connected);
        if (connected) {
          _subscribeToTopics();
        }
      }
    });

    widget.mqttService.messageStream.listen((message) {
      _handleMqttMessage(message);
    });

    // Auto-conectar al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectToBroker());
  }

  void _subscribeToTopics() {
    for (final device in _devices) {
      widget.mqttService.subscribe('${device.type.mqttTopic}/status');
    }
  }

  void _handleMqttMessage(Map<String, dynamic> message) {
    final topic = message['topic'] as String? ?? '';
    debugPrint('MQTT message received on $topic: $message');
    for (final device in _devices) {
      if (topic.startsWith(device.type.mqttTopic)) {
        setState(() {
          device.isConnected = true;
          if (message.containsKey('isOn')) device.isOn = message['isOn'] as bool;
          if (message.containsKey('value')) {
            device.value = (message['value'] as num).toDouble();
          }
        });
        break;
      }
    }
  }

  List<Device> get _filteredDevices {
    if (_selectedRoom == 'Todos') return _devices;
    return _devices.where((d) => d.room == _selectedRoom).toList();
  }

  int get _activeDevicesCount => _devices.where((d) => d.isOn).length;
  int get _totalDevices => _devices.length;

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshDevices,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Stats cards
            SliverToBoxAdapter(child: _buildStatsRow()),
            // Bitcoin price rings
            const SliverToBoxAdapter(child: BitcoinRingSection()),
            // Room filter chips
            SliverToBoxAdapter(child: _buildRoomFilter()),
            // Device grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: _buildDeviceGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          SvgPicture.asset(
            'assets/logo.svg',
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Domótica',
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppTheme.darkText,
                ),
              ),
              Text(
                _isConnected ? 'Conectado al broker' : 'Desconectado',
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: _isConnected ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Settings button
        IconButton(
          icon: FaIcon(
            FontAwesomeIcons.gear,
            size: 20,
            color: AppTheme.darkText,
          ),
          onPressed: _openBrokerConfig,
          tooltip: 'Configurar broker',
        ),
        // Connection indicator
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _isConnected ? AppTheme.success : AppTheme.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isConnected ? AppTheme.success : AppTheme.error).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _buildStatCard(
            icon: FontAwesomeIcons.solidLightbulb,
            label: 'Activos',
            value: '$_activeDevicesCount',
            color: AppTheme.success,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: FontAwesomeIcons.plug,
            label: 'Total',
            value: '$_totalDevices',
            color: AppTheme.primaryAccent,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: FontAwesomeIcons.wifi,
            label: 'Broker',
            value: _isConnected ? 'OK' : '--',
            color: _isConnected ? AppTheme.success : AppTheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required FaIconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: AppTheme.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomFilter() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          final isSelected = _selectedRoom == room;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRoom = room),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryAccent
                      : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryAccent
                        : AppTheme.deactivatedText.withValues(alpha: 0.3),
                  ),
                  boxShadow: isSelected ? AppTheme.cardShadow : null,
                ),
                child: Center(
                  child: Text(
                    room,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppTheme.darkText,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceGrid() {
    final devices = _filteredDevices;
    if (devices.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.magnifyingGlass, size: 48, color: AppTheme.deactivatedText),
              const SizedBox(height: 16),
              const Text(
                'No hay dispositivos en esta habitación',
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  color: AppTheme.lightText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return DeviceCard(
            device: devices[index],
            onTap: () => _openDeviceDetail(devices[index]),
            onToggle: () => _toggleDevice(devices[index]),
          );
        },
        childCount: devices.length,
      ),
    );
  }

  Widget _buildFloatingButton() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOutBack,
      ),
      child: FloatingActionButton.extended(
        onPressed: _isConnected ? null : _connectToBroker,
        backgroundColor: _isConnected ? AppTheme.success : AppTheme.primaryAccent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: FaIcon(
          _isConnected ? FontAwesomeIcons.check : FontAwesomeIcons.wifi,
          color: Colors.white,
          size: 18,
        ),
        label: Text(
          _isConnected ? 'Conectado' : 'Conectar Broker',
          style: const TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _connectToBroker() async {
    final connected = await widget.mqttService.connect();
    if (mounted) {
      setState(() => _isConnected = connected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connected
                ? 'Conectado al broker Mosquitto'
                : 'Error al conectar con el broker',
          ),
          backgroundColor: connected ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }

  void _openDeviceDetail(Device device) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DeviceDetailScreen(
          device: device,
          mqttService: widget.mqttService,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _toggleDevice(Device device) {
    setState(() {
      device.isOn = !device.isOn;
      if (device.isOn && device.hasSlider && device.value == 0) {
        device.value = device.maxValue * 0.5;
      }
    });

    if (_isConnected) {
      widget.mqttService.publish(device.type.mqttTopic, {
        'command': device.isOn ? 'on' : 'off',
        'deviceId': device.id,
      });
    }
  }

  void _openBrokerConfig() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BrokerConfigScreen(
          mqttService: widget.mqttService,
        ),
      ),
    ).then((changed) {
      if (mounted && changed == true) {
        setState(() {
          _isConnected = widget.mqttService.isConnected;
        });
      }
    });
  }

  Future<void> _refreshDevices() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {});
  }
}
