import io
from typing import Dict, Any, List, Optional
import pypdf
from app.services.prescription_parser import PrescriptionParser
from app.services.ocr_service import OcrService


class PdfService:
    @staticmethod
    def process_pdf(pdf_bytes: bytes, password: Optional[str] = None) -> tuple[Dict[str, Any], int]:
        if not pdf_bytes:
            return {"error": "Archivo PDF vacío o no provisto"}, 400

        try:
            reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))

            if reader.is_encrypted:
                if not password:
                    return {
                        "status": "password_required",
                        "message": "El documento PDF está protegido con contraseña. Ingrese la clave para desbloquearlo."
                    }, 200

                decrypt_success = False
                candidates = [
                    password.strip(),
                    password.strip().replace(".", "").replace(" ", ""),
                    password.strip().replace(".", "").replace(" ", "").replace("-", ""),
                    password.strip().upper(),
                    password.strip().lower()
                ]

                for pwd in candidates:
                    try:
                        res = reader.decrypt(pwd)
                        if res and int(res) > 0:
                            decrypt_success = True
                            break
                    except Exception:
                        pass

                if not decrypt_success:
                    return {
                        "status": "invalid_password",
                        "error": "Contraseña incorrecta. No se pudo desbloquear el documento PDF."
                    }, 400

            text_lines: List[str] = []
            for page in reader.pages:
                try:
                    text = page.extract_text()
                    if text:
                        for line in text.splitlines():
                            clean = line.strip()
                            if clean:
                                text_lines.append(clean)
                except Exception:
                    pass

            if not text_lines:
                for page in reader.pages:
                    try:
                        images = getattr(page, 'images', [])
                        for img in images:
                            try:
                                ocr_res, status = OcrService.process_image(img.data)
                                if status == 200 and ocr_res.get("medications"):
                                    return ocr_res, 200
                            except Exception:
                                pass
                    except Exception:
                        pass

            if not text_lines:
                return {
                    "error": "Archivos inválidos: El documento PDF no contiene texto legible ni imágenes procesables o está dañado"
                }, 400

            raw_text = "\n".join(text_lines)
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
