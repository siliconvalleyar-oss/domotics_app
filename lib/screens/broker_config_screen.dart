import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_theme.dart';
import '../models/broker_config.dart';
import '../services/mqtt_service.dart';
import '../services/config_persistence.dart';
import '../services/broker_scanner.dart';

class BrokerConfigScreen extends StatefulWidget {
  final MqttService mqttService;

  const BrokerConfigScreen({super.key, required this.mqttService});

  @override
  State<BrokerConfigScreen> createState() => _BrokerConfigScreenState();
}

class _BrokerConfigScreenState extends State<BrokerConfigScreen> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isConnecting = false;
  bool _isScanning = false;
  bool _passwordVisible = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    final config = widget.mqttService.config;
    _hostController = TextEditingController(text: config.host);
    _portController = TextEditingController(text: config.port.toString());
    _usernameController = TextEditingController(text: config.username);
    _passwordController = TextEditingController(text: config.password);
    _isConnected = widget.mqttService.isConnected;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  BrokerConfig? _validateAndBuildConfig() {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      _showError('El host no puede estar vacío');
      return null;
    }

    final port = int.tryParse(_portController.text.trim());
    if (port == null || port < 1 || port > 65535) {
      _showError('El puerto debe ser un número entre 1 y 65535');
      return null;
    }

    return BrokerConfig(
      host: host,
      port: port,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _connect() async {
    final config = _validateAndBuildConfig();
    if (config == null) return;

    setState(() => _isConnecting = true);

    widget.mqttService.updateConfig(config);
    final connected = await widget.mqttService.connect();

    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isConnected = connected;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connected
                ? 'Conectado a ${config.host}:${config.port}'
                : 'Error de conexión',
          ),
          backgroundColor: connected ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      if (connected) {
        await ConfigPersistence.saveConfig(config);
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _disconnect() async {
    await widget.mqttService.disconnect();
    if (mounted) {
      setState(() => _isConnected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Desconectado del broker'),
          backgroundColor: AppTheme.deactivatedText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Broker'),
        actions: [
          if (_isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Connection status card
          _buildConnectionStatus(),
          const SizedBox(height: 20),

          // Server settings section
          _buildSectionHeader('Servidor'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _hostController,
            label: 'Host',
            hint: 'test.mosquitto.org',
            icon: FontAwesomeIcons.server,
            enabled: !_isConnected,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _portController,
            label: 'Puerto',
            hint: '1883',
            icon: FontAwesomeIcons.plug,
            keyboardType: TextInputType.number,
            enabled: !_isConnected,
          ),
          const SizedBox(height: 24),

          // Authentication section
          _buildSectionHeader('Autenticación'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _usernameController,
            label: 'Usuario',
            hint: '(opcional)',
            icon: FontAwesomeIcons.user,
            enabled: !_isConnected,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordController,
            label: 'Contraseña',
            hint: '(opcional)',
            icon: FontAwesomeIcons.lock,
            obscureText: !_passwordVisible,
            enabled: !_isConnected,
            suffixIcon: IconButton(
              icon: FaIcon(
                _passwordVisible
                    ? FontAwesomeIcons.eye
                    : FontAwesomeIcons.eyeSlash,
                size: 18,
                color: AppTheme.lightText,
              ),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          _buildActionButtons(),
          const SizedBox(height: 20),

          // Info
          if (!_isConnected) _buildDefaultBrokersHint(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isConnected ? AppTheme.success : AppTheme.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isConnected ? AppTheme.success : AppTheme.error).withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Conectado' : 'Desconectado',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isConnected
                      ? '${widget.mqttService.config.host}:${widget.mqttService.config.port}'
                      : 'Sin conexión al broker',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 12,
                    color: AppTheme.lightText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required FaIconData icon,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: AppTheme.fontName,
          fontSize: 15,
          color: AppTheme.darkText,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: FaIcon(icon, size: 18, color: AppTheme.primaryAccent),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppTheme.primaryAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: AppTheme.cardBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 14,
            color: enabled ? AppTheme.primaryAccent : AppTheme.deactivatedText,
          ),
          hintStyle: const TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 14,
            color: AppTheme.deactivatedText,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade100,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isConnecting
                ? null
                : (_isConnected ? _disconnect : _connect),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isConnected ? AppTheme.error : AppTheme.primaryAccent,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: AppTheme.deactivatedText,
            ),
            child: _isConnecting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        _isConnected
                            ? FontAwesomeIcons.wifi
                            : FontAwesomeIcons.wifi,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isConnected
                            ? 'Desconectar'
                            : 'Probar Conexión',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isScanning || _isConnecting
                ? null
                : _scanForBrokers,
            icon: _isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const FaIcon(FontAwesomeIcons.wifi, size: 16),
            label: Text(
              _isScanning ? 'Escaneando...' : 'Escanear brokers en la red',
              style: const TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryAccent,
              side: BorderSide(
                color: AppTheme.primaryAccent.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: _isConnecting ? null : _resetToDefaults,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.deactivatedText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.arrowRotateLeft,
                  size: 16,
                  color: AppTheme.deactivatedText,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Restablecer valores por defecto',
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _scanForBrokers() async {
    setState(() => _isScanning = true);

    try {
      final results = await BrokerScanner.scanSubnet();

      if (!mounted) return;
      setState(() => _isScanning = false);

      if (results.isEmpty) {
        _showError('No se encontraron brokers en la red local');
        return;
      }

      _showScanResults(results);
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        _showError('Error al escanear: ${e.toString()}');
      }
    }
  }

  void _showScanResults(List<ScanResult> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.deactivatedText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.wifi,
                    size: 18,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Brokers encontrados (${results.length})',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Lista de resultados
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final result = results[index];
                  return _buildScanResultTile(result);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectBroker(ScanResult result) {
    _hostController.text = result.host;
    _portController.text = result.port.toString();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Broker seleccionado: ${result.display}'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildScanResultTile(ScanResult result) {
    return GestureDetector(
      onTap: () => _selectBroker(result),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(
                FontAwesomeIcons.server,
                size: 18,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.host,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Puerto ${result.port} · ${result.responseTimeMs}ms',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12,
                      color: AppTheme.lightText,
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.arrowRight,
              size: 14,
              color: AppTheme.deactivatedText,
            ),
          ],
        ),
      ),
    );
  }

  void _applyDefaults() {
    _hostController.text = 'test.mosquitto.org';
    _portController.text = '1883';
    _usernameController.text = '';
    _passwordController.text = '';
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Restablecer valores',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Se limpiará la configuración guardada y se reconectará con los valores por defecto (test.mosquitto.org:1883).',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Restablecer',
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Desconectar si está conectado
    if (_isConnected) {
      await widget.mqttService.disconnect();
    }

    // Limpiar configuración guardada
    await ConfigPersistence.clearConfig();

    // Resetear campos a valores por defecto
    _applyDefaults();

    if (!mounted) return;
    setState(() => _isConnected = false);

    // Actualizar el servicio y reconectar
    final defaultConfig = BrokerConfig(
      host: 'test.mosquitto.org',
      port: 1883,
    );
    widget.mqttService.updateConfig(defaultConfig);

    setState(() => _isConnecting = true);
    final connected = await widget.mqttService.connect();

    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isConnected = connected;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connected
                ? 'Conectado con valores por defecto'
                : 'Error al conectar con valores por defecto',
          ),
          backgroundColor: connected ? AppTheme.success : AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      if (connected) {
        await ConfigPersistence.saveConfig(defaultConfig);
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildDefaultBrokersHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(
            FontAwesomeIcons.circleInfo,
            size: 18,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Brokers públicos de prueba:',
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'test.mosquitto.org:1883\nbroker.emqx.io:1883\nbroker.hivemq.com:1883',
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 12,
                    color: AppTheme.lightText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
