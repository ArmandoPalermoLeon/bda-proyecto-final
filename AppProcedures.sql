-- AppProcedures.sql
-- DML stored procedures for app.py routes
-- Apply: psql -U palermingoat -d alzheimer -f AppProcedures.sql

-- ─────────────────────────────────────────────────────────────────────────────
-- PACIENTES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE sp_ins_paciente(
    p_id_paciente INT,
    p_nombre VARCHAR,
    p_apellido_p VARCHAR,
    p_apellido_m VARCHAR,
    p_fecha_nacimiento DATE,
    p_id_estado INT,
    p_id_sede INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_next_sp INT;
BEGIN
    SELECT COALESCE(MAX(id_sede_paciente), 0) + 1 INTO v_next_sp FROM sede_pacientes;

    INSERT INTO pacientes (id_paciente, nombre, apellido_p, apellido_m, fecha_nacimiento, id_estado)
    VALUES (p_id_paciente, p_nombre, p_apellido_p, p_apellido_m, p_fecha_nacimiento, p_id_estado);

    INSERT INTO sede_pacientes (id_sede_paciente, id_sede, id_paciente, fecha_ingreso, hora_ingreso)
    VALUES (v_next_sp, p_id_sede, p_id_paciente, CURRENT_DATE, CURRENT_TIME);
END;
$$;


CREATE OR REPLACE PROCEDURE sp_upd_paciente(
    p_id_paciente INT,
    p_nombre VARCHAR,
    p_apellido_p VARCHAR,
    p_apellido_m VARCHAR,
    p_fecha_nacimiento DATE,
    p_id_estado INT
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE pacientes
    SET nombre = p_nombre,
        apellido_p = p_apellido_p,
        apellido_m = p_apellido_m,
        fecha_nacimiento = p_fecha_nacimiento,
        id_estado = p_id_estado
    WHERE id_paciente = p_id_paciente;
END;
$$;


CREATE OR REPLACE PROCEDURE sp_del_paciente(
    p_id_paciente INT
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE pacientes SET id_estado = 3 WHERE id_paciente = p_id_paciente;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- ENFERMEDADES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE sp_ins_enfermedad(
    p_id_paciente INT,
    p_id_enfermedad INT,
    p_fecha_diag DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO tiene_enfermedad (id_paciente, id_enfermedad, fecha_diag)
    VALUES (p_id_paciente, p_id_enfermedad, p_fecha_diag);
END;
$$;


CREATE OR REPLACE PROCEDURE sp_del_enfermedad(
    p_id_paciente INT,
    p_id_enfermedad INT
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM tiene_enfermedad
    WHERE id_paciente = p_id_paciente AND id_enfermedad = p_id_enfermedad;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- CONTACTOS DE EMERGENCIA
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE sp_ins_contacto(
    p_id_paciente INT,
    p_nombre VARCHAR,
    p_apellido_p VARCHAR,
    p_apellido_m VARCHAR,
    p_telefono VARCHAR,
    p_relacion VARCHAR,
    p_email VARCHAR,
    p_pin_acceso VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_next_id INT;
    v_next_prio INT;
BEGIN
    SELECT COALESCE(MAX(id_contacto), 0) + 1 INTO v_next_id FROM contactos_emergencia;
    SELECT COALESCE(MAX(prioridad), 0) + 1 INTO v_next_prio FROM paciente_contactos WHERE id_paciente = p_id_paciente;

    INSERT INTO contactos_emergencia (id_contacto, nombre, apellido_p, apellido_m, telefono, relacion, email, pin_acceso)
    VALUES (v_next_id, p_nombre, p_apellido_p, p_apellido_m, p_telefono, p_relacion, p_email, p_pin_acceso);

    INSERT INTO paciente_contactos (id_paciente, id_contacto, prioridad)
    VALUES (p_id_paciente, v_next_id, v_next_prio);
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- KIT GPS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE sp_ins_kit(
    p_id_paciente INT,
    p_id_dispositivo_gps INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_next_id INT;
BEGIN
    SELECT COALESCE(MAX(id_monitoreo), 0) + 1 INTO v_next_id FROM asignacion_kit;

    INSERT INTO asignacion_kit (id_monitoreo, id_paciente, id_dispositivo_gps, fecha_entrega)
    VALUES (v_next_id, p_id_paciente, p_id_dispositivo_gps, CURRENT_DATE);
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- TURNOS
-- ─────────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────────
-- BEACON — asignación y detección
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE sp_ins_asignacion_beacon(
    p_id_dispositivo INT,
    p_id_cuidador INT
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO asignacion_beacon (id_dispositivo, id_cuidador, fecha_inicio)
    VALUES (p_id_dispositivo, p_id_cuidador, CURRENT_DATE);
END;
$$;


CREATE OR REPLACE PROCEDURE sp_ins_deteccion_beacon(
    p_id_dispositivo INT,
    p_id_cuidador INT,
    p_rssi INT,
    p_gateway_id VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_next_id INT;
BEGIN
    SELECT COALESCE(MAX(id_deteccion), 0) + 1 INTO v_next_id FROM detecciones_beacon;

    INSERT INTO detecciones_beacon (id_deteccion, id_dispositivo, id_cuidador, fecha_hora, rssi, id_gateway)
    VALUES (v_next_id, p_id_dispositivo, p_id_cuidador, NOW(), p_rssi, p_gateway_id);
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- TURNOS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE sp_ins_turno(
    p_id_turno INT,
    p_id_cuidador INT,
    p_id_zona INT,
    p_hora_inicio TIME,
    p_hora_fin TIME,
    p_lunes BOOLEAN,
    p_martes BOOLEAN,
    p_miercoles BOOLEAN,
    p_jueves BOOLEAN,
    p_viernes BOOLEAN,
    p_sabado BOOLEAN,
    p_domingo BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO turno_cuidador (id_turno, id_cuidador, id_zona, hora_inicio, hora_fin,
        lunes, martes, miercoles, jueves, viernes, sabado, domingo, activo)
    VALUES (p_id_turno, p_id_cuidador, p_id_zona, p_hora_inicio, p_hora_fin,
        p_lunes, p_martes, p_miercoles, p_jueves, p_viernes, p_sabado, p_domingo, TRUE);
END;
$$;


CREATE OR REPLACE PROCEDURE sp_upd_turno(
    p_id_turno INT,
    p_id_cuidador INT,
    p_id_zona INT,
    p_hora_inicio TIME,
    p_hora_fin TIME,
    p_lunes BOOLEAN,
    p_martes BOOLEAN,
    p_miercoles BOOLEAN,
    p_jueves BOOLEAN,
    p_viernes BOOLEAN,
    p_sabado BOOLEAN,
    p_domingo BOOLEAN,
    p_activo BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE turno_cuidador
    SET id_cuidador = p_id_cuidador,
        id_zona = p_id_zona,
        hora_inicio = p_hora_inicio,
        hora_fin = p_hora_fin,
        lunes = p_lunes,
        martes = p_martes,
        miercoles = p_miercoles,
        jueves = p_jueves,
        viernes = p_viernes,
        sabado = p_sabado,
        domingo = p_domingo,
        activo = p_activo
    WHERE id_turno = p_id_turno;
END;
$$;


CREATE OR REPLACE PROCEDURE sp_del_turno(
    p_id_turno INT
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM turno_cuidador WHERE id_turno = p_id_turno;
END;
$$;
