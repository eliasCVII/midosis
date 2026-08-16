import json
from flask import Blueprint, request, jsonify
from app.controllers.prescription_controller import PrescriptionController
from app.services.ocr_service import OcrService
from app.services.pdf_service import PdfService

prescription_bp = Blueprint("prescription", __name__, url_prefix="/api/prescriptions")

@prescription_bp.route("/manual", methods=["POST"])
def register_manual():
    data = request.get_json() or {}
    res, status_code = PrescriptionController.register_manual_prescription(data)
    return jsonify(res), status_code

@prescription_bp.route("/scan", methods=["POST"])
def scan_prescription():
    """Extracts medication text from prescription image using EasyOCR with optional region cropping."""
    if "file" not in request.files:
        return jsonify({"error": "Falla en el escaneo: No se envió ninguna imagen"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "Falla en el escaneo: Nombre de archivo vacío"}), 400

    # Parse optional crop bounding box parameters
    crop_box = None
    try:
        if "crop_box" in request.form:
            crop_box = json.loads(request.form["crop_box"])
        elif all(k in request.form for k in ["crop_x", "crop_y", "crop_width", "crop_height"]):
            crop_box = {
                "x": float(request.form["crop_x"]),
                "y": float(request.form["crop_y"]),
                "width": float(request.form["crop_width"]),
                "height": float(request.form["crop_height"])
            }
    except Exception:
        crop_box = None

    image_bytes = file.read()
    res, status_code = OcrService.process_image(image_bytes, crop_box=crop_box)
    return jsonify(res), status_code

@prescription_bp.route("/pdf", methods=["POST"])
def upload_pdf():
    """Extracts medication text from prescription PDF document."""
    if "file" not in request.files:
        return jsonify({"error": "Archivos inválidos: No se envió ningún archivo"}), 400

    file = request.files["file"]
    if not file.filename.lower().endswith(".pdf"):
        return jsonify({"error": "Archivos inválidos: El archivo debe ser un documento PDF (.pdf)"}), 400

    password = request.form.get("password") or request.args.get("password")
    pdf_bytes = file.read()
    res, status_code = PdfService.process_pdf(pdf_bytes, password=password)
    return jsonify(res), status_code

