import os

class Config:
    """Base configuration for Flask application."""
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-key-midosis")
    
    # Database Configuration
    # Default to MySQL docker container, fallback to environment variable
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL",
        "mysql+pymysql://midosis_user:midosis_password@mysql:3306/midosis_db"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Upload and Data directories
    CENABAST_DATA_DIR = os.environ.get(
        "CENABAST_DATA_DIR",
        os.path.join(os.path.dirname(os.path.dirname(__file__)), "..", "data", "cenabast")
    )
