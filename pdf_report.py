"""
pdf_report.py — ReportLab PDF generation for AlzMonitor patient reports.
"""
from io import BytesIO
from datetime import datetime, date

from reportlab.lib.pagesizes import LETTER
from reportlab.lib.units import inch, cm
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether,
)
from reportlab.lib.enums import TA_LEFT, TA_RIGHT, TA_CENTER

import db as _db

# ── Palette ──────────────────────────────────────────────────────────────────
TEAL      = colors.HexColor("#0E7490")
TEAL_DARK = colors.HexColor("#082F3E")
TEAL_LIGHT= colors.HexColor("#CFFAFE")
SLATE     = colors.HexColor("#334155")
MUTED     = colors.HexColor("#64748B")
BG_ROW    = colors.HexColor("#F0F9FF")
RED_LIGHT = colors.HexColor("#FFF1F2")
RED_TEXT  = colors.HexColor("#BE123C")
GREEN_BG  = colors.HexColor("#ECFDF5")
GREEN_TEXT= colors.HexColor("#065F46")
AMBER_BG  = colors.HexColor("#FFFBEB")
AMBER_TEXT= colors.HexColor("#92400E")
WHITE     = colors.white
BLACK     = colors.black

PAGE_W, PAGE_H = LETTER
MARGIN = 0.75 * inch

# ── Paragraph styles ─────────────────────────────────────────────────────────
def _styles():
    base = ParagraphStyle("base", fontName="Helvetica", fontSize=9,
                          leading=13, textColor=SLATE)
    return {
        "h1": ParagraphStyle("h1", fontName="Helvetica-Bold", fontSize=18,
                             leading=22, textColor=WHITE),
        "h1sub": ParagraphStyle("h1sub", fontName="Helvetica", fontSize=10,
                                leading=14, textColor=colors.HexColor("#A5F3FC")),
        "section": ParagraphStyle("section", fontName="Helvetica-Bold",
                                  fontSize=10, leading=14, textColor=TEAL,
                                  spaceBefore=6, spaceAfter=4),
        "body": base,
        "small": ParagraphStyle("small", fontName="Helvetica", fontSize=8,
                                leading=11, textColor=MUTED),
        "label": ParagraphStyle("label", fontName="Helvetica-Bold", fontSize=8,
                                leading=10, textColor=MUTED),
        "value": ParagraphStyle("value", fontName="Helvetica-Bold", fontSize=10,
                                leading=14, textColor=TEAL_DARK),
        "footer": ParagraphStyle("footer", fontName="Helvetica", fontSize=7.5,
                                 leading=10, textColor=MUTED, alignment=TA_CENTER),
        "badge_red":   ParagraphStyle("br", fontName="Helvetica-Bold", fontSize=8,
                                      textColor=RED_TEXT),
        "badge_green": ParagraphStyle("bg", fontName="Helvetica-Bold", fontSize=8,
                                      textColor=GREEN_TEXT),
        "badge_amber": ParagraphStyle("ba", fontName="Helvetica-Bold", fontSize=8,
                                      textColor=AMBER_TEXT),
    }


# ── Table helpers ─────────────────────────────────────────────────────────────
def _th_style(col_count):
    return TableStyle([
        ("BACKGROUND",   (0, 0), (-1, 0), TEAL),
        ("TEXTCOLOR",    (0, 0), (-1, 0), WHITE),
        ("FONTNAME",     (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE",     (0, 0), (-1, 0), 8),
        ("TOPPADDING",   (0, 0), (-1, 0), 5),
        ("BOTTOMPADDING",(0, 0), (-1, 0), 5),
        ("LEFTPADDING",  (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("FONTNAME",     (0, 1), (-1, -1), "Helvetica"),
        ("FONTSIZE",     (0, 1), (-1, -1), 8),
        ("TOPPADDING",   (0, 1), (-1, -1), 5),
        ("BOTTOMPADDING",(0, 1), (-1, -1), 5),
        ("TEXTCOLOR",    (0, 1), (-1, -1), SLATE),
        ("ROWBACKGROUNDS",(0, 1),(-1, -1), [WHITE, BG_ROW]),
        ("GRID",         (0, 0), (-1, -1), 0.3, colors.HexColor("#E0F2FE")),
        ("BOX",          (0, 0), (-1, -1), 0.5, colors.HexColor("#BAE6FD")),
    ])


def _kv_table(pairs, s):
    """Two-column label/value table for metadata blocks."""
    data = []
    for label, value in pairs:
        data.append([Paragraph(label, s["label"]), Paragraph(str(value), s["value"])])
    t = Table(data, colWidths=[1.6*inch, None])
    t.setStyle(TableStyle([
        ("VALIGN",       (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING",  (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING",   (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 3),
    ]))
    return t


# ── Header / footer callbacks ─────────────────────────────────────────────────
class _HeaderFooter:
    def __init__(self, title, generated, sede):
        self.title = title
        self.generated = generated
        self.sede = sede

    def __call__(self, canvas, doc):
        c = canvas
        w = PAGE_W
        c.saveState()

        # ── Header band ───────────────────────────────────────────────────────
        c.setFillColor(TEAL_DARK)
        c.rect(0, PAGE_H - 0.65*inch, w, 0.65*inch, fill=1, stroke=0)
        c.setFillColor(TEAL)
        c.rect(0, PAGE_H - 0.68*inch, w, 0.04*inch, fill=1, stroke=0)

        c.setFillColor(WHITE)
        c.setFont("Helvetica-Bold", 11)
        c.drawString(MARGIN, PAGE_H - 0.38*inch, "AlzMonitor — Reporte de Paciente")
        c.setFont("Helvetica", 8)
        c.setFillColor(colors.HexColor("#A5F3FC"))
        c.drawString(MARGIN, PAGE_H - 0.54*inch, self.sede)

        # right side: generated + page
        c.setFont("Helvetica", 7.5)
        c.setFillColor(colors.HexColor("#A5F3FC"))
        c.drawRightString(w - MARGIN, PAGE_H - 0.38*inch,
                          f"Generado: {self.generated}")
        c.drawRightString(w - MARGIN, PAGE_H - 0.52*inch,
                          f"Página {doc.page}")

        # ── Footer line ───────────────────────────────────────────────────────
        c.setStrokeColor(colors.HexColor("#E0F2FE"))
        c.setLineWidth(0.5)
        c.line(MARGIN, 0.5*inch, w - MARGIN, 0.5*inch)
        c.setFont("Helvetica", 7)
        c.setFillColor(MUTED)
        c.drawCentredString(w/2, 0.33*inch,
                            "Documento confidencial — uso exclusivo del personal autorizado de AlzMonitor")
        c.restoreState()


# ── Data fetchers ─────────────────────────────────────────────────────────────
def _fetch(patient_id):
    pid = patient_id

    paciente = _db.one("""
        SELECT p.id_paciente, p.nombre, p.apellido_p, p.apellido_m,
               p.fecha_nacimiento, ep.desc_estado
        FROM pacientes p
        JOIN estados_paciente ep ON p.id_estado = ep.id_estado
        WHERE p.id_paciente = %s
    """, (pid,))

    sede = _db.one("""
        SELECT s.nombre_sede, sp.fecha_ingreso
        FROM sede_pacientes sp
        JOIN sedes s ON sp.id_sede = s.id_sede
        WHERE sp.id_paciente = %s AND sp.fecha_salida IS NULL
        LIMIT 1
    """, (pid,))

    enfermedades = _db.query("""
        SELECT e.nombre_enfermedad,
               TO_CHAR(te.fecha_diag, 'DD/MM/YYYY') AS fecha_diag
        FROM tiene_enfermedad te
        JOIN enfermedades e ON te.id_enfermedad = e.id_enfermedad
        WHERE te.id_paciente = %s
        ORDER BY te.fecha_diag
    """, (pid,))

    cuidadores = _db.query("""
        SELECT e.nombre, e.apellido_p, e.apellido_m, e.telefono,
               TO_CHAR(ac.fecha_inicio, 'DD/MM/YYYY') AS fecha_inicio
        FROM asignacion_cuidador ac
        JOIN cuidadores c ON ac.id_cuidador = c.id_empleado
        JOIN empleados e  ON c.id_empleado  = e.id_empleado
        WHERE ac.id_paciente = %s AND ac.fecha_fin IS NULL
        ORDER BY e.apellido_p
    """, (pid,))

    contactos = _db.query("""
        SELECT ce.nombre, ce.relacion, ce.telefono, pc.prioridad
        FROM paciente_contactos pc
        JOIN contactos_emergencia ce ON pc.id_contacto = ce.id_contacto
        WHERE pc.id_paciente = %s
        ORDER BY pc.prioridad
    """, (pid,))

    kit = _db.one("""
        SELECT gps.id_serial AS codigo_gps,
               TO_CHAR(ak.fecha_entrega, 'DD/MM/YYYY') AS fecha_entrega,
               lg.nivel_bateria
        FROM asignacion_kit ak
        JOIN dispositivos gps ON ak.id_dispositivo_gps = gps.id_dispositivo
        LEFT JOIN LATERAL (
            SELECT nivel_bateria FROM lecturas_gps
            WHERE id_dispositivo = gps.id_dispositivo
            ORDER BY fecha_hora DESC LIMIT 1
        ) lg ON true
        WHERE ak.id_paciente = %s AND ak.fecha_fin IS NULL
        LIMIT 1
    """, (pid,))

    alertas = _db.query("""
        SELECT a.tipo_alerta, a.estatus,
               TO_CHAR(a.fecha_hora, 'DD/MM/YYYY') AS fecha,
               TO_CHAR(a.fecha_hora, 'HH24:MI')    AS hora
        FROM alertas a
        WHERE a.id_paciente = %s
          AND a.fecha_hora >= NOW() - INTERVAL '30 days'
        ORDER BY a.fecha_hora DESC
    """, (pid,))

    recetas = _db.query("""
        SELECT r.id_receta, m.nombre_medicamento, rm.dosis,
               rm.frecuencia_horas || ' h' AS frecuencia,
               (
                   SELECT COUNT(*) FROM lecturas_nfc ln
                   WHERE ln.id_receta = r.id_receta
                     AND ln.fecha_hora >= NOW() - INTERVAL '7 days'
               ) AS tomas_7d
        FROM recetas r
        JOIN receta_medicamentos rm ON r.id_receta = rm.id_receta
        JOIN medicamentos m ON rm.gtin = m.gtin
        WHERE r.id_paciente = %s AND r.estado = 'Activa'
        ORDER BY m.nombre_medicamento
    """, (pid,))

    ubicacion = _db.query("""
        SELECT TO_CHAR(fecha_hora, 'DD/MM/YYYY') AS fecha,
               TO_CHAR(fecha_hora, 'HH24:MI')   AS hora,
               latitud, longitud, nivel_bateria
        FROM lecturas_gps lg
        JOIN asignacion_kit ak ON lg.id_dispositivo = ak.id_dispositivo_gps
        WHERE ak.id_paciente = %s AND ak.fecha_fin IS NULL
          AND lg.fecha_hora >= NOW() - INTERVAL '7 days'
        ORDER BY lg.fecha_hora DESC
        LIMIT 10
    """, (pid,))

    return paciente, sede, enfermedades, cuidadores, contactos, kit, alertas, recetas, ubicacion


# ── Main builder ──────────────────────────────────────────────────────────────
def generate_patient_report(patient_id: int) -> BytesIO:
    buf = BytesIO()
    s = _styles()
    generated = datetime.now().strftime("%d/%m/%Y %H:%M")

    (paciente, sede, enfermedades, cuidadores, contactos,
     kit, alertas, recetas, ubicacion) = _fetch(patient_id)

    sede_nombre = sede["nombre_sede"] if sede else "Sede no asignada"

    doc = SimpleDocTemplate(
        buf,
        pagesize=LETTER,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=0.85*inch, bottomMargin=0.7*inch,
    )

    hf = _HeaderFooter(
        title="Reporte de Paciente",
        generated=generated,
        sede=sede_nombre,
    )

    story = []

    # ── Patient identity card ─────────────────────────────────────────────────
    full_name = (f"{paciente['nombre']} {paciente['apellido_p']} "
                 f"{paciente['apellido_m'] or ''}").strip()
    fn = paciente["fecha_nacimiento"]
    if isinstance(fn, (date, datetime)):
        dob = fn.strftime("%d/%m/%Y")
        age = (date.today() - fn).days // 365
    else:
        dob = str(fn)
        age = "—"

    id_card_data = [
        [
            Paragraph("PACIENTE", s["label"]),
            Paragraph("ID", s["label"]),
            Paragraph("FECHA DE NACIMIENTO", s["label"]),
            Paragraph("EDAD", s["label"]),
            Paragraph("ESTADO", s["label"]),
            Paragraph("SEDE", s["label"]),
        ],
        [
            Paragraph(full_name, s["value"]),
            Paragraph(str(paciente["id_paciente"]), s["value"]),
            Paragraph(dob, s["value"]),
            Paragraph(f"{age} años", s["value"]),
            Paragraph(paciente["desc_estado"], s["value"]),
            Paragraph(sede_nombre, s["value"]),
        ],
    ]
    id_table = Table(id_card_data,
                     colWidths=[2.3*inch, 0.6*inch, 1.4*inch,
                                0.7*inch, 0.9*inch, 1.3*inch])
    id_table.setStyle(TableStyle([
        ("BACKGROUND",   (0, 0), (-1, 0), colors.HexColor("#F0F9FF")),
        ("BACKGROUND",   (0, 1), (-1, 1), WHITE),
        ("BOX",          (0, 0), (-1, -1), 0.6, colors.HexColor("#BAE6FD")),
        ("LINEBELOW",    (0, 0), (-1, 0), 0.5, colors.HexColor("#BAE6FD")),
        ("GRID",         (0, 0), (-1, -1), 0.3, colors.HexColor("#E0F2FE")),
        ("TOPPADDING",   (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 6),
        ("LEFTPADDING",  (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("VALIGN",       (0, 0), (-1, -1), "TOP"),
        ("ROUNDEDCORNERS", [4]),
    ]))
    story.append(id_table)
    story.append(Spacer(1, 14))

    # ── Section: Dispositivo GPS ──────────────────────────────────────────────
    story.append(Paragraph("Dispositivo GPS Asignado", s["section"]))
    story.append(HRFlowable(width="100%", thickness=0.5,
                            color=colors.HexColor("#BAE6FD"), spaceAfter=6))
    if kit:
        bat = kit["nivel_bateria"]
        bat_str = f"{bat}%" if bat is not None else "Sin datos"
        pairs = [
            ("Serial / código GPS", kit["codigo_gps"] or "—"),
            ("Fecha de entrega",    kit["fecha_entrega"] or "—"),
            ("Batería (última lectura)", bat_str),
        ]
        story.append(_kv_table(pairs, s))
    else:
        story.append(Paragraph("Sin kit GPS asignado.", s["small"]))
    story.append(Spacer(1, 14))

    # ── Section: Enfermedades ─────────────────────────────────────────────────
    story.append(Paragraph("Enfermedades Diagnosticadas", s["section"]))
    story.append(HRFlowable(width="100%", thickness=0.5,
                            color=colors.HexColor("#BAE6FD"), spaceAfter=6))
    if enfermedades:
        rows = [["Enfermedad", "Fecha de diagnóstico"]]
        for e in enfermedades:
            rows.append([e["nombre_enfermedad"], e["fecha_diag"] or "—"])
        t = Table(rows, colWidths=[4.5*inch, 1.8*inch])
        t.setStyle(_th_style(2))
        story.append(t)
    else:
        story.append(Paragraph("Sin enfermedades registradas.", s["small"]))
    story.append(Spacer(1, 14))

    # ── Section: Cuidadores ───────────────────────────────────────────────────
    story.append(Paragraph("Cuidadores Activos", s["section"]))
    story.append(HRFlowable(width="100%", thickness=0.5,
                            color=colors.HexColor("#BAE6FD"), spaceAfter=6))
    if cuidadores:
        rows = [["Nombre", "Teléfono", "Asignado desde"]]
        for c in cuidadores:
            nombre = f"{c['nombre']} {c['apellido_p']} {c['apellido_m'] or ''}".strip()
            rows.append([nombre, c["telefono"] or "—", c["fecha_inicio"] or "—"])
        t = Table(rows, colWidths=[3*inch, 1.5*inch, 1.8*inch])
        t.setStyle(_th_style(3))
        story.append(t)
    else:
        story.append(Paragraph("Sin cuidadores asignados.", s["small"]))
    story.append(Spacer(1, 14))

    # ── Section: Contactos de emergencia ─────────────────────────────────────
    story.append(Paragraph("Contactos de Emergencia", s["section"]))
    story.append(HRFlowable(width="100%", thickness=0.5,
                            color=colors.HexColor("#BAE6FD"), spaceAfter=6))
    if contactos:
        rows = [["Nombre", "Relación", "Teléfono", "Prioridad"]]
        for ct in contactos:
            rows.append([ct["nombre"], ct["relacion"] or "—",
                         ct["telefono"] or "—", str(ct["prioridad"])])
        t = Table(rows, colWidths=[2.5*inch, 1.5*inch, 1.5*inch, 0.8*inch])
        t.setStyle(_th_style(4))
        story.append(t)
    else:
        story.append(Paragraph("Sin contactos registrados.", s["small"]))
    story.append(Spacer(1, 14))

    # ── Section: Alertas (30 días) ────────────────────────────────────────────
    story.append(Paragraph("Historial de Alertas — Últimos 30 días", s["section"]))
    story.append(HRFlowable(width="100%", thickness=0.5,
                            color=colors.HexColor("#BAE6FD"), spaceAfter=6))
    if alertas:
        rows = [["Tipo de alerta", "Fecha", "Hora", "Estado"]]
        for a in alertas:
            rows.append([
                a["tipo_alerta"],
                a["fecha"],
                a["hora"],
                a["estatus"],
            ])
        t = Table(rows, colWidths=[3*inch, 1.1*inch, 0.8*inch, 1.4*inch])
        ts = _th_style(4)
        # Color-code estatus column
        for i, a in enumerate(alertas, start=1):
            if a["estatus"] == "Activa":
                ts.add("TEXTCOLOR",  (3, i), (3, i), RED_TEXT)
                ts.add("FONTNAME",   (3, i), (3, i), "Helvetica-Bold")
            else:
                ts.add("TEXTCOLOR",  (3, i), (3, i), GREEN_TEXT)
        t.setStyle(ts)
        story.append(t)
    else:
        story.append(Paragraph("Sin alertas en los últimos 30 días.", s["small"]))
    story.append(Spacer(1, 14))

    # ── Section: Medicamentos y adherencia (7 días) ───────────────────────────
    story.append(Paragraph("Medicación Activa y Adherencia — Últimos 7 días", s["section"]))
    story.append(HRFlowable(width="100%", thickness=0.5,
                            color=colors.HexColor("#BAE6FD"), spaceAfter=6))
    if recetas:
        rows = [["Medicamento", "Dosis", "Frecuencia", "Tomas NFC (7 d)"]]
        for r in recetas:
            rows.append([
                r["nombre_medicamento"],
                r["dosis"] or "—",
                r["frecuencia"] or "—",
                str(r["tomas_7d"]),
            ])
        t = Table(rows, colWidths=[2.8*inch, 1.2*inch, 1.6*inch, 0.7*inch])
        t.setStyle(_th_style(4))
        story.append(t)
    else:
        story.append(Paragraph("Sin recetas activas.", s["small"]))
    story.append(Spacer(1, 14))

    # ── Section: Últimas lecturas GPS (7 días) ────────────────────────────────
    story.append(Paragraph("Últimas Lecturas GPS — 7 días (máx. 10)", s["section"]))
    story.append(HRFlowable(width="100%", thickness=0.5,
                            color=colors.HexColor("#BAE6FD"), spaceAfter=6))
    if ubicacion:
        rows = [["Fecha", "Hora", "Latitud", "Longitud", "Batería"]]
        for u in ubicacion:
            bat = f"{u['nivel_bateria']}%" if u["nivel_bateria"] is not None else "—"
            rows.append([u["fecha"], u["hora"],
                         f"{float(u['latitud']):.6f}",
                         f"{float(u['longitud']):.6f}",
                         bat])
        t = Table(rows, colWidths=[1*inch, 0.65*inch, 1.35*inch, 1.35*inch, 0.85*inch])
        t.setStyle(_th_style(5))
        story.append(t)
    else:
        story.append(Paragraph("Sin lecturas GPS en los últimos 7 días.", s["small"]))

    story.append(Spacer(1, 14))
    story.append(Paragraph(
        f"Fin del reporte — generado el {generated} · AlzMonitor",
        s["footer"]
    ))

    doc.build(story, onFirstPage=hf, onLaterPages=hf)
    buf.seek(0)
    return buf
