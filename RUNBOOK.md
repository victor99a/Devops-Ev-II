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

## Setup: Self-Hosted Runner (auto-sync con CI)

Esto configura tu laptop como runner de GitHub Actions. Cuando el pipeline termina,
el job `sync-local` ejecuta `git pull` y `docker compose up -d --build` EN TU MAQUINA.

### Instalacion (una sola vez)

1. Ve a **Settings → Actions → Runners → New self-hosted runner**
2. Elige macOS, sigue las instrucciones (descargar + configurar + `./run.sh`)
3. Inicia el runner como servicio:
   ```bash
   cd ~/actions-runner
   ./svc.sh install && ./svc.sh start
   ```
4. Verifica que aparece como "Idle" en Settings → Actions → Runners

El job `sync-local` en el pipeline usa `runs-on: self-hosted` y ejecuta:

```yaml
- name: Pull latest from main
  run: cd $HOME/Devops/demo-ms && git pull origin main

- name: Redeploy with Docker Compose
  run: cd $HOME/Devops/demo-ms && docker compose up -d --build
```

## Alternativa sin runner: sync.sh por polling

Si no quieres configurar el self-hosted runner, usa el script de polling:

```bash
./sync.sh   # monitorea origin/main cada 10s, hace git pull + redeploy al detectar cambios
```

## Flujo demo: cambio de mensaje + pipeline end-to-end

### Paso 1 — Levantar servicios

```bash
docker compose up -d --build
```

### Paso 2 — Ver el mensaje actual

```bash
curl -s -X POST "http://localhost:8080/api/v1/greetings?name=Demo" | python3 -m json.tool
# "message": "Hello devops V4, Demo!"
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

### Paso 5 — Pipeline se ejecuta, local se actualiza solo

- Pipeline en GitHub Actions: `build → security → deploy → sync-local`
- El job `sync-local` corre en tu **self-hosted runner** (tu laptop)
- Ejecuta `git pull` + `docker compose up -d --build` automaticamente
- O si usas `./sync.sh`, detecta el commit nuevo y redeploya

### Paso 6 — Verificar el cambio

```bash
curl -s -X POST "http://localhost:8080/api/v1/greetings?name=Demo" | python3 -m json.tool
# "message": "Hola mundo V5, Demo!"
```
