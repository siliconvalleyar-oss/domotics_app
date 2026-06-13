# Domótica App — Flutter MQTT Home Automation

## Descripción
App Flutter para controlar dispositivos domóticos (luces, temperatura, ventiladores, cerraduras, cortinas, energía) vía MQTT. Interfaz minimalista en español con 5 tabs en bottom navigation.

## Ramas
- `main` — versión estable original
- `feat/redesign-minimalist` — rediseño con bottom nav, energy monitor, add device, crypto fix

## Comandos Rápidos
```bash
cd domotics_app
flutter pub get
flutter run                    # Desarrollo
flutter build apk --release    # Android
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Deep Clean + Build Completo
```bash
rm -rf build/ .dart_tool/ pubspec.lock && flutter clean && flutter pub get
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Dependencias
```bash
flutter pub add mqtt_client font_awesome_flutter animations shared_preferences adb_wifi
```

## Arquitectura
```
lib/
├── main.dart                   # Entry point, 5 tabs bottom nav
├── app_theme.dart              # Tema claro con WorkSans + Roboto
├── models/
│   ├── device.dart             # Device + DeviceType (city, customTopic)
│   ├── broker_config.dart      # BrokerConfig (host, port, username, password)
│   ├── scene.dart              # Scene con múltiples acciones MQTT
│   ├── bitcoin_data.dart       # CryptoPrice model
│   ├── mqtt_log_entry.dart     # Log entry para monitor
│   └── energy_data.dart        # EnergyData con estimación kWh
├── screens/
│   ├── dashboard_screen.dart   # Solo grid + filtro habitación + FAB conectar/add
│   ├── add_device_screen.dart  # Formulario: tipo, nombre, habitación, ciudad, topic, max
│   ├── scenes_screen.dart      # Grid 2×2 de escenas
│   ├── energy_screen.dart      # Monitor de energía (barras animadas)
│   ├── crypto_screen.dart      # Anillos crypto (animación sin reset a 0)
│   ├── device_detail_screen.dart
│   ├── broker_config_screen.dart
│   └── monitor_screen.dart     # Log MQTT en tiempo real
├── services/
│   ├── mqtt_service.dart       # MqttServerClient wrapper (streams)
│   ├── config_persistence.dart # SharedPreferences: broker + devices
│   └── broker_scanner.dart     # Socket scan /24
└── widgets/
    ├── device_card.dart
    ├── animated_toggle.dart
    ├── animated_slider.dart
    ├── scene_card.dart
    ├── bitcoin_ring.dart
    └── energy_monitor_widget.dart  # Barras animadas estilo Storage Monitor
```

## Bottom Navigation (5 tabs)
| Tab | Contenido |
|-----|-----------|
| Dashboard | Grid dispositivos + filtro habitación |
| Escenas | Escenas inteligentes en grid 2×2 |
| Energía | Consumo estimado por dispositivo (kWh) |
| Crypto | Precios BTC/ETH/XRP en anillos animados |
| Monitor | Log MQTT en tiempo real |

## Agregar Dispositivo
- Botón **"+"** (FAB) en Dashboard → `AddDeviceScreen`
- Campos: tipo, nombre, habitación, ciudad (temp), topic personalizado, valor máximo
- Se persiste en SharedPreferences

## MQTT
- Broker default: `raspberry.local:1883`
- Tópico comando: `{topic}` → `{"command":"on"/"off", "deviceId":"<id>"}` o `{"deviceId":"<id>", "value":<num>}`
- Tópico estado: `{topic}/status` → `{"isOn":bool, "value":num}`
- Tipos: light, temperature, fan, lock, energy, curtain
- Topic personalizable por dispositivo

## Assets
- `assets/fonts/WorkSans-*.ttf`, `Roboto-*.ttf`
- `assets/linux.png` — icono app + launcher Android
- Generar launcher icons:
  ```bash
  python3 -c "
  from PIL import Image
  logo = Image.open('assets/linux.png').convert('RGBA')
  sizes = {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}
  for d,s in sizes.items():
      r=logo.resize((s,s),Image.LANCZOS)
      r.save(f'android/app/src/main/res/mipmap-{d}/ic_launcher.png')
      r.save(f'android/app/src/main/res/mipmap-{d}/ic_launcher_round.png')
  logo.resize((432,432),Image.LANCZOS).save('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png')
  "
  ```

## Dispositivo Físico (Xiaomi)
- `adb connect 192.168.1.34:33515`
- Si falla `INSTALL_FAILED_USER_RESTRICTED`:
  - Activar "Instalar vía USB" y "Depuración USB (Configuración de seguridad)"
  - Desbloquear pantalla y aceptar prompt

## Sincronización Raspberry Pi
- Broker Mosquitto en Raspberry Pi
- Comandos → `{topic}`, estado ← `{topic}/status`
- Escáner de red descubre brokers automáticamente
