# Arquitectura

## Flujo de Datos

```
[Broker MQTT] ←───→ [MqttService] ←───→ [DashboardScreen]
                      (publica)              │
                      (suscribe)             │
                                             ▼
                                      [DeviceDetailScreen]
                                             │
                                        [AnimatedToggle]
                                        [AnimatedSlider]
```

## Componentes

### Models

| Modelo | Campos | Propósito |
|---|---|---|
| `Device` | id, name, type (enum), room, isOn, value, min/maxValue, unit, isConnected | Estado de cada dispositivo |
| `DeviceType` | light, temperature, fan, lock, energy, curtain + extension con label, icon, color, mqttTopic | Tipos de dispositivos |
| `BrokerConfig` | host, port, username, password | Configuración de conexión MQTT |

### Services

| Servicio | Rol |
|---|---|
| `MqttService` | Envuelve `mqtt_client`: conecta, desconecta, publica JSON, suscribe a tópicos, expone streams de conexión (`Stream<bool>`) y mensajes (`Stream<Map<String,dynamic>>`) |
| `ConfigPersistence` | `SharedPreferences` para guardar/cargar `mqtt_host`, `mqtt_port`, `mqtt_username`, `mqtt_password` |
| `BrokerScanner` | Escanea la red local (/24) con `Socket.connect` (timeout 800ms) en lotes de 50 conexiones concurrentes; también revisa hostnames comunes (broker, mqtt, mosquitto, localhost) |

### Screens

| Screen | Widgets | Propósito |
|---|---|---|
| `DashboardScreen` | `DeviceCard` grid, FAB conectar/desconectar, badge contador, filtro por habitación | Vista principal con todos los dispositivos |
| `DeviceDetailScreen` | `AnimatedToggle`, `AnimatedSlider`, botones rápido (Min/Mid/Max) | Control individual de cada dispositivo |
| `BrokerConfigScreen` | Formulario host/puerto/auth, botón probar conexión, escáner de red | Configuración del broker MQTT |

### Custom Widgets

| Widget | Descripción |
|---|---|
| `AnimatedToggle` | Toggle pill animado, coloreado por tipo de dispositivo, modo interactivo o solo lectura |
| `AnimatedSlider` |Slider con track gradientado y badge de valor flotante |
| `DeviceCard` | Tarjeta con icono FontAwesome, nombre, habitación, toggle/valor, indicador de conexión |

## MQTT

### Conexión

- Broker por defecto: `test.mosquitto.org:1883`
- Timeout: 5 segundos
- Keep-alive: 30 segundos
- Client ID: `domotics_app_<timestamp_ms>`
- Autenticación opcional (username/password)

### Tópicos

| Dirección | Tópico | Formato |
|---|---|---|
| App → Broker (comando) | `domotics/{type}` | `{"command": "on"|"off", "deviceId": "<id>"}` |
| App → Broker (valor) | `domotics/{type}` | `{"deviceId": "<id>", "value": <number>}` |
| Broker → App (estado) | `domotics/{type}/status` | `{"isOn": true/false, "value": <number>}` |

### Tipos de dispositivo y sus tópicos

| Tipo | Tópico | Slider | Unidad |
|---|---|---|---|
| Luz | `domotics/light` | 0–100 | % |
| Temperatura | `domotics/temperature` | 16–30 | °C |
| Ventilador | `domotics/fan` | 0–5 | — |
| Cerradura | `domotics/lock` | No | — |
| Cortina | `domotics/curtain` | 0–100 | % |
| Energía | `domotics/energy` | 0–1000 | W |

## Ciclo de Vida

1. `main.dart` carga `BrokerConfig` desde `SharedPreferences` (o usa default `test.mosquitto.org:1883`)
2. Crea `MqttService` con esa config y lo pasa a `DashboardScreen`
3. Dashboard suscribe a `domotics/{type}/status` para cada tipo de dispositivo
4. Los mensajes entrantes se parsean como JSON y actualizan el `Device` correspondiente via `setState`
5. Al tocar un toggle/slider, se publica el comando al broker inmediatamente
6. La configuración se persiste al conectar exitosamente

## Limitaciones

- Sin estado global (no Provider/Riverpod/BLoC) — el estado se maneja con `setState` y `MqttService` se pasa manualmente
- `dart:io` usado en `broker_scanner.dart` — **no compila para web**
- Sin soporte TLS/SSL (aunque el escáner detecta puertos 8883/8884)
- Los dispositivos de ejemplo son fijos (`Device.sampleDevices`), no se crean desde configuración
