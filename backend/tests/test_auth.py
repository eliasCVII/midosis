import pytest
from app import create_app
from app.models import db, Usuario, Paciente

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

def test_google_login_invalid_email(client):
    res = client.post("/api/auth/google", json={})
    assert res.status_code == 400
