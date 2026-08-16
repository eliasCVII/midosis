from flask import Blueprint, request, jsonify
from app.controllers.auth_controller import AuthController

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")

@auth_bp.route("/google", methods=["POST"])
def login_google():
    data = request.get_json() or {}
    response, status_code = AuthController.login_google(data)
    return jsonify(response), status_code

@auth_bp.route("/switch-role", methods=["POST"])
def switch_role():
    data = request.get_json() or {}
    response, status_code = AuthController.switch_role(data)
    return jsonify(response), status_code

@auth_bp.route("/user/<id_usuario>", methods=["GET"])
def get_user_profile(id_usuario):
    response, status_code = AuthController.get_user_profile(id_usuario)
    return jsonify(response), status_code
