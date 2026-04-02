# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AlzMonitor** is an academic Flask web app for managing Alzheimer's patients across multiple clinical facilities. Built for an Advanced Databases (BDA) university course to demonstrate multi-tenant clinical data modeling.

## Running the App

```bash
pip install -r requirements.txt
python app.py
# Runs at http://localhost:5002
```

Apply the corrected schema to the database:
```bash
psql -U palermingoat -d alzheimer -f ProyectoFinalDDL.sql
```

> **Known DDL ordering issue**: `lecturas_nfc` is defined before `recetas` in the file, so its FK constraint fails on a fresh run. After running the DDL, manually create it:
> ```sql
> CREATE TABLE IF NOT EXISTS lecturas_nfc (
>     id_lectura_nfc INTEGER PRIMARY KEY,
>     id_dispositivo INTEGER NOT NULL,
>     id_receta      INTEGER NOT NULL,
>     fecha_hora     TIMESTAMP NOT NULL,
>     tipo_lectura   VARCHAR(30) NOT NULL DEFAULT 'Administración',
>     resultado      VARCHAR(20) NOT NULL DEFAULT 'Exitosa',
>     CONSTRAINT fk_lnfc_dispositivo FOREIGN KEY (id_dispositivo) REFERENCES dispositivos(id_dispositivo) ON DELETE RESTRICT,
>     CONSTRAINT fk_lnfc_receta      FOREIGN KEY (id_receta)      REFERENCES recetas(id_receta)            ON DELETE RESTRICT,
>     CONSTRAINT uq_lnfc_instante    UNIQUE (id_dispositivo, id_receta, fecha_hora)
> );
> ```

Test credentials (defined in `.env`):
- Admin: `admin` / `admin123`
- Medical staff: `medico` / `medico123`

## Architecture

### Data Layer
**Primary data source is PostgreSQL** (`alzheimer` DB, user `palermingoat`, empty password, Unix socket via `DB_HOST=/tmp`). `db.py` provides four helpers: `query()`, `one()`, `scalar()`, `execute()`, `execute_many()` — all use `RealDictCursor` so results are dict-compatible.

`data.py` is still imported for a small set of in-memory structures not yet migrated: `TURNOS_HOY`, `TAREAS_HOY`, `MEDICAMENTOS`, `BITACORAS`, `INCIDENTES`, `PERFIL_CLINICO`, `BITACORA_COMEDOR`, `ALERTAS_MEDICAS`, `ASIGNACIONES_CUIDADORES`.

Multi-facility filtering is done at the route level using `id_sede` (maps to `id_sucursal` in templates).

### Route Organization
All routes are flat in `app.py` — no blueprints. Two auth decorators defined at module level:
- `admin_requerido` — checks `session["admin"]`
- `medico_requerido` — checks `session["medico"]`

Two roles: `admin` (full CRUD, all sedes) and `medico` (clinic-scoped read view under `/clinica`).

### Templates
`templates/base.html` is the master layout with a sticky 248px sidebar. All authenticated pages extend it. Patient and caregiver templates live in `templates/pacientes/` and `templates/cuidadores/` subdirectories.

SQL aliases map real DB column names to the names templates expect (e.g. `nombre AS nombre_paciente`, `apellido_p AS apellido_p_pac`). Date columns used with string slicing in templates are returned via `TO_CHAR(col, 'YYYY-MM-DD')`.

### Frontend
Vanilla JS only (`static/js/main.js`, 25 lines) — handles auto-dismiss alerts and deletion confirmations. No build step, no bundler.

## Schema — ProyectoFinalDDL.sql

The corrected DDL (`ProyectoFinalDDL.sql`) incorporates three changes from the professor's feedback over the original `avance de proyecto.sql`:

1. **Removed `paciente_recetas`** — `recetas.id_paciente` is the single source of truth.
2. **Catalog tables replace CHECK literals** — `cat_tipo_dispositivo` (`GPS`, `BEACON`, `NFC`), `cat_estado_dispositivo` (`Activo`, `Inactivo`, `Mantenimiento`), `cat_tipo_alerta` (`Salida de Zona`, `Batería Baja`, `Botón SOS`, `Caída`), `cat_estado_alerta` (`Activa`, `Atendida`), `cat_estado_suministro`, `cat_estado_entrega`, `cat_turno_comedor`.
3. **`alerta_evento_origen`** — links each alert to the IoT event that triggered it. **`lecturas_nfc`** separated from `detecciones_beacon` (NFC = medication adherence, Beacon = location/presence).

Key schema facts:
- `pacientes.id_estado` is an integer FK → `estados_paciente` (1=Activo, 2=En Hospital, 3=Baja). Soft-delete sets `id_estado = 3`.
- Battery is in `lecturas_gps.nivel_bateria`, not on `dispositivos`.
- `empleados` has no `id_sede` — linked via `sede_empleados` bridge table.
- `asignacion_kit` links one patient to one GPS device + one Beacon device.
- `contactos_emergencia` linked via `paciente_contactos` bridge table.

## Key Behaviors

- **Dispositivo registration**: `id_dispositivo` must be supplied manually (no SERIAL). `estado` defaults to `'Activo'`. Tipo must be exactly `GPS`, `BEACON`, or `NFC`.
- **Cuidador deletion**: deletes from `cuidadores` then `empleados` in a single transaction (FK dependency).
- **Paciente deletion**: soft-delete only — `UPDATE pacientes SET id_estado = 3`.
- **Alerta status values**: `'Activa'` and `'Atendida'` (not `'Resuelta'`).

## What the App Can and Cannot Do

### Pacientes
- **Can**: List active patients (id_estado != 3) with sede; create new patient (manual ID required); edit name, DOB, estado; soft-delete (sets id_estado = 3).
- **Can**: View patient historial — enfermedades, assigned cuidadores, contactos de emergencia, assigned IoT kit (GPS + Beacon serials), sede ingreso, visit history, external deliveries.
- **Cannot**: Assign a patient to a sede from the form (no UI for INSERT into `sede_pacientes`); link diseases (`tiene_enfermedad`) from the UI; add emergency contacts (`paciente_contactos`) from the UI; assign an IoT kit (`asignacion_kit`) from the UI.

### Cuidadores
- **Can**: List cuidadores with their sede; create (inserts into both `empleados` and `cuidadores` in one transaction); edit name/phone/CURP; hard-delete (removes from `cuidadores` then `empleados`).
- **Cannot**: Assign a cuidador to a patient (`asignacion_cuidador`) from the UI; assign a cuidador to a sede (`sede_empleados`) from the UI.

### Alertas
- **Can**: List all alerts with patient name and sede; create new alert (manual ID, pick patient + type + datetime); mark alert as `Atendida`; hard-delete alert.
- **Cannot**: Link an alert to its triggering IoT event (`alerta_evento_origen`) from the UI.

### Dispositivos
- **Can**: List devices with last GPS battery level and assigned patient; create new device (manual ID, serial, tipo GPS/BEACON/NFC, modelo — estado defaults to `Activo`); edit serial/tipo/modelo/estado; hard-delete.
- **Cannot**: Assign a device to a patient kit (`asignacion_kit`) from the UI; view GPS location history or beacon detections from the UI.

### Zonas Seguras
- **Can**: List zonas with sede, coordinates, and radius; create new zona (nombre, latitud, longitud, radio); edit; hard-delete.
- **Cannot**: Link a zona to a sede (`sede_zonas`) from the UI after creation; manage gateways within a zona from the UI.

### Farmacia
- **Can**: View full medicine inventory per sede with stock vs minimum; highlight critical stock (below minimum); adjust stock inline (UPDATE `inventario_medicinas`); create a new supply order (`suministros`) linked to a pharmacy provider and sede.
- **Cannot**: Add medicines to a supply order (`suministro_medicinas` detail lines) from the UI; add/edit/delete `farmacias_proveedoras` from the UI; add/edit `medicamentos` catalog from the UI; manage `entregas_externas` from the farmacia module.

### Visitas
- **Can**: List today's visits and last 50 historical visits; list recent external deliveries; register a new visit (links existing `visitantes` to a patient + sede with date/time).
- **Cannot**: Create a new `visitante` (visitor) from the UI — must exist in DB already; register visit departure time (hora_salida) from the UI; register an `entrega_externa` from the UI.

### Portal Clínico (rol: médico)
- **Can**: View sede list with active patient count; view per-sede dashboard with patient list, their enfermedades, cuidador assignments, IoT kit, and active alerts.
- **Cannot**: Edit or create anything — read-only role.

### Sedes
- **No admin CRUD UI** — the 3 sedes seeded by the DDL are fixed. There is no route to create, edit, or delete sedes.

### Tables with No UI at All
The following DB tables exist in the schema but have zero routes pointing to them:
`lecturas_gps`, `detecciones_beacon`, `lecturas_nfc`, `recetas`, `receta_medicamentos`, `receta_nfc`, `tiene_enfermedad`, `enfermedades`, `contactos_emergencia`, `paciente_contactos`, `asignacion_kit`, `asignacion_cuidador`, `sede_pacientes`, `sede_empleados`, `sede_zonas`, `zona_beacons`, `gateways`, `bitacora_comedor`, `cocineros`, `alerta_evento_origen`, `entregas_externas`, `visitantes`.

---

## Design System

CSS variables in `static/css/main.css`:
- Primary teal: `#0E7490` / Dark bg: `#082F3E`
- Status colors: emerald (success), amber (warning), rose (danger), sky (info)

UI is entirely in Spanish.
