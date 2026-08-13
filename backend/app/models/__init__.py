from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

from app.models.user import Usuario, Paciente, Cuidador, Administrador
from app.models.medication import Medicamento
from app.models.prescription import Receta, DetalleReceta
from app.models.calendar import Calendario, ItemCalendario
from app.models.note import Nota

__all__ = [
    "db",
    "Usuario",
    "Paciente",
    "Cuidador",
    "Administrador",
    "Medicamento",
    "Receta",
    "DetalleReceta",
    "Calendario",
    "ItemCalendario",
    "Nota",
]
