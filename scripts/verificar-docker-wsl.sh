#!/usr/bin/env bash
# Verifica rapidamente se Docker responde no WSL.
set -euo pipefail

echo "== Docker PATH =="
command -v docker || { echo "docker nao encontrado no PATH"; exit 1; }

echo
echo "== docker version =="
docker version 2>/dev/null || sudo docker version

echo
echo "== docker info (resumo) =="
if docker info >/dev/null 2>&1; then
  docker info 2>/dev/null | sed -n '1,20p'
  echo
  echo "OK: Docker funcionando sem sudo."
elif sudo docker info >/dev/null 2>&1; then
  sudo docker info 2>/dev/null | sed -n '1,20p'
  echo
  echo "OK: Docker funciona com sudo. Reabra o terminal apos: sudo usermod -aG docker \$USER"
else
  echo "FALHA: daemon Docker nao esta respondendo."
  echo "Se usa Docker Desktop: Settings > Resources > WSL Integration (ative sua distro), depois: wsl --shutdown"
  echo "Se usa Engine no WSL: sudo service docker start   (ou systemctl start docker)"
  exit 1
fi
