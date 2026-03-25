
from datetime import date

SUCURSALES = [
    {
        "id_sucursal": 1,
        "nombre": "Sede Norte",
        "zona": "Zona Metropolitana Norte",
        "direccion": "Av. Insurgentes Norte 2140, CDMX",
        "telefono": "55-4100-0001",
        "director": "Dra. Patricia Vela",
    },
    {
        "id_sucursal": 2,
        "nombre": "Sede Sur",
        "zona": "Zona Metropolitana Sur",
        "direccion": "Calz. de Tlalpan 5500, CDMX",
        "telefono": "55-4100-0002",
        "director": "Dr. Miguel Ángel Fuentes",
    },
]

ESTADOS_PACIENTE = [
    {"id_estado": 1, "desc_estado": "Activo"},
    {"id_estado": 2, "desc_estado": "En tratamiento"},
    {"id_estado": 3, "desc_estado": "Inactivo"},
]

PACIENTES = [
    {
        "id_paciente": 1,
        "nombre_paciente": "María",
        "apellido_p_pac": "García",
        "apellido_m_pac": "López",
        "fecha_nacimiento": date(1945, 3, 12),
        "id_estado": 1,
        "desc_estado": "Activo",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "id_paciente": 2,
        "nombre_paciente": "Roberto",
        "apellido_p_pac": "Hernández",
        "apellido_m_pac": "Soto",
        "fecha_nacimiento": date(1938, 7, 25),
        "id_estado": 2,
        "desc_estado": "En tratamiento",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "id_paciente": 3,
        "nombre_paciente": "Elena",
        "apellido_p_pac": "Ramírez",
        "apellido_m_pac": "Vega",
        "fecha_nacimiento": date(1950, 11, 3),
        "id_estado": 1,
        "desc_estado": "Activo",
        "id_sucursal": 2,
        "nombre_sucursal": "Sede Sur",
    },
    {
        "id_paciente": 4,
        "nombre_paciente": "José",
        "apellido_p_pac": "Torres",
        "apellido_m_pac": "Mendoza",
        "fecha_nacimiento": date(1942, 9, 17),
        "id_estado": 1,
        "desc_estado": "Activo",
        "id_sucursal": 2,
        "nombre_sucursal": "Sede Sur",
    },
]

CUIDADORES = [
    {
        "id_cuidador": 1,
        "nombre_cuidador": "Ana",
        "apellido_p_cuid": "Martínez",
        "apellido_m_cuid": "Ruiz",
        "telefono_cuid": "555-0101",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "id_cuidador": 2,
        "nombre_cuidador": "Carlos",
        "apellido_p_cuid": "Pérez",
        "apellido_m_cuid": "Torres",
        "telefono_cuid": "555-0202",
        "id_sucursal": 2,
        "nombre_sucursal": "Sede Sur",
    },
    {
        "id_cuidador": 3,
        "nombre_cuidador": "Sofía",
        "apellido_p_cuid": "Morales",
        "apellido_m_cuid": "Jiménez",
        "telefono_cuid": "555-0303",
        "id_sucursal": 2,
        "nombre_sucursal": "Sede Sur",
    },
]

ALERTAS_RECIENTES = [
    {
        "tipo_alerta": "Zona peligrosa",
        "estatus_alerta": "Activa",
        "fecha_hora_lectura": "2026-03-24 10:30",
        "paciente": "María García",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "tipo_alerta": "Dispositivo sin señal",
        "estatus_alerta": "Activa",
        "fecha_hora_lectura": "2026-03-24 09:15",
        "paciente": "Roberto Hernández",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "tipo_alerta": "Caída detectada",
        "estatus_alerta": "Resuelta",
        "fecha_hora_lectura": "2026-03-23 18:42",
        "paciente": "Elena Ramírez",
        "id_sucursal": 2,
        "nombre_sucursal": "Sede Sur",
    },
    {
        "tipo_alerta": "Zona peligrosa",
        "estatus_alerta": "Activa",
        "fecha_hora_lectura": "2026-03-23 14:20",
        "paciente": "José Torres",
        "id_sucursal": 2,
        "nombre_sucursal": "Sede Sur",
    },
    {
        "tipo_alerta": "Batería baja",
        "estatus_alerta": "Resuelta",
        "fecha_hora_lectura": "2026-03-22 11:05",
        "paciente": "Roberto Hernández",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
]

# Historial clínico por id_paciente
ENFERMEDADES = {
    1: [
        {"nombre_enfermedad": "Alzheimer etapa temprana", "fecha_diag": "2020-05-10"},
        {"nombre_enfermedad": "Hipertensión arterial",    "fecha_diag": "2018-02-14"},
    ],
    2: [
        {"nombre_enfermedad": "Alzheimer etapa moderada", "fecha_diag": "2019-11-03"},
        {"nombre_enfermedad": "Diabetes tipo 2",          "fecha_diag": "2015-06-20"},
    ],
    3: [
        {"nombre_enfermedad": "Deterioro cognitivo leve", "fecha_diag": "2022-01-08"},
    ],
    4: [
        {"nombre_enfermedad": "Alzheimer etapa temprana", "fecha_diag": "2021-03-22"},
        {"nombre_enfermedad": "Arritmia cardíaca",        "fecha_diag": "2019-08-11"},
    ],
}

DISPOSITIVOS = [
    {
        "id_dispositivo": 1,
        "codigo": "GPS-405",
        "tipo": "Pulsera GPS Tracker",
        "id_paciente": 1,
        "paciente": "María García López",
        "bateria": 85,
        "estatus": "Activo / Transmitiendo",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "id_dispositivo": 2,
        "codigo": "B-102",
        "tipo": "Beacon Habitación",
        "id_paciente": 2,
        "paciente": "Roberto Hernández Soto",
        "bateria": 10,
        "estatus": "Batería crítica",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "id_dispositivo": 3,
        "codigo": "GPS-112",
        "tipo": "Collar GPS",
        "id_paciente": 3,
        "paciente": "Elena Ramírez Vega",
        "bateria": 100,
        "estatus": "Cargando",
        "id_sucursal": 2,
        "nombre_sucursal": "Sede Sur",
    },
    {
        "id_dispositivo": 4,
        "codigo": "NFC-001",
        "tipo": "Sensor NFC Medicación",
        "id_paciente": 1,
        "paciente": "María García López",
        "bateria": 72,
        "estatus": "Activo / Transmitiendo",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "id_dispositivo": 5,
        "codigo": "NFC-002",
        "tipo": "Sensor NFC Medicación",
        "id_paciente": 4,
        "paciente": "José Torres Mendoza",
        "bateria": 55,
        "estatus": "Activo / Transmitiendo",
        "id_sucursal": 2,
        "nombre_sucursal": "Sede Sur",
    },
]

ZONAS = [
    {
        "id_zona": 1,
        "nombre_zona": "Casa - Perímetro principal",
        "id_paciente": 2,
        "paciente": "Roberto Hernández Soto",
        "radio_metros": 15,
        "notificar_a": "Familiares y Cuidador primario",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "id_zona": 2,
        "nombre_zona": "Jardín de Reposo",
        "id_paciente": 1,
        "paciente": "María García López",
        "radio_metros": 30,
        "notificar_a": "Enfermería (Turno matutino)",
        "id_sucursal": 1,
        "nombre_sucursal": "Sede Norte",
    },
    {
        "id_zona": 3,
        "nombre_zona": "Clínica (Terapia Física)",
        "id_paciente": None,
        "paciente": "Todos los pacientes",
        "radio_metros": 50,
        "notificar_a": "Administración Central",
        "id_sucursal": 2,
        "nombre_sucursal": "Sede Sur",
    },
]

# ── Módulo Clínico ────────────────────────────────────────────────────────────

TURNOS_HOY = [
    {
        "id": 1,
        "nombre": "Ana Martínez Ruiz",
        "rol": "Cuidadora",
        "turno": "Matutino",
        "hora_entrada": "07:00",
        "hora_salida": "15:00",
        "estado": "En turno",
        "pacientes_asignados": "María García, José Torres",
    },
    {
        "id": 2,
        "nombre": "Carlos Pérez Torres",
        "rol": "Cuidador",
        "turno": "Vespertino",
        "hora_entrada": "15:00",
        "hora_salida": "23:00",
        "estado": "Pendiente",
        "pacientes_asignados": "Roberto Hernández",
    },
    {
        "id": 3,
        "nombre": "Sofía Morales Jiménez",
        "rol": "Cuidadora",
        "turno": "Nocturno",
        "hora_entrada": "23:00",
        "hora_salida": "07:00",
        "estado": "Pendiente",
        "pacientes_asignados": "Elena Ramírez",
    },
    {
        "id": 4,
        "nombre": "Dr. Ramón Gutiérrez",
        "rol": "Médico de turno",
        "turno": "Matutino",
        "hora_entrada": "08:00",
        "hora_salida": "16:00",
        "estado": "En turno",
        "pacientes_asignados": "Todos",
    },
]

TAREAS_HOY = [
    {"hora": "09:00", "tarea": "Ronda de medicamentos matutina", "responsable": "Ana Martínez", "estado": "Completada"},
    {"hora": "10:30", "tarea": "Sesión de terapia cognitiva — María García", "responsable": "Dr. Gutiérrez", "estado": "Completada"},
    {"hora": "12:00", "tarea": "Ronda de medicamentos mediodía", "responsable": "Ana Martínez", "estado": "Pendiente"},
    {"hora": "14:00", "tarea": "Terapia física — Roberto Hernández", "responsable": "Dr. Gutiérrez", "estado": "Pendiente"},
    {"hora": "20:00", "tarea": "Ronda de medicamentos nocturna", "responsable": "Carlos Pérez", "estado": "Pendiente"},
]

ALERTAS_MEDICAS = [
    {"tipo": "Caída detectada",           "paciente": "Elena Ramírez",   "hora": "18:42", "fecha": "2026-03-23", "gravedad": "Alta",  "estado": "Atendida"},
    {"tipo": "Agitación severa",          "paciente": "Roberto Hernández","hora": "02:15", "fecha": "2026-03-24", "gravedad": "Media", "estado": "En seguimiento"},
    {"tipo": "Medicamento no administrado","paciente": "José Torres",     "hora": "09:05", "fecha": "2026-03-24", "gravedad": "Media", "estado": "Resuelto"},
]

PERFIL_CLINICO = {
    1: {
        "grupo_sanguineo": "O+",
        "alergias": "Penicilina",
        "etapa_alzheimer": "Temprana",
        "peso_kg": 58,
        "talla_cm": 162,
        "medico_tratante": "Dr. Ramón Gutiérrez",
        "contacto_emergencia": "Lucía García (hija) · 555-9901",
    },
    2: {
        "grupo_sanguineo": "A+",
        "alergias": "Ninguna conocida",
        "etapa_alzheimer": "Moderada",
        "peso_kg": 72,
        "talla_cm": 170,
        "medico_tratante": "Dr. Ramón Gutiérrez",
        "contacto_emergencia": "Pedro Hernández (hijo) · 555-9902",
    },
    3: {
        "grupo_sanguineo": "B+",
        "alergias": "Ibuprofeno",
        "etapa_alzheimer": "Leve (deterioro cognitivo)",
        "peso_kg": 55,
        "talla_cm": 158,
        "medico_tratante": "Dr. Ramón Gutiérrez",
        "contacto_emergencia": "Carmen Vega (hermana) · 555-9903",
    },
    4: {
        "grupo_sanguineo": "AB-",
        "alergias": "Sulfonamidas",
        "etapa_alzheimer": "Temprana",
        "peso_kg": 80,
        "talla_cm": 175,
        "medico_tratante": "Dr. Ramón Gutiérrez",
        "contacto_emergencia": "Rosa Mendoza (esposa) · 555-9904",
    },
}

MEDICAMENTOS = {
    1: [
        {"medicamento": "Donepezilo",  "dosis": "10 mg",      "hora": "08:00", "via": "Oral",                "indicacion": "En ayunas",                        "estado_hoy": "Administrado"},
        {"medicamento": "Amlodipino",  "dosis": "5 mg",       "hora": "20:00", "via": "Oral",                "indicacion": "Con alimentos",                    "estado_hoy": "Pendiente"},
    ],
    2: [
        {"medicamento": "Memantina",   "dosis": "20 mg",      "hora": "08:00", "via": "Oral",                "indicacion": "Con o sin alimentos",              "estado_hoy": "Administrado"},
        {"medicamento": "Metformina",  "dosis": "500 mg",     "hora": "13:00", "via": "Oral",                "indicacion": "Con comida",                       "estado_hoy": "Pendiente"},
        {"medicamento": "Lorazepam",   "dosis": "1 mg",       "hora": "22:00", "via": "Oral",                "indicacion": "Solo si hay agitación nocturna",   "estado_hoy": "Pendiente"},
    ],
    3: [
        {"medicamento": "Rivastigmina","dosis": "4.6 mg/24h", "hora": "08:00", "via": "Parche transdérmico", "indicacion": "Aplicar en torso o brazo",         "estado_hoy": "Administrado"},
    ],
    4: [
        {"medicamento": "Donepezilo",  "dosis": "5 mg",       "hora": "08:00", "via": "Oral",                "indicacion": "En ayunas",                        "estado_hoy": "Administrado"},
        {"medicamento": "Amiodarona",  "dosis": "100 mg",     "hora": "13:00", "via": "Oral",                "indicacion": "Con alimentos",                    "estado_hoy": "Pendiente"},
    ],
}

BITACORAS = [
    {
        "id": 1,
        "fecha": "2026-03-24",
        "id_paciente": 1,
        "paciente": "María García López",
        "tipo_sesion": "Terapia cognitiva",
        "terapeuta": "Dr. Ramón Gutiérrez",
        "nota": "La paciente mostró mejora en reconocimiento facial. Respondió positivamente a estímulos musicales del período 1960-1970. Se recomienda continuar con musicoterapia.",
        "estado": "Favorable",
    },
    {
        "id": 2,
        "fecha": "2026-03-24",
        "id_paciente": 2,
        "paciente": "Roberto Hernández Soto",
        "tipo_sesion": "Terapia física",
        "terapeuta": "Dr. Ramón Gutiérrez",
        "nota": "Paciente con alta resistencia durante la sesión. Se detectó agitación al inicio; se pausó 10 minutos. Concluyó sin incidentes. Evaluar ajuste en plan de ejercicio.",
        "estado": "Atención requerida",
    },
    {
        "id": 3,
        "fecha": "2026-03-23",
        "id_paciente": 3,
        "paciente": "Elena Ramírez Vega",
        "tipo_sesion": "Terapia cognitiva",
        "terapeuta": "Dr. Ramón Gutiérrez",
        "nota": "Sesión enfocada en memoria a corto plazo. La paciente recordó 4 de 6 objetos presentados. Mejora respecto a sesión anterior (2 de 6). Progreso sostenido.",
        "estado": "Favorable",
    },
    {
        "id": 4,
        "fecha": "2026-03-22",
        "id_paciente": 4,
        "paciente": "José Torres Mendoza",
        "tipo_sesion": "Evaluación médica",
        "terapeuta": "Dr. Ramón Gutiérrez",
        "nota": "Revisión mensual de rutina. PA: 128/82 mmHg. Glucosa en ayunas: 94 mg/dL. Medicación actual bien tolerada. Próxima revisión en 30 días.",
        "estado": "Estable",
    },
]

INCIDENTES = [
    {
        "id": 1,
        "fecha": "2026-03-23",
        "hora": "18:42",
        "id_paciente": 3,
        "paciente": "Elena Ramírez Vega",
        "tipo": "Caída detectada",
        "descripcion": "El dispositivo GPS detectó movimiento brusco. La paciente fue encontrada en el pasillo sin lesiones visibles. Se realizó evaluación física completa.",
        "accion_tomada": "Evaluación médica inmediata. Sin fracturas. Ajuste de plan de supervisión nocturna.",
        "gravedad": "Alta",
    },
    {
        "id": 2,
        "fecha": "2026-03-24",
        "hora": "02:15",
        "id_paciente": 2,
        "paciente": "Roberto Hernández Soto",
        "tipo": "Abandono de zona nocturno",
        "descripcion": "Salida del perímetro establecido durante horario nocturno. El paciente fue localizado en el jardín exterior a 14°C.",
        "accion_tomada": "Paciente reubicado de forma segura. Se evalúa prescribir melatonina o ajustar dosis de Lorazepam para mejora del ciclo de sueño.",
        "gravedad": "Media",
    },
    {
        "id": 3,
        "fecha": "2026-03-24",
        "hora": "09:05",
        "id_paciente": 4,
        "paciente": "José Torres Mendoza",
        "tipo": "Medicamento no administrado",
        "descripcion": "El sensor NFC no registró lectura en la ronda de las 08:00. El cuidador confirmó que el paciente rechazó tomar el medicamento.",
        "accion_tomada": "Medicamento administrado a las 09:15 con apoyo del equipo. Se documenta para evaluar adherencia al tratamiento.",
        "gravedad": "Media",
    },
]

# ── Contactos de emergencia por id_paciente ───────────────────────────────────
CONTACTOS_EMERGENCIA = {
    1: [
        {"nombre": "Lucía García Martínez",   "relacion": "Hija",   "telefono": "555-9901", "prioridad": 1},
    ],
    2: [
        {"nombre": "Pedro Hernández Soto",    "relacion": "Hijo",   "telefono": "555-9902", "prioridad": 1},
        {"nombre": "Laura Hernández Cruz",    "relacion": "Nuera",  "telefono": "555-9910", "prioridad": 2},
    ],
    3: [
        {"nombre": "Carmen Vega Ruiz",        "relacion": "Hermana","telefono": "555-9903", "prioridad": 1},
    ],
    4: [
        {"nombre": "Rosa Mendoza Vargas",     "relacion": "Esposa", "telefono": "555-9904", "prioridad": 1},
        {"nombre": "Jorge Torres Mendoza",    "relacion": "Hijo",   "telefono": "555-9911", "prioridad": 2},
    ],
}

# ── Registro de ingreso a sede por id_paciente ────────────────────────────────
SEDE_PACIENTES = {
    1: {"id_sede": 1, "nombre_sede": "Sede Norte", "fecha_ingreso": "2020-06-01", "hora_ingreso": "09:30"},
    2: {"id_sede": 1, "nombre_sede": "Sede Norte", "fecha_ingreso": "2019-12-15", "hora_ingreso": "11:00"},
    3: {"id_sede": 2, "nombre_sede": "Sede Sur",   "fecha_ingreso": "2022-02-10", "hora_ingreso": "10:15"},
    4: {"id_sede": 2, "nombre_sede": "Sede Sur",   "fecha_ingreso": "2021-04-05", "hora_ingreso": "14:00"},
}

# ── Kit GPS + Beacon asignado por id_paciente ─────────────────────────────────
ASIGNACION_KIT = {
    1: {"codigo_gps": "GPS-405", "codigo_beacon": "B-101", "codigo_nfc": "NFC-001", "fecha_entrega": "2020-06-01"},
    2: {"codigo_gps": "GPS-302", "codigo_beacon": "B-102", "codigo_nfc": None,      "fecha_entrega": "2019-12-15"},
    3: {"codigo_gps": "GPS-112", "codigo_beacon": "B-201", "codigo_nfc": None,      "fecha_entrega": "2022-02-10"},
    4: {"codigo_gps": "GPS-203", "codigo_beacon": "B-202", "codigo_nfc": "NFC-002", "fecha_entrega": "2021-04-05"},
}

# ── Visitantes registrados ────────────────────────────────────────────────────
VISITANTES = [
    {"id_visitante": 1, "nombre": "Lucía",     "apellido_p": "García",    "apellido_m": "Martínez", "relacion": "Hija",   "telefono": "555-9901"},
    {"id_visitante": 2, "nombre": "Pedro",     "apellido_p": "Hernández", "apellido_m": "Soto",     "relacion": "Hijo",   "telefono": "555-9902"},
    {"id_visitante": 3, "nombre": "Carmen",    "apellido_p": "Vega",      "apellido_m": "Ruiz",     "relacion": "Hermana","telefono": "555-9903"},
    {"id_visitante": 4, "nombre": "Rosa",      "apellido_p": "Mendoza",   "apellido_m": "Vargas",   "relacion": "Esposa", "telefono": "555-9904"},
    {"id_visitante": 5, "nombre": "Jorge",     "apellido_p": "Torres",    "apellido_m": "Mendoza",  "relacion": "Hijo",   "telefono": "555-9911"},
]

# ── Visitas (recientes + hoy) ─────────────────────────────────────────────────
VISITAS = [
    {"id_visita": 1, "id_paciente": 1, "paciente": "María García López",    "visitante": "Lucía García Martínez",  "relacion": "Hija",    "id_sucursal": 1, "nombre_sucursal": "Sede Norte", "fecha_entrada": "2026-03-24", "hora_entrada": "10:00", "fecha_salida": "2026-03-24", "hora_salida": "12:30"},
    {"id_visita": 2, "id_paciente": 2, "paciente": "Roberto Hernández Soto","visitante": "Pedro Hernández Soto",   "relacion": "Hijo",    "id_sucursal": 1, "nombre_sucursal": "Sede Norte", "fecha_entrada": "2026-03-24", "hora_entrada": "16:00", "fecha_salida": None,         "hora_salida": None},
    {"id_visita": 3, "id_paciente": 4, "paciente": "José Torres Mendoza",   "visitante": "Rosa Mendoza Vargas",    "relacion": "Esposa",  "id_sucursal": 2, "nombre_sucursal": "Sede Sur",   "fecha_entrada": "2026-03-23", "hora_entrada": "14:00", "fecha_salida": "2026-03-23", "hora_salida": "16:00"},
    {"id_visita": 4, "id_paciente": 3, "paciente": "Elena Ramírez Vega",    "visitante": "Carmen Vega Ruiz",       "relacion": "Hermana", "id_sucursal": 2, "nombre_sucursal": "Sede Sur",   "fecha_entrada": "2026-03-22", "hora_entrada": "11:00", "fecha_salida": "2026-03-22", "hora_salida": "13:00"},
    {"id_visita": 5, "id_paciente": 1, "paciente": "María García López",    "visitante": "Lucía García Martínez",  "relacion": "Hija",    "id_sucursal": 1, "nombre_sucursal": "Sede Norte", "fecha_entrada": "2026-03-17", "hora_entrada": "10:00", "fecha_salida": "2026-03-17", "hora_salida": "11:45"},
]

# ── Entregas externas ─────────────────────────────────────────────────────────
ENTREGAS_EXTERNAS = [
    {"id_entrega": 1, "id_paciente": 1, "paciente": "María García López",    "visitante": "Lucía García Martínez",  "descripcion": "Ropa de temporada (2 blusas, 1 pantalón)", "estado": "Recibido",  "fecha": "2026-03-24", "hora": "10:15", "cuidador_receptor": "Ana Martínez"},
    {"id_entrega": 2, "id_paciente": 4, "paciente": "José Torres Mendoza",   "visitante": "Rosa Mendoza Vargas",    "descripcion": "Libro ilustrado y tableta de chocolate",   "estado": "Recibido",  "fecha": "2026-03-23", "hora": "14:10", "cuidador_receptor": "Ana Martínez"},
    {"id_entrega": 3, "id_paciente": 2, "paciente": "Roberto Hernández Soto","visitante": "Pedro Hernández Soto",   "descripcion": "Medicamento externo (requiere autorización médica)", "estado": "Pendiente", "fecha": "2026-03-24", "hora": "16:05", "cuidador_receptor": None},
]

# ── Farmacia ──────────────────────────────────────────────────────────────────

FARMACIAS_PROVEEDORAS = [
    {"id_farmacia": 1, "nombre": "Farmacia del Ahorro (Mayoreo)", "telefono": "55-6000-0001", "municipio": "Cuauhtémoc", "estado": "CDMX", "RFC": "FAH800101XX1"},
    {"id_farmacia": 2, "nombre": "Genéricos Lacasa",              "telefono": "55-6000-0002", "municipio": "Tlalpan",    "estado": "CDMX", "RFC": "GLA950615XX2"},
]

INVENTARIO_MEDICINAS = [
    # Sede Norte
    {"GTIN": "7501234001", "nombre_medicamento": "Donepezilo 10 mg",             "id_sede": 1, "nombre_sede": "Sede Norte", "stock_actual": 28, "stock_minimo": 30},
    {"GTIN": "7501234002", "nombre_medicamento": "Memantina 20 mg",              "id_sede": 1, "nombre_sede": "Sede Norte", "stock_actual": 45, "stock_minimo": 20},
    {"GTIN": "7501234003", "nombre_medicamento": "Lorazepam 1 mg",               "id_sede": 1, "nombre_sede": "Sede Norte", "stock_actual":  8, "stock_minimo": 15},
    {"GTIN": "7501234004", "nombre_medicamento": "Metformina 500 mg",            "id_sede": 1, "nombre_sede": "Sede Norte", "stock_actual": 60, "stock_minimo": 30},
    {"GTIN": "7501234005", "nombre_medicamento": "Amlodipino 5 mg",              "id_sede": 1, "nombre_sede": "Sede Norte", "stock_actual": 22, "stock_minimo": 20},
    # Sede Sur
    {"GTIN": "7501234006", "nombre_medicamento": "Rivastigmina parche 4.6 mg",   "id_sede": 2, "nombre_sede": "Sede Sur",   "stock_actual": 12, "stock_minimo": 10},
    {"GTIN": "7501234007", "nombre_medicamento": "Donepezilo 5 mg",              "id_sede": 2, "nombre_sede": "Sede Sur",   "stock_actual":  5, "stock_minimo": 20},
    {"GTIN": "7501234008", "nombre_medicamento": "Amiodarona 100 mg",            "id_sede": 2, "nombre_sede": "Sede Sur",   "stock_actual": 18, "stock_minimo": 15},
]

SUMINISTROS = [
    {"id_suministro": 1, "farmacia": "Farmacia del Ahorro (Mayoreo)", "id_sede": 1, "nombre_sede": "Sede Norte", "fecha_entrega": "2026-03-26", "estado": "Pendiente",  "medicamentos": ["Donepezilo 10 mg × 60", "Lorazepam 1 mg × 30"]},
    {"id_suministro": 2, "farmacia": "Genéricos Lacasa",              "id_sede": 2, "nombre_sede": "Sede Sur",   "fecha_entrega": "2026-03-25", "estado": "Pendiente",  "medicamentos": ["Donepezilo 5 mg × 40"]},
    {"id_suministro": 3, "farmacia": "Farmacia del Ahorro (Mayoreo)", "id_sede": 1, "nombre_sede": "Sede Norte", "fecha_entrega": "2026-03-10", "estado": "Entregado",  "medicamentos": ["Metformina 500 mg × 120", "Amlodipino 5 mg × 60"]},
]

# ── Comedor ───────────────────────────────────────────────────────────────────

COCINEROS = [
    {"id_cocinero": 10, "nombre": "Tomás",     "apellido_p": "Rivas", "apellido_m": "Cruz",    "id_sucursal": 1, "nombre_sucursal": "Sede Norte"},
    {"id_cocinero": 11, "nombre": "Esperanza", "apellido_p": "Luna",  "apellido_m": "Jiménez", "id_sucursal": 2, "nombre_sucursal": "Sede Sur"},
]

BITACORA_COMEDOR = [
    {"id": 1, "id_sede": 1, "nombre_sede": "Sede Norte", "cocinero": "Tomás Rivas Cruz",      "fecha": "2026-03-24", "turno": "Desayuno", "menu_nombre": "Avena con fruta y jugo de naranja",              "cantidad_platos": 4, "incidencias": None},
    {"id": 2, "id_sede": 1, "nombre_sede": "Sede Norte", "cocinero": "Tomás Rivas Cruz",      "fecha": "2026-03-24", "turno": "Comida",   "menu_nombre": "Caldo de pollo, arroz integral, gelatina",       "cantidad_platos": 4, "incidencias": "Paciente Roberto Hernández rechazó el caldo, se sustituyó por sopa de pasta."},
    {"id": 3, "id_sede": 2, "nombre_sede": "Sede Sur",   "cocinero": "Esperanza Luna Jiménez","fecha": "2026-03-24", "turno": "Desayuno", "menu_nombre": "Yogurt, pan integral tostado, fruta picada",      "cantidad_platos": 2, "incidencias": None},
    {"id": 4, "id_sede": 2, "nombre_sede": "Sede Sur",   "cocinero": "Esperanza Luna Jiménez","fecha": "2026-03-24", "turno": "Comida",   "menu_nombre": "Sopa de lentejas, pechuga a la plancha, verduras al vapor", "cantidad_platos": 2, "incidencias": None},
    {"id": 5, "id_sede": 1, "nombre_sede": "Sede Norte", "cocinero": "Tomás Rivas Cruz",      "fecha": "2026-03-23", "turno": "Desayuno", "menu_nombre": "Huevos revueltos, frijoles, tortillas de maíz",  "cantidad_platos": 4, "incidencias": None},
    {"id": 6, "id_sede": 1, "nombre_sede": "Sede Norte", "cocinero": "Tomás Rivas Cruz",      "fecha": "2026-03-23", "turno": "Comida",   "menu_nombre": "Pozole rojo, tostadas, agua de horchata",        "cantidad_platos": 4, "incidencias": None},
    {"id": 7, "id_sede": 2, "nombre_sede": "Sede Sur",   "cocinero": "Esperanza Luna Jiménez","fecha": "2026-03-23", "turno": "Desayuno", "menu_nombre": "Papaya con limón, pan dulce, leche descremada",   "cantidad_platos": 2, "incidencias": None},
    {"id": 8, "id_sede": 2, "nombre_sede": "Sede Sur",   "cocinero": "Esperanza Luna Jiménez","fecha": "2026-03-23", "turno": "Comida",   "menu_nombre": "Crema de elote, filete de pescado al horno, arroz", "cantidad_platos": 2, "incidencias": None},
]

ASIGNACIONES_CUIDADORES = {
    1: [
        {
            "nombre_cuidador":    "Ana",
            "apellido_p_cuid":    "Martínez",
            "apellido_m_cuid":    "Ruiz",
            "telefono_cuid":      "555-0101",
            "fecha_asig_cuidador": "2020-06-01",
        }
    ],
    2: [
        {
            "nombre_cuidador":    "Carlos",
            "apellido_p_cuid":    "Pérez",
            "apellido_m_cuid":    "Torres",
            "telefono_cuid":      "555-0202",
            "fecha_asig_cuidador": "2019-12-15",
        }
    ],
    3: [
        {
            "nombre_cuidador":    "Sofía",
            "apellido_p_cuid":    "Morales",
            "apellido_m_cuid":    "Jiménez",
            "telefono_cuid":      "555-0303",
            "fecha_asig_cuidador": "2022-02-10",
        }
    ],
    4: [
        {
            "nombre_cuidador":    "Ana",
            "apellido_p_cuid":    "Martínez",
            "apellido_m_cuid":    "Ruiz",
            "telefono_cuid":      "555-0101",
            "fecha_asig_cuidador": "2021-04-05",
        }
    ],
}
