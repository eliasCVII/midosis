import re
import difflib
import unicodedata
from typing import Dict, Any, List, Optional
from app.models import Medicamento


class PrescriptionParser:
    """Parser que compara strings con nombres de medicamento en la base de datos CENABAST.
    """

    CANTIDAD_REGEX = r'\b(\d+(?:[,\.]\d+)?\s*(?:mg|miligramos?|g|gramos?|ml|mililitros?|mcg|microgramos?|ug|ui|%|mg\/ml))\b'

    _catalog_cache: Optional[Dict[str, str]] = None

    @classmethod
    def normalize_text(cls, text: str) -> str:
        """Normaliza strings."""
        if not text:
            return ""
        nfkd = unicodedata.normalize('NFKD', text)
        unacc = ''.join([c for c in nfkd if not unicodedata.combining(c)])
        clean = re.sub(r'[^a-z0-9\s]', ' ', unacc.lower())
        return re.sub(r'\s+', ' ', clean).strip()

    @classmethod
    def _clean_catalog_name(cls, raw: str) -> str:
        """Extrae unicamente el nombre del medicamento, sin dosis ni cantidad."""
        c = re.split(cls.CANTIDAD_REGEX, raw, flags=re.IGNORECASE)[0]
        c = re.sub(r'[\/\+\(\)\,\.]', ' ', c)
        return re.sub(r'\s+', ' ', c).strip()

    @classmethod
    def get_catalog(cls) -> Dict[str, str]:
        """Carga la BD CENABAST a la memoria cache."""
        if cls._catalog_cache is not None:
            return cls._catalog_cache

        raw_meds = []
        try:
            raw_meds = [m.nombre for m in Medicamento.query.all()]
        except Exception:
            try:
                from app import create_app
                app = create_app()
                with app.app_context():
                    raw_meds = [m.nombre for m in Medicamento.query.all()]
            except Exception:
                pass

        catalog: Dict[str, str] = {}
        for raw in raw_meds:
            cleaned = cls._clean_catalog_name(raw)
            norm = cls.normalize_text(cleaned)
            if len(norm) >= 3:
                catalog[norm] = cleaned.title()

        cls._catalog_cache = catalog
        return cls._catalog_cache

    @classmethod
    def resolve_medication(cls, text: str) -> Optional[str]:
        """Busca el 'match' mas largo con la BD CENABAST."""
        catalog = cls.get_catalog()
        words = cls.normalize_text(text).split()
        if not words or not catalog:
            return None

        for n in range(min(5, len(words)), 0, -1):
            for i in range(len(words) - n + 1):
                phrase = ' '.join(words[i:i+n])
                if phrase in catalog:
                    return catalog[phrase]

        for n in range(min(3, len(words)), 0, -1):
            for i in range(len(words) - n + 1):
                phrase = ' '.join(words[i:i+n])
                if len(phrase) >= 5 and not phrase.isdigit():
                    close = difflib.get_close_matches(phrase, catalog.keys(), n=1, cutoff=0.85)
                    if close:
                        return catalog[close[0]]
        return None

    @classmethod
    def parse_text_lines(cls, lines: List[str]) -> List[Dict[str, Any]]:
        """Realiza escaneo completo del texto extraido.
        """
        if not lines:
            return [{
                # Valores por defecto
                "Nombre": "Medicamento",
                "FrecuenciaHoras": 8,
                "DuracionDias": 7,
                "HoraInicio": "08:00",
                "needs_confirmation": True
            }]

        results: List[Dict[str, Any]] = []
        seen_names: set = set()

        for idx, line in enumerate(lines):
            trimmed = line.strip()
            if not trimmed:
                continue

            matched_drug = cls.resolve_medication(trimmed)
            if matched_drug:
                norm_matched = cls.normalize_text(matched_drug)
                if norm_matched in seen_names:
                    continue
                seen_names.add(norm_matched)

                strength_match = re.search(cls.CANTIDAD_REGEX, trimmed, re.IGNORECASE)
                if not strength_match and idx + 1 < len(lines):
                    strength_match = re.search(cls.CANTIDAD_REGEX, lines[idx + 1], re.IGNORECASE)

                if strength_match:
                    raw_str = strength_match.group(1).strip()
                    parts_match = re.search(r'^(\d+(?:[,\.]\d+)?)\s*([A-Za-z%]+)$', raw_str)
                    if parts_match:
                        strength = f"{parts_match.group(1)} {parts_match.group(2).lower()}"
                    else:
                        strength = raw_str
                else:
                    strength = None

                if strength and strength.lower() not in matched_drug.lower():
                    final_name = f"{matched_drug} {strength}"
                else:
                    final_name = matched_drug

                results.append({
                    "Nombre": final_name,
                    "FrecuenciaHoras": 8,
                    "DuracionDias": 7,
                    "HoraInicio": "08:00",
                    "needs_confirmation": True
                })

        if not results:
            first_valid = next((l.strip() for l in lines if len(l.strip()) >= 3), "Medicamento Detectado")
            results.append({
                "Nombre": first_valid,
                "FrecuenciaHoras": 8,
                "DuracionDias": 7,
                "HoraInicio": "08:00",
                "needs_confirmation": True
            })

        return results
