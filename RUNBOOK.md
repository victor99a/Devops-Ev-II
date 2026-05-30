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

## Flujo demo: cambio de mensaje + pipeline end-to-end

Para demostrar que el pipeline funciona de punta a punta, se modifica el string del saludo
y se observa como el pipeline valida el cambio y actualiza el despliegue local automaticamente.

### Paso 1 — Levantar servicios y el sync

```bash
# Terminal 1: levantar Docker Compose
docker compose up -d --build

# Terminal 2: iniciar el monitor de cambios (auto-pull + redeploy)
./sync.sh
```

### Paso 2 — Ver el mensaje actual

```bash
curl -s -X POST "http://localhost:8080/api/v1/greetings?name=Demo" | python3 -m json.tool
# Respuesta: "message": "Hello devops V4, Demo!"
```

### Paso 3 — Modificar el mensaje

Editar `src/main/java/com/example/demo/application/service/GreetingServiceImpl.java`:

```java
// Antes:
String message = "Hello devops V4, " + name + "!";

// Despues:
String message = "Hola mundo V5, " + name + "!";
```

### Paso 4 — Commit + push (dispara el pipeline)

```bash
git add -A
git commit -m "feat: cambiar mensaje de greeting a V5"
git push
```

### Paso 5 — Observar

- El pipeline se ejecuta en GitHub Actions (build → test → Snyk → deploy)
- Al terminar, la terminal con `./sync.sh` detecta el nuevo commit
- Hace `git pull` + `docker compose up -d --build` automaticamente
- Al volver a probar el endpoint, el mensaje ya refleja el cambio

```bash
curl -s -X POST "http://localhost:8080/api/v1/greetings?name=Demo" | python3 -m json.tool
# Respuesta: "message": "Hola mundo V5, Demo!"
```
