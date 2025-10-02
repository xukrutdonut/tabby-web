# Instalación de Tabby Web en Raspberry Pi 5 con Docker

Esta guía describe cómo instalar Tabby Web en una Raspberry Pi 5 usando Docker, configurado para funcionar detrás de Nginx Proxy Manager (que se ejecuta en otra Raspberry Pi 5), y con integración de Tabby Connection Gateway.

## Requisitos Previos

### Hardware
- Raspberry Pi 5 (4GB RAM mínimo, 8GB recomendado)
- Tarjeta microSD de 32GB o más (recomendado: 64GB+ con SSD USB)
- Conexión de red estable

### Software
- Raspberry Pi OS (64-bit) - Bookworm o posterior
- Docker Engine y Docker Compose
- Nginx Proxy Manager (ejecutándose en otra RPi5)
- Dominio configurado: `tabby.serviciosylaboratoriodomestico.site`

## 1. Preparación del Sistema

### Instalar Docker en Raspberry Pi 5

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo apt install docker-compose -y

# Reiniciar para aplicar cambios de grupo
sudo reboot
```

### Verificar la instalación

```bash
docker --version
docker-compose --version
```

## 2. Configurar OAuth para Autenticación

Tabby Web requiere al menos un proveedor OAuth para la autenticación. Se recomienda GitHub OAuth.

### GitHub OAuth

1. Ve a https://github.com/settings/developers
2. Click en "New OAuth App"
3. Configura:
   - **Application name**: Tabby Web
   - **Homepage URL**: `https://tabby.serviciosylaboratoriodomestico.site`
   - **Authorization callback URL**: `https://tabby.serviciosylaboratoriodomestico.site/api/1/auth/social/complete/github/`
4. Guarda el **Client ID** y **Client Secret**

### Otros proveedores OAuth (Opcional)

#### GitLab OAuth
- URL de callback: `https://tabby.serviciosylaboratoriodomestico.site/api/1/auth/social/complete/gitlab/`

#### Google OAuth
- URL de callback: `https://tabby.serviciosylaboratoriodomestico.site/api/1/auth/social/complete/google-oauth2/`

#### Microsoft OAuth
- URL de callback: `https://tabby.serviciosylaboratoriodomestico.site/api/1/auth/social/complete/azuread-oauth2/`

## 3. Clonar el Repositorio

```bash
cd ~
git clone https://github.com/xukrutdonut/tabby-web.git
cd tabby-web
```

## 4. Configurar Variables de Entorno

### Copiar el archivo de ejemplo

```bash
cp .env.example .env
```

### Editar el archivo .env

```bash
nano .env
```

Configuración mínima requerida:

```bash
# Base de datos
DATABASE_URL=mysql://root:TU_PASSWORD_SEGURO@db/tabby

# Django Secret Key (genera uno único)
DJANGO_SECRET_KEY=tu_clave_secreta_aqui_generala_aleatoriamente

# URLs del dominio
FRONTEND_URL=https://tabby.serviciosylaboratoriodomestico.site
BACKEND_URL=https://tabby.serviciosylaboratoriodomestico.site

# OAuth GitHub (obligatorio)
SOCIAL_AUTH_GITHUB_KEY=tu_github_client_id
SOCIAL_AUTH_GITHUB_SECRET=tu_github_client_secret

# Contraseñas de MariaDB
MARIADB_PASSWORD=TU_PASSWORD_SEGURO
MYSQL_ROOT_PASSWORD=TU_PASSWORD_SEGURO

# Puerto (default: 9090)
TABBY_PORT=9090
```

### Generar una clave secreta de Django

```bash
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

Copia la salida y úsala como `DJANGO_SECRET_KEY` en tu archivo `.env`.

## 5. Habilitar Docker BuildKit

```bash
export DOCKER_BUILDKIT=1
echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc
```

## 6. Construir y Ejecutar los Contenedores

### Primera construcción (puede tardar 20-40 minutos en RPi5)

```bash
docker-compose build --no-cache
```

### Iniciar los servicios

```bash
docker-compose up -d
```

### Verificar que los contenedores estén funcionando

```bash
docker-compose ps
docker-compose logs -f tabby
```

## 7. Agregar Versiones de Tabby

Después de que los contenedores estén funcionando, agrega versiones de Tabby:

```bash
# Ver versiones disponibles en: https://www.npmjs.com/package/tabby-web-container

# Agregar una versión específica
docker-compose run --rm tabby /manage.sh add_version 1.0.187

# O la versión más reciente
docker-compose run --rm tabby /manage.sh add_version 1.0.187-nightly.1
```

## 8. Configurar Nginx Proxy Manager

En tu Nginx Proxy Manager (en la otra RPi5):

### Crear Proxy Host

1. **Domain Names**: `tabby.serviciosylaboratoriodomestico.site`
2. **Scheme**: `http`
3. **Forward Hostname / IP**: `IP_DE_TU_RPI5_CON_TABBY` (ejemplo: `192.168.1.100`)
4. **Forward Port**: `9090` (o el puerto que configuraste en `TABBY_PORT`)
5. **Cache Assets**: ✓ (habilitado)
6. **Block Common Exploits**: ✓ (habilitado)
7. **Websockets Support**: ✓ (habilitado) - **IMPORTANTE para Tabby**

### SSL

1. **SSL Certificate**: Solicita un certificado Let's Encrypt
2. **Force SSL**: ✓ (habilitado)
3. **HTTP/2 Support**: ✓ (habilitado)
4. **HSTS Enabled**: ✓ (habilitado)

### Custom Locations (Opcional pero recomendado)

Agrega una ubicación personalizada para WebSockets:

**Location**: `/`

**Custom config**:
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header Host $host;
proxy_http_version 1.1;
proxy_buffering off;
proxy_read_timeout 86400;
```

## 9. Configurar Tabby Connection Gateway (Opcional)

Para habilitar conexiones SSH/Telnet a través de Tabby Web:

### Opción A: Usar el Gateway Público (Más Simple)

1. Inicia sesión en tu instancia de Tabby Web
2. Ve a Configuración (Settings)
3. Ingresa la dirección del gateway público y el token de autenticación proporcionado

### Opción B: Ejecutar tu Propio Gateway (Más Seguro)

```bash
# En un directorio separado
cd ~
git clone https://github.com/Eugeny/tabby-connection-gateway.git
cd tabby-connection-gateway

# Seguir las instrucciones del README para configurar
# Generar certificados y configurar en .env de tabby-web:
# CONNECTION_GATEWAY_AUTH_CA=/path/to/ca.crt
# CONNECTION_GATEWAY_AUTH_CERTIFICATE=/path/to/cert.crt
# CONNECTION_GATEWAY_AUTH_KEY=/path/to/key.key
```

## 10. Verificación y Pruebas

### Verificar acceso local

```bash
curl http://localhost:9090
```

### Verificar acceso externo

Abre tu navegador y ve a: `https://tabby.serviciosylaboratoriodomestico.site`

### Logs

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Ver logs solo de tabby
docker-compose logs -f tabby

# Ver logs solo de la base de datos
docker-compose logs -f db
```

## 11. Mantenimiento

### Actualizar Tabby Web

```bash
cd ~/tabby-web
git pull
export DOCKER_BUILDKIT=1
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Backup de la Base de Datos

```bash
# Crear backup
docker-compose exec db mysqldump -u root -p tabby > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurar backup
docker-compose exec -T db mysql -u root -p tabby < backup_20240101_120000.sql
```

### Monitoreo de Recursos

```bash
# Ver uso de recursos
docker stats

# Ver espacio en disco
df -h
docker system df
```

### Limpiar recursos Docker

```bash
# Limpiar imágenes no utilizadas
docker image prune -a

# Limpiar todo (¡cuidado!)
docker system prune -a --volumes
```

## 12. Optimizaciones para Raspberry Pi 5

### Limitar uso de memoria

Edita `docker-compose.yml` y agrega límites de recursos:

```yaml
services:
  tabby:
    # ... otras configuraciones ...
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 512M
  
  db:
    # ... otras configuraciones ...
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 256M
```

### Usar SSD USB en lugar de microSD

Para mejor rendimiento:

```bash
# Montar SSD USB
sudo mkdir /mnt/ssd
sudo mount /dev/sda1 /mnt/ssd

# Mover datos de Docker al SSD
sudo systemctl stop docker
sudo mv /var/lib/docker /mnt/ssd/docker
sudo ln -s /mnt/ssd/docker /var/lib/docker
sudo systemctl start docker
```

## 13. Solución de Problemas

### El contenedor no inicia

```bash
docker-compose logs tabby
# Buscar errores en la salida
```

### Problemas de conexión a la base de datos

```bash
# Verificar que MariaDB esté funcionando
docker-compose exec db mysqladmin ping -u root -p

# Reiniciar servicios
docker-compose restart
```

### Errores de OAuth

- Verifica que las URLs de callback estén configuradas correctamente en el proveedor OAuth
- Asegúrate de que `FRONTEND_URL` y `BACKEND_URL` coincidan con tu dominio
- Verifica que el certificado SSL esté funcionando correctamente

### Problemas de CORS

Si ves errores de CORS en la consola del navegador:

1. Verifica que `FRONTEND_URL` y `BACKEND_URL` estén correctamente configurados
2. Asegúrate de que Nginx Proxy Manager esté enviando los headers correctos
3. Revisa los logs: `docker-compose logs -f tabby`

### Rendimiento lento

- Considera usar un SSD USB en lugar de microSD
- Ajusta los límites de memoria en `docker-compose.yml`
- Usa `docker stats` para identificar cuellos de botella

## 14. Seguridad

### Recomendaciones

1. **Cambia todas las contraseñas por defecto** en `.env`
2. **Genera una clave secreta única** para `DJANGO_SECRET_KEY`
3. **Usa HTTPS** (configurado a través de Nginx Proxy Manager)
4. **Mantén el sistema actualizado**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
5. **Firewall**: Configura un firewall para permitir solo los puertos necesarios
   ```bash
   sudo apt install ufw
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 9090/tcp  # Tabby (solo si accedes localmente)
   sudo ufw enable
   ```
6. **Backups regulares** de la base de datos

### Ejecutar tu propio Gateway

Para mayor seguridad en conexiones SSH/Telnet, ejecuta tu propio `tabby-connection-gateway` en lugar de usar el servicio público.

## 15. Referencias

- [Tabby Web GitHub](https://github.com/Eugeny/tabby-web)
- [Tabby Terminal](https://github.com/Eugeny/tabby)
- [Tabby Connection Gateway](https://github.com/Eugeny/tabby-connection-gateway)
- [Docker en Raspberry Pi](https://docs.docker.com/engine/install/debian/)
- [Nginx Proxy Manager](https://nginxproxymanager.com/)

## Soporte

Para problemas y preguntas:
- Issues del proyecto: https://github.com/Eugeny/tabby-web/issues
- Documentación de Tabby: https://github.com/Eugeny/tabby/wiki
