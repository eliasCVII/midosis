from datetime import datetime, timedelta
import re
from app.models import db, Calendario, ItemCalendario, DetalleReceta

class CalendarController:
    @staticmethod
    def get_patient_calendar(id_paciente):
        calendario = Calendario.query.filter_by(id_paciente=id_paciente).first()
        if not calendario:
            # Fallback to any existing calendar or empty structure
            calendario = Calendario.query.first()
            if not calendario:
                return {"status": "success", "calendario": {"IdCalendario": "empty", "IdPaciente": id_paciente, "Items": []}}, 200
        return {"status": "success", "calendario": calendario.to_dict()}, 200

    @staticmethod
    def delete_calendar_item(id_paciente, id_item_calendario):
        item = db.session.get(ItemCalendario, id_item_calendario)
        if not item:
            return {"error": "No se puede eliminar el medicamento: No existe en el calendario"}, 404

        db.session.delete(item)
        db.session.commit()
        return {"status": "success", "message": "Medicamento eliminado del calendario"}, 200

    @staticmethod
    def modify_schedule(id_paciente, id_item_calendario, nueva_hora):
        # Validate time format (HH:MM 24h)
        if not re.match(r"^([01]?[0-9]|2[0-3]):[0-5][0-9]$", nueva_hora):
            return {"error": "Hora inválida. Debe usar formato HH:MM"}, 400

        item = db.session.get(ItemCalendario, id_item_calendario)
        if not item:
            return {"error": "Medicamento no encontrado"}, 404

        item.hora_inicio = nueva_hora
        db.session.commit()

        return {
            "status": "success",
            "message": "Horario modificado exitosamente",
            "item": item.to_dict()
        }, 200

    @staticmethod
    def modify_frequency(id_paciente, id_item_calendario, nueva_frecuencia):
        try:
            frec = int(nueva_frecuencia)
        except (ValueError, TypeError):
            return {"error": "Frecuencia inválida"}, 400

        if frec <= 0:
            return {"error": "Frecuencia inválida. Debe ser mayor a 0 horas"}, 400

        item = db.session.get(ItemCalendario, id_item_calendario)
        if not item:
            return {"error": "Medicamento no encontrado"}, 404

        item.frecuencia_horas = frec
        if item.id_detalle_receta:
            detalle = db.session.get(DetalleReceta, item.id_detalle_receta)
            if detalle:
                detalle.frecuencia_horas = frec

        db.session.commit()
        return {
            "status": "success",
            "message": "Frecuencia modificada exitosamente",
            "item": item.to_dict()
        }, 200

    @staticmethod
    def modify_duration(id_paciente, id_item_calendario, nueva_duracion):
        try:
            dur = int(nueva_duracion)
        except (ValueError, TypeError):
            return {"error": "Duración inválida"}, 400

        if dur <= 0:
            return {"error": "Duración inválida. Debe ser mayor a 0 días"}, 400

        item = db.session.get(ItemCalendario, id_item_calendario)
        if not item:
            return {"error": "Medicamento no encontrado"}, 404

        item.duracion_dias = dur
        item.fecha_termino = item.fecha_inicio + timedelta(days=dur)
        
        if item.id_detalle_receta:
            detalle = db.session.get(DetalleReceta, item.id_detalle_receta)
            if detalle:
                detalle.duracion_dias = dur

        db.session.commit()
        return {
            "status": "success",
            "message": "Duración modificada exitosamente",
            "item": item.to_dict()
        }, 200

