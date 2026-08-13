# Midosis - Web & Mobile Application

A university team project for medication data management and OCR processing built with Flutter, Python Flask, and MySQL.

---

## 🏗️ Architecture Overview

- **Frontend:** Single [Flutter](https://flutter.dev) codebase targeting **Web** and **Mobile** (iOS / Android). Runs natively on the host machine.
- **Backend:** Python 3.14.1 + Flask 3.1.2 API container running in Docker.
- **Database:** MySQL 9.1 container running in Docker.
- **ORM:** SQLAlchemy.
- **OCR & NLP:** EasyOCR & medSpaCy (integrated into the Flask backend container).
- **Data Source:** CENABAST `.xlsx` files placed in `data/cenabast/` for batch processing into MySQL.

---

## 📋 Prerequisites

Before starting, ensure you have installed on your host machine:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Docker Compose v2)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.30.5 or newer)

---

## 🚀 Getting Started

### 1. Start Docker Development Environment (Backend + MySQL)

From the project root directory, run:

```bash
docker compose up --build
```

This starts:
- **MySQL 9.1** on port `3306` (with healthcheck enabled)
- **Flask Backend** on port `5000` (starts automatically after MySQL is healthy)

To run containers in detached mode:
```bash
docker compose up -d
```

### 2. Verify Backend Health

Open your browser or run:

```bash
curl http://localhost:5000/health
```

Expected response:
```json
{
  "status": "ok",
  "service": "midosis-backend",
  "database": "connected"
}
```

### 3. Run the Flutter Frontend Application

Install dependencies:

```bash
cd frontend
flutter pub get
```

Run on Web:
```bash
flutter run -d chrome
```

Run on Mobile Emulator / Device:
```bash
flutter run
```

---

## 🌐 Local API Communication (Flutter ↔ Flask Backend)

When developing locally, configure your Flutter API base URL based on the target platform:

- **Web / iOS Simulator / Desktop:** `http://localhost:5000`
- **Android Emulator:** `http://10.0.2.2:5000` (points to host `localhost`)
- **Physical Device:** `http://<YOUR_COMPUTER_LOCAL_IP>:5000`

---

## 📁 Project Structure

```text
midosis/
├── backend/                  # Flask application source
│   ├── app/                  # Application package
│   │   ├── models/           # SQLAlchemy models
│   │   ├── routes/           # REST API routes (health, etc.)
│   │   ├── services/         # Business logic & CENABAST parser
│   │   ├── config.py         # App configuration
│   │   └── __init__.py       # App factory
│   ├── migrations/           # Alembic / database migrations
│   ├── tests/                # Unit tests
│   ├── Dockerfile            # Docker image build instructions
│   ├── requirements.txt      # Python dependencies
│   └── run.py                # Server entry point
│
├── frontend/                 # Flutter project (Web + Mobile)
│   ├── lib/                  # Dart source code
│   └── pubspec.yaml          # Flutter dependencies
│
├── data/
│   └── cenabast/             # Place CENABAST .xlsx files here
│
├── mysql/
│   └── init/                 # Custom initial SQL scripts (.sql)
│
├── .env.example              # Environment variables template
├── .gitignore                # Git ignore rules
├── docker-compose.yml        # Multi-container setup
└── README.md                 # Documentation
```

---

## 📊 Processing CENABAST Medication Files

CENABAST medication data is provided as `.xlsx` spreadsheets.

1. Place your `.xlsx` files inside `data/cenabast/`.
2. The folder is mounted into the Flask container at `/app/data/cenabast`.
3. The backend service (`app.services.cenabast.CenabastService`) reads and parses the Excel data into MySQL.

---

## 🛑 Stopping the Environment

To stop and remove containers:

```bash
docker compose down
```

To stop containers and reset database data volume:

```bash
docker compose down -v
```
