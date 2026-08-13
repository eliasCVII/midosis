from datetime import datetime
from app.models import db

class Calendario(db.Model):
    __tablename__ = "calendario"

    id_calendario = db.Column(db.String(36), primary_key=True)
    id_paciente = db.Column(db.String(36), db.ForeignKey("paciente.id_paciente"), nullable=False, unique=True)
    fecha_actualizacion = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    items = db.relationship("ItemCalendario", backref="calendario", lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "IdCalendario": self.id_calendario,
            "IdPaciente": self.id_paciente,
            "FechaActualizacion": self.fecha_actualizacion.isoformat() if self.fecha_actualizacion else None,
            "Items": [item.to_dict() for item in self.items]
        }


class ItemCalendario(db.Model):
    __tablename__ = "item_calendario"

    id_item_calendario = db.Column(db.String(36), primary_key=True)
    id_calendario = db.Column(db.String(36), db.ForeignKey("calendario.id_calendario"), nullable=False)
    id_detalle_receta = db.Column(db.String(36), db.ForeignKey("detalle_receta.id_detalle_receta"), nullable=True)
    id_medicamento = db.Column(db.String(36), db.ForeignKey("medicamento.id_medicamento"), nullable=False)
    
    # Intakes schedule details for this active treatment item
    frecuencia_horas = db.Column(db.Integer, nullable=False)
    duracion_dias = db.Column(db.Integer, nullable=False)
    hora_inicio = db.Column(db.String(5), nullable=False) # e.g. "08:00"
    fecha_inicio = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    fecha_termino = db.Column(db.DateTime, nullable=False)

    # Relationship to Medicamento
    medicamento = db.relationship("Medicamento", lazy=True)

    def to_dict(self):
        med_info = self.medicamento.to_dict() if self.medicamento else {}
        return {
            "IdItemCalendario": self.id_item_calendario,
            "IdCalendario": self.id_calendario,
            "IdDetalleReceta": self.id_detalle_receta,
            "IdMedicamento": self.id_medicamento,
            "Nombre": med_info.get("Nombre", ""),
            "Descripcion": med_info.get("Descripcion", ""),
            "EfectosSecundarios": med_info.get("EfectosSecundarios", ""),
            "FrecuenciaHoras": self.frecuencia_horas,
            "DuracionDias": self.duracion_dias,
            "HoraInicio": self.hora_inicio,
            "FechaInicio": self.fecha_inicio.isoformat() if self.fecha_inicio else None,
            "FechaTermino": self.fecha_termino.isoformat() if self.fecha_termino else None
        }
