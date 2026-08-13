import io
from typing import Dict, Any, List
import pypdf
from app.services.prescription_parser import PrescriptionParser


class PdfService:
    @staticmethod
    def process_pdf(pdf_bytes: bytes) -> Dict[str, Any]:
        """Processes uploaded prescription PDF bytes, extracting text and structured medication fields."""
        if not pdf_bytes:
            return {"error": "Archivo PDF vacío o no provisto"}, 400

        try:
            reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
            text_lines: List[str] = []

            for page in reader.pages:
                text = page.extract_text()
                if text:
                    for line in text.splitlines():
                        if line.strip():
                            text_lines.append(line.strip())

            raw_text = "\n".join(text_lines)

            if not text_lines:
                return {
                    "error": "Archivos inválidos: El documento PDF no contiene texto legible o está dañado"
                }, 400

            parsed_meds = PrescriptionParser.parse_text_lines(text_lines)

            return {
                "status": "success",
                "message": "Documento PDF leído exitosamente",
                "medications": parsed_meds,
                "raw_text": raw_text
            }, 200

        except Exception as e:
            return {
                "error": f"Archivos inválidos: No se pudo procesar el PDF ({str(e)})"
            }, 400
