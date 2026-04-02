-- =============================================================================
-- FinalStoredProcedures.sql
-- AlzMonitor — Stored Procedures
-- Base de datos: alzheimer
--
-- Convenciones:
--   - Todos los procedures usan LANGUAGE plpgsql.
--   - Nombres: sp_<modulo>_<accion>
--   - IDs se pasan como parámetro (no hay SERIAL en las tablas clave).
--   - Errores se lanzan con RAISE EXCEPTION para que Flask los capture.
--   - Las operaciones multi-tabla usan una sola transacción implícita del procedure.
-- =============================================================================


-- =============================================================================
-- BLOQUE 1: PACIENTES
-- =============================================================================

-- Registra un nuevo paciente y lo admite en una sede al mismo tiempo.
-- Inserta en: pacientes, sede_pacientes
CREATE OR REPLACE PROCEDURE sp_paciente_registrar(
    p_id_paciente      INTEGER,
    p_nombre           VARCHAR,
    p_apellido_p       VARCHAR,
    p_apellido_m       VARCHAR,
    p_fecha_nacimiento DATE,
    p_id_estado        INTEGER,    -- 1=Activo por defecto
    p_id_sede          INTEGER,    -- sede donde ingresa
    p_fecha_ingreso    DATE,
    p_hora_ingreso     TIME,
    p_id_sede_paciente INTEGER     -- PK de sede_pacientes (manual)
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Validar que p_id_paciente no exista ya en pacientes
    -- 2. Validar que p_id_sede exista en sedes
    -- 3. INSERT INTO pacientes (...)
    -- 4. INSERT INTO sede_pacientes (...)
END;
$$;


-- Actualiza los datos personales de un paciente existente.
-- Modifica: pacientes
CREATE OR REPLACE PROCEDURE sp_paciente_editar(
    p_id_paciente      INTEGER,
    p_nombre           VARCHAR,
    p_apellido_p       VARCHAR,
    p_apellido_m       VARCHAR,
    p_fecha_nacimiento DATE,
    p_id_estado        INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el paciente existe y no está dado de baja (id_estado != 3)
    -- 2. UPDATE pacientes SET nombre=..., apellido_p=..., ... WHERE id_paciente=...
END;
$$;


-- Baja lógica de un paciente (no elimina el registro).
-- Modifica: pacientes (id_estado = 3), sede_pacientes (fecha_salida)
CREATE OR REPLACE PROCEDURE sp_paciente_dar_baja(
    p_id_paciente  INTEGER,
    p_fecha_salida DATE,
    p_hora_salida  TIME
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el paciente existe y está activo
    -- 2. UPDATE pacientes SET id_estado = 3 WHERE id_paciente = ...
    -- 3. UPDATE sede_pacientes SET fecha_salida=..., hora_salida=...
    --    WHERE id_paciente=... AND fecha_salida IS NULL
    -- 4. UPDATE asignacion_cuidador SET fecha_fin=... WHERE id_paciente=... AND fecha_fin IS NULL
END;
$$;


-- Asigna o transfiere un paciente a otra sede.
-- Cierra el registro activo en sede_pacientes y abre uno nuevo.
CREATE OR REPLACE PROCEDURE sp_paciente_transferir_sede(
    p_id_paciente        INTEGER,
    p_id_sede_nueva      INTEGER,
    p_fecha_salida       DATE,
    p_hora_salida        TIME,
    p_fecha_ingreso      DATE,
    p_hora_ingreso       TIME,
    p_id_sede_paciente   INTEGER    -- nueva PK para sede_pacientes
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Cerrar registro activo: UPDATE sede_pacientes SET fecha_salida=..., hora_salida=...
    --    WHERE id_paciente=... AND fecha_salida IS NULL
    -- 2. Insertar nuevo ingreso: INSERT INTO sede_pacientes (...)
END;
$$;


-- Vincula una enfermedad diagnosticada a un paciente.
-- Inserta en: tiene_enfermedad
CREATE OR REPLACE PROCEDURE sp_paciente_agregar_enfermedad(
    p_id_paciente   INTEGER,
    p_id_enfermedad INTEGER,
    p_fecha_diag    DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el paciente existe y está activo
    -- 2. Verificar que la enfermedad existe en el catálogo enfermedades
    -- 3. INSERT INTO tiene_enfermedad (id_paciente, id_enfermedad, fecha_diag)
    --    ON CONFLICT DO NOTHING (par ya registrado)
END;
$$;


-- Registra un contacto de emergencia nuevo y lo vincula al paciente.
-- Inserta en: contactos_emergencia, paciente_contactos
CREATE OR REPLACE PROCEDURE sp_paciente_agregar_contacto(
    p_id_contacto   INTEGER,
    p_nombre        VARCHAR,
    p_apellido_p    VARCHAR,
    p_apellido_m    VARCHAR,
    p_telefono      VARCHAR,
    p_relacion      VARCHAR,
    p_fecha_nac     DATE,
    p_curp          VARCHAR,
    p_id_paciente   INTEGER,
    p_prioridad     INTEGER    -- debe ser único por paciente
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. INSERT INTO contactos_emergencia (...)
    -- 2. INSERT INTO paciente_contactos (id_paciente, id_contacto, prioridad)
    --    Verificar antes que la prioridad no esté ya usada para ese paciente
END;
$$;


-- =============================================================================
-- BLOQUE 2: CUIDADORES
-- =============================================================================

-- Registra un nuevo cuidador (empleado + cuidador en una transacción).
-- Inserta en: empleados, cuidadores
CREATE OR REPLACE PROCEDURE sp_cuidador_registrar(
    p_id_empleado         INTEGER,
    p_nombre              VARCHAR,
    p_apellido_p          VARCHAR,
    p_apellido_m          VARCHAR,
    p_curp                VARCHAR,
    p_telefono            VARCHAR,
    p_fecha_nac           DATE,
    p_certificacion       VARCHAR,   -- puede ser NULL
    p_especialidad        VARCHAR    -- puede ser NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que p_id_empleado no exista ya
    -- 2. Verificar unicidad de CURP_pasaporte
    -- 3. INSERT INTO empleados (...)
    -- 4. INSERT INTO cuidadores (id_empleado, certificacion_medica, especialidad)
END;
$$;


-- Actualiza los datos personales y profesionales de un cuidador.
-- Modifica: empleados, cuidadores
CREATE OR REPLACE PROCEDURE sp_cuidador_editar(
    p_id_empleado   INTEGER,
    p_nombre        VARCHAR,
    p_apellido_p    VARCHAR,
    p_apellido_m    VARCHAR,
    p_curp          VARCHAR,
    p_telefono      VARCHAR,
    p_certificacion VARCHAR,
    p_especialidad  VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el cuidador existe
    -- 2. UPDATE empleados SET nombre=..., ... WHERE id_empleado=...
    -- 3. UPDATE cuidadores SET certificacion_medica=..., especialidad=...
    --    WHERE id_empleado=...
END;
$$;


-- Elimina un cuidador físicamente (hard delete).
-- Requiere que no tenga asignaciones activas.
-- Elimina de: cuidadores, empleados (en ese orden por FK)
CREATE OR REPLACE PROCEDURE sp_cuidador_eliminar(
    p_id_empleado INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que no tiene asignaciones activas en asignacion_cuidador (fecha_fin IS NULL)
    --    Si las tiene, lanzar RAISE EXCEPTION
    -- 2. DELETE FROM cuidadores WHERE id_empleado=...
    -- 3. DELETE FROM empleados  WHERE id_empleado=...
END;
$$;


-- Asigna un cuidador a un paciente.
-- Cierra la asignación anterior del paciente si existe.
-- Inserta en: asignacion_cuidador
CREATE OR REPLACE PROCEDURE sp_cuidador_asignar_paciente(
    p_id_asig_cuidador INTEGER,
    p_id_cuidador      INTEGER,
    p_id_paciente      INTEGER,
    p_fecha_inicio     DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el cuidador y el paciente existen y están activos
    -- 2. Cerrar asignación activa previa del paciente (si la hay):
    --    UPDATE asignacion_cuidador SET fecha_fin=p_fecha_inicio - 1
    --    WHERE id_paciente=... AND fecha_fin IS NULL
    -- 3. INSERT INTO asignacion_cuidador (...)
END;
$$;


-- Asigna un cuidador a una sede (registro de ingreso laboral).
-- Inserta en: sede_empleados
CREATE OR REPLACE PROCEDURE sp_cuidador_asignar_sede(
    p_id_sede_empleado INTEGER,
    p_id_sede          INTEGER,
    p_id_empleado      INTEGER,
    p_fecha_ingreso    DATE,
    p_hora_ingreso     TIME
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el empleado y la sede existen
    -- 2. Cerrar registro activo previo si existe:
    --    UPDATE sede_empleados SET fecha_salida=..., hora_salida=...
    --    WHERE id_empleado=... AND fecha_salida IS NULL
    -- 3. INSERT INTO sede_empleados (...)
END;
$$;


-- =============================================================================
-- BLOQUE 3: ALERTAS
-- =============================================================================

-- Registra una nueva alerta clínica.
-- Inserta en: alertas
CREATE OR REPLACE PROCEDURE sp_alerta_registrar(
    p_id_alerta   INTEGER,
    p_id_paciente INTEGER,
    p_tipo_alerta VARCHAR,    -- debe existir en cat_tipo_alerta
    p_fecha_hora  TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que p_tipo_alerta existe en cat_tipo_alerta
    -- 2. Verificar que el paciente existe y no está dado de baja
    -- 3. INSERT INTO alertas (id_alerta, id_paciente, tipo_alerta, fecha_hora, estatus)
    --    estatus = 'Activa' siempre en la creación
END;
$$;


-- Marca una alerta como atendida.
-- Modifica: alertas
CREATE OR REPLACE PROCEDURE sp_alerta_atender(
    p_id_alerta INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que la alerta existe y su estatus es 'Activa'
    -- 2. UPDATE alertas SET estatus = 'Atendida' WHERE id_alerta=...
END;
$$;


-- Elimina una alerta (hard delete). Elimina también su origen IoT si existe.
-- Elimina de: alerta_evento_origen (CASCADE), alertas
CREATE OR REPLACE PROCEDURE sp_alerta_eliminar(
    p_id_alerta INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que la alerta existe
    -- 2. DELETE FROM alertas WHERE id_alerta=...
    --    (alerta_evento_origen se borra por ON DELETE CASCADE)
END;
$$;


-- Vincula una alerta existente con el evento IoT que la disparó.
-- Inserta en: alerta_evento_origen
CREATE OR REPLACE PROCEDURE sp_alerta_vincular_origen(
    p_id_origen       INTEGER,
    p_id_alerta       INTEGER,
    p_tipo_evento     VARCHAR,    -- 'GPS', 'BEACON', 'NFC', 'SOS'
    p_id_lectura_gps  INTEGER,    -- NULL si no aplica
    p_id_deteccion    INTEGER,    -- NULL si no aplica
    p_regla_disparada VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que la alerta existe
    -- 2. Verificar que p_tipo_evento es uno de: 'GPS', 'BEACON', 'NFC', 'SOS'
    -- 3. Si tipo='GPS', verificar que p_id_lectura_gps existe en lecturas_gps
    -- 4. Si tipo='BEACON', verificar que p_id_deteccion existe en detecciones_beacon
    -- 5. INSERT INTO alerta_evento_origen (...)
END;
$$;


-- =============================================================================
-- BLOQUE 4: DISPOSITIVOS
-- =============================================================================

-- Registra un nuevo dispositivo IoT.
-- Inserta en: dispositivos
CREATE OR REPLACE PROCEDURE sp_dispositivo_registrar(
    p_id_dispositivo INTEGER,
    p_id_serial      VARCHAR,
    p_tipo           VARCHAR,    -- 'GPS', 'BEACON' o 'NFC'
    p_modelo         VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que p_tipo existe en cat_tipo_dispositivo
    -- 2. Verificar que p_id_serial no está ya en uso
    -- 3. INSERT INTO dispositivos (id_dispositivo, id_serial, tipo, modelo, estado)
    --    estado = 'Activo' por defecto
END;
$$;


-- Actualiza serial, tipo, modelo y estado de un dispositivo.
-- Modifica: dispositivos
CREATE OR REPLACE PROCEDURE sp_dispositivo_editar(
    p_id_dispositivo INTEGER,
    p_id_serial      VARCHAR,
    p_tipo           VARCHAR,
    p_modelo         VARCHAR,
    p_estado         VARCHAR    -- 'Activo', 'Inactivo', 'Mantenimiento'
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el dispositivo existe
    -- 2. Verificar que p_tipo existe en cat_tipo_dispositivo
    -- 3. Verificar que p_estado existe en cat_estado_dispositivo
    -- 4. UPDATE dispositivos SET id_serial=..., tipo=..., modelo=..., estado=...
    --    WHERE id_dispositivo=...
END;
$$;


-- Elimina un dispositivo. Falla si está asignado a un kit activo.
-- Elimina de: dispositivos
CREATE OR REPLACE PROCEDURE sp_dispositivo_eliminar(
    p_id_dispositivo INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que no está asignado en asignacion_kit (GPS o Beacon)
    --    Si está asignado, RAISE EXCEPTION
    -- 2. DELETE FROM dispositivos WHERE id_dispositivo=...
END;
$$;


-- Asigna un kit GPS + Beacon a un paciente.
-- Verifica que ambos dispositivos sean del tipo correcto y estén disponibles.
-- Inserta en: asignacion_kit
CREATE OR REPLACE PROCEDURE sp_dispositivo_asignar_kit(
    p_id_monitoreo          INTEGER,
    p_id_paciente           INTEGER,
    p_id_dispositivo_gps    INTEGER,
    p_id_dispositivo_beacon INTEGER,
    p_fecha_entrega         DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que p_id_dispositivo_gps tiene tipo='GPS'
    -- 2. Verificar que p_id_dispositivo_beacon tiene tipo='BEACON'
    -- 3. Verificar que ninguno de los dos ya está asignado en asignacion_kit
    -- 4. Verificar que el paciente no tiene ya un kit activo (si aplica)
    -- 5. INSERT INTO asignacion_kit (...)
END;
$$;


-- =============================================================================
-- BLOQUE 5: ZONAS SEGURAS
-- =============================================================================

-- Registra una nueva zona segura y opcionalmente la vincula a una sede.
-- Inserta en: zonas, y opcionalmente sede_zonas
CREATE OR REPLACE PROCEDURE sp_zona_registrar(
    p_nombre_zona     VARCHAR,
    p_latitud_centro  NUMERIC,
    p_longitud_centro NUMERIC,
    p_radio_metros    NUMERIC,
    p_id_sede         INTEGER    -- NULL = no vincular a sede todavía
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que nombre_zona no exista ya
    -- 2. INSERT INTO zonas (nombre_zona, latitud_centro, longitud_centro, radio_metros)
    --    RETURNING id_zona INTO v_id_zona  (zonas usa SERIAL o el id es manual?)
    --    Nota: id_zona no tiene SERIAL en el DDL — debe pasarse como parámetro si es manual,
    --    o usar currval si se agrega SERIAL.
    -- 3. Si p_id_sede IS NOT NULL:
    --    INSERT INTO sede_zonas (id_sede, id_zona) VALUES (p_id_sede, v_id_zona)
END;
$$;


-- Actualiza los datos geográficos de una zona.
-- Modifica: zonas
CREATE OR REPLACE PROCEDURE sp_zona_editar(
    p_id_zona         INTEGER,
    p_nombre_zona     VARCHAR,
    p_latitud_centro  NUMERIC,
    p_longitud_centro NUMERIC,
    p_radio_metros    NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que la zona existe
    -- 2. UPDATE zonas SET nombre_zona=..., latitud_centro=...,
    --    longitud_centro=..., radio_metros=... WHERE id_zona=...
END;
$$;


-- Elimina una zona. Falla si tiene gateways o beacons asociados.
-- Elimina de: zonas (sede_zonas se borra por CASCADE si se configura, o manual)
CREATE OR REPLACE PROCEDURE sp_zona_eliminar(
    p_id_zona INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que no tiene gateways activos en gateways (id_zona)
    --    Si tiene, RAISE EXCEPTION
    -- 2. Verificar que no tiene beacons en zona_beacons
    --    Si tiene, RAISE EXCEPTION
    -- 3. DELETE FROM sede_zonas WHERE id_zona=...
    -- 4. DELETE FROM zonas WHERE id_zona=...
END;
$$;


-- =============================================================================
-- BLOQUE 6: FARMACIA
-- =============================================================================

-- Ajusta el stock de un medicamento en una sede (sobrescribe el valor).
-- Modifica: inventario_medicinas
CREATE OR REPLACE PROCEDURE sp_farmacia_ajustar_stock(
    p_gtin        VARCHAR,
    p_id_sede     INTEGER,
    p_stock_nuevo INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el par (GTIN, id_sede) existe en inventario_medicinas
    -- 2. Verificar que p_stock_nuevo >= 0
    -- 3. UPDATE inventario_medicinas SET stock_actual=p_stock_nuevo
    --    WHERE GTIN=... AND id_sede=...
END;
$$;


-- Registra una nueva orden de suministro con sus líneas de medicamentos.
-- Inserta en: suministros, suministro_medicinas (una fila por medicamento)
-- p_medicamentos es un array de pares (GTIN, cantidad)
CREATE OR REPLACE PROCEDURE sp_farmacia_registrar_suministro(
    p_id_suministro INTEGER,
    p_id_farmacia   INTEGER,
    p_id_sede       INTEGER,
    p_fecha_entrega DATE,
    p_estado        VARCHAR,       -- valor de cat_estado_suministro
    p_gtins         VARCHAR[],     -- array de GTINs
    p_cantidades    INTEGER[]      -- array de cantidades, mismo orden que p_gtins
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que p_id_farmacia existe en farmacias_proveedoras
    -- 2. Verificar que p_id_sede existe en sedes
    -- 3. Verificar que p_estado existe en cat_estado_suministro
    -- 4. INSERT INTO suministros (id_suministro, id_farmacia, id_sede, fecha_entrega, estado)
    -- 5. FOR i IN 1..array_length(p_gtins, 1) LOOP
    --      Verificar que p_gtins[i] existe en medicamentos
    --      INSERT INTO suministro_medicinas (id_suministro, GTIN, cantidad) VALUES (...)
    --    END LOOP
END;
$$;


-- Recibe un suministro: cambia estado a 'Recibido' y suma stock al inventario.
-- Modifica: suministros, inventario_medicinas
CREATE OR REPLACE PROCEDURE sp_farmacia_recibir_suministro(
    p_id_suministro INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el suministro existe y su estado es 'Pendiente'
    -- 2. UPDATE suministros SET estado='Recibido' WHERE id_suministro=...
    -- 3. Para cada línea en suministro_medicinas con ese id_suministro:
    --    UPDATE inventario_medicinas
    --    SET stock_actual = stock_actual + sm.cantidad
    --    WHERE GTIN=sm.GTIN AND id_sede=(SELECT id_sede FROM suministros WHERE ...)
    --    Si el par (GTIN, id_sede) no existe, insertarlo con ese stock inicial
END;
$$;


-- =============================================================================
-- BLOQUE 7: VISITAS Y ENTREGAS
-- =============================================================================

-- Registra un nuevo visitante en el catálogo.
-- Inserta en: visitantes
CREATE OR REPLACE PROCEDURE sp_visitante_registrar(
    p_id_visitante  INTEGER,
    p_nombre        VARCHAR,
    p_apellido_p    VARCHAR,
    p_apellido_m    VARCHAR,
    p_relacion      VARCHAR,
    p_telefono      VARCHAR,
    p_curp          VARCHAR    -- puede ser NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. INSERT INTO visitantes (id_visitante, nombre, apellido_p, apellido_m,
    --    relacion, telefono, CURP_pasaporte)
END;
$$;


-- Registra la entrada de una visita.
-- Inserta en: visitas
CREATE OR REPLACE PROCEDURE sp_visita_registrar_entrada(
    p_id_visita    INTEGER,
    p_id_paciente  INTEGER,
    p_id_visitante INTEGER,
    p_id_sede      INTEGER,
    p_fecha        DATE,
    p_hora         TIME
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el paciente existe y está activo
    -- 2. Verificar que el visitante existe en visitantes
    -- 3. Verificar que la sede existe
    -- 4. INSERT INTO visitas (id_visita, id_paciente, id_visitante, id_sede,
    --    fecha_entrada, hora_entrada)
    --    fecha_salida y hora_salida quedan NULL hasta el registro de salida
END;
$$;


-- Registra la salida de una visita ya ingresada.
-- Modifica: visitas
CREATE OR REPLACE PROCEDURE sp_visita_registrar_salida(
    p_id_visita    INTEGER,
    p_fecha_salida DATE,
    p_hora_salida  TIME
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que la visita existe y que hora_salida IS NULL (no ya cerrada)
    -- 2. Verificar que fecha_salida >= fecha_entrada
    -- 3. UPDATE visitas SET fecha_salida=..., hora_salida=... WHERE id_visita=...
END;
$$;


-- Registra una entrega externa recibida para un paciente.
-- Inserta en: entregas_externas
CREATE OR REPLACE PROCEDURE sp_entrega_registrar(
    p_id_entrega      INTEGER,
    p_id_paciente     INTEGER,
    p_id_visitante    INTEGER,
    p_id_cuidador     INTEGER,    -- puede ser NULL
    p_descripcion     VARCHAR,
    p_fecha_recepcion DATE,
    p_hora_recepcion  TIME
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el paciente existe y está activo
    -- 2. Verificar que el visitante existe
    -- 3. Si p_id_cuidador IS NOT NULL, verificar que existe en cuidadores
    -- 4. INSERT INTO entregas_externas (id_entrega, id_paciente, id_visitante,
    --    id_cuidador, descripcion, estado, fecha_recepcion, hora_recepcion)
    --    estado = 'Pendiente' por defecto
END;
$$;


-- =============================================================================
-- BLOQUE 8: RECETAS
-- =============================================================================

-- Registra una receta completa con sus líneas de medicamentos.
-- Inserta en: recetas, receta_medicamentos (una fila por medicamento)
CREATE OR REPLACE PROCEDURE sp_receta_registrar(
    p_id_receta   INTEGER,
    p_id_paciente INTEGER,
    p_fecha       DATE,
    p_gtins       VARCHAR[],    -- array de GTINs
    p_dosis       VARCHAR[],    -- array de dosis, mismo orden
    p_frecuencias INTEGER[]     -- array de frecuencias en horas, mismo orden
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el paciente existe y está activo
    -- 2. Verificar que p_gtins, p_dosis y p_frecuencias tienen la misma longitud
    -- 3. INSERT INTO recetas (id_receta, fecha, id_paciente)
    -- 4. FOR i IN 1..array_length(p_gtins, 1) LOOP
    --      Verificar que p_gtins[i] existe en medicamentos
    --      INSERT INTO receta_medicamentos (id_receta, GTIN, dosis, frecuencia_horas)
    --    END LOOP
END;
$$;


-- Asigna un dispositivo NFC para gestionar la lectura de una receta.
-- Inserta en: receta_nfc
CREATE OR REPLACE PROCEDURE sp_receta_asignar_nfc(
    p_id_receta            INTEGER,
    p_id_dispositivo       INTEGER,
    p_fecha_inicio_gestion DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que la receta existe
    -- 2. Verificar que el dispositivo existe y su tipo='NFC'
    -- 3. Cerrar gestión activa previa si existe:
    --    UPDATE receta_nfc SET fecha_fin_gestion=p_fecha_inicio_gestion - 1
    --    WHERE id_receta=... AND fecha_fin_gestion IS NULL
    -- 4. INSERT INTO receta_nfc (id_receta, id_dispositivo, fecha_inicio_gestion)
END;
$$;


-- =============================================================================
-- BLOQUE 9: LECTURAS IoT
-- (Generadas por sensores; el app web las registraría via API o batch)
-- =============================================================================

-- Registra una lectura GPS de un dispositivo.
-- Inserta en: lecturas_gps
CREATE OR REPLACE PROCEDURE sp_iot_registrar_lectura_gps(
    p_id_lectura     INTEGER,
    p_id_dispositivo INTEGER,
    p_fecha_hora     TIMESTAMP,
    p_latitud        NUMERIC,
    p_longitud       NUMERIC,
    p_altura         NUMERIC,    -- puede ser NULL
    p_nivel_bateria  INTEGER     -- 0-100, puede ser NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el dispositivo existe y su tipo='GPS'
    -- 2. Verificar que p_nivel_bateria está entre 0 y 100 si no es NULL
    -- 3. INSERT INTO lecturas_gps (...)
    -- 4. UPDATE dispositivos SET ultima_conexion=p_fecha_hora WHERE id_dispositivo=...
END;
$$;


-- Registra una detección de beacon en un gateway.
-- Inserta en: detecciones_beacon
CREATE OR REPLACE PROCEDURE sp_iot_registrar_deteccion_beacon(
    p_id_deteccion   INTEGER,
    p_id_dispositivo INTEGER,
    p_id_gateway     INTEGER,
    p_fecha_hora     TIMESTAMP,
    p_rssi           INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el dispositivo existe y su tipo='BEACON'
    -- 2. Verificar que el gateway existe en gateways
    -- 3. INSERT INTO detecciones_beacon (id_deteccion, id_dispositivo, id_gateway,
    --    fecha_hora, rssi)
    -- 4. UPDATE dispositivos SET ultima_conexion=p_fecha_hora WHERE id_dispositivo=...
END;
$$;


-- Registra una lectura de chip NFC (adherencia terapéutica).
-- Inserta en: lecturas_nfc
CREATE OR REPLACE PROCEDURE sp_iot_registrar_lectura_nfc(
    p_id_lectura_nfc INTEGER,
    p_id_dispositivo INTEGER,
    p_id_receta      INTEGER,
    p_fecha_hora     TIMESTAMP,
    p_tipo_lectura   VARCHAR,    -- 'Administración', 'Verificación', 'Rechazo'
    p_resultado      VARCHAR     -- 'Exitosa', 'Fallida', 'Sin respuesta'
)
LANGUAGE plpgsql AS $$
BEGIN
    -- TODO: implementar
    -- 1. Verificar que el dispositivo existe y su tipo='NFC'
    -- 2. Verificar que la receta existe en recetas
    -- 3. INSERT INTO lecturas_nfc (...)
    -- 4. UPDATE dispositivos SET ultima_conexion=p_fecha_hora WHERE id_dispositivo=...
END;
$$;
