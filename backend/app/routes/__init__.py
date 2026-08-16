from app.routes.health import health_bp
from app.routes.prescription import prescription_bp
from app.routes.calendar import calendar_bp
from app.routes.medication import medication_bp
from app.routes.note import note_bp
from app.routes.sync import sync_bp
from app.routes.auth import auth_bp

__all__ = [
    "health_bp",
    "prescription_bp",
    "calendar_bp",
    "medication_bp",
    "note_bp",
    "sync_bp",
    "auth_bp",
]

