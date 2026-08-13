FROM python:3.14.1-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=5000 \
    FLASK_APP=run.py \
    FLASK_RUN_HOST=0.0.0.0

WORKDIR /app

# Install system dependencies required for OpenCV (EasyOCR) and compiling packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

# Expose backend port
EXPOSE 5000

# Run Flask application
CMD ["python", "run.py"]
