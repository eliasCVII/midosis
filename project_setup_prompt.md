# CLI Project Initialization Prompt

Act as a senior software engineer helping me initialize a university team project.

Create the initial project structure and Docker development environment for a **web app + mobile app** with the following architecture:

- **Frontend:** Flutter
  - One Flutter project targeting both Web and Mobile.
  - Keep Flutter running natively on the host machine rather than inside Docker.
- **Backend:** Python 3.14.1 + Flask 3.1.2
- **Database:** MySQL 9.1
- **ORM:** SQLAlchemy
- **OCR:** EasyOCR
- **NLP:** medSpaCy
- **External data:** CENABAST is **not an external API/database**. It is an `.xlsx` file containing medication information that the backend will process/import into MySQL.

The main goal is to make development easy and reproducible for a team: a new developer should be able to clone the repository, start Docker, install Flutter dependencies, and begin working with minimal manual setup.

## Project structure

Create this initial structure:

```text
project/
├── backend/
│   ├── app/
│   │   ├── routes/
│   │   ├── models/
│   │   ├── services/
│   │   └── __init__.py
│   ├── migrations/
│   ├── tests/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── run.py
│
├── frontend/
│   └── [Flutter project]
│
├── data/
│   └── cenabast/
│       └── .gitkeep
│
├── mysql/
│   └── init/
│
├── .env.example
├── .gitignore
├── docker-compose.yml
└── README.md
```

## Docker Compose

Configure Docker Compose with **two services only**:

### 1. `backend`

- Build from `backend/Dockerfile`.
- Use Python 3.14.1.
- Install Flask.
- Install SQLAlchemy.
- Install EasyOCR.
- Install medSpaCy.
- Expose Flask on port `5000`.
- Mount the backend source for development.
- Mount `data/cenabast` into the container so the backend can access CENABAST XLSX files.
- Use environment variables for database configuration.
- Make Flask listen on `0.0.0.0`.
- Include a simple `/health` endpoint that confirms the backend is running.
- Configure the service to wait for MySQL to become healthy before starting.

### 2. `mysql`

- Use MySQL 9.1.
- Persist its data using a named Docker volume.
- Create a development database, user, and password from environment variables.
- Include a healthcheck.
- Make the backend depend on the MySQL healthcheck.

Do **not** create a SQLite service or SQLite database. We have decided to use MySQL as the only application database.

## Backend architecture

Use SQLAlchemy in a way that keeps the application relatively database-agnostic.

Set up the backend so that database migrations can be added later using Alembic or Flask-Migrate, but don't overengineer the migration system yet.

Create:

- A basic database configuration module.
- A minimal Flask application.
- A simple `/health` endpoint.
- A clean application structure suitable for adding REST API routes later.

Also create a placeholder CENABAST service:

```text
backend/app/services/cenabast.py
```

It should eventually be responsible for reading/importing the CENABAST `.xlsx` file.

Do not implement the actual CENABAST import logic yet. Just establish a clean interface/place for it.

## Environment variables

Use environment variables rather than hardcoding credentials.

Create:

```text
.env.example
```

with sensible development defaults.

Make sure:

```text
.env
```

is ignored by `.gitignore`.

## README

Create a minimal `README.md` explaining:

1. Required host software:
   - Docker
   - Docker Compose
   - Flutter 3.30.5

2. How to start the backend and MySQL:

```bash
docker compose up --build
```

3. How to check the backend health endpoint.

4. How to install Flutter dependencies:

```bash
cd frontend
flutter pub get
```

5. How Flutter should communicate with the Flask API during local development.

6. How to stop the Docker environment.

7. How CENABAST XLSX files should eventually be placed in:

```text
data/cenabast/
```

## Flutter

Do **not** put Flutter inside Docker.

If a Flutter project already exists, reuse it rather than generating another one.

If no Flutter project exists, create the appropriate Flutter project in `frontend/`, targeting Web and Mobile.

Do not create separate web and mobile codebases.

## Validation

Before creating files, inspect the existing directory so you don't overwrite or destroy existing project files.

After creating everything, validate the setup as much as possible:

- Validate the Docker Compose configuration.
- Build the backend image.
- Start the containers if Docker is available.
- Verify that Flask can start.
- Verify that MySQL becomes healthy.
- Verify that the backend can connect to MySQL.
- Verify that the Python imports for Flask, SQLAlchemy, EasyOCR, and medSpaCy work.
- Verify the `/health` endpoint.
- If Flutter is available, verify that the Flutter project is valid and that dependencies can be resolved.

If any dependency/version combination is incompatible with Python 3.14.1, **do not silently change versions**. Report the incompatibility and explain what needs to be changed.

Keep the setup simple, clean, and suitable for a university team project.

Do not implement application features yet. This task is only for establishing the project structure and reproducible development environment.

Do not add unnecessary services such as:

- Redis
- Nginx
- Celery
- Kubernetes
- Additional databases
- Separate frontend containers
- Separate web/mobile projects
