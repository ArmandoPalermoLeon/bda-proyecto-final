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
-- 11. Suministros con farmacia proveedora, sede y medicamentos del pedido
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_suministros AS
SELECT
    su.id_suministro,
    TO_CHAR(su.fecha_entrega, 'YYYY-MM-DD') AS fecha_entrega,
    su.estado,
    fp.nombre AS farmacia,
    fp.id_farmacia,
    s.id_sede,
    s.nombre_sede,
    COALESCE(STRING_AGG(m.nombre_medicamento, ' · ' ORDER BY m.nombre_medicamento), '—') AS medicamentos
FROM suministros su
JOIN farmacias_proveedoras fp ON fp.id_farmacia = su.id_farmacia
JOIN sedes s ON s.id_sede = su.id_sede
LEFT JOIN suministro_medicinas sm ON sm.id_suministro = su.id_suministro
LEFT JOIN medicamentos m ON m.gtin = sm.gtin
GROUP BY su.id_suministro, su.fecha_entrega, su.estado, fp.nombre, fp.id_farmacia, s.id_sede, s.nombre_sede
ORDER BY su.id_suministro DESC;


-- -----------------------------------------------------------------------------
-- 12. Visitas con paciente, visitante y sede (filtrar por fecha en Python)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_visitas AS
SELECT
    v.id_visita,
    v.id_paciente,
    TO_CHAR(v.fecha_entrada, 'YYYY-MM-DD') AS fecha_entrada,
    v.hora_entrada,
    v.fecha_salida,
    v.hora_salida,
    p.nombre || ' ' || p.apellido_p AS paciente,
    vt.nombre || ' ' || vt.apellido_p AS visitante,
    vt.relacion,
    v.id_sede AS id_sucursal,
    s.nombre_sede AS nombre_sucursal
FROM visitas v
JOIN pacientes p ON p.id_paciente = v.id_paciente
JOIN visitantes vt ON vt.id_visitante = v.id_visitante
JOIN sedes s ON s.id_sede = v.id_sede
ORDER BY v.fecha_entrada DESC, v.hora_entrada DESC;


-- -----------------------------------------------------------------------------
-- 13. Entregas externas con paciente y visitante que las trajo
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_entregas_externas AS
SELECT
    ee.id_entrega,
    ee.id_paciente,
    ee.descripcion,
    ee.estado,
    TO_CHAR(ee.fecha_recepcion, 'YYYY-MM-DD') AS fecha,
    ee.hora_recepcion,
    p.nombre || ' ' || p.apellido_p AS paciente,
    vt.nombre || ' ' || vt.apellido_p AS visitante
FROM entregas_externas ee
JOIN pacientes p ON p.id_paciente = ee.id_paciente
JOIN visitantes vt ON vt.id_visitante = ee.id_visitante
ORDER BY ee.fecha_recepcion DESC;


-- -----------------------------------------------------------------------------
-- 14. Medicamentos por receta con estadísticas de adherencia NFC (30 días)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_receta_medicamentos AS
SELECT
    rm.id_detalle,
    rm.id_receta,
    rm.gtin,
    m.nombre_medicamento,
    rm.dosis,
    rm.frecuencia_horas,
    COUNT(ln.id_lectura_nfc) AS total_lecturas,
    COUNT(ln.id_lectura_nfc) FILTER (WHERE ln.resultado = 'Exitosa') AS exitosas,
    COUNT(ln.id_lectura_nfc) FILTER (
        WHERE ln.resultado = 'Exitosa'
          AND ln.fecha_hora >= CURRENT_DATE - INTERVAL '30 days'
    ) AS exitosas_30d
FROM receta_medicamentos rm
JOIN medicamentos m ON m.gtin = rm.gtin
LEFT JOIN receta_nfc rn ON rn.id_receta = rm.id_receta AND rn.fecha_fin_gestion IS NULL
LEFT JOIN lecturas_nfc ln ON ln.id_receta = rm.id_receta AND ln.id_dispositivo = rn.id_dispositivo
GROUP BY rm.id_detalle, rm.id_receta, rm.gtin, m.nombre_medicamento, rm.dosis, rm.frecuencia_horas
ORDER BY rm.id_receta, m.nombre_medicamento;


-- -----------------------------------------------------------------------------
-- 15. NFC activo por receta con serial del dispositivo
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_nfc_activo AS
SELECT
    rn.id_receta,
    rn.id_dispositivo,
    d.id_serial,
    TO_CHAR(rn.fecha_inicio_gestion, 'DD/MM/YYYY') AS desde,
    rn.fecha_fin_gestion
FROM receta_nfc rn
JOIN dispositivos d ON d.id_dispositivo = rn.id_dispositivo
WHERE rn.fecha_fin_gestion IS NULL;


-- -----------------------------------------------------------------------------
-- 16. Asignaciones beacon activas con cuidador
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_asignacion_beacon AS
SELECT
    ab.id_asignacion,
    ab.id_dispositivo,
    d.id_serial AS serial_beacon,
    d.modelo,
    ab.id_cuidador,
    e.nombre || ' ' || e.apellido_p AS nombre_cuidador,
    e.telefono,
    TO_CHAR(ab.fecha_inicio, 'YYYY-MM-DD') AS fecha_inicio
FROM asignacion_beacon ab
JOIN dispositivos d ON d.id_dispositivo = ab.id_dispositivo
JOIN empleados e ON e.id_empleado = ab.id_cuidador
WHERE ab.fecha_fin IS NULL
ORDER BY ab.id_asignacion;


-- -----------------------------------------------------------------------------
-- 17. Cuidadores actualmente asignados a cada paciente activo
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_cuidadores_asignados AS
SELECT
    ac.id_paciente,
    p.nombre || ' ' || p.apellido_p AS nombre_paciente,
    e.nombre AS nombre_cuidador,
    e.apellido_p,
    e.apellido_m,
    e.telefono AS telefono_cuid,
    TO_CHAR(ac.fecha_inicio, 'YYYY-MM-DD') AS fecha_asig_cuidador
FROM asignacion_cuidador ac
JOIN pacientes p ON p.id_paciente = ac.id_paciente
JOIN cuidadores c ON c.id_empleado = ac.id_cuidador
JOIN empleados e ON e.id_empleado = c.id_empleado
WHERE ac.fecha_fin IS NULL
ORDER BY ac.id_paciente;


-- -----------------------------------------------------------------------------
-- 18. Medicamentos activos por paciente desde recetas vigentes
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_medicamentos_por_paciente AS
SELECT
    r.id_paciente,
    p.nombre || ' ' || p.apellido_p AS nombre_paciente,
    r.id_receta,
    m.nombre_medicamento AS medicamento,
    rm.dosis,
    rm.frecuencia_horas
FROM recetas r
JOIN receta_medicamentos rm ON rm.id_receta = r.id_receta
JOIN medicamentos m ON m.gtin = rm.gtin
JOIN pacientes p ON p.id_paciente = r.id_paciente
WHERE r.estado = 'Activa'
ORDER BY r.id_paciente, m.nombre_medicamento;


-- -----------------------------------------------------------------------------
-- 19. Contactos de emergencia con prioridad por paciente
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_contactos_emergencia AS
SELECT
    pc.id_paciente,
    p.nombre || ' ' || p.apellido_p AS nombre_paciente,
    pc.prioridad,
    ce.id_contacto,
    ce.nombre,
    ce.apellido_p,
    ce.nombre || ' ' || ce.apellido_p AS nombre_completo,
    ce.telefono,
    ce.relacion
FROM paciente_contactos pc
JOIN pacientes p ON p.id_paciente = pc.id_paciente
JOIN contactos_emergencia ce ON ce.id_contacto = pc.id_contacto
ORDER BY pc.id_paciente, pc.prioridad;


-- -----------------------------------------------------------------------------
-- 20. Últimas lecturas GPS por paciente activo (una fila por paciente)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_ultima_lectura_gps AS
SELECT DISTINCT ON (ak.id_paciente)
    ak.id_paciente,
    p.nombre || ' ' || p.apellido_p AS nombre_paciente,
    lg.id_lectura,
    lg.latitud,
    lg.longitud,
    lg.nivel_bateria,
    lg.altura,
    lg.fecha_hora AS ts,
    TO_CHAR(lg.fecha_hora, 'YYYY-MM-DD') AS fecha,
    TO_CHAR(lg.fecha_hora, 'HH24:MI') AS hora,
    d.id_serial AS serial_gps
FROM asignacion_kit ak
JOIN pacientes p ON p.id_paciente = ak.id_paciente
JOIN lecturas_gps lg ON lg.id_dispositivo = ak.id_dispositivo_gps
JOIN dispositivos d ON d.id_dispositivo = ak.id_dispositivo_gps
WHERE ak.fecha_fin IS NULL
ORDER BY ak.id_paciente, lg.fecha_hora DESC;


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
    RAISE NOTICE '✓ v_suministros';
    RAISE NOTICE '✓ v_visitas';
    RAISE NOTICE '✓ v_entregas_externas';
    RAISE NOTICE '✓ v_receta_medicamentos';
    RAISE NOTICE '✓ v_nfc_activo';
    RAISE NOTICE '✓ v_asignacion_beacon';
    RAISE NOTICE '✓ v_cuidadores_asignados';
    RAISE NOTICE '✓ v_medicamentos_por_paciente';
    RAISE NOTICE '✓ v_contactos_emergencia';
    RAISE NOTICE '✓ v_ultima_lectura_gps';
    RAISE NOTICE '20 vistas aplicadas correctamente.';
END;
$$;
