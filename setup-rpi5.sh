#!/bin/bash

# Tabby Web - Script de configuración para Raspberry Pi 5
# Este script ayuda a configurar Tabby Web para ejecutarse en Docker

set -e

echo "=================================================="
echo "  Tabby Web - Instalación para Raspberry Pi 5"
echo "=================================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encuentra docker-compose.yml. Ejecuta este script desde el directorio raíz del proyecto."
    exit 1
fi

# Verificar Docker
print_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado."
    echo "Instala Docker con:"
    echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "  sudo sh get-docker.sh"
    exit 1
fi

# Verificar Docker Compose
print_info "Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose no está instalado."
    echo "Instala Docker Compose con:"
    echo "  sudo apt install docker-compose -y"
    exit 1
fi

# Verificar arquitectura
ARCH=$(uname -m)
print_info "Arquitectura detectada: $ARCH"
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    print_warn "Este script está optimizado para Raspberry Pi 5 (ARM64)."
    read -p "¿Continuar de todos modos? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Crear archivo .env si no existe
if [ ! -f ".env" ]; then
    print_info "Creando archivo .env desde .env.example..."
    cp .env.example .env
    print_warn "IMPORTANTE: Debes editar el archivo .env con tus credenciales antes de continuar."
    echo ""
    echo "Edita el archivo .env con:"
    echo "  nano .env"
    echo ""
    echo "Configuración mínima requerida:"
    echo "  - DJANGO_SECRET_KEY (genera una clave única)"
    echo "  - SOCIAL_AUTH_GITHUB_KEY y SOCIAL_AUTH_GITHUB_SECRET"
    echo "  - MARIADB_PASSWORD y MYSQL_ROOT_PASSWORD"
    echo "  - FRONTEND_URL y BACKEND_URL (tu dominio)"
    echo ""
    read -p "¿Ya has configurado el archivo .env? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_info "Por favor, configura el archivo .env y ejecuta este script nuevamente."
        exit 0
    fi
else
    print_info "Archivo .env encontrado."
fi

# Verificar variables críticas en .env
print_info "Verificando configuración..."

source .env

MISSING_VARS=()

if [[ "$DJANGO_SECRET_KEY" == "CHANGE_ME_TO_A_SECURE_RANDOM_STRING" ]] || [[ -z "$DJANGO_SECRET_KEY" ]]; then
    MISSING_VARS+=("DJANGO_SECRET_KEY")
fi

if [[ -z "$SOCIAL_AUTH_GITHUB_KEY" && -z "$SOCIAL_AUTH_GITLAB_KEY" && -z "$SOCIAL_AUTH_GOOGLE_OAUTH2_KEY" && -z "$SOCIAL_AUTH_MICROSOFT_GRAPH_KEY" ]]; then
    MISSING_VARS+=("Al menos un proveedor OAuth (SOCIAL_AUTH_*_KEY)")
fi

if [[ "$MYSQL_ROOT_PASSWORD" == "CHANGE_ME" ]] || [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
    MISSING_VARS+=("MYSQL_ROOT_PASSWORD")
fi

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    print_error "Faltan las siguientes variables críticas en .env:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    print_info "Edita .env con: nano .env"
    exit 1
fi

print_info "Configuración verificada correctamente."

# Habilitar Docker BuildKit
print_info "Habilitando Docker BuildKit..."
export DOCKER_BUILDKIT=1

# Preguntar si construir o descargar
echo ""
echo "Opciones de instalación:"
echo "  1) Construir la imagen localmente (recomendado para primera instalación)"
echo "  2) Iniciar servicios (si la imagen ya está construida)"
echo "  3) Reconstruir completamente (limpia y construye de nuevo)"
echo ""
read -p "Selecciona una opción (1-3): " -n 1 -r OPTION
echo ""

case $OPTION in
    1)
        print_info "Construyendo imagen de Tabby Web..."
        print_warn "Esto puede tardar 20-40 minutos en Raspberry Pi 5..."
        docker-compose build
        ;;
    2)
        print_info "Iniciando servicios..."
        ;;
    3)
        print_info "Reconstruyendo completamente..."
        print_warn "Esto puede tardar 20-40 minutos en Raspberry Pi 5..."
        docker-compose down
        docker-compose build --no-cache
        ;;
    *)
        print_error "Opción inválida."
        exit 1
        ;;
esac

# Iniciar servicios
print_info "Iniciando servicios de Tabby Web..."
docker-compose up -d

# Esperar a que los servicios estén listos
print_info "Esperando a que los servicios inicien..."
sleep 10

# Verificar estado de los contenedores
print_info "Verificando estado de los contenedores..."
docker-compose ps

# Verificar si los contenedores están ejecutándose
if docker-compose ps | grep -q "Up"; then
    echo ""
    print_info "✓ Servicios iniciados correctamente!"
    echo ""
    
    # Información de acceso
    TABBY_PORT=${TABBY_PORT:-9090}
    echo "=================================================="
    echo "  Información de Acceso"
    echo "=================================================="
    echo ""
    echo "Acceso local:"
    echo "  http://localhost:$TABBY_PORT"
    echo ""
    if [[ ! -z "$FRONTEND_URL" ]]; then
        echo "Acceso externo (después de configurar Nginx Proxy Manager):"
        echo "  $FRONTEND_URL"
        echo ""
    fi
    echo "Siguiente paso:"
    echo "  1. Configura Nginx Proxy Manager (ver NGINX_PROXY_MANAGER_CONFIG.md)"
    echo "  2. Agrega una versión de Tabby:"
    echo "     docker-compose run --rm tabby /manage.sh add_version 1.0.187"
    echo ""
    echo "Ver logs:"
    echo "  docker-compose logs -f tabby"
    echo ""
    echo "Detener servicios:"
    echo "  docker-compose down"
    echo ""
    
else
    print_error "Hubo un problema al iniciar los servicios."
    echo ""
    print_info "Ver logs con:"
    echo "  docker-compose logs -f"
    exit 1
fi

# Ofrecer agregar versión de Tabby
echo ""
read -p "¿Deseas agregar una versión de Tabby ahora? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "Versiones disponibles en: https://www.npmjs.com/package/tabby-web-container"
    read -p "Ingresa el número de versión (ej: 1.0.187): " VERSION
    
    if [[ ! -z "$VERSION" ]]; then
        print_info "Agregando versión $VERSION..."
        docker-compose run --rm tabby /manage.sh add_version "$VERSION"
        print_info "Versión agregada correctamente."
    fi
fi

echo ""
print_info "¡Instalación completada!"
print_info "Lee INSTALL_RPI5.md para más información y configuración avanzada."
