from flask import Blueprint, request, jsonify
from app.controllers.calendar_controller import CalendarController

calendar_bp = Blueprint("calendar", __name__, url_prefix="/api/calendar")

@calendar_bp.route("/<id_paciente>", methods=["GET"])
def get_calendar(id_paciente):
    res, status = CalendarController.get_patient_calendar(id_paciente)
    return jsonify(res), status

@calendar_bp.route("/<id_paciente>/items/<id_item_calendario>", methods=["DELETE"])
def delete_item(id_paciente, id_item_calendario):
    res, status = CalendarController.delete_calendar_item(id_paciente, id_item_calendario)
    return jsonify(res), status

@calendar_bp.route("/<id_paciente>/items/<id_item_calendario>/horario", methods=["PUT", "POST"])
def modify_schedule(id_paciente, id_item_calendario):
    data = request.get_json() or {}
    nueva_hora = data.get("Hora")
    res, status = CalendarController.modify_schedule(id_paciente, id_item_calendario, nueva_hora)
    return jsonify(res), status

@calendar_bp.route("/<id_paciente>/items/<id_item_calendario>/frecuencia", methods=["PUT", "POST"])
def modify_frequency(id_paciente, id_item_calendario):
    data = request.get_json() or {}
    nueva_frecuencia = data.get("Frecuencia")
    res, status = CalendarController.modify_frequency(id_paciente, id_item_calendario, nueva_frecuencia)
    return jsonify(res), status

@calendar_bp.route("/<id_paciente>/items/<id_item_calendario>/duracion", methods=["PUT", "POST"])
def modify_duration(id_paciente, id_item_calendario):
    data = request.get_json() or {}
    nueva_duracion = data.get("Duracion")
    res, status = CalendarController.modify_duration(id_paciente, id_item_calendario, nueva_duracion)
    return jsonify(res), status
