-- =============================================================================
-- ProcedimientosAlmacenados.sql
-- AlzMonitor — Procedimientos Almacenados: Módulo Recetas + NFC
-- Base de datos: alzheimer
--
-- Convenciones seguidas:
--   - CREATE PROCEDURE (sin OR REPLACE)
--   - LANGUAGE plpgsql
--   - Procedimientos que retornan filas: parámetro INOUT io_resultados REFCURSOR
--     y OPEN io_resultados FOR SELECT … en el cuerpo
--   - Procedimientos DML (sin resultado): sin REFCURSOR
--   - Cada procedimiento acompañado de su bloque de uso:
--       BEGIN; CALL sp_xxx(…); [FETCH ALL FROM io_resultados;] COMMIT;
--   - Errores con RAISE EXCEPTION — Flask los captura como excepciones
--   - IDs manuales (no hay SERIAL en las tablas clave)
-- =============================================================================


-- =============================================================================
-- BLOQUE 1: GESTIÓN DE RECETAS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- sp_receta_crear
-- Crea una nueva receta vacía para un paciente.
-- Inserta en: recetas
-- Precondiciones: id_paciente debe existir y no estar dado de baja (id_estado != 3)
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_receta_crear(
    IN p_id_receta INTEGER,
    IN p_id_paciente INTEGER,
    IN p_fecha DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pacientes
        WHERE id_paciente = p_id_paciente AND id_estado != 3
    ) THEN
        RAISE EXCEPTION 'Paciente % no encontrado o dado de baja.', p_id_paciente;
    END IF;

    IF EXISTS (SELECT 1 FROM recetas WHERE id_receta = p_id_receta) THEN
        RAISE EXCEPTION 'Ya existe una receta con ID %.', p_id_receta;
    END IF;

    INSERT INTO recetas (id_receta, fecha, id_paciente)
    VALUES (p_id_receta, p_fecha, p_id_paciente);
END;
$$;

BEGIN;
CALL sp_receta_crear(101, 5, '2024-01-15');
COMMIT;


-- -----------------------------------------------------------------------------
-- sp_receta_agregar_medicamento
-- Agrega un medicamento a una receta existente.
-- Inserta en: receta_medicamentos
-- Precondiciones: receta y medicamento (gtin) deben existir
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_receta_agregar_medicamento(
    IN p_id_detalle INTEGER,
    IN p_id_receta INTEGER,
    IN p_gtin VARCHAR,
    IN p_dosis VARCHAR,
    IN p_frecuencia_horas INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM recetas WHERE id_receta = p_id_receta) THEN
        RAISE EXCEPTION 'Receta % no encontrada.', p_id_receta;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM medicamentos WHERE gtin = p_gtin) THEN
        RAISE EXCEPTION 'Medicamento con GTIN % no encontrado.', p_gtin;
    END IF;

    IF p_frecuencia_horas <= 0 THEN
        RAISE EXCEPTION 'La frecuencia debe ser mayor a cero horas.';
    END IF;

    INSERT INTO receta_medicamentos (id_detalle, id_receta, gtin, dosis, frecuencia_horas)
    VALUES (p_id_detalle, p_id_receta, p_gtin, p_dosis, p_frecuencia_horas);
END;
$$;

BEGIN;
CALL sp_receta_agregar_medicamento(201, 101, '7501234567890', '10mg', 8);
COMMIT;


-- -----------------------------------------------------------------------------
-- sp_receta_quitar_medicamento
-- Elimina un medicamento de una receta.
-- Borra de: receta_medicamentos
-- Precondiciones: el detalle debe pertenecer a la receta indicada
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_receta_quitar_medicamento(
    IN p_id_detalle INTEGER,
    IN p_id_receta INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM receta_medicamentos
        WHERE id_detalle = p_id_detalle AND id_receta = p_id_receta
    ) THEN
        RAISE EXCEPTION 'Detalle % no encontrado en receta %.', p_id_detalle, p_id_receta;
    END IF;

    DELETE FROM receta_medicamentos
    WHERE id_detalle = p_id_detalle AND id_receta = p_id_receta;
END;
$$;

BEGIN;
CALL sp_receta_quitar_medicamento(201, 101);
COMMIT;


-- -----------------------------------------------------------------------------
-- sp_receta_actualizar_medicamento
-- Actualiza la dosis o frecuencia de un medicamento en una receta.
-- Modifica: receta_medicamentos
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_receta_actualizar_medicamento(
    IN p_id_detalle INTEGER,
    IN p_id_receta INTEGER,
    IN p_dosis VARCHAR,
    IN p_frecuencia_horas INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM receta_medicamentos
        WHERE id_detalle = p_id_detalle AND id_receta = p_id_receta
    ) THEN
        RAISE EXCEPTION 'Detalle % no encontrado en receta %.', p_id_detalle, p_id_receta;
    END IF;

    IF p_frecuencia_horas <= 0 THEN
        RAISE EXCEPTION 'La frecuencia debe ser mayor a cero horas.';
    END IF;

    UPDATE receta_medicamentos
    SET dosis = p_dosis,
        frecuencia_horas = p_frecuencia_horas
    WHERE id_detalle = p_id_detalle AND id_receta = p_id_receta;
END;
$$;

BEGIN;
CALL sp_receta_actualizar_medicamento(201, 101, '20mg', 12);
COMMIT;


-- =============================================================================
-- BLOQUE 2: GESTIÓN DE PULSERAS NFC
-- =============================================================================

-- -----------------------------------------------------------------------------
-- sp_receta_activar_nfc
-- Vincula un dispositivo NFC a una receta (inicia gestión de adherencia).
-- Inserta en: receta_nfc
-- Regla: una receta sólo puede tener un NFC activo a la vez
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_receta_activar_nfc(
    IN p_id_receta INTEGER,
    IN p_id_dispositivo INTEGER,
    IN p_fecha_inicio DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM recetas WHERE id_receta = p_id_receta) THEN
        RAISE EXCEPTION 'Receta % no encontrada.', p_id_receta;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM dispositivos
        WHERE id_dispositivo = p_id_dispositivo AND tipo = 'NFC'
    ) THEN
        RAISE EXCEPTION 'El dispositivo % no es de tipo NFC o no existe.', p_id_dispositivo;
    END IF;

    IF EXISTS (
        SELECT 1 FROM receta_nfc
        WHERE id_receta = p_id_receta AND fecha_fin_gestion IS NULL
    ) THEN
        RAISE EXCEPTION 'La receta % ya tiene un dispositivo NFC activo. Ciérralo primero.', p_id_receta;
    END IF;

    INSERT INTO receta_nfc (id_receta, id_dispositivo, fecha_inicio_gestion, fecha_fin_gestion)
    VALUES (p_id_receta, p_id_dispositivo, p_fecha_inicio, NULL);
END;
$$;

BEGIN;
CALL sp_receta_activar_nfc(101, 30, '2024-01-15');
COMMIT;


-- -----------------------------------------------------------------------------
-- sp_receta_cerrar_nfc
-- Cierra la gestión NFC activa de una receta.
-- Modifica: receta_nfc (fecha_fin_gestion)
-- Útil cuando se cambia de pulsera o el paciente se da de baja.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_receta_cerrar_nfc(
    IN p_id_receta INTEGER,
    IN p_id_dispositivo INTEGER,
    IN p_fecha_fin DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM receta_nfc
        WHERE id_receta = p_id_receta
          AND id_dispositivo = p_id_dispositivo
          AND fecha_fin_gestion IS NULL
    ) THEN
        RAISE EXCEPTION 'No hay vínculo NFC activo entre receta % y dispositivo %.', p_id_receta, p_id_dispositivo;
    END IF;

    UPDATE receta_nfc
    SET fecha_fin_gestion = p_fecha_fin
    WHERE id_receta = p_id_receta
      AND id_dispositivo = p_id_dispositivo
      AND fecha_fin_gestion IS NULL;
END;
$$;

BEGIN;
CALL sp_receta_cerrar_nfc(101, 30, '2024-03-01');
COMMIT;


-- -----------------------------------------------------------------------------
-- sp_receta_cambiar_nfc
-- Sustituye el dispositivo NFC de una receta en un solo paso atómico.
-- Cierra el vínculo actual e inicia uno nuevo.
-- Modifica: receta_nfc (UPDATE + INSERT)
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_receta_cambiar_nfc(
    IN p_id_receta INTEGER,
    IN p_id_dispositivo_nuevo INTEGER,
    IN p_fecha_cambio DATE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_dispositivo_actual INTEGER;
BEGIN
    SELECT id_dispositivo INTO v_dispositivo_actual
    FROM receta_nfc
    WHERE id_receta = p_id_receta AND fecha_fin_gestion IS NULL;

    IF v_dispositivo_actual IS NULL THEN
        RAISE EXCEPTION 'La receta % no tiene un NFC activo para reemplazar.', p_id_receta;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM dispositivos
        WHERE id_dispositivo = p_id_dispositivo_nuevo AND tipo = 'NFC'
    ) THEN
        RAISE EXCEPTION 'El dispositivo % no es de tipo NFC o no existe.', p_id_dispositivo_nuevo;
    END IF;

    UPDATE receta_nfc
    SET fecha_fin_gestion = p_fecha_cambio
    WHERE id_receta = p_id_receta
      AND id_dispositivo = v_dispositivo_actual
      AND fecha_fin_gestion IS NULL;

    INSERT INTO receta_nfc (id_receta, id_dispositivo, fecha_inicio_gestion, fecha_fin_gestion)
    VALUES (p_id_receta, p_id_dispositivo_nuevo, p_fecha_cambio, NULL);
END;
$$;

BEGIN;
CALL sp_receta_cambiar_nfc(101, 31, '2024-03-01');
COMMIT;


-- =============================================================================
-- BLOQUE 3: LECTURAS NFC (adherencia terapéutica)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- sp_nfc_registrar_lectura
-- Registra una lectura NFC de administración de medicamento.
-- Inserta en: lecturas_nfc
-- Llamado por POST /api/nfc/lectura cuando el cuidador toca la pulsera
-- del paciente con su teléfono (Web NFC API).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_nfc_registrar_lectura(
    IN p_id_lectura_nfc INTEGER,
    IN p_id_dispositivo INTEGER,
    IN p_id_receta INTEGER,
    IN p_fecha_hora TIMESTAMP,
    IN p_tipo_lectura VARCHAR,
    IN p_resultado VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM receta_nfc
        WHERE id_receta = p_id_receta
          AND id_dispositivo = p_id_dispositivo
          AND fecha_fin_gestion IS NULL
    ) THEN
        RAISE EXCEPTION 'No hay vínculo NFC activo entre receta % y dispositivo %.', p_id_receta, p_id_dispositivo;
    END IF;

    IF p_tipo_lectura NOT IN ('Administración', 'Verificación') THEN
        RAISE EXCEPTION 'tipo_lectura inválido: %. Usar Administración o Verificación.', p_tipo_lectura;
    END IF;

    IF p_resultado NOT IN ('Exitosa', 'Fallida') THEN
        RAISE EXCEPTION 'resultado inválido: %. Usar Exitosa o Fallida.', p_resultado;
    END IF;

    INSERT INTO lecturas_nfc
        (id_lectura_nfc, id_dispositivo, id_receta, fecha_hora, tipo_lectura, resultado)
    VALUES
        (p_id_lectura_nfc, p_id_dispositivo, p_id_receta, p_fecha_hora, p_tipo_lectura, p_resultado);
END;
$$;

BEGIN;
CALL sp_nfc_registrar_lectura(501, 30, 101, '2024-01-15 08:00:00', 'Administración', 'Exitosa');
COMMIT;


-- =============================================================================
-- BLOQUE 4: OPERACIONES DE CIERRE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- sp_receta_cerrar
-- Cierra completamente una receta: cierra todos los vínculos NFC activos
-- y preserva el historial (no elimina la receta).
-- Modifica: receta_nfc
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_receta_cerrar(
    IN p_id_receta INTEGER,
    IN p_fecha_fin DATE
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM recetas WHERE id_receta = p_id_receta) THEN
        RAISE EXCEPTION 'Receta % no encontrada.', p_id_receta;
    END IF;

    UPDATE receta_nfc
    SET fecha_fin_gestion = p_fecha_fin
    WHERE id_receta = p_id_receta AND fecha_fin_gestion IS NULL;
END;
$$;

BEGIN;
CALL sp_receta_cerrar(101, '2024-03-31');
COMMIT;


-- =============================================================================
-- BLOQUE 5: ASIGNACIÓN DIRECTA NFC ↔ PACIENTE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- sp_nfc_asignar
-- Asigna (o reasigna) un dispositivo NFC a un paciente.
-- Cierra cualquier asignación activa previa del paciente o del dispositivo,
-- luego abre una nueva en asignacion_nfc.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_nfc_asignar(
    IN p_id_paciente INTEGER,
    IN p_id_dispositivo INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pacientes
        WHERE id_paciente = p_id_paciente AND id_estado != 3
    ) THEN
        RAISE EXCEPTION 'Paciente % no encontrado o dado de baja.', p_id_paciente;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM dispositivos
        WHERE id_dispositivo = p_id_dispositivo AND tipo = 'NFC'
    ) THEN
        RAISE EXCEPTION 'Dispositivo % no es de tipo NFC o no existe.', p_id_dispositivo;
    END IF;

    UPDATE asignacion_nfc
    SET fecha_fin = CURRENT_DATE
    WHERE id_paciente = p_id_paciente AND fecha_fin IS NULL;

    UPDATE asignacion_nfc
    SET fecha_fin = CURRENT_DATE
    WHERE id_dispositivo = p_id_dispositivo AND fecha_fin IS NULL;

    INSERT INTO asignacion_nfc (id_paciente, id_dispositivo, fecha_inicio)
    VALUES (p_id_paciente, p_id_dispositivo, CURRENT_DATE);
END;
$$;

BEGIN;
CALL sp_nfc_asignar(5, 30);
COMMIT;


-- =============================================================================
-- BLOQUE 6: CONSULTAS CON REFCURSOR
-- Procedimientos que retornan conjuntos de filas mediante un cursor.
-- Patrón de uso:
--   BEGIN;
--   CALL sp_xxx(param, 'io_resultados');
--   FETCH ALL FROM io_resultados;
--   COMMIT;
-- =============================================================================

-- -----------------------------------------------------------------------------
-- sp_receta_consultar_medicamentos
-- Devuelve todos los medicamentos de una receta con su nombre, dosis y
-- frecuencia. Útil para mostrar el detalle completo de una receta.
-- Retorna: id_detalle, gtin, nombre_medicamento, dosis, frecuencia_horas
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_receta_consultar_medicamentos(
    IN p_id_receta INTEGER,
    INOUT io_resultados REFCURSOR
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM recetas WHERE id_receta = p_id_receta) THEN
        RAISE EXCEPTION 'Receta % no encontrada.', p_id_receta;
    END IF;

    OPEN io_resultados FOR
        SELECT rm.id_detalle,
               rm.gtin,
               m.nombre_medicamento,
               rm.dosis,
               rm.frecuencia_horas
        FROM receta_medicamentos rm
        JOIN medicamentos m ON m.gtin = rm.gtin
        WHERE rm.id_receta = p_id_receta
        ORDER BY rm.id_detalle;
END;
$$;

BEGIN;
CALL sp_receta_consultar_medicamentos(101, 'io_resultados');
FETCH ALL FROM io_resultados;
COMMIT;


-- -----------------------------------------------------------------------------
-- sp_nfc_historial_lecturas
-- Devuelve el historial de lecturas NFC de una receta, limitado a los
-- últimos p_limite registros. Incluye el número de serie del dispositivo.
-- Retorna: id_lectura_nfc, numero_serie, fecha_hora, tipo_lectura, resultado
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_nfc_historial_lecturas(
    IN p_id_receta INTEGER,
    IN p_limite INTEGER,
    INOUT io_resultados REFCURSOR
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM recetas WHERE id_receta = p_id_receta) THEN
        RAISE EXCEPTION 'Receta % no encontrada.', p_id_receta;
    END IF;

    IF p_limite <= 0 THEN
        RAISE EXCEPTION 'El límite debe ser mayor a cero.';
    END IF;

    OPEN io_resultados FOR
        SELECT ln.id_lectura_nfc,
               d.numero_serie,
               ln.fecha_hora,
               ln.tipo_lectura,
               ln.resultado
        FROM lecturas_nfc ln
        JOIN dispositivos d ON d.id_dispositivo = ln.id_dispositivo
        WHERE ln.id_receta = p_id_receta
        ORDER BY ln.fecha_hora DESC
        LIMIT p_limite;
END;
$$;

BEGIN;
CALL sp_nfc_historial_lecturas(101, 20, 'io_resultados');
FETCH ALL FROM io_resultados;
COMMIT;


-- -----------------------------------------------------------------------------
-- sp_paciente_recetas_activas
-- Devuelve todas las recetas activas de un paciente junto con el número de
-- medicamentos y el número de serie de la pulsera NFC vinculada (si existe).
-- Retorna: id_receta, fecha, total_medicamentos, numero_serie_nfc
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_paciente_recetas_activas(
    IN p_id_paciente INTEGER,
    INOUT io_resultados REFCURSOR
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pacientes
        WHERE id_paciente = p_id_paciente AND id_estado != 3
    ) THEN
        RAISE EXCEPTION 'Paciente % no encontrado o dado de baja.', p_id_paciente;
    END IF;

    OPEN io_resultados FOR
        SELECT r.id_receta,
               r.fecha,
               COUNT(rm.id_detalle) AS total_medicamentos,
               d.numero_serie AS numero_serie_nfc
        FROM recetas r
        LEFT JOIN receta_medicamentos rm ON rm.id_receta = r.id_receta
        LEFT JOIN receta_nfc rn ON rn.id_receta = r.id_receta
                               AND rn.fecha_fin_gestion IS NULL
        LEFT JOIN dispositivos d ON d.id_dispositivo = rn.id_dispositivo
        WHERE r.id_paciente = p_id_paciente
          AND r.estado = 'Activa'
        GROUP BY r.id_receta, r.fecha, d.numero_serie
        ORDER BY r.fecha DESC;
END;
$$;

BEGIN;
CALL sp_paciente_recetas_activas(5, 'io_resultados');
FETCH ALL FROM io_resultados;
COMMIT;


-- =============================================================================
-- Para verificar que los procedimientos existen en la base de datos:
--   SELECT proname, pronargs FROM pg_proc
--   WHERE proname LIKE 'sp_receta%' OR proname LIKE 'sp_nfc%'
--   ORDER BY proname;
-- =============================================================================
