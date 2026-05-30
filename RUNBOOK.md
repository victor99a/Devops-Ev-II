# demo-ms — Guia de Ejecucion

## Requisitos

- Java 17+
- Maven 3.9+
- Docker + Docker Compose

## Ejecucion local (sin Docker)

```bash
# Compilar, ejecutar tests y validar cobertura
mvn clean verify

# Solo compilar sin tests
mvn clean package -DskipTests

# Ejecutar el JAR (necesita PostgreSQL corriendo o configurar DB_HOST)
java -jar target/demo-ms-1.0.0.jar
```

## Ejecucion con Docker Compose (recomendado)

Levanta PostgreSQL 15 + la app con un solo comando:

```bash
# Construir e iniciar ambos servicios
docker compose up -d --build

# Ver estado
docker compose ps

# Ver logs
docker compose logs -f app

# Detener
docker compose down

# Detener y borrar volumen de BD
docker compose down -v
```

## Probar endpoints

```bash
# Health check
curl http://localhost:8080/actuator/health

# Listar saludos
curl http://localhost:8080/api/v1/greetings

# Crear saludo
curl -X POST "http://localhost:8080/api/v1/greetings?name=Duoc"

# Buscar por ID
curl http://localhost:8080/api/v1/greetings/1

# Buscar ID inexistente (404)
curl -i http://localhost:8080/api/v1/greetings/99
```

## Variables de entorno

| Variable | Default | Uso |
|---|---|---|
| `SERVER_PORT` | `8080` | Puerto de la app |
| `DB_HOST` | `localhost` | Host PostgreSQL |
| `DB_PORT` | `5432` | Puerto PostgreSQL |
| `DB_NAME` | `demo` | Nombre BD |
| `DB_USER` | `postgres` | Usuario BD |
| `DB_PASS` | `postgres` | Password BD |

Ejemplo con variables custom:

```bash
DB_HOST=192.168.1.100 DB_NAME=produccion java -jar target/demo-ms-1.0.0.jar
```
