from flask import Blueprint, request, jsonify
from app.controllers.medication_controller import MedicationController
from app.services.cenabast import CenabastService

medication_bp = Blueprint("medication", __name__, url_prefix="/api/medications")

@medication_bp.route("", methods=["GET"])
def get_medications():
    query = request.args.get("q", "").strip()
    res, status = MedicationController.search_medications(query)
    return jsonify(res), status

@medication_bp.route("/import-cenabast", methods=["POST"])
def import_cenabast():
    service = CenabastService()
    res, status = service.import_excel_data()
    return jsonify(res), status

@medication_bp.route("/<id_medicamento>", methods=["PUT", "POST"])
def update_medication(id_medicamento):
    data = request.get_json() or {}
    res, status = MedicationController.update_medication_info(id_medicamento, data)
    return jsonify(res), status

