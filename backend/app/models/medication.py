from app.models import db

class Medicamento(db.Model):
    __tablename__ = "medicamento"

    id_medicamento = db.Column(db.String(36), primary_key=True)
    nombre = db.Column(db.String(150), nullable=False, index=True)
    descripcion = db.Column(db.Text, nullable=True)
    efectos_secundarios = db.Column(db.Text, nullable=True)

    # Relationships
    detalles_receta = db.relationship("DetalleReceta", backref="medicamento", lazy=True)

    def to_dict(self):
        return {
            "IdMedicamento": self.id_medicamento,
            "Nombre": self.nombre,
            "Descripcion": self.descripcion,
            "EfectosSecundarios": self.efectos_secundarios
        }
