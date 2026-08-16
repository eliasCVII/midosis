import re
from typing import Dict, Any, List
from app.models import Medicamento


class PrescriptionParser:
    @staticmethod
    def parse_text_lines(lines: List[str]) -> List[Dict[str, Any]]:
        """Parses raw text lines extracted via OCR or PDF into multiple structured prescription items.
        
        Applies multi-pass filtering, CENABAST catalog matching, and header pruning to prevent
        non-medication preamble from corrupting the medication name.
        """
        if not lines:
            return [{
                "Nombre": "Medicamento",
                "FrecuenciaHoras": 8,
                "DuracionDias": 7,
                "HoraInicio": "08:00"
            }]

        # Preamble / metadata patterns that should be completely ignored
        ignored_patterns = [
            r'^(?:rp|receta|receta\s*m[ée]dica|m[ée]dico|paciente|rut|fecha|doctor|instituci[óo]n|folio|servicio\s*de\s*salud|hospital|cl[íi]nica|centro\s*m[ée]dico|atenci[óo]n|previsi[óo]n|edad|sexo|domicilio|tel[ée]fono):?',
            r'^(?:diagn[óo]stico|observaciones|firma|timbre|v[áa]lida\s*hasta|pr[óo]ximo\s*control|superintendencia|registro\s*colegio|atentamente|pie\s*de\s*firma|c[óo]digo\s*de\s*verificaci[óo]n):?',
            r'^(?:informaci[óo]n\s*al\s*paciente|advertencia|precauciones|venta\s*bajo\s*receta|retenida|controlada):?'
        ]

        def is_ignored_line(line: str) -> bool:
            clean = line.strip().lower()
            if len(clean) < 2:
                return True
            return any(re.search(pat, clean, re.IGNORECASE) for pat in ignored_patterns)

        def is_instruction_line(line: str) -> bool:
            clean = line.strip().lower()
            return bool(re.match(r'^(?:tomar|usar|aplicar|ingerir|consumir|administrar|dosis|indicaci[óo]n|indicaciones|posolog[íi]a|v[íi]a|v[íi]a\s*oral|cada|c\/|por|durante|x\s*\d+|1\s*comprimido|1\s*c[áa]psula|2\s*comprimidos|1\s*tableta):?', clean, re.IGNORECASE))

        def find_cenabast_match(text: str) -> str | None:
            """Checks if text contains a known medication name from CENABAST."""
            words = [w for w in re.split(r'[\s,\.\-]+', text) if len(w) >= 4 and not w.isdigit()]
            for word in words[:3]:
                try:
                    match = Medicamento.query.filter(Medicamento.nombre.ilike(f"%{word}%")).first()
                    if match:
                        return match.nombre
                except Exception:
                    pass
            return None

        def is_medication_header(line: str) -> bool:
            clean = line.strip()
            if not clean or is_instruction_line(clean) or is_ignored_line(clean):
                return False

            # 1. Numbered items: "1.", "1.-", "2)", "Item 1", "[1]"
            if re.match(r'^(?:item\s*|med\s*|n[°º]\s*)?\d+[\.\-\)]\s*[A-Za-z]', clean, re.IGNORECASE):
                return True

            # 2. Bullet points: "•", "-", "*"
            if re.match(r'^[\•\-\*]\s*[A-Za-z]', clean):
                return True

            # 3. Drug name pattern with explicit strength: e.g. "Paracetamol 500mg" or "Losartan 50 mg"
            if re.search(r'\b\d+(?:[\.,]\d+)?\s*(?:mg|g|ml|mcg|ui|%|mg\/ml)\b', clean, re.IGNORECASE):
                # Ensure it's not a date, phone number, or patient age
                if not re.search(r'(?:a[ñn]os|meses|horas|d[íi]as|hrs|rut|tel)\b', clean, re.IGNORECASE):
                    return True

            # 4. Check CENABAST catalogue
            if find_cenabast_match(clean):
                return True

            return False

        # Build segmented blocks
        blocks: List[List[str]] = []
        current_block: List[str] = []
        started = False

        for line in lines:
            clean = line.strip()
            if not clean or is_ignored_line(clean):
                continue

            if is_medication_header(clean):
                if current_block:
                    blocks.append(current_block)
                current_block = [clean]
                started = True
            else:
                if started and current_block:
                    # Append instruction/details to the active medication block
                    current_block.append(clean)
                elif not started:
                    # Ignore unclassified preamble before the first real medication header
                    continue

        if current_block:
            blocks.append(current_block)

        # Fallback if no header matched: try looking for any medication keyword in lines
        if not blocks:
            filtered_lines = [l for l in lines if not is_ignored_line(l)]
            if filtered_lines:
                blocks = [filtered_lines]
            else:
                blocks = [lines]

        results = []
        for block in blocks:
            block_text = " ".join(block)

            # 1. Frequency (hours)
            frecuencia = 8
            frec_match = re.search(r'(?:c\/|cada\s*)(\d+)\s*(?:h|hrs|horas)', block_text, re.IGNORECASE)
            if frec_match:
                frecuencia = int(frec_match.group(1))
            elif re.search(r'1\s*vez\s*al\s*d[íi]a|cada\s*24\s*horas|una\s*vez\s*al\s*d[íi]a|en\s*la\s*ma[ñn]ana\s*solamente', block_text, re.IGNORECASE):
                frecuencia = 24
            elif re.search(r'2\s*veces\s*al\s*d[íi]a|cada\s*12\s*horas|dos\s*veces\s*al\s*d[íi]a', block_text, re.IGNORECASE):
                frecuencia = 12
            elif re.search(r'3\s*veces\s*al\s*d[íi]a|cada\s*8\s*horas|tres\s*veces\s*al\s*d[íi]a', block_text, re.IGNORECASE):
                frecuencia = 8
            elif re.search(r'4\s*veces\s*al\s*d[íi]a|cada\s*6\s*horas|cuatro\s*veces\s*al\s*d[íi]a', block_text, re.IGNORECASE):
                frecuencia = 6
            elif re.search(r'cada\s*4\s*horas', block_text, re.IGNORECASE):
                frecuencia = 4

            # 2. Duration (days)
            duracion = 7
            dur_match = re.search(r'(?:por|durante|x)\s*(\d+)\s*(?:d[íi]as?|d\b)', block_text, re.IGNORECASE)
            if dur_match:
                duracion = int(dur_match.group(1))
            else:
                sem_match = re.search(r'(?:por|durante|x)\s*(\d+)\s*semanas?', block_text, re.IGNORECASE)
                if sem_match:
                    duracion = int(sem_match.group(1)) * 7
                elif re.search(r'por\s*1\s*mes|durante\s*1\s*mes|por\s*un\s*mes', block_text, re.IGNORECASE):
                    duracion = 30
                elif re.search(r'por\s*2\s*meses', block_text, re.IGNORECASE):
                    duracion = 60
                elif re.search(r'por\s*3\s*meses', block_text, re.IGNORECASE):
                    duracion = 90
                elif re.search(r'permanente|cr[óo]nico|uso\s*continuo|de\s*por\s*vida', block_text, re.IGNORECASE):
                    duracion = 90

            # 3. Start Time (HH:MM)
            hora_inicio = "08:00"
            hora_match = re.search(r'\b([01]?\d|2[0-3]):([0-5]\d)\b', block_text)
            if hora_match:
                h, m = int(hora_match.group(1)), int(hora_match.group(2))
                hora_inicio = f"{h:02d}:{m:02d}"
            elif re.search(r'en\s*la\s*noche|al\s*acostarse|antes\s*de\s*dormir', block_text, re.IGNORECASE):
                hora_inicio = "21:00"
            elif re.search(r'en\s*el\s*almuerzo|mediod[íi]a', block_text, re.IGNORECASE):
                hora_inicio = "13:00"
            elif re.search(r'en\s*la\s*ma[ñn]ana|en\s*ayunas', block_text, re.IGNORECASE):
                hora_inicio = "08:00"

            # 4. Clean Drug Name
            first_line = block[0].strip()
            clean_name = re.sub(r'^(?:item\s*|med\s*|n[°º]\s*)?\d+[\.\-\)]\s*|^[\•\-\*]\s*', '', first_line, flags=re.IGNORECASE).strip()
            # Trim trailing instructions if in same line (e.g. "Paracetamol 500mg Tomar 1 comp cada 8 hrs")
            split_inst = re.split(r'\s+(?:tomar|usar|aplicar|ingerir|consumir|cada|c\/|por|durante)\b', clean_name, flags=re.IGNORECASE)
            if split_inst and split_inst[0].strip():
                clean_name = split_inst[0].strip()

            nombre_med = clean_name if clean_name else "Medicamento Detectado"

            results.append({
                "Nombre": nombre_med,
                "FrecuenciaHoras": frecuencia,
                "DuracionDias": duracion,
                "HoraInicio": hora_inicio
            })

        return results
