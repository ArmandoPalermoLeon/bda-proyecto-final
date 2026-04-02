# AlzMonitor — Sistema de Monitoreo para Pacientes con Alzheimer

Proyecto universitario de Bases de Datos Avanzadas (BDA). Aplicacion web en Flask para la gestion y monitoreo de pacientes con Alzheimer en multiples sedes clinicas, respaldada por PostgreSQL.

---

## Descripcion general

AlzMonitor permite administrar pacientes, cuidadores, dispositivos IoT (GPS, Beacon, NFC), alertas medicas, prescripciones, contactos de emergencia, visitas, farmacia e inventario de medicamentos. Cuenta con dos roles de usuario: **Administrador** y **Medico/Clinica**.

---

## Requisitos

- Python 3.10 o superior
- PostgreSQL 14 o superior
- pip

---

## Instalacion y ejecucion

```bash
# 1. Instalar dependencias
pip install -r requirements.txt

# 2. Aplicar el esquema a la base de datos
psql -U palermingoat -d alzheimer -f ProyectoFinalDDL.sql

# 3. Ejecutar el servidor de desarrollo (puerto 5002)
python app.py
```

Abre tu navegador en `http://localhost:5002`.

### Nota: problema de orden en el DDL

`lecturas_nfc` esta definida antes que `recetas` en el archivo DDL, por lo que su FK falla en una ejecucion limpia. Despues de correr el DDL, crear la tabla manualmente:

```sql
CREATE TABLE IF NOT EXISTS lecturas_nfc (
    id_lectura_nfc INTEGER PRIMARY KEY,
    id_dispositivo INTEGER NOT NULL,
    id_receta      INTEGER NOT NULL,
    fecha_hora     TIMESTAMP NOT NULL,
    tipo_lectura   VARCHAR(30) NOT NULL DEFAULT 'Administracion',
    resultado      VARCHAR(20) NOT NULL DEFAULT 'Exitosa',
    CONSTRAINT fk_lnfc_dispositivo FOREIGN KEY (id_dispositivo) REFERENCES dispositivos(id_dispositivo) ON DELETE RESTRICT,
    CONSTRAINT fk_lnfc_receta      FOREIGN KEY (id_receta)      REFERENCES recetas(id_receta)            ON DELETE RESTRICT,
    CONSTRAINT uq_lnfc_instante    UNIQUE (id_dispositivo, id_receta, fecha_hora)
);
```

---

## Credenciales de acceso

| Rol | Usuario | Contrasena | Portal |
|---|---|---|---|
| Administrador | `admin` | `admin123` | `/dashboard` — gestion completa |
| Medico / Clinica | `medico` | `medico123` | `/clinica` — vista clinica por sede |

Las credenciales se configuran en el archivo `.env`.

---

## Base de datos

- Motor: PostgreSQL
- Base de datos: `alzheimer`
- Usuario: `palermingoat` (sin contrasena, conexion por socket Unix via `DB_HOST=/tmp`)
- Esquema: `public` — 43 tablas

### Archivo de esquema: `ProyectoFinalDDL.sql`

Incorpora tres cambios respecto al avance anterior segun retroalimentacion del profesor:

1. Se elimino `paciente_recetas` — `recetas.id_paciente` es la unica fuente de verdad.
2. Tablas de catalogo reemplazan CHECK con literales: `cat_tipo_dispositivo`, `cat_estado_dispositivo`, `cat_tipo_alerta`, `cat_estado_alerta`, `cat_estado_suministro`, `cat_estado_entrega`, `cat_turno_comedor`.
3. `alerta_evento_origen` vincula cada alerta al evento IoT que la origino. `lecturas_nfc` separada de `detecciones_beacon` (NFC = adherencia terapeutica, Beacon = presencia/ubicacion).

### Capa de acceso a datos: `db.py`

Cuatro funciones utilitarias, todas usan `RealDictCursor` para devolver resultados como diccionarios:

| Funcion | Uso |
|---|---|
| `query(sql, params)` | SELECT que devuelve lista de filas |
| `one(sql, params)` | SELECT que devuelve solo la primera fila |
| `scalar(sql, params)` | SELECT que devuelve el primer campo de la primera fila |
| `execute(sql, params)` | INSERT / UPDATE / DELETE en su propia transaccion |
| `execute_many(statements)` | Lista de sentencias en una sola transaccion |

---

## Lo que la aplicacion puede y no puede hacer

### Pacientes
- Puede: listar activos, crear, editar datos personales y estado, baja logica (id_estado = 3).
- Puede: ver historial completo — enfermedades, cuidadores, contactos de emergencia, kit IoT, sede, visitas, entregas.
- No puede: asignar a sede desde el formulario, vincular enfermedades, agregar contactos de emergencia, asignar kit IoT.

### Cuidadores
- Puede: listar, crear (empleados + cuidadores en una transaccion), editar, eliminar (hard delete).
- No puede: asignar cuidador a paciente ni a sede desde la UI.

### Alertas
- Puede: listar, crear, marcar como Atendida, eliminar.
- No puede: vincular alerta a evento IoT origen (`alerta_evento_origen`).

### Dispositivos
- Puede: listar (con bateria desde ultima lectura GPS y paciente asignado), crear, editar, eliminar.
- No puede: asignar kit a paciente (`asignacion_kit`), ver historial de lecturas GPS ni detecciones beacon.

### Zonas seguras
- Puede: listar, crear, editar, eliminar.
- No puede: vincular zona a sede (`sede_zonas`) despues de crearla, gestionar gateways.

### Farmacia
- Puede: ver inventario por sede con criticos resaltados, ajustar stock, crear orden de suministro.
- No puede: agregar lineas de medicamentos a una orden (`suministro_medicinas`), gestionar farmacias proveedoras ni catalogo de medicamentos desde la UI.

### Visitas
- Puede: listar visitas de hoy e historico, listar entregas externas, registrar nueva visita.
- No puede: crear nuevo visitante, registrar hora de salida, registrar entrega externa.

### Portal Clinico (rol medico)
- Solo lectura: lista de sedes, pacientes por sede, enfermedades, cuidadores, kit IoT, alertas activas.

### Sin UI
Las siguientes tablas existen en la base de datos pero no tienen ninguna ruta en la aplicacion:
`lecturas_gps`, `detecciones_beacon`, `lecturas_nfc`, `recetas`, `receta_medicamentos`, `receta_nfc`, `tiene_enfermedad`, `enfermedades`, `contactos_emergencia`, `paciente_contactos`, `asignacion_kit`, `asignacion_cuidador`, `sede_pacientes`, `sede_empleados`, `sede_zonas`, `zona_beacons`, `gateways`, `bitacora_comedor`, `cocineros`, `alerta_evento_origen`, `entregas_externas`, `visitantes`.

---

## Stored procedures: `FinalStoredProcedures.sql`

Contiene el diseno de 22 stored procedures para todas las operaciones importantes del sistema. Aun no implementados (contienen bloques TODO con la logica esperada).

| Bloque | Procedures |
|---|---|
| Pacientes | registrar, editar, dar_baja, transferir_sede, agregar_enfermedad, agregar_contacto |
| Cuidadores | registrar, editar, eliminar, asignar_paciente, asignar_sede |
| Alertas | registrar, atender, eliminar, vincular_origen |
| Dispositivos | registrar, editar, eliminar, asignar_kit |
| Zonas | registrar, editar, eliminar |
| Farmacia | ajustar_stock, registrar_suministro, recibir_suministro |
| Visitas y entregas | registrar_visitante, registrar_entrada, registrar_salida, registrar_entrega |
| Recetas | registrar (con lineas), asignar_nfc |
| Lecturas IoT | lectura_gps, deteccion_beacon, lectura_nfc |

---

## Estructura del proyecto

```
app.py                        — Todas las rutas (sin blueprints)
db.py                         — Helpers de conexion a PostgreSQL
data.py                       — Estructuras en memoria aun no migradas a BD
requirements.txt              — Dependencias Python

ProyectoFinalDDL.sql          — Esquema DDL final con datos de prueba (43 tablas)
FinalStoredProcedures.sql     — Diseno de stored procedures (pendientes de implementar)
avance de proyecto.sql        — DDL anterior (referencia historica)
finalqueries.sql              — Consultas de referencia

static/
  css/main.css                — Estilos globales (paleta teal: #0E7490)
  js/main.js                  — Auto-dismiss de alertas y confirmacion de borrado

templates/
  base.html                   — Layout base con barra lateral (248px)
  login.html
  dashboard.html
  alertas.html / alertas_form.html
  dispositivos.html / dispositivos_form.html
  zonas.html / zonas_form.html
  farmacia.html / farmacia_suministro_form.html
  visitas.html / visitas_form.html
  clinica_sedes.html
  pacientes/
    list.html / form.html / historial.html
  cuidadores/
    list.html / form.html
```

---

## Rutas de la aplicacion

| Ruta | Rol | Descripcion |
|---|---|---|
| `/` | Publico | Redirige al login |
| `/login` | Publico | Formulario de autenticacion |
| `/logout` | Autenticado | Cierra la sesion |
| `/dashboard` | Admin | Panel principal con estadisticas globales |
| `/pacientes` | Admin | Listado de pacientes activos |
| `/pacientes/nuevo` | Admin | Formulario de alta de paciente |
| `/pacientes/editar/<id>` | Admin | Edicion de paciente |
| `/pacientes/eliminar/<id>` | Admin | Baja logica de paciente |
| `/pacientes/historial/<id>` | Admin | Expediente completo del paciente |
| `/cuidadores` | Admin | Listado de cuidadores |
| `/cuidadores/nuevo` | Admin | Alta de cuidador |
| `/cuidadores/editar/<id>` | Admin | Edicion de cuidador |
| `/cuidadores/eliminar/<id>` | Admin | Eliminacion de cuidador |
| `/alertas` | Admin | Centro de alertas medicas |
| `/alertas/nueva` | Admin | Registrar nueva alerta |
| `/alertas/resolver/<id>` | Admin | Marcar alerta como atendida |
| `/alertas/eliminar/<id>` | Admin | Eliminar alerta |
| `/dispositivos` | Admin | Gestion de dispositivos IoT |
| `/dispositivos/nuevo` | Admin | Registrar dispositivo |
| `/dispositivos/editar/<id>` | Admin | Editar dispositivo |
| `/dispositivos/eliminar/<id>` | Admin | Eliminar dispositivo |
| `/zonas` | Admin | Zonas seguras |
| `/zonas/nueva` | Admin | Crear zona |
| `/zonas/editar/<id>` | Admin | Editar zona |
| `/zonas/eliminar/<id>` | Admin | Eliminar zona |
| `/farmacia` | Admin | Inventario y ordenes de suministro |
| `/farmacia/inventario/ajustar` | Admin | Ajustar stock de un medicamento |
| `/farmacia/suministro/nuevo` | Admin | Nueva orden de suministro |
| `/visitas` | Admin | Registro de visitas y entregas |
| `/visitas/nueva` | Admin | Registrar nueva visita |
| `/clinica` | Medico | Selector de sede clinica |
| `/clinica/<id_sede>` | Medico | Dashboard clinico de la sede |
