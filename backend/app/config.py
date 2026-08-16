import os

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-key-midosis")

    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL",
        "mysql+pymysql://midosis_user:midosis_password@mysql:3306/midosis_db"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    CENABAST_DATA_DIR = os.environ.get(
        "CENABAST_DATA_DIR",
        os.path.join(os.path.dirname(os.path.dirname(__file__)), "..", "data", "cenabast")
    )
