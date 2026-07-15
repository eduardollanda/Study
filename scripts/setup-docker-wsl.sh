#!/usr/bin/env bash
# Configura Docker no WSL2 (Ubuntu/Debian).
# Preferencia: Docker Desktop no Windows com integracao WSL.
# Alternativa: Docker Engine instalado diretamente nesta distro.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[ok]${NC} $*"; }
warn()  { echo -e "${YELLOW}[aviso]${NC} $*"; }
fail()  { echo -e "${RED}[erro]${NC} $*"; exit 1; }
step()  { echo -e "\n==> $*"; }

require_sudo() {
  if [[ "${EUID}" -eq 0 ]]; then
    return
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo nao encontrado. Rode como root ou instale sudo."
  fi
  sudo -v || fail "Nao foi possivel obter privilegios de administrador."
}

is_wsl() {
  grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]
}

docker_works() {
  docker info >/dev/null 2>&1
}

desktop_cli_present() {
  [[ -x /mnt/wsl/docker-desktop/cli-tools/usr/bin/docker ]] \
    || [[ -x /usr/local/bin/docker ]] \
    || command -v docker.exe >/dev/null 2>&1
}

ensure_wsl() {
  step "Verificando se estamos no WSL"
  if ! is_wsl; then
    fail "Este script deve rodar dentro de uma distro WSL2 (ex.: Ubuntu)."
  fi
  info "WSL detectado (${WSL_DISTRO_NAME:-distro desconhecida})"

  if command -v wsl.exe >/dev/null 2>&1; then
    warn "Confira no PowerShell se a distro esta em versao 2: wsl -l -v"
  fi
}

print_desktop_instructions() {
  cat <<'EOF'

----------------------------------------------------------------------
Caminho recomendado (Docker Desktop + WSL):

1) No PowerShell (Admin), garanta WSL2:
   wsl --update
   wsl --set-default-version 2
   wsl -l -v

2) Instale Docker Desktop no Windows:
   https://docs.docker.com/desktop/setup/install/windows-install/

3) Abra Docker Desktop > Settings:
   - General: "Use the WSL 2 based engine" ativo
   - Resources > WSL Integration:
     - Enable integration with my default WSL distro
     - Ative tambem a toggle da sua distro (Ubuntu, etc.)
   - Apply & Restart

4) No PowerShell:
   wsl --shutdown
   Depois abra de novo o Ubuntu e o Docker Desktop.

5) No WSL, teste:
   docker version
   docker run --rm hello-world

6) No Cursor (Windows):
   - Extensao: anysphere.remote-wsl
   - Se for usar Dev Containers: anysphere.remote-containers
   - Remova as extensoes Microsoft equivalentes se estiverem instaladas
   - Abra o projeto pelo filesystem do WSL (/home/...), nao por C:\
----------------------------------------------------------------------
EOF
}

try_start_docker_service() {
  if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    sudo systemctl enable --now docker >/dev/null 2>&1 || true
    sudo systemctl start docker >/dev/null 2>&1 || true
    return
  fi

  # WSL sem systemd completo
  if command -v service >/dev/null 2>&1; then
    sudo service docker start >/dev/null 2>&1 || true
  fi
}

configure_docker_group() {
  local user_name="${SUDO_USER:-${USER}}"
  if [[ "${user_name}" == "root" ]]; then
    warn "Rodando como root; pulando grupo docker."
    return
  fi

  if ! getent group docker >/dev/null 2>&1; then
    sudo groupadd docker
  fi

  if id -nG "${user_name}" | tr ' ' '\n' | grep -qx docker; then
    info "Usuario ${user_name} ja esta no grupo docker"
  else
    sudo usermod -aG docker "${user_name}"
    warn "Usuario ${user_name} adicionado ao grupo docker."
    warn "Feche e reabra o terminal WSL (ou rode: newgrp docker) para usar docker sem sudo."
  fi
}

install_docker_engine() {
  step "Instalando Docker Engine nesta distro WSL"

  if [[ ! -f /etc/os-release ]]; then
    fail "Arquivo /etc/os-release nao encontrado."
  fi
  # shellcheck disable=SC1091
  . /etc/os-release

  case "${ID:-}" in
    ubuntu|debian) ;;
    *)
      fail "Distro '${ID:-desconhecida}' nao suportada por este script. Use Ubuntu/Debian ou Docker Desktop."
      ;;
  esac

  require_sudo

  step "Removendo pacotes conflitantes (se existirem)"
  sudo apt-get remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc \
    >/dev/null 2>&1 || true

  step "Preparando repositorio oficial Docker"
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  local codename="${VERSION_CODENAME:-}"
  if [[ -z "${codename}" ]]; then
    fail "Nao foi possivel detectar VERSION_CODENAME."
  fi

  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/${ID}
Suites: ${codename}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo apt-get update -y
  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  configure_docker_group
  try_start_docker_service
}

verify_docker() {
  step "Verificando Docker"

  if ! command -v docker >/dev/null 2>&1; then
    fail "Comando docker nao encontrado no PATH."
  fi

  echo "--- docker version ---"
  docker version || sudo docker version

  if docker_works || sudo docker info >/dev/null 2>&1; then
    info "Daemon Docker respondendo"
  else
    fail "Docker CLI existe, mas o daemon nao responde. Se usa Desktop, ative a WSL Integration e rode wsl --shutdown."
  fi

  step "Teste hello-world"
  if docker_works; then
    docker run --rm hello-world
  else
    sudo docker run --rm hello-world
    warn "Funcionou com sudo. Reabra o terminal apos entrar no grupo docker."
  fi

  info "Docker esta funcionando no WSL."
}

usage() {
  cat <<'EOF'
Uso: ./scripts/setup-docker-wsl.sh [opcao]

Opcoes:
  (sem args)       Detecta o estado e pergunta o que fazer
  --desktop-help   Mostra o passo a passo do Docker Desktop + WSL + Cursor
  --engine         Instala Docker Engine nesta distro (nao interativo)
  --check          So verifica se o Docker esta funcionando
  -h, --help       Ajuda
EOF
}

main() {
  local mode="${1:-}"

  case "${mode}" in
    -h|--help)
      usage
      exit 0
      ;;
    --desktop-help)
      print_desktop_instructions
      exit 0
      ;;
  esac

  echo "Setup Docker no WSL"
  ensure_wsl

  if [[ "${mode}" == "--check" ]]; then
    verify_docker
    exit 0
  fi

  if docker_works; then
    info "Docker ja esta funcionando."
    docker version
    exit 0
  fi

  if command -v docker >/dev/null 2>&1; then
    warn "docker esta no PATH, mas o daemon nao responde."
    try_start_docker_service
    if docker_works || sudo docker info >/dev/null 2>&1; then
      configure_docker_group
      verify_docker
      exit 0
    fi
  fi

  if [[ "${mode}" == "--engine" ]]; then
    install_docker_engine
    verify_docker
    exit 0
  fi

  if desktop_cli_present; then
    warn "Parece que o Docker Desktop esta parcial/instalado, mas a integracao WSL nao esta ok."
    print_desktop_instructions
    exit 1
  fi

  if [[ -n "${mode}" ]]; then
    usage
    fail "Opcao desconhecida: ${mode}"
  fi

  echo
  echo "Nenhum Docker funcional detectado."
  echo "Escolha uma opcao:"
  echo "  1) Ver instrucoes do Docker Desktop (recomendado com Cursor no Windows)"
  echo "  2) Instalar Docker Engine direto nesta distro WSL"
  echo "  3) Sair"
  read -r -p "Opcao [1/2/3]: " choice

  case "${choice}" in
    1)
      print_desktop_instructions
      ;;
    2)
      install_docker_engine
      verify_docker
      ;;
    *)
      echo "Cancelado."
      exit 0
      ;;
  esac
}

main "${1:-}"
