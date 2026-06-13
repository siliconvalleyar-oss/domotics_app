# Protocolo MQTT — Domótica App

## Broker por Defecto

```
Host: test.mosquitto.org
Puerto: 1883
TLS: No
```

## Formato de Mensajes

### App → Broker (Comandos)

Cuando el usuario interactúa con un dispositivo, la app publica en el tópico `domotics/{tipo}`:

**Toggle On/Off:**
```json
{"command": "on", "deviceId": "light_1"}
{"command": "off", "deviceId": "light_1"}
```

**Ajustar valor (slider o botones rápido):**
```json
{"deviceId": "temp_1", "value": 22.5}
```

### Broker → App (Estado)

La app suscribe a `domotics/{tipo}/status` para cada tipo de dispositivo. El broker debe publicar:

```json
{"isOn": true, "value": 75}
```

| Campo | Tipo | Descripción |
|---|---|---|
| `isOn` | boolean | Estado encendido/apagado |
| `value` | number | Valor actual (temperatura, brillo, velocidad, etc.) |

## Tópicos

| Tipo Dispositivo | Tópico Comando | Tópico Estado |
|---|---|---|
| Luz | `domotics/light` | `domotics/light/status` |
| Temperatura | `domotics/temperature` | `domotics/temperature/status` |
| Ventilador | `domotics/fan` | `domotics/fan/status` |
| Cerradura | `domotics/lock` | `domotics/lock/status` |
| Cortina | `domotics/curtain` | `domotics/curtain/status` |
| Energía | `domotics/energy` | `domotics/energy/status` |

## Rangos de Valores

| Tipo | Min | Max | Unidad |
|---|---|---|---|
| Luz | 0 | 100 | % |
| Temperatura | 16 | 30 | °C |
| Ventilador | 0 | 5 | velocidad |
| Cerradura | — | — | on/off (sin slider) |
| Cortina | 0 | 100 | % apertura |
| Energía | 0 | 1000 | W |

## QoS

La app utiliza QoS **al menos una vez** (at least once delivery).

## Ejemplo Completo

```bash
# Terminal 1: monitorear todos los mensajes
mosquitto_sub -h test.mosquitto.org -t "domotics/#" -v

# Terminal 2: simular un dispositivo que reporta estado
mosquitto_pub -h test.mosquitto.org -t "domotics/light/status" -m '{"isOn": true, "value": 80}'
mosquitto_pub -h test.mosquitto.org -t "domotics/temperature/status" -m '{"isOn": true, "value": 24.5}'
mosquitto_pub -h test.mosquitto.org -t "domotics/lock/status" -m '{"isOn": false, "value": 0}'
```

Cuando la app está abierta, recibirá estos mensajes y actualizará las tarjetas en tiempo real.
