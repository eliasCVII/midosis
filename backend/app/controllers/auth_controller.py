import uuid
from app.models import db, Usuario, Paciente, Cuidador, Administrador, Calendario

class AuthController:
    @staticmethod
    def login_google(data):
        email = data.get("email") or data.get("Correo")
        name = data.get("name") or data.get("Nombre") or "Usuario Google"
        role = data.get("role") or data.get("Rol") or "paciente"

        if not email:
            return {"error": "El correo electrónico es requerido"}, 400

        email = email.strip().lower()
        role = role.strip().lower()
        if role not in ["paciente", "cuidador", "administrador"]:
            role = "paciente"

        user = Usuario.query.filter_by(correo=email).first()
        if not user:
            user_id = f"user_{uuid.uuid4().hex[:12]}"
            user = Usuario(
                id_usuario=user_id,
                correo=email,
                nombre=name,
                rol=role
            )
            db.session.add(user)
            db.session.flush()
        else:
            user.rol = role
            if name and name != "Usuario Google":
                user.nombre = name

        paciente_dict = None
        cuidador_dict = None
        admin_dict = None

        paciente = Paciente.query.filter_by(id_usuario=user.id_usuario).first()
        if not paciente:
            raw_code = str(uuid.uuid4()).replace("-", "").upper()
            sync_code = f"{raw_code[:3]}-{raw_code[3:6]}"
            paciente_id = f"paciente_{uuid.uuid4().hex[:12]}"
            paciente = Paciente(
                id_paciente=paciente_id,
                id_usuario=user.id_usuario,
                codigo_sincronizacion=sync_code
            )
            db.session.add(paciente)
            db.session.flush()

            cal_id = f"cal_{uuid.uuid4().hex[:12]}"
            calendario = Calendario(
                id_calendario=cal_id,
                id_paciente=paciente.id_paciente
            )
            db.session.add(calendario)
        else:
            cal = Calendario.query.filter_by(id_paciente=paciente.id_paciente).first()
            if not cal:
                cal_id = f"cal_{uuid.uuid4().hex[:12]}"
                cal = Calendario(
                    id_calendario=cal_id,
                    id_paciente=paciente.id_paciente
                )
                db.session.add(cal)

        paciente_dict = paciente.to_dict()

        cuidador = Cuidador.query.filter_by(id_usuario=user.id_usuario).first()
        if not cuidador:
            cuidador_id = f"cuidador_{uuid.uuid4().hex[:12]}"
            cuidador = Cuidador(
                id_cuidador=cuidador_id,
                id_usuario=user.id_usuario
            )
            db.session.add(cuidador)
            db.session.flush()
        cuidador_dict = cuidador.to_dict()

        if user.rol == "administrador":
            admin = Administrador.query.filter_by(id_usuario=user.id_usuario).first()
            if not admin:
                admin_id = f"admin_{uuid.uuid4().hex[:12]}"
                admin = Administrador(
                    id_administrador=admin_id,
                    id_usuario=user.id_usuario,
                    institucion="MiDosis Central"
                )
                db.session.add(admin)
                db.session.flush()
            admin_dict = admin.to_dict()

        db.session.commit()

        return {
            "status": "success",
            "message": "Autenticación exitosa",
            "usuario": user.to_dict(),
            "paciente": paciente_dict,
            "cuidador": cuidador_dict,
            "administrador": admin_dict
        }, 200

    @staticmethod
    def switch_role(data):
        user_id = data.get("id_usuario") or data.get("idUsuario")
        email = data.get("email") or data.get("correo")
        new_role = data.get("role") or data.get("new_role") or data.get("rol")

        if not new_role or new_role.strip().lower() not in ["paciente", "cuidador", "administrador"]:
            return {"error": "Rol inválido"}, 400

        new_role = new_role.strip().lower()
        user = None
        if user_id:
            user = db.session.get(Usuario, user_id)
        elif email:
            user = Usuario.query.filter_by(correo=email.strip().lower()).first()

        if not user:
            return {"error": "Usuario no encontrado"}, 404

        user.rol = new_role

        paciente = Paciente.query.filter_by(id_usuario=user.id_usuario).first()
        if not paciente:
            raw_code = str(uuid.uuid4()).replace("-", "").upper()
            sync_code = f"{raw_code[:3]}-{raw_code[3:6]}"
            paciente_id = f"paciente_{uuid.uuid4().hex[:12]}"
            paciente = Paciente(
                id_paciente=paciente_id,
                id_usuario=user.id_usuario,
                codigo_sincronizacion=sync_code
            )
            db.session.add(paciente)
            db.session.flush()

            cal_id = f"cal_{uuid.uuid4().hex[:12]}"
            calendario = Calendario(
                id_calendario=cal_id,
                id_paciente=paciente.id_paciente
            )
            db.session.add(calendario)
        else:
            cal = Calendario.query.filter_by(id_paciente=paciente.id_paciente).first()
            if not cal:
                cal_id = f"cal_{uuid.uuid4().hex[:12]}"
                cal = Calendario(
                    id_calendario=cal_id,
                    id_paciente=paciente.id_paciente
                )
                db.session.add(cal)

        cuidador = Cuidador.query.filter_by(id_usuario=user.id_usuario).first()
        if not cuidador:
            cuidador_id = f"cuidador_{uuid.uuid4().hex[:12]}"
            cuidador = Cuidador(
                id_cuidador=cuidador_id,
                id_usuario=user.id_usuario
            )
            db.session.add(cuidador)

        db.session.commit()

        return {
            "status": "success",
            "message": f"Rol cambiado a {new_role}",
            "usuario": user.to_dict(),
            "paciente": paciente.to_dict() if paciente else None,
            "cuidador": cuidador.to_dict() if cuidador else None
        }, 200

    @staticmethod
    def get_user_profile(id_usuario):
        user = db.session.get(Usuario, id_usuario)
        if not user:
            return {"error": "Usuario no encontrado"}, 404

        paciente = Paciente.query.filter_by(id_usuario=user.id_usuario).first()
        cuidador = Cuidador.query.filter_by(id_usuario=user.id_usuario).first()
        admin = Administrador.query.filter_by(id_usuario=user.id_usuario).first()

        return {
            "status": "success",
            "usuario": user.to_dict(),
            "paciente": paciente.to_dict() if paciente else None,
            "cuidador": cuidador.to_dict() if cuidador else None,
            "administrador": admin.to_dict() if admin else None
        }, 200
