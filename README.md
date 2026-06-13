# Domótica App

Panel de control domótico multiplataforma construido con Flutter. Controla luces, temperatura, ventiladores, cerraduras, cortinas y monitoreo de energía vía MQTT.

## Capturas

<!-- TODO: Agregar capturas de pantalla -->
| Dashboard | Detalle dispositivo | Configuración broker |
|---|---|---|

## Inicio Rápido

```bash
flutter pub get
flutter run
```

La app se conecta por defecto al broker público `test.mosquitto.org:1883`. Para usar un broker local, toca el icono de engranaje en el dashboard y configura tu propio host/puerto.

## Requisitos

- Flutter >=3.12.1
- Dart >=3.12.1
- Dispositivo Android/iOS o emulador
- (Opcional) Broker MQTT — `test.mosquitto.org:1883` funciona sin configuración

## Dependencias

| Paquete | Versión | Propósito |
|---|---|---|
| mqtt_client | ^10.11.11 | Conexión MQTT (publicar/suscribir) |
| font_awesome_flutter | ^11.0.0 | Iconos de dispositivos |
| animations | ^2.2.0 | Transiciones (FadeThroughTransition) |
| shared_preferences | ^2.5.5 | Persistir configuración del broker |

## Características

- **6 tipos de dispositivos**: Luz, Temperatura, Ventilador, Cerradura, Cortina, Energía
- **Dashboard** con grid de tarjetas, filtro por habitación y badge de dispositivos encendidos
- **Toggle animado** personalizado para encender/apagar cada dispositivo
- **Slider animado** para ajustar brillo, temperatura, velocidad, etc.
- **Control MQTT en vivo**: publica comandos JSON y recibe actualizaciones de estado
- **Escáner de brokers** en la red local (subnet /24, puertos 1883/8883/1884/8884/8080/8081)
- **Persistencia** de configuración del broker (SharedPreferences)
- **Interfaz en español**

## Estructura

```
lib/
├── main.dart                         # Entry point + inyección de MqttService
├── app_theme.dart                    # Tema claro (WorkSans + Roboto)
├── models/
│   ├── device.dart                   # Device, DeviceType (6 tipos)
│   └── broker_config.dart            # Configuración MQTT (host, puerto, auth)
├── screens/
│   ├── dashboard_screen.dart         # Dashboard principal con grid
│   ├── device_detail_screen.dart     # Control detallado del dispositivo
│   └── broker_config_screen.dart     # Configuración + escáner de brokers
├── services/
│   ├── mqtt_service.dart             # Cliente MQTT (conectar, publicar, suscribir)
│   ├── config_persistence.dart       # Guardar/cargar config desde SharedPreferences
│   └── broker_scanner.dart           # Escáner de red local para brokers MQTT
└── widgets/
    ├── device_card.dart              # Tarjeta de dispositivo en el grid
    ├── animated_toggle.dart          # Toggle personalizado animado
    └── animated_slider.dart          # Slider personalizado animado
```

## Comandos

```bash
flutter pub get              # Instalar dependencias
flutter run                  # Ejecutar en modo debug
flutter run --release        # Ejecutar en modo release
flutter build apk --debug    # Build APK debug
flutter build apk --release  # Build APK release
flutter build ios            # Build iOS (requiere macOS)
flutter analyze              # Analizar código
flutter test                 # Ejecutar tests
```

## Monitorear y Controlar desde Otro PC

### 1. Ver todos los mensajes en tiempo real

```bash
# Desde tu PC local
mosquitto_sub -h test.mosquitto.org -t "domotics/#" -v

# Desde una Raspberry Pi vía SSH
ssh joy@raspberry.local "mosquitto_sub -h test.mosquitto.org -t 'domotics/#' -v"
```

### 2. Enviar comandos que la app recibe en vivo

La app está suscrita a `domotics/{tipo}/status`. Publicá en ese tópico y el dashboard se actualiza al instante:

```bash
# Actualizar temperatura del termostato
mosquitto_pub -h test.mosquitto.org -t "domotics/temperature/status" -m '{"isOn": true, "value": 22.5}'

# Apagar luz cocina
mosquitto_pub -h test.mosquitto.org -t "domotics/light/status" -m '{"isOn": false, "value": 0}'

# Desde la Raspberry vía SSH
ssh joy@raspberry.local "mosquitto_pub -h test.mosquitto.org -t 'domotics/temperature/status' -m '{\"isOn\": true, \"value\": 24.0}'"
```

> **Nota:** Si el JSON contiene comillas dobles dentro de un string SSH, escapalas con `\"`.

### 3. Probar el ciclo completo (app ↔ broker ↔ PC)

```
┌─────────────────┐     publish      ┌──────────────────┐     publish      ┌────────────┐
│  App (móvil)     │ ───────────────→ │  Broker MQTT      │ ←─────────────── │  PC / RPi  │
│  Subscribe       │ ←─────────────── │  test.mosquitto   │ ────────────────→ │  mosquitto  │
│  domotics/#      │     subscribe    │  .org:1883        │     subscribe    │  _sub/_pub  │
└─────────────────┘                  └──────────────────┘                  └────────────┘
```

Cada vez que publicás desde la terminal, la app muestra el cambio al instante (si está conectada al broker).

### 4. Script rápido para pruebas (Python)

```bash
pip install paho-mqtt
```

```python
import paho.mqtt.client as mqtt

def on_msg(c, u, m):
    print(f'{m.topic}: {m.payload.decode()}')

c = mqtt.Client()
c.on_message = on_msg
c.connect('test.mosquitto.org', 1883, 60)
c.subscribe('domotics/#')

# Publicar un mensaje de prueba
c.publish('domotics/temperature/status', '{"isOn": true, "value": 22.5}')

c.loop_forever()
```

## Tópicos MQTT

| Tipo | Tópico comando (app → broker) | Tópico estado (broker → app) |
|---|---|---|
| Luz | `domotics/light` | `domotics/light/status` |
| Temperatura | `domotics/temperature` | `domotics/temperature/status` |
| Ventilador | `domotics/fan` | `domotics/fan/status` |
| Cerradura | `domotics/lock` | `domotics/lock/status` |
| Cortina | `domotics/curtain` | `domotics/curtain/status` |
| Energía | `domotics/energy` | `domotics/energy/status` |

### Formato de mensajes

**Comando (app → broker):**
```json
{"command": "on", "deviceId": "light_1"}
{"command": "off", "deviceId": "light_1"}
{"deviceId": "temp_1", "value": 22.5}
```

**Estado (broker → app):**
```json
{"isOn": true, "value": 75}
```

## Conexión Automática

La app se conecta automáticamente al broker al iniciar. El badge verde en el AppBar y el texto "Conectado al broker" confirman que la conexión está activa. Si algo falla, tocá el botón flotante "Conectar Broker".
