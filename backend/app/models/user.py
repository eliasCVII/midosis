from app.models import db

class Usuario(db.Model):
    __tablename__ = "usuario"

    id_usuario = db.Column(db.String(36), primary_key=True)
    correo = db.Column(db.String(120), unique=True, nullable=False)
    nombre = db.Column(db.String(100), nullable=False)
    rol = db.Column(db.String(20), nullable=False) # 'paciente', 'cuidador', 'administrador'

    paciente = db.relationship("Paciente", backref="usuario", uselist=False, cascade="all, delete-orphan")
    cuidador = db.relationship("Cuidador", backref="usuario", uselist=False, cascade="all, delete-orphan")
    administrador = db.relationship("Administrador", backref="usuario", uselist=False, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "IdUsuario": self.id_usuario,
            "Correo": self.correo,
            "Nombre": self.nombre,
            "Rol": self.rol
        }


class Paciente(db.Model):
    __tablename__ = "paciente"

    id_paciente = db.Column(db.String(36), primary_key=True)
    id_usuario = db.Column(db.String(36), db.ForeignKey("usuario.id_usuario"), nullable=False, unique=True)
    edad = db.Column(db.Integer, nullable=True)
    genero = db.Column(db.String(10), nullable=True)
    codigo_sincronizacion = db.Column(db.String(20), unique=True, nullable=True)

    recetas = db.relationship("Receta", backref="paciente", lazy=True, cascade="all, delete-orphan")
    calendario = db.relationship("Calendario", backref="paciente", uselist=False, cascade="all, delete-orphan")
    notas = db.relationship("Nota", backref="paciente", lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "IdPaciente": self.id_paciente,
            "IdUsuario": self.id_usuario,
            "Edad": self.edad,
            "Genero": self.genero,
            "CodigoSincronizacion": self.codigo_sincronizacion
        }


class Cuidador(db.Model):
    __tablename__ = "cuidador"

    id_cuidador = db.Column(db.String(36), primary_key=True)
    id_usuario = db.Column(db.String(36), db.ForeignKey("usuario.id_usuario"), nullable=False, unique=True)
    edad = db.Column(db.Integer, nullable=True)

    def to_dict(self):
        return {
            "IdCuidador": self.id_cuidador,
            "IdUsuario": self.id_usuario,
            "Edad": self.edad
        }


class Administrador(db.Model):
    __tablename__ = "administrador"

    id_administrador = db.Column(db.String(36), primary_key=True)
    id_usuario = db.Column(db.String(36), db.ForeignKey("usuario.id_usuario"), nullable=False, unique=True)
    institucion = db.Column(db.String(150), nullable=True)
    telefono = db.Column(db.String(30), nullable=True)

    def to_dict(self):
        return {
            "IdAdministrador": self.id_administrador,
            "IdUsuario": self.id_usuario,
            "Institucion": self.institucion,
            "Telefono": self.telefono
        }
