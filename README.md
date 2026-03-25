# AlzMonitor — Sistema de Monitoreo para Pacientes con Alzheimer

Proyecto universitario de Bases de Datos (BDA). Aplicación web en Flask para la gestión y monitoreo de pacientes con Alzheimer en múltiples sedes clínicas.

---

## Descripción general

AlzMonitor permite administrar pacientes, cuidadores, dispositivos IoT (GPS, Beacon, NFC), alertas médicas, prescripciones, contactos de emergencia, visitas, farmacia y bitácora del comedor. Cuenta con dos roles de usuario: **Administrador** y **Médico/Clínica**.

> **Nota:** Este proyecto es una demo académica. No se utiliza una base de datos real — toda la información está definida como datos en memoria dentro de `data.py`.

---

## Requisitos

- Python 3.10 o superior
- pip

---

## Instalación y ejecución

```bash
# 1. Crear y activar un entorno virtual (recomendado)
python -m venv venv
source venv/bin/activate        # macOS / Linux
venv\Scripts\activate           # Windows

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Ejecutar el servidor de desarrollo (puerto 5002)
python app.py
```

Abre tu navegador en `http://localhost:5002`.

---

## Credenciales de acceso

| Rol | Usuario | Contraseña | Portal |
|---|---|---|---|
| Administrador | `admin` | `admin123` | `/dashboard` — gestión completa |
| Médico / Clínica | `medico` | `medico123` | `/clinica` — vista clínica por sede |

---

## Estructura del proyecto

```
app.py                  — Fábrica de la app Flask; registra las rutas de cada módulo
data.py                 — Datos de ejemplo en memoria (reemplaza la BD)
config.py               — Configuración (sin uso activo; referencia futura)
db.py                   — Conexión a BD (sin uso activo; referencia futura)
requirements.txt        — Dependencias Python

routes/
  public.py             — Login y logout (sin decorador de autenticación)
  admin.py              — Rutas del panel administrador
  clinica.py            — Rutas del portal médico/clínica

static/
  css/main.css          — Estilos globales (paleta teal)
  js/main.js            — Scripts generales
  img/                  — Recursos de imagen

templates/
  base.html             — Layout base con barra lateral
  login.html            — Pantalla de inicio de sesión
  dashboard.html        — Panel principal (admin)
  alertas.html          — Módulo de alertas
  dispositivos.html     — Gestión de dispositivos IoT
  zonas.html            — Zonas seguras
  farmacia.html         — Inventario de medicamentos y pedidos
  visitas.html          — Registro de visitas y entregas externas
  clinica_sedes.html    — Selector de sede (portal médico)
  clinica.html          — Dashboard clínico por sede
  pacientes/
    list.html           — Listado de pacientes
    form.html           — Alta/edición de paciente
    historial.html      — Expediente completo del paciente
  cuidadores/
    list.html           — Listado de cuidadores
    form.html           — Alta/edición de cuidador
```

---

## Arquitectura de rutas

Las rutas se registran mediante `init_routes(app)` en cada módulo dentro de `routes/`. Las rutas de administrador usan un decorador `login_requerido` que verifica `session["admin"]`.

### Rutas principales

| Ruta | Rol | Descripción |
|---|---|---|
| `/` | Público | Redirige al login |
| `/login` | Público | Formulario de autenticación |
| `/logout` | Autenticado | Cierra la sesión |
| `/dashboard` | Admin | Panel principal con estadísticas globales |
| `/pacientes` | Admin | Listado de pacientes activos |
| `/pacientes/historial/<id>` | Admin | Expediente completo del paciente |
| `/cuidadores` | Admin | Listado de cuidadores |
| `/alertas` | Admin | Centro de alertas médicas |
| `/dispositivos` | Admin | Gestión de dispositivos IoT |
| `/zonas` | Admin | Zonas seguras configuradas |
| `/farmacia` | Admin | Inventario y pedidos de medicamentos |
| `/visitas` | Admin | Registro de visitas y entregas externas |
| `/clinica` | Médico | Selector de sede clínica |
| `/clinica/<id_sucursal>` | Médico | Dashboard clínico de la sede seleccionada |

---

## Arquitectura multi-sede

Cada entidad (pacientes, cuidadores, dispositivos, zonas, alertas) lleva `id_sucursal` + `nombre_sucursal`. El dashboard calcula estadísticas por sede de forma dinámica. Actualmente hay dos sedes: **Sede Norte** y **Sede Sur**.

---

## Esquema de datos principal (`data.py`)

| Variable | Descripción |
|---|---|
| `PACIENTES` | Lista de pacientes con estado y sede asignada |
| `CUIDADORES` | Personal de cuidado por sede |
| `ENFERMEDADES` | Diagnósticos por paciente (dict keyed by `id_paciente`) |
| `ALERTAS_RECIENTES` | Alertas médicas activas e históricas |
| `DISPOSITIVOS` | Sensores GPS, Beacon y NFC |
| `ZONAS` | Zonas seguras configuradas por sede |
| `CONTACTOS_EMERGENCIA` | Contactos por paciente |
| `ASIGNACION_KIT` | Kit de dispositivos asignado por paciente |
| `SEDE_PACIENTES` | Registro de ingreso por paciente |
| `VISITAS` / `VISITANTES` | Registro de visitas y datos de visitantes |
| `ENTREGAS_EXTERNAS` | Paquetes enviados por familiares |
| `INVENTARIO_MEDICINAS` | Stock de medicamentos por sede |
| `SUMINISTROS` | Órdenes de compra a farmacias |
| `FARMACIAS_PROVEEDORAS` | Directorio de proveedores |
| `BITACORA_COMEDOR` | Registro diario de alimentación por sede |
