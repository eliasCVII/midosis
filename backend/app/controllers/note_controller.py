import uuid
from datetime import datetime
from app.models import db, Nota, Paciente

class NoteController:
    @staticmethod
    def create_note(data):
        id_paciente = data.get("IdPaciente")
        id_medicamento = data.get("IdMedicamento")
        descripcion = data.get("Descripcion")

        if not descripcion or not descripcion.strip():
            return {"error": "La descripción del efecto secundario / síntoma es requerida"}, 400

        if not id_paciente:
            paciente = Paciente.query.first()
            if paciente:
                id_paciente = paciente.id_paciente
            else:
                return {"error": "Paciente no especificado o no existe"}, 400

        if id_medicamento in ["ninguno", "none", "", None]:
            id_medicamento = None

        nueva_nota = Nota(
            id_nota=str(uuid.uuid4()),
            id_paciente=id_paciente,
            id_medicamento=id_medicamento,
            descripcion=descripcion.strip(),
            fecha=datetime.utcnow()
        )
        db.session.add(nueva_nota)
        db.session.commit()

        return {
            "status": "success",
            "message": "Nota de efecto secundario registrada exitosamente",
            "nota": nueva_nota.to_dict()
        }, 201

    @staticmethod
    def get_notes(id_paciente):
        notas = Nota.query.filter_by(id_paciente=id_paciente).order_by(Nota.fecha.desc()).all()
        return {"status": "success", "notas": [n.to_dict() for n in notas]}, 200
