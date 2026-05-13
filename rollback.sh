#!/bin/bash
# Uso: ./rollback.sh <SHA_DEL_COMMIT> <DOCKER_USERNAME>
# Ejemplo: ./rollback.sh e4f5g6h miusuario

SHA=$1
USUARIO=$2

if [ -z "$SHA" ] || [ -z "$USUARIO" ]; then
  echo "Uso: $0 <sha_commit> <docker_username>"
  exit 1
fi

IMAGE="$USUARIO/mi-app:$SHA"

echo "=== Iniciando rollback a $IMAGE ==="

docker pull $IMAGE

docker stop mi-app || true
docker rm mi-app || true

docker run -d \
  --name mi-app \
  --restart unless-stopped \
  -p 80:3000 \
  $IMAGE

echo "Verificando rollback..."
sleep 3
curl -sf http://localhost/health && echo "" && echo "Rollback exitoso." || echo "ERROR: el contenedor no responde."
