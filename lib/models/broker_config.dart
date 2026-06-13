class BrokerConfig {
  String host;
  int port;
  String username;
  String password;
  String clientId;

  BrokerConfig({
    this.host = 'raspberry.local',
    this.port = 1883,
    this.username = '',
    this.password = '',
    String? clientId,
  }) : clientId = clientId ?? 'domotics_app_${DateTime.now().millisecondsSinceEpoch}';

  BrokerConfig copy() => BrokerConfig(
        host: host,
        port: port,
        username: username,
        password: password,
        clientId: clientId,
      );

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'username': username,
        'password': password,
      };

  factory BrokerConfig.fromJson(Map<String, dynamic> json) => BrokerConfig(
        host: json['host'] as String? ?? 'raspberry.local',
        port: json['port'] as int? ?? 1883,
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );
}
