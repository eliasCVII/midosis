import io
import os
from typing import Dict, Any, List, Optional
from PIL import Image
import easyocr
from app.services.prescription_parser import PrescriptionParser

# Singleton EasyOCR reader instance for performance
_reader: Optional[easyocr.Reader] = None


def get_ocr_reader() -> easyocr.Reader:
    global _reader
    if _reader is None:
        _reader = easyocr.Reader(['es', 'en'], gpu=False)
    return _reader


class OcrService:
    @staticmethod
    def process_image(image_bytes: bytes, crop_box: Optional[Dict[str, float]] = None) -> Dict[str, Any]:
        """Processes prescription image bytes, optionally cropping to user-selected region before running OCR."""
        if not image_bytes:
            return {"error": "Imagen vacía o no provista"}, 400

        try:
            image = Image.open(io.BytesIO(image_bytes))
            
            # Crop to user-specified bounding box if provided (percentages 0.0 - 1.0)
            if crop_box:
                x = float(crop_box.get("x", 0))
                y = float(crop_box.get("y", 0))
                w = float(crop_box.get("width", 1.0))
                h = float(crop_box.get("height", 1.0))
                
                # Normalize bounds
                if w < 0:
                    x += w
                    w = abs(w)
                if h < 0:
                    y += h
                    h = abs(h)

                x = max(0.0, min(1.0, x))
                y = max(0.0, min(1.0, y))
                w = max(0.0, min(1.0 - x, w))
                h = max(0.0, min(1.0 - y, h))
                
                left = int(x * image.width)
                top = int(y * image.height)
                right = int((x + w) * image.width)
                bottom = int((y + h) * image.height)
                
                if right > left and bottom > top:
                    image = image.crop((left, top, right, bottom))


            # Convert PIL Image to byte buffer for EasyOCR
            buffer = io.BytesIO()
            image.convert("RGB").save(buffer, format="JPEG")
            img_bytes = buffer.getvalue()

            reader = get_ocr_reader()
            results = reader.readtext(img_bytes)

            lines = [res[1] for res in results if res[1] and res[1].strip()]
            raw_text = "\n".join(lines)

            if not lines:
                return {
                    "status": "warning",
                    "message": "Falla en el escaneo: No se pudo extraer texto claro de la región seleccionada.",
                    "medications": [{
                        "Nombre": "",
                        "FrecuenciaHoras": 8,
                        "DuracionDias": 7,
                        "HoraInicio": "08:00"
                    }],
                    "raw_text": ""
                }, 200

            parsed_meds = PrescriptionParser.parse_text_lines(lines)

            return {
                "status": "success",
                "message": "Prescripción escaneada exitosamente",
                "medications": parsed_meds,
                "raw_text": raw_text
            }, 200

        except Exception as e:
            return {"error": f"Falla al procesar imagen: {str(e)}"}, 500
