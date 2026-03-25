from flask import render_template, redirect, url_for, session
import data


def init_routes(app):

    @app.route("/clinica")
    def dashboard_clinica():
        if not session.get("medico"):
            return redirect(url_for("login"))

        staff_en_turno    = sum(1 for t in data.TURNOS_HOY if t["estado"] == "En turno")
        tareas_pendientes = sum(1 for t in data.TAREAS_HOY  if t["estado"] == "Pendiente")
        alertas_activas   = sum(1 for a in data.ALERTAS_MEDICAS if a["estado"] not in ("Atendida", "Resuelto"))

        expedientes = []
        for p in data.PACIENTES:
            pid = p["id_paciente"]
            expedientes.append({
                "paciente":    p,
                "perfil":      data.PERFIL_CLINICO.get(pid, {}),
                "medicamentos": data.MEDICAMENTOS.get(pid, []),
                "bitacoras":   [b for b in data.BITACORAS if b["id_paciente"] == pid],
                "enfermedades": data.ENFERMEDADES.get(pid, []),
            })

        return render_template(
            "clinica.html",

            staff_en_turno=staff_en_turno,
            total_pacientes=len(data.PACIENTES),
            tareas_pendientes=tareas_pendientes,
            alertas_activas=alertas_activas,
            tareas=data.TAREAS_HOY,
            alertas_medicas=data.ALERTAS_MEDICAS,

            turnos=data.TURNOS_HOY,
            asignaciones=data.ASIGNACIONES_CUIDADORES,
            pacientes=data.PACIENTES,

            expedientes=expedientes,

            incidentes=data.INCIDENTES,
        )
