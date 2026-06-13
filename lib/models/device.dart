import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum DeviceType {
  light,
  temperature,
  fan,
  lock,
  energy,
  curtain,
}

extension DeviceTypeExtension on DeviceType {
  String get label {
    switch (this) {
      case DeviceType.light:
        return 'Luz';
      case DeviceType.temperature:
        return 'Temperatura';
      case DeviceType.fan:
        return 'Ventilador';
      case DeviceType.lock:
        return 'Cerradura';
      case DeviceType.energy:
        return 'Energía';
      case DeviceType.curtain:
        return 'Cortina';
    }
  }

  FaIconData get icon {
    switch (this) {
      case DeviceType.light:
        return FontAwesomeIcons.lightbulb;
      case DeviceType.temperature:
        return FontAwesomeIcons.temperatureHigh;
      case DeviceType.fan:
        return FontAwesomeIcons.fan;
      case DeviceType.lock:
        return FontAwesomeIcons.lock;
      case DeviceType.energy:
        return FontAwesomeIcons.bolt;
      case DeviceType.curtain:
        return FontAwesomeIcons.personWalkingWithCane;
    }
  }

  Color get color {
    switch (this) {
      case DeviceType.light:
        return const Color(0xFFF9CA24);
      case DeviceType.temperature:
        return const Color(0xFFFF6B6B);
      case DeviceType.fan:
        return const Color(0xFF74B9FF);
      case DeviceType.lock:
        return const Color(0xFFA29BFE);
      case DeviceType.energy:
        return const Color(0xFF55EFC4);
      case DeviceType.curtain:
        return const Color(0xFFFDA7DF);
    }
  }

  String get mqttTopic {
    switch (this) {
      case DeviceType.light:
        return 'domotics/light';
      case DeviceType.temperature:
        return 'domotics/temperature';
      case DeviceType.fan:
        return 'domotics/fan';
      case DeviceType.lock:
        return 'domotics/lock';
      case DeviceType.energy:
        return 'domotics/energy';
      case DeviceType.curtain:
        return 'domotics/curtain';
    }
  }

  bool get hasSlider {
    return this == DeviceType.light ||
        this == DeviceType.temperature ||
        this == DeviceType.fan ||
        this == DeviceType.energy ||
        this == DeviceType.curtain;
  }
}

class Device {
  final String id;
  final String name;
  final DeviceType type;
  String room;
  bool isOn;
  double value;
  double minValue;
  double maxValue;
  String unit;
  bool isConnected;
  String city;
  String customTopic;

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.room = 'Sala',
    this.isOn = false,
    this.value = 0,
    this.minValue = 0,
    this.maxValue = 100,
    this.unit = '%',
    this.isConnected = false,
    this.city = '',
    this.customTopic = '',
  });

  String get effectiveTopic {
    if (customTopic.isNotEmpty) return customTopic;
    return type.mqttTopic;
  }

  String get valueDisplay {
    if (type == DeviceType.temperature) {
      final cityLabel = city.isNotEmpty ? ' $city' : '';
      return '${value.toStringAsFixed(1)}°C$cityLabel';
    }
    if (type == DeviceType.lock) {
      return isOn ? 'Cerrado' : 'Abierto';
    }
    return '${value.toInt()}$unit';
  }

  String get statusText {
    if (!isConnected) return 'Desconectado';
    if (type == DeviceType.temperature) return valueDisplay;
    return isOn ? 'Encendido' : 'Apagado';
  }

  bool get hasSlider {
    return type == DeviceType.light ||
        type == DeviceType.temperature ||
        type == DeviceType.fan ||
        type == DeviceType.energy ||
        type == DeviceType.curtain;
  }

  static List<Device> sampleDevices = [
    Device(
      id: 'light_1',
      name: 'Lámpara Principal',
      type: DeviceType.light,
      room: 'Sala',
      isOn: false,
      value: 75,
      maxValue: 100,
    ),
    Device(
      id: 'temp_1',
      name: 'Termostato',
      type: DeviceType.temperature,
      room: 'Sala',
      isOn: true,
      value: 22.5,
      minValue: 16,
      maxValue: 30,
      unit: '°C',
      city: 'Buenos Aires',
    ),
    Device(
      id: 'fan_1',
      name: 'Ventilador Techo',
      type: DeviceType.fan,
      room: 'Dormitorio',
      isOn: false,
      value: 2,
      minValue: 0,
      maxValue: 5,
      unit: '',
    ),
    Device(
      id: 'lock_1',
      name: 'Puerta Principal',
      type: DeviceType.lock,
      room: 'Entrada',
      isOn: true,
      value: 1,
      maxValue: 1,
    ),
    Device(
      id: 'light_2',
      name: 'Luz Cocina',
      type: DeviceType.light,
      room: 'Cocina',
      isOn: true,
      value: 100,
      maxValue: 100,
    ),
    Device(
      id: 'curtain_1',
      name: 'Cortina Sala',
      type: DeviceType.curtain,
      room: 'Sala',
      isOn: false,
      value: 0,
      maxValue: 100,
    ),
    Device(
      id: 'energy_1',
      name: 'Consumo Total',
      type: DeviceType.energy,
      room: 'General',
      isOn: true,
      value: 342,
      minValue: 0,
      maxValue: 1000,
      unit: 'W',
    ),
    Device(
      id: 'light_3',
      name: 'Luz Jardín',
      type: DeviceType.light,
      room: 'Exterior',
      isOn: false,
      value: 50,
      maxValue: 100,
    ),
  ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'room': room,
        'isOn': isOn,
        'value': value,
        'city': city,
        'customTopic': customTopic,
        'minValue': minValue,
        'maxValue': maxValue,
        'unit': unit,
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        name: json['name'] as String,
        type: DeviceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DeviceType.light,
        ),
        room: json['room'] as String? ?? 'Sala',
        isOn: json['isOn'] as bool? ?? false,
        value: (json['value'] as num?)?.toDouble() ?? 0,
        city: json['city'] as String? ?? '',
        customTopic: json['customTopic'] as String? ?? '',
        minValue: (json['minValue'] as num?)?.toDouble() ?? 0,
        maxValue: (json['maxValue'] as num?)?.toDouble() ?? 100,
        unit: json['unit'] as String? ?? '%',
      );
}
