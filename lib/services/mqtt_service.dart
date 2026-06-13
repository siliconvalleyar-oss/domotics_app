import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/broker_config.dart';

class MqttService {
  MqttServerClient? _client;
  BrokerConfig _config;
  bool _isConnected = false;

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;
  BrokerConfig get config => _config;

  MqttService({BrokerConfig? config})
      : _config = config ?? BrokerConfig();

  /// Actualiza la configuración del broker.
  /// Si está conectado, se desconecta automáticamente.
  void updateConfig(BrokerConfig newConfig) {
    _config = newConfig;
    if (_isConnected) {
      disconnect();
    }
  }

  Future<bool> connect() async {
    if (_isConnected) return true;

    try {
      _client = MqttServerClient(_config.host, _config.clientId);
      _client!.port = _config.port;
      _client!.keepAlivePeriod = 30;
      _client!.connectTimeoutPeriod = 5000;
      _client!.logging(on: false);

      // Configurar callbacks
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.pongCallback = _pong;

      // Conexión con autenticación opcional
      final connMessage = MqttConnectMessage().startClean().withWillQos(MqttQos.atLeastOnce);
      if (_config.username.isNotEmpty && _config.password.isNotEmpty) {
        connMessage.authenticateAs(_config.username, _config.password);
      }
      _client!.connectionMessage = connMessage;

      await _client!.connect();

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _isConnected = true;

        // Escuchar mensajes (antes de emitir connected para que las suscripciones
        // se hagan después de tener el listener activo)
        _client!.updates?.listen(_onMessageReceived);

        _connectionController.add(true);
        return true;
      }

      _isConnected = false;
      _connectionController.add(false);
      return false;
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      print('MQTT connection error: $e');
      return false;
    }
  }

  void _onConnected() {
    _isConnected = true;
    _connectionController.add(true);
  }

  void _onDisconnected() {
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onSubscribed(String topic) {
    // Suscripción exitosa
  }

  void _pong() {
    // Pong recibido
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = message.payload as MqttPublishMessage;
      final data = utf8.decode(payload.payload.message);

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        json['topic'] = topic;
        _messageController.add(json);
      } catch (_) {
        _messageController.add({
          'topic': topic,
          'value': data,
        });
      }
    }
  }

  Future<void> subscribe(String topic,
      {MqttQos qos = MqttQos.atLeastOnce}) async {
    if (!_isConnected || _client == null) return;
    _client!.subscribe(topic, qos);
  }

  Future<void> publish(String topic, Map<String, dynamic> message,
      {MqttQos qos = MqttQos.atLeastOnce}) async {
    if (!_isConnected || _client == null) return;

    final payload = jsonEncode(message);
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    await _client!.publishMessage(topic, qos, builder.payload!);
  }

  Future<void> publishCommand(String topic, String command) async {
    await publish(topic, {'command': command});
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _connectionController.add(false);
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _messageController.close();
  }
}
