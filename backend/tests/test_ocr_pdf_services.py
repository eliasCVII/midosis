import io
import pytest
from PIL import Image, ImageDraw
import pypdf

from app import create_app
from app.models import db, Medicamento
from app.services.prescription_parser import PrescriptionParser
from app.services.ocr_service import OcrService
from app.services.pdf_service import PdfService


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


def test_prescription_parser_regex():
    lines = [
        "RP: PARACETAMOL 500 MG",
        "Tomar 1 comprimido cada 8 horas",
        "Por 7 días a las 08:00 hrs"
    ]
    parsed = PrescriptionParser.parse_text_lines(lines)
    assert len(parsed) == 1
    item = parsed[0]
    assert item["FrecuenciaHoras"] == 8
    assert item["DuracionDias"] == 7
    assert item["HoraInicio"] == "08:00"


def test_prescription_parser_multi_medications():
    lines = [
        "1. Paracetamol 500 mg",
        "Tomar 1 comprimido cada 8 horas por 7 días",
        "2. Amoxicilina 500 mg",
        "Tomar 1 cápsula cada 12 horas por 10 días",
        "3. Losartán 50 mg",
        "Tomar 1 comprimido cada 24 horas por 30 días a las 08:00"
    ]
    parsed = PrescriptionParser.parse_text_lines(lines)
    assert len(parsed) == 3
    assert parsed[0]["FrecuenciaHoras"] == 8
    assert parsed[0]["DuracionDias"] == 7
    assert "Paracetamol" in parsed[0]["Nombre"]

    assert parsed[1]["FrecuenciaHoras"] == 12
    assert parsed[1]["DuracionDias"] == 10
    assert "Amoxicilina" in parsed[1]["Nombre"]

    assert parsed[2]["FrecuenciaHoras"] == 24
    assert parsed[2]["DuracionDias"] == 30
    assert "Losartán" in parsed[2]["Nombre"]


def test_prescription_parser_preamble_and_headers():
    lines = [
        "CENTRO MÉDICO SANTA MARÍA",
        "Servicio de Salud Metropolitano",
        "Receta Médica Electrónica - Folio: 9948271",
        "Dr. Alejandro Silva - Rut Médico: 11.222.333-4",
        "Paciente: Juan Pérez - Rut: 12.345.678-9 - Edad: 68 años",
        "Diagnóstico: Hipertensión Arterial Primaria",
        "Rp.",
        "1. Losartán Potásico 50 mg comprimidos",
        "Tomar 1 comprimido cada 12 horas por 30 días",
        "2. Atorvastatina 20 mg",
        "Tomar 1 comprimido al acostarse cada 24 horas por 30 días",
        "Observaciones: Mantener dieta baja en sodio",
        "Próximo control: 30 días",
        "Firma y Timbre del Médico Tratante"
    ]
    parsed = PrescriptionParser.parse_text_lines(lines)
    assert len(parsed) == 2
    assert "Losartán" in parsed[0]["Nombre"]
    assert "CENTRO" not in parsed[0]["Nombre"]
    assert parsed[0]["FrecuenciaHoras"] == 12
    assert parsed[0]["DuracionDias"] == 30

    assert "Atorvastatina" in parsed[1]["Nombre"]
    assert parsed[1]["FrecuenciaHoras"] == 24
    assert parsed[1]["DuracionDias"] == 30
    assert parsed[1]["HoraInicio"] == "21:00"


def test_scan_prescription_image_endpoint(client):
    img = Image.new("RGB", (600, 300), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw.text((20, 20), "AMOXICILINA 500 MG", fill=(0, 0, 0))
    draw.text((20, 60), "Tomar cada 12 horas", fill=(0, 0, 0))
    draw.text((20, 100), "Por 10 dias", fill=(0, 0, 0))

    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_bytes = img_byte_arr.getvalue()

    data = {
        'file': (io.BytesIO(img_bytes), 'test_prescription.jpg'),
        'crop_box': '{"x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0}'
    }
    res = client.post("/api/prescriptions/scan", data=data, content_type='multipart/form-data')
    assert res.status_code == 200
    res_data = res.get_json()
    assert res_data["status"] in ["success", "warning"]
    assert "medications" in res_data
    assert len(res_data["medications"]) >= 1


def test_pdf_upload_endpoint(client):
    writer = pypdf.PdfWriter()
    writer.add_blank_page(width=612, height=792)
    
    pdf_buffer = io.BytesIO()
    writer.write(pdf_buffer)
    pdf_bytes = pdf_buffer.getvalue()

    data = {
        'file': (io.BytesIO(pdf_bytes), 'prescription.pdf')
    }
    res = client.post("/api/prescriptions/pdf", data=data, content_type='multipart/form-data')
    assert res.status_code in [200, 400]


def test_encrypted_pdf_password_flow(client):
    # 1. Create a password-protected PDF
    writer = pypdf.PdfWriter()
    writer.add_blank_page(width=612, height=792)
    writer.encrypt("12345678-9")

    pdf_buffer = io.BytesIO()
    writer.write(pdf_buffer)
    pdf_bytes = pdf_buffer.getvalue()

    # 2. Upload without password -> status: password_required
    data = {
        'file': (io.BytesIO(pdf_bytes), 'protected_prescription.pdf')
    }
    res = client.post("/api/prescriptions/pdf", data=data, content_type='multipart/form-data')
    assert res.status_code == 200
    res_data = res.get_json()
    assert res_data["status"] == "password_required"

    # 3. Upload with wrong password -> status: invalid_password
    data_wrong = {
        'file': (io.BytesIO(pdf_bytes), 'protected_prescription.pdf'),
        'password': 'wrong_password'
    }
    res_wrong = client.post("/api/prescriptions/pdf", data=data_wrong, content_type='multipart/form-data')
    assert res_wrong.status_code == 400
    res_wrong_data = res_wrong.get_json()
    assert res_wrong_data["status"] == "invalid_password"

    # 4. Upload with correct password (or clean RUT)
    data_correct = {
        'file': (io.BytesIO(pdf_bytes), 'protected_prescription.pdf'),
        'password': '12345678-9'
    }
    res_correct = client.post("/api/prescriptions/pdf", data=data_correct, content_type='multipart/form-data')
    # Since it's a blank page with no text, decryption succeeds and it attempts text reading
    assert res_correct.status_code in [200, 400]
    res_correct_data = res_correct.get_json()
    assert res_correct_data.get("status") != "password_required"
    assert res_correct_data.get("status") != "invalid_password"
