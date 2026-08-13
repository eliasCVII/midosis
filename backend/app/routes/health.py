from flask import Blueprint, jsonify
from sqlalchemy import text
from app.models import db

health_bp = Blueprint("health", __name__)

@health_bp.route("/health", methods=["GET"])
def health_check():
    db_status = "unknown"
    try:
        # Verify database connection
        db.session.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception as e:
        db_status = f"disconnected: {str(e)}"

    return jsonify({
        "status": "ok",
        "service": "midosis-backend",
        "database": db_status
    }), 200
