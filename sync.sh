#!/bin/bash
set -e

echo "🔍 Monitoreando origin/main cada 10s..."
echo "   Cambia el mensaje en GreetingServiceImpl, haz push, y mira como se actualiza solo."
echo ""

while true; do
  git fetch origin 2>/dev/null
  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse origin/main)

  if [ "$LOCAL" != "$REMOTE" ]; then
    echo ""
    echo "📦 Nuevo commit detectado: $(git log --oneline -1 origin/main)"
    echo "⬇️  Haciendo git pull..."
    git pull

    if docker compose ps | grep -q "demo-ms"; then
      echo "🔁 Redeploy con Docker Compose..."
      docker compose up -d --build
    fi

    echo "✅ Listo. Prueba el endpoint:"
    echo "   curl http://localhost:8080/api/v1/greetings"
    echo ""
  fi

  sleep 10
done
