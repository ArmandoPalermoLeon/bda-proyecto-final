# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AlzMonitor** — a Flask web app for monitoring Alzheimer's patients. Tracks patients, caregivers, medical histories, IoT devices (GPS/Beacons/NFC), alerts, prescriptions, emergency contacts, and locations (branches/care centers organized by zone). Two user roles: Admin and Doctor/Clinic.

This is a university database project ("proyecto-bda"). **No real database is used** — all data is hardcoded in `data.py` as Python lists and dicts for academic/demo purposes.

## Running the Application

```bash
# Install dependencies (use a virtual environment)
pip install -r requirements.txt

# Run the development server (port 5002)
python app.py
```

Default dev credentials (hardcoded in `public.py`):
- Admin: `admin` / `admin123`
- Doctor: `medico` / `medico123`

## Data Layer

All application data lives in **`data.py`** as module-level constants (lists/dicts). There is no database connection. Routes import `data` directly and read/mutate these structures in memory.

**Multi-sede architecture**: Every entity (patients, caregivers, devices, zones, alerts) carries `id_sucursal` + `nombre_sucursal`. The dashboard computes per-clinic stats dynamically. Adding a third clinic requires only a new entry in `SUCURSALES` and tagging records with the new `id_sucursal`.

Key data structures:
- `PACIENTES`, `ESTADOS_PACIENTE`
- `CUIDADORES`, `ASIGNACIONES_CUIDADORES`
- `ENFERMEDADES` — keyed by `id_paciente`
- `ALERTAS_RECIENTES`, `DASHBOARD_STATS`
- `DISPOSITIVOS` — GPS, Beacon, NFC sensors
- `PRESCRIPCIONES` — medication prescriptions per patient
- `CONTACTOS_EMERGENCIA` — emergency contacts per patient
- `ZONAS`, `SUCURSALES` — zones and branch locations (care centers)

`db.py` and `config.py` remain in the repo but are **not used**.

## Architecture

```
app.py              — Flask app factory; calls init_routes() from each blueprint module
data.py             — All hardcoded placeholder data (replaces DB)
config.py           — Unused; kept for reference
db.py               — Unused; kept for reference
routes/
  __init__.py
  public.py         — Login/logout routes (no auth decorator)
  admin.py          — All admin routes (dashboard, patients, caregivers, devices, alerts, zones)
  clinica.py        — Doctor/clinic dashboard route
static/
  css/
  js/
  img/
templates/
  base.html         — Base layout
  login.html
  public.html
  dashboard.html
  alertas.html
  dispositivos.html
  zonas.html
  clinica.html
  pacientes/
    list.html
    form.html
    historial.html
  cuidadores/
    list.html
    form.html
```

## Route Pattern

Routes are registered via `init_routes(app)` in each module under `routes/`. Admin routes use a `login_requerido` decorator that checks `session["admin"]`.

```python
# routes/admin.py
def init_routes(app):
    def login_requerido(f): ...

    @app.route("/pacientes")
    @login_requerido
    def pacientes_lista():
        return render_template("pacientes/list.html", pacientes=data.PACIENTES)
```

All data reads/writes go directly against the in-memory structures in `data.py`. No SQL, no ORM.
