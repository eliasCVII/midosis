from datetime import datetime
from app.models import db

class Nota(db.Model):
    __tablename__ = "nota"

    id_nota = db.Column(db.String(36), primary_key=True)
    id_paciente = db.Column(db.String(36), db.ForeignKey("paciente.id_paciente"), nullable=False)
    id_medicamento = db.Column(db.String(36), db.ForeignKey("medicamento.id_medicamento"), nullable=True) # Nullable for "Ninguno específico"
    descripcion = db.Column(db.Text, nullable=False)
    fecha = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    medicamento = db.relationship("Medicamento", lazy=True)

    def to_dict(self):
        med_dict = self.medicamento.to_dict() if self.medicamento else None
        return {
            "IdNota": self.id_nota,
            "IdPaciente": self.id_paciente,
            "IdMedicamento": self.id_medicamento,
            "NombreMedicamento": med_dict.get("Nombre") if med_dict else "Ninguno específico",
            "Descripcion": self.descripcion,
            "Fecha": self.fecha.strftime("%d/%m/%Y %H:%M") if self.fecha else None
        }
