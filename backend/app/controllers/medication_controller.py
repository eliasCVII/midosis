from app.models import db, Medicamento

class MedicationController:
    @staticmethod
    def get_all_medications():
        meds = Medicamento.query.all()
        return {"status": "success", "medicamentos": [m.to_dict() for m in meds]}, 200

    @staticmethod
    def search_medications(query_str):
        if not query_str:
            return MedicationController.get_all_medications()
        
        matches = Medicamento.query.filter(Medicamento.nombre.ilike(f"%{query_str}%")).all()
        if not matches:
            return {"error": "Datos no existentes: No se encontraron medicamentos con esa búsqueda"}, 404
        
        return {"status": "success", "medicamentos": [m.to_dict() for m in matches]}, 200

    @staticmethod
    def update_medication_info(id_medicamento, data):
        med = db.session.get(Medicamento, id_medicamento)
        if not med:
            return {"error": "Medicamento no encontrado"}, 404

        descripcion = data.get("Descripcion")
        efectos_secundarios = data.get("EfectosSecundarios")

        if descripcion is not None:
            med.descripcion = descripcion
        if efectos_secundarios is not None:
            med.efectos_secundarios = efectos_secundarios

        db.session.commit()
        return {
            "status": "success",
            "message": "Información de medicamento actualizada exitosamente",
            "medicamento": med.to_dict()
        }, 200
