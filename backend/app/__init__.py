from flask import Flask
from flask_cors import CORS
from app.config import Config
from app.models import (
    db,
    Usuario,
    Paciente,
    Cuidador,
    Administrador,
    Medicamento,
    Receta,
    DetalleReceta,
    Calendario,
    ItemCalendario,
    Nota,
)
from app.routes import (
    health_bp,
    prescription_bp,
    calendar_bp,
    medication_bp,
    note_bp,
    sync_bp,
    auth_bp,
)

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Enable CORS for all routes (allows Flutter Web / Mobile clients)
    CORS(app, resources={r"/*": {"origins": "*"}})

    # Initialize extensions
    db.init_app(app)

    with app.app_context():
        # Ensure all models are registered in metadata and tables exist
        db.create_all()

        # Auto-seed CENABAST medications if table is empty
        try:
            if db.session.query(Medicamento).count() < 100:
                from app.services.cenabast import CenabastService
                CenabastService().import_excel_data()
        except Exception:
            pass



    # Register blueprints
    app.register_blueprint(health_bp)
    app.register_blueprint(prescription_bp)
    app.register_blueprint(calendar_bp)
    app.register_blueprint(medication_bp)
    app.register_blueprint(note_bp)
    app.register_blueprint(sync_bp)
    app.register_blueprint(auth_bp)

    return app
