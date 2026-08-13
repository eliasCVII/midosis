from flask import Blueprint, request, jsonify
from app.controllers.note_controller import NoteController

note_bp = Blueprint("note", __name__, url_prefix="/api/notes")

@note_bp.route("", methods=["POST"])
def create_note():
    data = request.get_json() or {}
    res, status = NoteController.create_note(data)
    return jsonify(res), status

@note_bp.route("/<id_paciente>", methods=["GET"])
def get_notes(id_paciente):
    res, status = NoteController.get_notes(id_paciente)
    return jsonify(res), status
