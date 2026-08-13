import pytest
from app import create_app
from app.services.cenabast import CenabastService
from app.models import db, Medicamento

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

def test_cenabast_import_endpoint(client):
    res = client.post("/api/medications/import-cenabast")
    assert res.status_code == 200
    data = res.get_json()
    assert data["status"] == "success"
    assert data["imported_count"] >= 0
    assert Medicamento.query.count() > 0

    aciclovir = Medicamento.query.filter(Medicamento.nombre.ilike("%ACICLOVIR%")).first()
    assert aciclovir is not None
    assert aciclovir.id_medicamento.startswith("cenabast_")

