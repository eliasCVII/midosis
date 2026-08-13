# Midosis

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o Docker Engine + Docker Compose v2)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.30.5+)

---

## Compilado

### 1. Iniciar Docker + MySQL

```bash
docker compose up --build
```

### 2. Correr la app con Flutter

Instalar dependencias:

```bash
cd frontend
flutter pub get
```

Version Web:
```bash
flutter run -d chrome
```

Version Nativa:
```bash
flutter run
```

---

## Terminar procesos

Matar docker
```bash
docker compose down
```

Matar docker y resetear base de datos

```bash
docker compose down -v
```

