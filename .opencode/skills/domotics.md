# Domótica App — Flutter MQTT Home Automation

## Descripción
App Flutter para controlar dispositivos domóticos (luces, temperatura, ventiladores, cerraduras, cortinas, energía) vía MQTT. Interfaz en español con toggles animados, sliders, escáner de brokers y persistencia de configuración.

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
├── main.dart                   # Entry point, carga config guardada, inyecta MqttService
├── app_theme.dart              # Tema claro con WorkSans + Roboto
├── models/
│   ├── device.dart             # Device + DeviceType (6 tipos con icono, color, tópico MQTT)
│   └── broker_config.dart      # BrokerConfig (host, port, username, password)
├── screens/
│   ├── dashboard_screen.dart   # Grid de tarjetas, filtro por habitación, FAB conectar
│   ├── device_detail_screen.dart # Toggle + slider + botones rápido (Min/Mid/Max)
│   └── broker_config_screen.dart # Formulario broker + escáner de red
├── services/
│   ├── mqtt_service.dart       # MqttServerClient wrapper (streams connection + messages)
│   ├── config_persistence.dart # SharedPreferences load/save
│   └── broker_scanner.dart     # Socket scan /24 (lotes 50 conexiones, timeout 800ms)
└── widgets/
    ├── device_card.dart        # Tarjeta con icono, toggle, badge de estado
    ├── animated_toggle.dart    # Toggle pill animado personalizado
    └── animated_slider.dart    # Slider con track gradientado y badge
```

## MQTT
- Broker default: `test.mosquitto.org:1883`
- Tópico comando: `domotics/{type}` → `{"command":"on"/"off", "deviceId":"<id>"}` o `{"deviceId":"<id>", "value":<num>}`
- Tópico estado: `domotics/{type}/status` → `{"isOn":bool, "value":num}`
- Tipos: light, temperature, fan, lock, energy, curtain
- Sin estado global (setState + MqttService inyectado manualmente)
- `dart:io` en broker_scanner → no compila para web

## Cómo Agregar un Dispositivo
1. Agregar enum a `DeviceType` en `models/device.dart`
2. Implementar extension: label, icon, color, mqttTopic
3. Agregar sample a `Device.sampleDevices`
4. Dashboard y detail screen funcionan automáticamente (genéricos por tipo)

## Assets
- `assets/fonts/WorkSans-*.ttf`
- `assets/fonts/Roboto-*.ttf`
- `assets/logo.png` (icono app + launcher Android)
- Generar launcher icons desde `assets/logo.png`:
  ```bash
  python3 -c "
  from PIL import Image
  logo = Image.open('assets/logo.png').convert('RGBA')
  sizes = {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}
  for d,s in sizes.items():
      r=logo.resize((s,s),Image.LANCZOS)
      r.save(f'android/app/src/main/res/mipmap-{d}/ic_launcher.png')
      r.save(f'android/app/src/main/res/mipmap-{d}/ic_launcher_round.png')
  logo.resize((432,432),Image.LANCZOS).save('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png')
  "
  ```

## Dispositivo Físico (Xiaomi)
- Conectar vía WiFi ADB: `adb connect 192.168.1.34:33515`
- Si falla `INSTALL_FAILED_USER_RESTRICTED`:
  - Activar "Instalar vía USB" y "Depuración USB (Configuración de seguridad)" en Opciones de desarrollador
  - Desbloquear pantalla y aceptar el prompt de instalación

## Sincronización Raspberry Pi
- La app se conecta al broker MQTT (Mosquitto) en la Raspberry
- Los comandos se envían a `domotics/{type}` y la Raspberry publica estados en `domotics/{type}/status`
- Escáner de red descubre brokers automáticamente en la subred /24
