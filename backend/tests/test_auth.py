import pytest
from app import create_app
from app.models import db, Usuario, Paciente, Cuidador

@pytest.fixture
def client():
    app = create_app()
    app.config["TESTING"] = True
    with app.test_client() as client:
        with app.app_context():
            yield client

def test_google_login_flow(client):
    # 1. Login as patient
    payload = {
        "email": "test.patient@example.com",
        "name": "Paciente Demo Google",
        "role": "paciente"
    }
    res = client.post("/api/auth/google", json=payload)
    assert res.status_code == 200
    data = res.get_json()
    assert data["status"] == "success"
    assert data["usuario"]["Correo"] == "test.patient@example.com"
    assert data["usuario"]["Rol"] == "paciente"
    assert data["paciente"] is not None
    assert data["paciente"]["CodigoSincronizacion"] is not None
    user_id = data["usuario"]["IdUsuario"]

    # 2. Get profile
    res_prof = client.get(f"/api/auth/user/{user_id}")
    assert res_prof.status_code == 200
    prof_data = res_prof.get_json()
    assert prof_data["usuario"]["IdUsuario"] == user_id
    assert prof_data["paciente"]["IdPaciente"] == data["paciente"]["IdPaciente"]

def test_switch_role_flow(client):
    # 1. Register/Login as caregiver
    payload = {
        "email": "caregiver.user@example.com",
        "name": "Maria Cuidadora",
        "role": "cuidador"
    }
    res = client.post("/api/auth/google", json=payload)
    assert res.status_code == 200
    data = res.get_json()
    assert data["usuario"]["Rol"] == "cuidador"
    user_id = data["usuario"]["IdUsuario"]

    # 2. Switch to patient role
    switch_res = client.post("/api/auth/switch-role", json={
        "id_usuario": user_id,
        "role": "paciente"
    })
    assert switch_res.status_code == 200
    switch_data = switch_res.get_json()
    assert switch_data["usuario"]["Rol"] == "paciente"
    assert switch_data["paciente"] is not None
    assert switch_data["paciente"]["CodigoSincronizacion"] is not None

    # 3. Switch back to caregiver
    switch_back = client.post("/api/auth/switch-role", json={
        "id_usuario": user_id,
        "role": "cuidador"
    })
    assert switch_back.status_code == 200
    assert switch_back.get_json()["usuario"]["Rol"] == "cuidador"

def test_google_login_invalid_email(client):
    res = client.post("/api/auth/google", json={})
    assert res.status_code == 400
