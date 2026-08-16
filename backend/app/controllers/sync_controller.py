import uuid
from app.models import db, Paciente, Calendario

class SyncController:
    @staticmethod
    def generate_sync_code(id_paciente):
        paciente = db.session.get(Paciente, id_paciente)
        if not paciente:
            paciente = Paciente.query.first()
            if not paciente:
                return {"error": "Calendario no encontrado"}, 404

        if not paciente.codigo_sincronizacion:
            raw = str(uuid.uuid4()).replace("-", "").upper()
            paciente.codigo_sincronizacion = f"{raw[:3]}-{raw[3:6]}"
            db.session.commit()

        return {
            "status": "success",
            "Codigo": paciente.codigo_sincronizacion
        }, 200

    @staticmethod
    def link_calendar_by_code(codigo):
        if not codigo:
            return {"error": "Código de sincronización requerido"}, 400

        clean_code = codigo.strip().upper()
        paciente = Paciente.query.filter_by(codigo_sincronizacion=clean_code).first()
        if not paciente:
            return {"error": "Código inválido o no encontrado"}, 404

        calendario = Calendario.query.filter_by(id_paciente=paciente.id_paciente).first()
        if not calendario:
            return {"error": "Calendario no encontrado para el paciente registrado"}, 404

        return {
            "status": "success",
            "message": "Calendario sincronizado exitosamente",
            "paciente": paciente.to_dict(),
            "calendario": calendario.to_dict()
        }, 200
