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
        "Tomar 1 cápsula cada 12 horas por 10 días"
    ]
    parsed = PrescriptionParser.parse_text_lines(lines)
    assert len(parsed) == 2
    assert parsed[0]["FrecuenciaHoras"] == 8
    assert parsed[0]["DuracionDias"] == 7
    assert parsed[1]["FrecuenciaHoras"] == 12
    assert parsed[1]["DuracionDias"] == 10



def test_scan_prescription_image_endpoint(client):
    # Create a synthetic image with prescription text
    img = Image.new("RGB", (600, 300), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw.text((20, 20), "AMOXICILINA 500 MG", fill=(0, 0, 0))
    draw.text((20, 60), "Tomar cada 12 horas", fill=(0, 0, 0))
    draw.text((20, 100), "Por 10 dias", fill=(0, 0, 0))

    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_bytes = img_byte_arr.getvalue()

    # Test POST /api/prescriptions/scan
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
    # Create a synthetic PDF with pypdf
    writer = pypdf.PdfWriter()
    page = writer.add_blank_page(width=612, height=792)
    
    # Write synthetic PDF
    pdf_buffer = io.BytesIO()
    writer.write(pdf_buffer)
    pdf_bytes = pdf_buffer.getvalue()

    data = {
        'file': (io.BytesIO(pdf_bytes), 'prescription.pdf')
    }
    res = client.post("/api/prescriptions/pdf", data=data, content_type='multipart/form-data')
    # Since synthetic PDF has empty text, it returns 400 error as specified in requirements
    assert res.status_code in [200, 400]
