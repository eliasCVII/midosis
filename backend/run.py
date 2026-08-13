import os
from dotenv import load_dotenv
from app import create_app

# Load environment variables from .env if present
load_dotenv()

app = create_app()

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    host = os.environ.get("FLASK_RUN_HOST", "0.0.0.0")
    debug = os.environ.get("FLASK_DEBUG", "1") == "1"
    
    app.run(host=host, port=port, debug=debug)
