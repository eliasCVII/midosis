import os
from typing import Dict, Any
import openpyxl
from app.models import db, Medicamento


class CenabastService:
    def __init__(self, data_dir: str = None):
        self.data_dir = data_dir or os.getenv("CENABAST_DATA_DIR", "/app/data/cenabast")

    def list_cenabast_files(self):
        """List all available CENABAST excel files in the target data directory."""
        if not os.path.exists(self.data_dir):
            return []
        return [f for f in os.listdir(self.data_dir) if f.endswith(".xlsx")]

    def import_excel_data(self, file_path: str = None) -> Dict[str, Any]:
        """Reads and imports CENABAST XLSX data into MySQL database as Medicamento records."""
        if not file_path:
            files = self.list_cenabast_files()
            if not files:
                return {"error": f"No se encontraron archivos .xlsx en {self.data_dir}"}, 404
            file_path = os.path.join(self.data_dir, files[0])

        if not os.path.exists(file_path):
            return {"error": f"El archivo {file_path} no existe"}, 404

        wb = openpyxl.load_workbook(file_path, read_only=True)
        sheet = wb.active

        imported_count = 0
        updated_count = 0

        for i, row in enumerate(sheet.iter_rows(values_only=True)):
            if i == 0 or not row:
                continue

            if len(row) < 4:
                continue

            codigo_gen, nombre_gen, desc_gen, tipo_prod = row[0], row[1], row[2], row[3]

            if not tipo_prod or str(tipo_prod).strip() != "Fármacos" or not nombre_gen:
                continue

            nombre_upper = str(nombre_gen).strip().upper()
            if any(term in nombre_upper for term in ["BORRAR", "MARCADO PARA BORRAR", "DESCONTINUADO", "OBSOLETO", "CANCELADO", "NO USAR"]):
                continue

            med_id = f"cenabast_{codigo_gen}"
            nombre_clean = str(nombre_gen).strip()[:150]
            desc_clean = "Información del medicamento"
            efectos_clean = "No registrados"


            med = db.session.get(Medicamento, med_id)
            if not med:
                med = Medicamento(
                    id_medicamento=med_id,
                    nombre=nombre_clean,
                    descripcion=desc_clean,
                    efectos_secundarios=efectos_clean
                )
                db.session.add(med)
                imported_count += 1
            else:
                med.nombre = nombre_clean
                med.descripcion = desc_clean
                med.efectos_secundarios = efectos_clean
                updated_count += 1

        # Purge any obsolete or marked-for-deletion items from the database
        for term in ["BORRAR", "DESCONTINUADO", "OBSOLETO", "CANCELADO", "NO USAR"]:
            Medicamento.query.filter(Medicamento.nombre.ilike(f"%{term}%")).delete(synchronize_session=False)

        db.session.commit()

        return {
            "status": "success",
            "message": f"Importación completada: {imported_count} nuevos medicamentos agregados, {updated_count} actualizados.",
            "imported_count": imported_count,
            "updated_count": updated_count,
            "file": file_path
        }, 200

