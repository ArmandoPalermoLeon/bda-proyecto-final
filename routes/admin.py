from functools import wraps
from flask import render_template, request, redirect, url_for, session, flash
import data


def init_routes(app):

    def login_requerido(f):
        @wraps(f)
        def decorado(*args, **kwargs):
            if not session.get("admin"):
                return redirect(url_for("login"))
            return f(*args, **kwargs)
        return decorado

    # ── Dashboard ─────────────────────────────────────────────────────────────

    @app.route("/dashboard")
    @login_requerido
    def dashboard():
        stats = {
            "pacientes":      len(data.PACIENTES),
            "cuidadores":     len(data.CUIDADORES),
            "dispositivos":   len(data.DISPOSITIVOS),
            "alertas_activas": sum(1 for a in data.ALERTAS_RECIENTES if a["estatus_alerta"] == "Activa"),
        }
        stats_por_sede = []
        for s in data.SUCURSALES:
            sid = s["id_sucursal"]
            stats_por_sede.append({
                "sucursal":   s,
                "pacientes":  sum(1 for p in data.PACIENTES    if p.get("id_sucursal") == sid),
                "cuidadores": sum(1 for c in data.CUIDADORES   if c.get("id_sucursal") == sid),
                "dispositivos": sum(1 for d in data.DISPOSITIVOS if d.get("id_sucursal") == sid),
                "alertas_activas": sum(
                    1 for a in data.ALERTAS_RECIENTES
                    if a.get("id_sucursal") == sid and a["estatus_alerta"] == "Activa"
                ),
            })

        return render_template(
            "dashboard.html",
            stats=stats,
            alertas=data.ALERTAS_RECIENTES,
            stats_por_sede=stats_por_sede,
            sucursales=data.SUCURSALES,
        )


    @app.route("/pacientes")
    @login_requerido
    def pacientes_lista():
        activos = [p for p in data.PACIENTES if p["desc_estado"] != "Inactivo"]
        return render_template("pacientes/list.html", pacientes=activos, sucursales=data.SUCURSALES)

    @app.route("/pacientes/nuevo", methods=["GET", "POST"])
    @login_requerido
    def pacientes_nuevo():
        if request.method == "POST":
            flash("Paciente registrado correctamente.", "success")
            return redirect(url_for("pacientes_lista"))
        return render_template("pacientes/form.html", paciente=None, estados=data.ESTADOS_PACIENTE)

    @app.route("/pacientes/editar/<int:id>", methods=["GET", "POST"])
    @login_requerido
    def pacientes_editar(id):
        paciente = next((p for p in data.PACIENTES if p["id_paciente"] == id), None)
        if request.method == "POST":
            flash("Paciente actualizado correctamente.", "success")
            return redirect(url_for("pacientes_lista"))
        return render_template("pacientes/form.html", paciente=paciente, estados=data.ESTADOS_PACIENTE)

    @app.route("/pacientes/eliminar/<int:id>", methods=["POST"])
    @login_requerido
    def pacientes_eliminar(id):
        flash("Paciente dado de baja correctamente.", "success")
        return redirect(url_for("pacientes_lista"))

    @app.route("/pacientes/historial/<int:id>")
    @login_requerido
    def pacientes_historial(id):
        paciente     = next((p for p in data.PACIENTES if p["id_paciente"] == id), None)
        estado       = next((e for e in data.ESTADOS_PACIENTE if e["id_estado"] == paciente["id_estado"]), None)
        enfermedades = data.ENFERMEDADES.get(id, [])
        cuidadores   = data.ASIGNACIONES_CUIDADORES.get(id, [])
        return render_template(
            "pacientes/historial.html",
            paciente=paciente,
            estado=estado,
            enfermedades=enfermedades,
            cuidadores=cuidadores,
        )

    @app.route("/cuidadores")
    @login_requerido
    def cuidadores_lista():
        return render_template("cuidadores/list.html", cuidadores=data.CUIDADORES, sucursales=data.SUCURSALES)

    @app.route("/cuidadores/nuevo", methods=["GET", "POST"])
    @login_requerido
    def cuidadores_nuevo():
        if request.method == "POST":
            flash("Cuidador registrado correctamente.", "success")
            return redirect(url_for("cuidadores_lista"))
        return render_template("cuidadores/form.html", cuidador=None)

    @app.route("/cuidadores/editar/<int:id>", methods=["GET", "POST"])
    @login_requerido
    def cuidadores_editar(id):
        cuidador = next((c for c in data.CUIDADORES if c["id_cuidador"] == id), None)
        if request.method == "POST":
            flash("Cuidador actualizado correctamente.", "success")
            return redirect(url_for("cuidadores_lista"))
        return render_template("cuidadores/form.html", cuidador=cuidador)

    @app.route("/cuidadores/eliminar/<int:id>", methods=["POST"])
    @login_requerido
    def cuidadores_eliminar(id):
        flash("Cuidador marcado como inactivo.", "success")
        return redirect(url_for("cuidadores_lista"))


    @app.route("/alertas")
    @login_requerido
    def alertas():
        return render_template("alertas.html")

    @app.route("/dispositivos")
    @login_requerido
    def dispositivos():
        return render_template("dispositivos.html", dispositivos=data.DISPOSITIVOS)

    @app.route("/dispositivos/nuevo", methods=["GET", "POST"])
    @login_requerido
    def dispositivos_nuevo():
        if request.method == "POST":
            flash("Dispositivo vinculado correctamente.", "success")
            return redirect(url_for("dispositivos"))
        return render_template("dispositivos_form.html", pacientes=data.PACIENTES)

    @app.route("/zonas")
    @login_requerido
    def zonas():
        return render_template("zonas.html", zonas=data.ZONAS)

    @app.route("/zonas/nueva", methods=["GET", "POST"])
    @login_requerido
    def zonas_nueva():
        if request.method == "POST":
            flash("Zona segura registrada correctamente.", "success")
            return redirect(url_for("zonas"))
        return render_template("zonas_form.html", pacientes=data.PACIENTES)
