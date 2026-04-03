# IoT Hardware — Dispositivos y Plan de Integración

Documentación de los dispositivos físicos seleccionados para AlzMonitor y cómo se integrarán al sistema una vez configurados.

> **Estado actual:** dispositivos adquiridos, pendientes de configuración manual. Ningún endpoint de recepción de datos está implementado todavía en la aplicación Flask. Este documento describe la arquitectura objetivo.

---

## Inventario de dispositivos

| Rol | Modelo | Tecnología | Estado |
|-----|--------|-----------|--------|
| GPS | PG12 GPS Tracker — Luejnbogty | GPRS / 4G + GPS | Sin configurar |
| Beacon | FeasyBeacon FSC-BP104D Waterproof | Bluetooth 5.1 BLE | Sin configurar |
| NFC | RFID/NFC Tag Blue Fob — NTAG213, 13.56 MHz | ISO 14443A | Sin configurar |

---

## 1. PG12 GPS Tracker

### Descripción técnica
- Localización por GPS + asistencia por red celular (GPRS/4G).
- Envía reportes periódicos de posición vía HTTP o MQTT según configuración.
- Reporta: latitud, longitud, velocidad, nivel de batería, timestamp.
- Configurable para enviar eventos especiales: batería baja, botón SOS, encendido/apagado.

### Rol en el sistema
Cada paciente tiene asignado un GPS mediante `asignacion_kit`. El tracker lleva el paciente. El sistema recibe sus lecturas y verifica si la posición está dentro de las zonas seguras (`zonas`) asignadas a la sede.

### Flujo de datos
```
PG12 → HTTP POST → /api/gps/lectura
       ↓
  lecturas_gps (id_dispositivo, lat, lon, velocidad, nivel_bateria, fecha_hora)
       ↓
  Verificar distancia a zonas seguras del paciente
       ↓
  Si fuera de zona → INSERT alertas (tipo='Salida de Zona')
                   → INSERT alerta_evento_origen (FK → lecturas_gps)
```

### Endpoint a implementar
```
POST /api/gps/lectura
Body: { "id_serial": "...", "latitud": 0.0, "longitud": 0.0,
        "velocidad": 0.0, "nivel_bateria": 85, "fecha_hora": "..." }
```

- Busca `id_dispositivo` por `id_serial`.
- Inserta en `lecturas_gps`.
- Evalúa zonas: usa `ST_DWithin` (PostGIS) o la fórmula Haversine con `LEAST/GREATEST` en `ACOS` para calcular distancia al centro de cada zona activa del paciente.
- Si distancia > `radio_metros` → genera `alertas` con estatus `'Activa'` y vincula en `alerta_evento_origen`.

### Configuración pendiente
1. Insertar SIM con datos en el dispositivo.
2. Configurar servidor destino (IP/dominio + puerto) y formato de reporte (HTTP POST, intervalo de reporte).
3. Registrar el dispositivo en la tabla `dispositivos` con tipo `GPS` y su número de serie.
4. Asignarlo al paciente vía `asignacion_kit` desde el historial del paciente en la app.

---

## 2. FeasyBeacon FSC-BP104D

### Descripción técnica
- Beacon BLE (Bluetooth 5.1), resistente al agua.
- Emite paquetes de advertisement BLE a intervalos configurables.
- Identifícase por: UUID, Major, Minor (estándar iBeacon) o por dirección MAC (Eddystone).
- No tiene conexión a internet directa — necesita **gateways BLE** en cada zona/cuarto que escuchen y reporten las detecciones.

### Rol en el sistema
Complementa al GPS para detección de presencia en interiores donde el GPS pierde precisión (habitaciones, pasillos). Los gateways dentro de cada zona detectan el beacon del paciente y reportan si está presente o ausente en esa zona.

### Arquitectura de gateways
```
Beacon (en paciente)
    ↓  BLE advertisement
Gateway BLE (Raspberry Pi / dispositivo dedicado en cada zona)
    ↓  HTTP POST
/api/beacon/deteccion
    ↓
  detecciones_beacon (id_dispositivo, id_gateway, rssi, fecha_hora)
```

Los gateways se registran en la tabla `gateways` y se vinculan a zonas via `zona_beacons`.

### Endpoint a implementar
```
POST /api/beacon/deteccion
Body: { "mac_beacon": "...", "id_gateway": 1,
        "rssi": -72, "fecha_hora": "..." }
```

- Busca `id_dispositivo` por `id_serial` (MAC del beacon).
- Inserta en `detecciones_beacon`.
- RSSI muy bajo (ej. < -90 dBm) podría indicar que el paciente está alejándose de la zona.

### Configuración pendiente
1. Configurar UUID/Major/Minor (o MAC fija) en la app de FeasyBeacon.
2. Ajustar intervalo de advertisement (recomendado: 500 ms para balance batería/respuesta).
3. Instalar gateways BLE en cada sede (un dispositivo por zona o corredor).
4. Registrar el beacon en `dispositivos` con tipo `BEACON` y asignarlo al paciente via `asignacion_kit`.

---

## 3. NFC Tag NTAG213 (Blue Fob)

### Descripción técnica
- Tag NFC pasivo (sin batería), activa al acercar un lector.
- Chip NTAG213: 144 bytes de memoria de usuario, 13.56 MHz, compatible ISO 14443A.
- Leído por cualquier smartphone con NFC o lector NFC dedicado.
- Se puede escribir con cualquier app de escritura NFC (ej. NFC Tools).

### Rol en el sistema
Confirmación de administración de medicamentos. Cada tag se asocia a una receta (`receta_nfc`). Cuando un cuidador o enfermero administra el medicamento, acerca su teléfono al tag y la lectura queda registrada en `lecturas_nfc`, lo que alimenta el indicador de adherencia terapéutica.

### Contenido a grabar en el tag
Se recomienda grabar un registro NDEF tipo URI apuntando al endpoint de registro:
```
https://<servidor>/api/nfc/lectura?id_receta=<id>&tipo=Administración
```
O bien un registro de texto plano con `id_receta:<id>` que la app móvil interprete.

### Flujo de datos
```
Cuidador acerca teléfono al NFC fob
    ↓  NDEF record leído
App móvil / shortcut de teléfono
    ↓  HTTP POST
/api/nfc/lectura
    ↓
  lecturas_nfc (id_dispositivo, id_receta, fecha_hora, tipo_lectura, resultado)
    ↓
  Actualiza adherencia terapéutica del paciente
```

Mientras no haya app móvil, las lecturas se registran **manualmente** desde la vista de detalle de la receta en la web (`/recetas/<id>`).

### Endpoint a implementar
```
POST /api/nfc/lectura
Body: { "id_serial_nfc": "...", "id_receta": 1,
        "tipo_lectura": "Administración", "resultado": "Exitosa" }
```

### Configuración pendiente
1. Escribir en cada tag el ID de receta correspondiente usando NFC Tools u otra app.
2. Registrar el tag en `dispositivos` con tipo `NFC` y su ID de serial.
3. Crear la `receta_nfc` que vincula el tag a la receta del paciente desde `/recetas/<id>/editar`.

---

## Resumen de tablas afectadas

| Dispositivo | Tabla principal de lecturas | Tabla de alerta | Tabla de asignación |
|-------------|----------------------------|-----------------|---------------------|
| GPS PG12 | `lecturas_gps` | `alertas` + `alerta_evento_origen` | `asignacion_kit` |
| Beacon FSC-BP104D | `detecciones_beacon` | — (presencia, no alerta directa) | `asignacion_kit` |
| NFC NTAG213 | `lecturas_nfc` | — (adherencia, no alerta directa) | `receta_nfc` |

---

## Endpoints API a implementar (resumen)

Ninguno existe todavía. Cuando se configuren los dispositivos, se agregarán estas rutas a `app.py`:

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/api/gps/lectura` | POST | Recibe lectura GPS, inserta en `lecturas_gps`, evalúa zonas, genera alertas |
| `/api/beacon/deteccion` | POST | Recibe detección BLE de gateway, inserta en `detecciones_beacon` |
| `/api/nfc/lectura` | POST | Recibe escaneo NFC, inserta en `lecturas_nfc` |
| `/api/gps/sos` | POST | Botón SOS del GPS → alerta tipo `'Botón SOS'` inmediata |

Todos requieren autenticación mínima por API key (header `X-API-Key`) para evitar inserciones no autorizadas.

---

## Orden de implementación recomendada

1. **NFC primero** — el más sencillo, no requiere infraestructura de red adicional. Grabar tags, probar POST manual, validar en `lecturas_nfc`.
2. **GPS segundo** — configurar APN + servidor destino en el PG12, implementar `/api/gps/lectura`, probar generación de alertas con coordenadas fuera de zona.
3. **Beacon al final** — requiere instalar y configurar gateways BLE en la sede física, más complejo de infraestructura.
