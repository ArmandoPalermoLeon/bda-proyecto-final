-- =============================================================================
-- ViewsDB.sql — Vistas de base de datos para AlzMonitor
-- Todas las vistas son de solo lectura. No reemplazan stored procedures DML.
-- Aplicar: psql -U palermingoat -d alzheimer -f ViewsDB.sql
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Pacientes activos con su sede y estado actual
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_pacientes_activos AS
SELECT
    p.id_paciente,
    p.nombre AS nombre_paciente,
    p.apellido_p,
    p.apellido_m,
    p.nombre || ' ' || p.apellido_p || ' ' || p.apellido_m AS nombre_completo,
    p.fecha_nacimiento,
    p.id_estado,
    ep.desc_estado,
    sp.id_sede AS id_sucursal,
    s.nombre_sede AS nombre_sucursal
FROM pacientes p
JOIN estados_paciente ep ON ep.id_estado = p.id_estado
LEFT JOIN sede_pacientes sp ON sp.id_paciente = p.id_paciente AND sp.fecha_salida IS NULL
LEFT JOIN sedes s ON s.id_sede = sp.id_sede
WHERE p.id_estado != 3
ORDER BY p.id_paciente;


-- -----------------------------------------------------------------------------
-- 2. Cuidadores con su sede actual
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_cuidadores AS
SELECT
    e.id_empleado AS id_cuidador,
    e.nombre AS nombre_cuidador,
    e.apellido_p,
    e.apellido_m,
    e.nombre || ' ' || e.apellido_p AS nombre_completo,
    e.telefono,
    se.id_sede AS id_sucursal,
    s.nombre_sede AS nombre_sucursal
FROM cuidadores c
JOIN empleados e ON e.id_empleado = c.id_empleado
LEFT JOIN sede_empleados se ON se.id_empleado = e.id_empleado AND se.fecha_salida IS NULL
LEFT JOIN sedes s ON s.id_sede = se.id_sede
ORDER BY e.id_empleado;


-- -----------------------------------------------------------------------------
-- 3. Dispositivos con batería más reciente y paciente asignado
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_dispositivos AS
SELECT
    d.id_dispositivo,
    d.id_serial AS codigo,
    d.tipo,
    d.modelo,
    d.estado AS estatus,
    (
        SELECT lg.nivel_bateria
        FROM lecturas_gps lg
        WHERE lg.id_dispositivo = d.id_dispositivo
        ORDER BY lg.fecha_hora DESC
        LIMIT 1
    ) AS bateria,
    COALESCE(p.nombre || ' ' || p.apellido_p, '—') AS paciente,
    sp.id_sede AS id_sucursal,
    COALESCE(s.nombre_sede, '—') AS nombre_sucursal
FROM dispositivos d
LEFT JOIN asignacion_kit ak ON ak.id_dispositivo_gps = d.id_dispositivo AND ak.fecha_fin IS NULL
LEFT JOIN pacientes p ON p.id_paciente = ak.id_paciente
LEFT JOIN sede_pacientes sp ON sp.id_paciente = p.id_paciente AND sp.fecha_salida IS NULL
LEFT JOIN sedes s ON s.id_sede = sp.id_sede
ORDER BY d.id_dispositivo;


-- -----------------------------------------------------------------------------
-- 4. Zonas seguras con sede, pacientes activos en esa sede y contacto de alerta
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_zonas AS
SELECT
    z.id_zona,
    z.nombre_zona,
    z.radio_metros,
    z.latitud_centro,
    z.longitud_centro,
    sz.id_sede AS id_sucursal,
    COALESCE(s.nombre_sede, '—') AS nombre_sucursal,
    COALESCE(
        (
            SELECT STRING_AGG(p.nombre || ' ' || p.apellido_p, ', ' ORDER BY p.nombre)
            FROM pacientes p
            JOIN sede_pacientes sp ON sp.id_paciente = p.id_paciente
            WHERE sp.id_sede = sz.id_sede
              AND sp.fecha_salida IS NULL
              AND p.id_estado != 3
        ),
        '—'
    ) AS pacientes_en_zona,
    COALESCE(
        (
            SELECT ce.nombre || ' ' || ce.apellido_p || ' · ' || ce.telefono
            FROM paciente_contactos pc
            JOIN contactos_emergencia ce ON ce.id_contacto = pc.id_contacto
            JOIN sede_pacientes sp ON sp.id_paciente = pc.id_paciente
            WHERE sp.id_sede = sz.id_sede
              AND sp.fecha_salida IS NULL
            ORDER BY pc.prioridad ASC
            LIMIT 1
        ),
        '—'
    ) AS notificar_a
FROM zonas z
LEFT JOIN sede_zonas sz ON sz.id_zona = z.id_zona
LEFT JOIN sedes s ON s.id_sede = sz.id_sede
ORDER BY z.id_zona;


-- -----------------------------------------------------------------------------
-- 5. Alertas con paciente, sede, origen del evento y contacto prioritario
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_alertas AS
SELECT
    a.id_alerta,
    a.id_paciente,
    a.tipo_alerta,
    a.estatus,
    a.fecha_hora,
    COALESCE(
        p.nombre || ' ' || p.apellido_p || ' ' || p.apellido_m,
        '— Zona: ' || z.nombre_zona,
        '—'
    ) AS paciente,
    COALESCE(s.nombre_sede, sz.nombre_sede, '—') AS nombre_sucursal,
    aeo.tipo_evento,
    aeo.regla_disparada,
    ce.nombre || ' ' || ce.apellido_p AS contacto_prioritario,
    ce.telefono AS telefono_contacto
FROM alertas a
LEFT JOIN pacientes p ON p.id_paciente = a.id_paciente
LEFT JOIN zonas z ON z.id_zona = a.id_zona
LEFT JOIN sede_pacientes sp ON sp.id_paciente = p.id_paciente AND sp.fecha_salida IS NULL
LEFT JOIN sedes s ON s.id_sede = sp.id_sede
LEFT JOIN sede_zonas szr ON szr.id_zona = a.id_zona
LEFT JOIN sedes sz ON sz.id_sede = szr.id_sede
LEFT JOIN alerta_evento_origen aeo ON aeo.id_alerta = a.id_alerta
LEFT JOIN (
    SELECT pc.id_paciente, pc.id_contacto
    FROM paciente_contactos pc
    WHERE pc.prioridad = (
        SELECT MIN(pc2.prioridad)
        FROM paciente_contactos pc2
        WHERE pc2.id_paciente = pc.id_paciente
    )
) pc_top ON pc_top.id_paciente = a.id_paciente
LEFT JOIN contactos_emergencia ce ON ce.id_contacto = pc_top.id_contacto
ORDER BY a.fecha_hora DESC;


-- -----------------------------------------------------------------------------
-- 6. Recetas con paciente, sede, NFC activo y conteo de medicamentos
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_recetas AS
SELECT
    r.id_receta,
    r.estado,
    TO_CHAR(r.fecha, 'DD/MM/YYYY') AS fecha,
    p.id_paciente,
    p.nombre || ' ' || p.apellido_p || ' ' || p.apellido_m AS nombre_paciente,
    COALESCE(s.nombre_sede, '—') AS nombre_sede,
    COUNT(DISTINCT rm.id_detalle) AS n_medicamentos,
    d.id_serial AS serial_nfc,
    TO_CHAR(rn.fecha_inicio_gestion, 'DD/MM/YYYY') AS nfc_desde,
    COUNT(ln.id_lectura_nfc) FILTER (WHERE ln.fecha_hora::date = CURRENT_DATE) AS lecturas_hoy,
    COUNT(ln.id_lectura_nfc) FILTER (WHERE ln.fecha_hora::date = CURRENT_DATE AND ln.resultado = 'Exitosa') AS exitosas_hoy
FROM recetas r
JOIN pacientes p ON p.id_paciente = r.id_paciente
LEFT JOIN sede_pacientes sp ON sp.id_paciente = p.id_paciente AND sp.fecha_salida IS NULL
LEFT JOIN sedes s ON s.id_sede = sp.id_sede
LEFT JOIN receta_medicamentos rm ON rm.id_receta = r.id_receta
LEFT JOIN receta_nfc rn ON rn.id_receta = r.id_receta AND rn.fecha_fin_gestion IS NULL
LEFT JOIN dispositivos d ON d.id_dispositivo = rn.id_dispositivo
LEFT JOIN lecturas_nfc ln ON ln.id_receta = r.id_receta
WHERE p.id_estado != 3
GROUP BY r.id_receta, r.estado, r.fecha, p.id_paciente, p.nombre, p.apellido_p,
         p.apellido_m, s.nombre_sede, d.id_serial, rn.fecha_inicio_gestion
ORDER BY r.fecha DESC;


-- -----------------------------------------------------------------------------
-- 7. Turnos de cuidadores con zona y días de cobertura
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_turnos AS
SELECT
    tc.id_turno,
    tc.hora_inicio,
    tc.hora_fin,
    tc.activo,
    tc.lunes, tc.martes, tc.miercoles, tc.jueves,
    tc.viernes, tc.sabado, tc.domingo,
    z.nombre_zona,
    tc.id_zona,
    e.nombre || ' ' || e.apellido_p AS nombre_cuidador,
    tc.id_cuidador
FROM turno_cuidador tc
JOIN zonas z ON z.id_zona = tc.id_zona
JOIN cuidadores c ON c.id_empleado = tc.id_cuidador
JOIN empleados e ON e.id_empleado = c.id_empleado
ORDER BY z.nombre_zona, tc.hora_inicio;


-- -----------------------------------------------------------------------------
-- 8. Detecciones beacon con cuidador y gateway (arquitectura cuidador lleva beacon)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_detecciones_beacon AS
SELECT
    db.id_deteccion,
    db.fecha_hora,
    db.rssi,
    db.id_gateway,
    d.id_serial AS serial_beacon,
    COALESCE(e.nombre || ' ' || e.apellido_p, 'Anónimo') AS nombre_cuidador,
    db.id_cuidador
FROM detecciones_beacon db
JOIN dispositivos d ON d.id_dispositivo = db.id_dispositivo
LEFT JOIN cuidadores c ON c.id_empleado = db.id_cuidador
LEFT JOIN empleados e ON e.id_empleado = c.id_empleado
ORDER BY db.fecha_hora DESC;


-- -----------------------------------------------------------------------------
-- 9. Kit GPS activo por paciente con última lectura de batería
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_kit_gps_activo AS
SELECT
    ak.id_monitoreo,
    ak.id_paciente,
    p.nombre || ' ' || p.apellido_p AS nombre_paciente,
    d.id_dispositivo,
    d.id_serial AS codigo_gps,
    d.modelo,
    TO_CHAR(ak.fecha_entrega, 'YYYY-MM-DD') AS fecha_entrega,
    (
        SELECT lg.nivel_bateria
        FROM lecturas_gps lg
        WHERE lg.id_dispositivo = d.id_dispositivo
        ORDER BY lg.fecha_hora DESC
        LIMIT 1
    ) AS ultima_bateria,
    (
        SELECT TO_CHAR(lg.fecha_hora, 'YYYY-MM-DD HH24:MI')
        FROM lecturas_gps lg
        WHERE lg.id_dispositivo = d.id_dispositivo
        ORDER BY lg.fecha_hora DESC
        LIMIT 1
    ) AS ultima_lectura
FROM asignacion_kit ak
JOIN pacientes p ON p.id_paciente = ak.id_paciente
JOIN dispositivos d ON d.id_dispositivo = ak.id_dispositivo_gps
WHERE ak.fecha_fin IS NULL;


-- -----------------------------------------------------------------------------
-- 10. Inventario de farmacia por sede con alerta de stock crítico
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_inventario_farmacia AS
SELECT
    im.gtin,
    im.id_sede,
    s.nombre_sede,
    m.nombre_medicamento,
    im.stock_actual,
    im.stock_minimo,
    im.stock_actual <= im.stock_minimo AS stock_critico
FROM inventario_medicinas im
JOIN sedes s ON s.id_sede = im.id_sede
JOIN medicamentos m ON m.gtin = im.gtin
ORDER BY im.id_sede, stock_critico DESC, m.nombre_medicamento;


-- -----------------------------------------------------------------------------
-- Confirmación
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE '✓ v_pacientes_activos';
    RAISE NOTICE '✓ v_cuidadores';
    RAISE NOTICE '✓ v_dispositivos';
    RAISE NOTICE '✓ v_zonas';
    RAISE NOTICE '✓ v_alertas';
    RAISE NOTICE '✓ v_recetas';
    RAISE NOTICE '✓ v_turnos';
    RAISE NOTICE '✓ v_detecciones_beacon';
    RAISE NOTICE '✓ v_kit_gps_activo';
    RAISE NOTICE '✓ v_inventario_farmacia';
    RAISE NOTICE '10 vistas aplicadas correctamente.';
END;
$$;
