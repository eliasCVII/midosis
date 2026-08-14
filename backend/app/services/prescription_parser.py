import re
from typing import Dict, Any, List
from app.models import db, Medicamento


class PrescriptionParser:
    @staticmethod
    def parse_text_lines(lines: List[str]) -> List[Dict[str, Any]]:
        """Parses a list of text lines extracted via OCR or PDF into multiple structured prescription objects."""
        if not lines:
            return [{
                "Nombre": "Medicamento",
                "FrecuenciaHoras": 8,
                "DuracionDias": 7,
                "HoraInicio": "08:00"
            }]

        blocks: List[List[str]] = []
        current_block: List[str] = []

        def is_medication_header(line: str) -> bool:
            clean = line.strip()
            if not clean:
                return False
            # Lines starting with intake instructions/verbs are NOT new medication headers
            if re.match(r'^(tomar|usar|aplicar|ingerir|dosis|indicaciones|v[íi]a):?', clean, re.IGNORECASE):
                return False
            # Check numbered lines like "1.", "1-", "2.", "1)"
            if re.match(r'^\d+[\.\-\)]\s*', clean):
                return True
            # Check DB match on first word
            words = [w for w in re.split(r'\s+', clean) if len(w) >= 3]
            if words:
                try:
                    match = Medicamento.query.filter(Medicamento.nombre.ilike(f"%{words[0]}%")).first()
                    if match:
                        return True
                except Exception:
                    pass
            # Check drug name pattern e.g. "Paracetamol 500mg" or "Amoxicilina"
            if re.search(r'^[A-Za-zÀ-ÿ0-9\s]+\d+\s*(mg|g|ml|mcg)\b', clean, re.IGNORECASE):
                return True
            return False

        for line in lines:
            clean = line.strip()
            if not clean:
                continue
            # Ignore global document header keywords
            if re.match(r'^(rp|receta|médico|paciente|rut|fecha|doctor|instituci[óo]n):?', clean, re.IGNORECASE):
                continue

            if is_medication_header(clean) and current_block:
                blocks.append(current_block)
                current_block = [clean]
            else:
                current_block.append(clean)

        if current_block:
            blocks.append(current_block)

        if not blocks:
            blocks = [lines]

        results = []
        for block in blocks:
            block_text = " ".join(block)
            
            # Extract frequency
            frecuencia = 8
            frec_match = re.search(r'(?:c/|cada\s*)(\d+)\s*(?:h|hrs|horas)', block_text, re.IGNORECASE)
            if frec_match:
                frecuencia = int(frec_match.group(1))
            elif re.search(r'1\s*vez\s*al\s*d[íi]a', block_text, re.IGNORECASE):
                frecuencia = 24
            elif re.search(r'2\s*veces\s*al\s*d[íi]a', block_text, re.IGNORECASE):
                frecuencia = 12
            elif re.search(r'3\s*veces\s*al\s*d[íi]a', block_text, re.IGNORECASE):
                frecuencia = 8
            elif re.search(r'4\s*veces\s*al\s*d[íi]a', block_text, re.IGNORECASE):
                frecuencia = 6

            # Extract duration
            duracion = 7
            dur_match = re.search(r'(?:por|durante|x)\s*(\d+)\s*(?:d[íi]as?|d)', block_text, re.IGNORECASE)
            if dur_match:
                duracion = int(dur_match.group(1))
            else:
                sem_match = re.search(r'(?:por|durante|x)\s*(\d+)\s*semanas?', block_text, re.IGNORECASE)
                if sem_match:
                    duracion = int(sem_match.group(1)) * 7
                elif re.search(r'por\s*1\s*mes', block_text, re.IGNORECASE):
                    duracion = 30

            # Extract start time
            hora_inicio = "08:00"
            hora_match = re.search(r'\b([01]?\d|2[0-3]):([0-5]\d)\b', block_text)
            if hora_match:
                h, m = int(hora_match.group(1)), int(hora_match.group(2))
                hora_inicio = f"{h:02d}:{m:02d}"

            # Extract drug name: ALWAYS preserve exact text extracted from OCR/PDF
            first_line = re.sub(r'^\d+[\.\-\)]\s*', '', block[0]).strip()
            nombre_med = first_line if first_line else "Medicamento Detectado"


            results.append({
                "Nombre": nombre_med,
                "FrecuenciaHoras": frecuencia,
                "DuracionDias": duracion,
                "HoraInicio": hora_inicio
            })

        return results
