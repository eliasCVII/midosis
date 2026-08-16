import uuid
from datetime import datetime, timedelta, timezone
from app.models import db, Receta, DetalleReceta, Medicamento, Calendario, ItemCalendario, Paciente, Usuario

class PrescriptionController:
    @staticmethod
    def register_manual_prescription(data):
        """Processes manual prescription registration and automatically updates/generates medication calendar.

        Expected payload:
        {
            "IdPaciente": "str",  # Optional; if not provided, a default demo patient is used
            "MetodoIngreso": "Manual" | "Foto" | "PDF",
            "Medications": [
                {
                    "Nombre": "Paracetamol",
                    "FrecuenciaHoras": 8,
                    "DuracionDias": 7,
                    "HoraInicio": "08:00"
                }
            ]
        }
        """
        id_paciente = data.get("IdPaciente")
        metodo_ingreso = data.get("MetodoIngreso", "Manual")
        medications_data = data.get("Medications", [])

        if not medications_data:
            return {"error": "Debe incluir al menos un medicamento"}, 400

        for item in medications_data:
            if not item.get("Nombre"):
                return {"error": "El nombre del medicamento es requerido"}, 400
            try:
                frec = int(item.get("FrecuenciaHoras", 0))
                dur = int(item.get("DuracionDias", 0))
            except (ValueError, TypeError):
                return {"error": "Frecuencia y Duración deben ser números enteros"}, 400

            if frec <= 0:
                return {"error": "La frecuencia debe ser mayor a 0 horas"}, 400
            if dur <= 0:
                return {"error": "La duración debe ser mayor a 0 días"}, 400

        id_paciente = data.get("IdPaciente") or "demo"

        paciente = Paciente.query.filter((Paciente.id_paciente == id_paciente) | (Paciente.id_paciente == "demo")).first()
        if not paciente:
            default_user = Usuario.query.filter_by(correo="paciente.demo@midosis.cl").first()
            if not default_user:
                default_user = Usuario(
                    id_usuario="usuario_demo",
                    correo="paciente.demo@midosis.cl",
                    nombre="Paciente Demo",
                    rol="paciente"
                )
                db.session.add(default_user)
                db.session.flush()

            paciente = Paciente.query.filter_by(id_usuario=default_user.id_usuario).first()
            if not paciente:
                paciente = Paciente(
                    id_paciente="demo",
                    id_usuario=default_user.id_usuario,
                    edad=65,
                    genero="M",
                    codigo_sincronizacion="K7A-6AT"
                )
                db.session.add(paciente)
                db.session.commit()
        id_paciente = paciente.id_paciente

        receta_id = str(uuid.uuid4())
        nueva_receta = Receta(
            id_receta=receta_id,
            fecha_registro=datetime.now(timezone.utc),
            metodo_ingreso=metodo_ingreso,
            id_paciente=id_paciente
        )
        db.session.add(nueva_receta)

        calendario = Calendario.query.filter_by(id_paciente=id_paciente).first()
        if not calendario:
            calendario = Calendario(
                id_calendario=str(uuid.uuid4()),
                id_paciente=id_paciente
            )
            db.session.add(calendario)

        processed_details = []
        for item in medications_data:
            nombre_med = item["Nombre"].strip()
            frec = int(item["FrecuenciaHoras"])
            dur = int(item["DuracionDias"])
            hora_inicio = item.get("HoraInicio", "08:00")

            medicamento = Medicamento.query.filter(Medicamento.nombre.ilike(nombre_med)).first()
            if not medicamento:
                medicamento = Medicamento(
                    id_medicamento=str(uuid.uuid4()),
                    nombre=nombre_med,
                    descripcion="Información del medicamento",
                    efectos_secundarios="No registrados"
                )
                db.session.add(medicamento)
                db.session.flush()

            detalle_id = str(uuid.uuid4())
            detalle = DetalleReceta(
                id_detalle_receta=detalle_id,
                id_receta=receta_id,
                id_medicamento=medicamento.id_medicamento,
                frecuencia_horas=frec,
                duracion_dias=dur,
                hora_inicio=hora_inicio
            )
            db.session.add(detalle)
            db.session.flush()

            now = datetime.now(timezone.utc)
            try:
                h, m = map(int, hora_inicio.split(":"))
                fecha_inicio = now.replace(hour=h, minute=m, second=0, microsecond=0)
                if fecha_inicio < now:
                    fecha_inicio += timedelta(days=1)
            except Exception:
                fecha_inicio = now

            fecha_termino = fecha_inicio + timedelta(days=dur)
            item_cal = ItemCalendario(
                id_item_calendario=str(uuid.uuid4()),
                id_calendario=calendario.id_calendario,
                id_detalle_receta=detalle_id,
                id_medicamento=medicamento.id_medicamento,
                frecuencia_horas=frec,
                duracion_dias=dur,
                hora_inicio=hora_inicio,
                fecha_inicio=fecha_inicio,
                fecha_termino=fecha_termino
            )
            db.session.add(item_cal)
            processed_details.append(detalle)

        db.session.commit()

        return {
            "status": "success",
            "message": "Receta registrada y calendario generado exitosamente",
            "receta": nueva_receta.to_dict(),
            "calendario": calendario.to_dict()
        }, 201
