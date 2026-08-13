import pytest
from app import create_app
from app.models import db, Medicamento, Receta, DetalleReceta, Calendario, Paciente

@pytest.fixture
def client():
    app = create_app()
    app.config["TESTING"] = True
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.session.remove()
            db.drop_all()

def test_manual_prescription_registration_and_detalle_receta_split(client):
    # Test registering a prescription manually
    payload = {
        "MetodoIngreso": "Manual",
        "Medications": [
            {
                "Nombre": "Amoxicilina",
                "FrecuenciaHoras": 8,
                "DuracionDias": 7,
                "HoraInicio": "08:00"
            }
        ]
    }
    res = client.post("/api/prescriptions/manual", json=payload)
    assert res.status_code == 201
    data = res.get_json()
    assert data["status"] == "success"

    # Verify DetalleReceta contains prescription-specific frequency and duration
    receta_id = data["receta"]["IdReceta"]
    detalle = DetalleReceta.query.filter_by(id_receta=receta_id).first()
    assert detalle is not None
    assert detalle.frecuencia_horas == 8
    assert detalle.duracion_dias == 7

    # Verify Medicamento does NOT store global frequency or duration
    med = db.session.get(Medicamento, detalle.id_medicamento)
    assert med.nombre == "Amoxicilina"
    assert not hasattr(med, "frecuencia_horas")
    assert not hasattr(med, "duracion_dias")

def test_calendar_modifications_and_validations(client):
    # Register prescription first
    payload = {
        "MetodoIngreso": "Manual",
        "Medications": [
            {"Nombre": "Ibuprofeno", "FrecuenciaHoras": 12, "DuracionDias": 5, "HoraInicio": "09:00"}
        ]
    }
    res = client.post("/api/prescriptions/manual", json=payload)
    data = res.get_json()
    paciente_id = data["receta"]["IdPaciente"]
    item_id = data["calendario"]["Items"][0]["IdItemCalendario"]

    # 1. Modify Schedule
    res_sched = client.put(f"/api/calendar/{paciente_id}/items/{item_id}/horario", json={"Hora": "10:30"})
    assert res_sched.status_code == 200
    assert res_sched.get_json()["item"]["HoraInicio"] == "10:30"

    # 2. Modify Frequency with invalid <= 0
    res_frec_inv = client.put(f"/api/calendar/{paciente_id}/items/{item_id}/frecuencia", json={"Frecuencia": 0})
    assert res_frec_inv.status_code == 400

    # 3. Modify Frequency with valid value
    res_frec = client.put(f"/api/calendar/{paciente_id}/items/{item_id}/frecuencia", json={"Frecuencia": 6})
    assert res_frec.status_code == 200
    assert res_frec.get_json()["item"]["FrecuenciaHoras"] == 6

    # 4. Modify Duration with invalid <= 0
    res_dur_inv = client.put(f"/api/calendar/{paciente_id}/items/{item_id}/duracion", json={"Duracion": -1})
    assert res_dur_inv.status_code == 400

    # 5. Modify Duration with valid value
    res_dur = client.put(f"/api/calendar/{paciente_id}/items/{item_id}/duracion", json={"Duracion": 10})
    assert res_dur.status_code == 200
    assert res_dur.get_json()["item"]["DuracionDias"] == 10

def test_sync_code_and_caregiver_linking(client):
    # Create prescription to get patient
    client.post("/api/prescriptions/manual", json={
        "Medications": [{"Nombre": "Paracetamol", "FrecuenciaHoras": 8, "DuracionDias": 3}]
    })

    paciente = Paciente.query.first()
    assert paciente is not None

    # Generate sync code
    res_gen = client.post("/api/sync/generate-code", json={"IdPaciente": paciente.id_paciente})
    assert res_gen.status_code == 200
    code = res_gen.get_json()["Codigo"]
    assert code is not None

    # Caregiver links with code
    res_link = client.post("/api/sync/link", json={"Codigo": code})
    assert res_link.status_code == 200
    assert res_link.get_json()["calendario"] is not None
