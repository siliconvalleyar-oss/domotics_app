import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animations/animations.dart';
import '../app_theme.dart';
import '../models/device.dart';
import '../services/mqtt_service.dart';
import '../services/config_persistence.dart';
import '../widgets/device_card.dart';
import 'device_detail_screen.dart';
import 'broker_config_screen.dart';
import 'add_device_screen.dart';

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
  bool _loaded = false;

  final List<String> _rooms = ['Todos', 'Sala', 'Dormitorio', 'Cocina', 'Entrada', 'Exterior', 'General'];

  @override
  void initState() {
    super.initState();
    _devices = List.from(Device.sampleDevices);
    _loadDevices();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    widget.mqttService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() => _isConnected = connected);
        if (connected) _subscribeToTopics();
      }
    });

    widget.mqttService.messageStream.listen((message) {
      _handleMqttMessage(message);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _connectToBroker());
  }

  Future<void> _loadDevices() async {
    final saved = await ConfigPersistence.loadDevices();
    if (saved.isNotEmpty && mounted) {
      setState(() {
        _devices = [...Device.sampleDevices, ...saved];
        _loaded = true;
      });
    } else {
      if (mounted) setState(() => _loaded = true);
    }
  }

  void _subscribeToTopics() {
    for (final device in _devices) {
      widget.mqttService.subscribe('${device.effectiveTopic}/status');
    }
  }

  void _handleMqttMessage(Map<String, dynamic> message) {
    final topic = message['topic'] as String? ?? '';
    final msgDeviceId = message['deviceId'] as String?;

    for (final device in _devices) {
      bool matches;
      if (msgDeviceId != null) {
        matches = device.id == msgDeviceId;
      } else {
        matches = topic.startsWith(device.effectiveTopic);
      }
      if (matches) {
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

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _loaded
          ? RefreshIndicator(
              onRefresh: _refreshDevices,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildRoomFilter()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    sliver: _buildDeviceGrid(),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_device',
            onPressed: _openAddDevice,
            backgroundColor: AppTheme.primaryAccent,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _fabAnimationController,
              curve: Curves.easeOutBack,
            ),
            child: FloatingActionButton.extended(
              heroTag: 'connect_broker',
              onPressed: _isConnected ? null : _connectToBroker,
              backgroundColor: _isConnected ? AppTheme.success : AppTheme.primaryAccent,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              icon: FaIcon(
                _isConnected ? FontAwesomeIcons.check : FontAwesomeIcons.wifi,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                _isConnected ? 'Conectado' : 'Conectar',
                style: const TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final activeCount = _devices.where((d) => d.isOn).length;

    return AppBar(
      title: Row(
        children: [
          Image.asset('assets/linux.png', width: 32, height: 32),
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
                _isConnected
                    ? '$activeCount dispositivos activos'
                    : 'Desconectado',
                style: TextStyle(
                  fontFamily: AppTheme.fontName,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: _isConnected ? AppTheme.lightText : AppTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.gear, size: 20, color: AppTheme.darkText),
          onPressed: _openBrokerConfig,
          tooltip: 'Configurar broker',
        ),
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

  Widget _buildRoomFilter() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  color: isSelected ? AppTheme.primaryAccent : AppTheme.cardBackground,
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
              const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 48, color: AppTheme.deactivatedText),
              const SizedBox(height: 16),
              const Text(
                'No hay dispositivos en esta habitación',
                style: TextStyle(fontFamily: AppTheme.fontName, color: AppTheme.lightText),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _openAddDevice,
                icon: const Icon(Icons.add),
                label: const Text('Agregar dispositivo'),
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
        (context, index) => DeviceCard(
          device: devices[index],
          onTap: () => _openDeviceDetail(devices[index]),
          onToggle: () => _toggleDevice(devices[index]),
        ),
        childCount: devices.length,
      ),
    );
  }

  Future<void> _connectToBroker() async {
    final connected = await widget.mqttService.connect();
    if (mounted) {
      setState(() => _isConnected = connected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(connected ? 'Conectado al broker Mosquitto' : 'Error al conectar con el broker'),
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
            DeviceDetailScreen(device: device, mqttService: widget.mqttService),
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
      if (device.isOn && device.hasSlider && device.value == 0) {
        device.value = device.maxValue * 0.5;
      }
    });

    if (_isConnected) {
      widget.mqttService.publish(device.effectiveTopic, {
        'command': device.isOn ? 'on' : 'off',
        'deviceId': device.id,
      });
    }
  }

  void _openAddDevice() {
    Navigator.push<Device>(
      context,
      MaterialPageRoute(builder: (_) => const AddDeviceScreen()),
    ).then((newDevice) {
      if (newDevice != null && mounted) {
        setState(() => _devices.add(newDevice));
        _saveDevices();
        if (_isConnected) {
          widget.mqttService.subscribe('${newDevice.effectiveTopic}/status');
        }
      }
    });
  }

  void _openBrokerConfig() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BrokerConfigScreen(mqttService: widget.mqttService),
      ),
    ).then((changed) {
      if (mounted && changed == true) {
        setState(() => _isConnected = widget.mqttService.isConnected);
      }
    });
  }

  Future<void> _refreshDevices() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {});
  }

  Future<void> _saveDevices() async {
    final sampleIds = Device.sampleDevices.map((d) => d.id).toSet();
    final custom = _devices.where((d) => !sampleIds.contains(d.id)).toList();
    await ConfigPersistence.saveDevices(custom);
  }
}
