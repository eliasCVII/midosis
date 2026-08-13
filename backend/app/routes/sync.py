from flask import Blueprint, request, jsonify
from app.controllers.sync_controller import SyncController

sync_bp = Blueprint("sync", __name__, url_prefix="/api/sync")

@sync_bp.route("/generate-code", methods=["POST"])
def generate_code():
    data = request.get_json() or {}
    id_paciente = data.get("IdPaciente")
    res, status = SyncController.generate_sync_code(id_paciente)
    return jsonify(res), status

@sync_bp.route("/link", methods=["POST"])
def link_calendar():
    data = request.get_json() or {}
    codigo = data.get("CodigoSincronizacion") or data.get("Codigo")
    res, status = SyncController.link_calendar_by_code(codigo)
    return jsonify(res), status
