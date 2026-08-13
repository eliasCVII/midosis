from datetime import datetime
from app.models import db

class Receta(db.Model):
    __tablename__ = "receta"

    id_receta = db.Column(db.String(36), primary_key=True)
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    metodo_ingreso = db.Column(db.String(20), nullable=False) # 'Manual', 'Foto', 'PDF'
    id_paciente = db.Column(db.String(36), db.ForeignKey("paciente.id_paciente"), nullable=False)

    # Relationships
    detalles = db.relationship("DetalleReceta", backref="receta", lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "IdReceta": self.id_receta,
            "FechaRegistro": self.fecha_registro.isoformat() if self.fecha_registro else None,
            "MetodoIngreso": self.metodo_ingreso,
            "IdPaciente": self.id_paciente,
            "Detalles": [d.to_dict() for d in self.detalles]
        }


class DetalleReceta(db.Model):
    __tablename__ = "detalle_receta"

    id_detalle_receta = db.Column(db.String(36), primary_key=True)
    id_receta = db.Column(db.String(36), db.ForeignKey("receta.id_receta"), nullable=False)
    id_medicamento = db.Column(db.String(36), db.ForeignKey("medicamento.id_medicamento"), nullable=False)
    frecuencia_horas = db.Column(db.Integer, nullable=False)
    duracion_dias = db.Column(db.Integer, nullable=False)
    hora_inicio = db.Column(db.String(5), nullable=True) # Format HH:MM e.g. "08:00"

    def to_dict(self):
        med_dict = self.medicamento.to_dict() if self.medicamento else {}
        return {
            "IdDetalleReceta": self.id_detalle_receta,
            "IdReceta": self.id_receta,
            "IdMedicamento": self.id_medicamento,
            "NombreMedicamento": med_dict.get("Nombre", ""),
            "FrecuenciaHoras": self.frecuencia_horas,
            "DuracionDias": self.duracion_dias,
            "HoraInicio": self.hora_inicio
        }
