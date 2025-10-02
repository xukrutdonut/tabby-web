# Tabby Web - Instalación para Raspberry Pi 5

[English version](README.md)

## 🚀 Inicio Rápido

Esta es la configuración de Tabby Web optimizada para ejecutarse en **Raspberry Pi 5** con **Docker**, detrás de **Nginx Proxy Manager**, con soporte para **Tabby Connection Gateway**.

### Dominio configurado
```
https://tabby.serviciosylaboratoriodomestico.site
```

## 📋 Pre-requisitos

- ✅ Raspberry Pi 5 con Raspberry Pi OS de 64-bit
- ✅ Docker y Docker Compose instalados
- ✅ Nginx Proxy Manager ejecutándose en otra RPi5
- ✅ Credenciales OAuth (GitHub, GitLab, Google o Microsoft)
- ✅ Dominio apuntando a tu red

## 📚 Documentación

### Guías Principales

| Guía | Descripción | Tiempo |
|------|-------------|--------|
| [QUICKSTART_RPI5.md](QUICKSTART_RPI5.md) | Inicio rápido con comandos esenciales | 5 min |
| [INSTALL_RPI5.md](INSTALL_RPI5.md) | Guía completa de instalación paso a paso | 30-60 min |
| [NGINX_PROXY_MANAGER_CONFIG.md](NGINX_PROXY_MANAGER_CONFIG.md) | Configuración de Nginx Proxy Manager | 15 min |
| [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) | Lista de verificación interactiva | - |

### Archivos de Configuración

- **`.env.example`**: Plantilla de configuración con todas las variables necesarias
- **`setup-rpi5.sh`**: Script automatizado de instalación
- **`docker-compose.yml`**: Orquestación de contenedores optimizada para RPi5

## ⚡ Instalación en 3 Pasos

### 1. Clonar y Configurar

```bash
# Clonar el repositorio
git clone https://github.com/xukrutdonut/tabby-web.git
cd tabby-web

# Crear archivo de configuración
cp .env.example .env
nano .env
```

### 2. Configurar Variables Mínimas

Edita `.env` con tus valores:

```bash
# Django (CRÍTICO - generar una clave única)
DJANGO_SECRET_KEY=tu_clave_secreta_aqui

# Dominio
FRONTEND_URL=https://tabby.serviciosylaboratoriodomestico.site
BACKEND_URL=https://tabby.serviciosylaboratoriodomestico.site

# OAuth GitHub (o GitLab, Google, Microsoft)
SOCIAL_AUTH_GITHUB_KEY=tu_client_id
SOCIAL_AUTH_GITHUB_SECRET=tu_client_secret

# Base de datos
DATABASE_URL=mysql://root:PASSWORD_SEGURO@db/tabby
MYSQL_ROOT_PASSWORD=PASSWORD_SEGURO
MARIADB_PASSWORD=PASSWORD_SEGURO
```

### 3. Ejecutar Instalación

```bash
# Opción A: Script automatizado (recomendado)
chmod +x setup-rpi5.sh
./setup-rpi5.sh

# Opción B: Manual
export DOCKER_BUILDKIT=1
docker-compose build    # ~30 minutos en RPi5
docker-compose up -d
docker-compose run --rm tabby /manage.sh add_version 1.0.187
```

## 🔧 Configuración de Nginx Proxy Manager

En tu Nginx Proxy Manager (otra RPi5):

### Crear Proxy Host

1. **Configuración Básica:**
   - Domain: `tabby.serviciosylaboratoriodomestico.site`
   - Scheme: `http`
   - Forward to: `IP_DE_TU_RPI5_CON_TABBY:9090`
   - ✅ **Websockets Support** (CRÍTICO)
   - ✅ Cache Assets
   - ✅ Block Common Exploits

2. **SSL:**
   - Request Let's Encrypt certificate
   - ✅ Force SSL
   - ✅ HTTP/2 Support
   - ✅ HSTS Enabled

3. **Advanced (Recomendado):**
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_http_version 1.1;
proxy_buffering off;
proxy_read_timeout 86400;
```

Ver [NGINX_PROXY_MANAGER_CONFIG.md](NGINX_PROXY_MANAGER_CONFIG.md) para detalles completos.

## 🔑 Obtener Credenciales OAuth

### GitHub OAuth (Recomendado)

1. Ve a https://github.com/settings/developers
2. Click en "New OAuth App"
3. Configura:
   - **Homepage URL**: `https://tabby.serviciosylaboratoriodomestico.site`
   - **Callback URL**: `https://tabby.serviciosylaboratoriodomestico.site/api/1/auth/social/complete/github/`
4. Guarda Client ID y Client Secret en `.env`

### Otros Proveedores

- **GitLab**: Callback URL → `.../complete/gitlab/`
- **Google**: Callback URL → `.../complete/google-oauth2/`
- **Microsoft**: Callback URL → `.../complete/azuread-oauth2/`

Ver [INSTALL_RPI5.md](INSTALL_RPI5.md) para instrucciones detalladas de cada proveedor.

## 📊 Verificación

```bash
# Verificar contenedores
docker-compose ps

# Ver logs
docker-compose logs -f tabby

# Verificar acceso local
curl http://localhost:9090

# Verificar acceso externo
curl -I https://tabby.serviciosylaboratoriodomestico.site
```

## 🔐 Seguridad

### ⚠️ IMPORTANTE

1. **Cambia TODAS las contraseñas** en `.env`
2. **Genera una clave secreta única** para Django:
   ```bash
   python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
   ```
3. **Configura HTTPS** (via Nginx Proxy Manager)
4. **Mantén el sistema actualizado**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

### Firewall (Opcional)

```bash
sudo apt install ufw -y
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 9090/tcp  # Tabby (solo si acceso local)
sudo ufw enable
```

## 🛠️ Comandos Útiles

```bash
# Ver estado de servicios
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Reiniciar servicios
docker-compose restart

# Detener servicios
docker-compose down

# Actualizar Tabby Web
git pull
docker-compose build
docker-compose up -d

# Agregar versión de Tabby
docker-compose run --rm tabby /manage.sh add_version 1.0.188

# Backup de base de datos
docker-compose exec db mysqldump -u root -p tabby > backup_$(date +%Y%m%d).sql

# Restaurar backup
docker-compose exec -T db mysql -u root -p tabby < backup.sql

# Ver uso de recursos
docker stats

# Limpiar recursos no utilizados
docker system prune -a
```

## 🔌 Tabby Connection Gateway (Opcional)

Para usar conexiones SSH/Telnet:

### Opción 1: Gateway Público
1. Inicia sesión en Tabby Web
2. Ve a Settings
3. Ingresa dirección y token del gateway público

### Opción 2: Gateway Propio (Más Seguro)
```bash
# Clonar y configurar gateway propio
git clone https://github.com/Eugeny/tabby-connection-gateway.git
cd tabby-connection-gateway
# Seguir instrucciones del README
```

Configurar en `.env` de tabby-web:
```bash
CONNECTION_GATEWAY_AUTH_CA=/ruta/a/ca.crt
CONNECTION_GATEWAY_AUTH_CERTIFICATE=/ruta/a/cert.crt
CONNECTION_GATEWAY_AUTH_KEY=/ruta/a/key.key
```

## 🐛 Solución de Problemas

### Error 502 Bad Gateway
```bash
# Verificar que Tabby esté ejecutándose
docker-compose ps

# Verificar conectividad desde NPM
telnet IP_TABBY 9090
```

### Errores de CORS
- Verifica que `FRONTEND_URL` y `BACKEND_URL` sean correctos en `.env`
- Reinicia: `docker-compose restart tabby`

### Terminal no se conecta (WebSocket)
- ✅ Habilita "Websockets Support" en Nginx Proxy Manager
- Agrega configuración avanzada de WebSocket (ver arriba)

### Errores de OAuth
- Verifica URLs de callback en tu proveedor OAuth
- Asegúrate de que coincidan exactamente con tu dominio

Ver [INSTALL_RPI5.md](INSTALL_RPI5.md) para troubleshooting completo.

## 📦 Mantenimiento

### Backups Automáticos

Crear script de backup:

```bash
#!/bin/bash
# ~/backup-tabby.sh
cd ~/tabby-web
docker-compose exec db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} tabby > \
    ~/backups/tabby_$(date +%Y%m%d_%H%M%S).sql
```

Configurar cronjob:
```bash
crontab -e
# Agregar: backup diario a las 2 AM
0 2 * * * /home/usuario/backup-tabby.sh
```

### Actualizaciones

```bash
cd ~/tabby-web
git pull
export DOCKER_BUILDKIT=1
docker-compose down
docker-compose build
docker-compose up -d
```

## 🎯 Optimizaciones para Raspberry Pi 5

### Usar SSD USB

```bash
# Montar SSD
sudo mkdir /mnt/ssd
sudo mount /dev/sda1 /mnt/ssd

# Mover datos de Docker
sudo systemctl stop docker
sudo mv /var/lib/docker /mnt/ssd/docker
sudo ln -s /mnt/ssd/docker /var/lib/docker
sudo systemctl start docker
```

### Limitar Memoria

Editar `docker-compose.yml`:
```yaml
services:
  tabby:
    deploy:
      resources:
        limits:
          memory: 2G
```

Ver [INSTALL_RPI5.md](INSTALL_RPI5.md) para más optimizaciones.

## 📖 Estructura del Proyecto

```
tabby-web/
├── .env                          # Tu configuración (NUNCA versionar)
├── .env.example                  # Plantilla de configuración
├── docker-compose.yml            # Orquestación de contenedores
├── Dockerfile                    # Imagen de Docker
├── setup-rpi5.sh                # Script de instalación
├── README.md                     # Documentación en inglés
├── LEEME.md                      # Esta documentación
├── QUICKSTART_RPI5.md           # Inicio rápido
├── INSTALL_RPI5.md              # Guía completa de instalación
├── NGINX_PROXY_MANAGER_CONFIG.md # Configuración de Nginx
├── DEPLOYMENT_CHECKLIST.md      # Lista de verificación
├── backend/                      # Backend Django
│   └── tabby/
│       └── settings.py          # Configuración (CSRF fix incluido)
└── frontend/                     # Frontend Angular
```

## 🌐 Características Principales

✅ **Optimizado para Raspberry Pi 5**
- Soporte ARM64/aarch64
- Health checks
- Volúmenes persistentes
- Resource limits configurables

✅ **Configuración Específica del Dominio**
- Pre-configurado para `tabby.serviciosylaboratoriodomestico.site`
- CORS y CSRF_TRUSTED_ORIGINS correctamente configurados
- Compatible con Nginx Proxy Manager

✅ **Seguridad**
- HTTPS via Nginx Proxy Manager
- Django secret key única requerida
- Headers de seguridad configurados
- Soporte para OAuth múltiple

✅ **Integración Gateway**
- Variables para Tabby Connection Gateway
- Soporte para certificados personalizados
- Opción de gateway público o propio

✅ **Documentación Completa en Español**
- 4 guías principales (+42KB)
- Troubleshooting exhaustivo
- Ejemplos de comandos
- Script de instalación automatizado

## 🆘 Soporte

Si encuentras problemas:

1. 📖 Consulta [INSTALL_RPI5.md](INSTALL_RPI5.md) - Sección de troubleshooting
2. 🔧 Revisa [NGINX_PROXY_MANAGER_CONFIG.md](NGINX_PROXY_MANAGER_CONFIG.md)
3. ✅ Usa [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) para verificar pasos
4. 📝 Revisa los logs: `docker-compose logs -f`
5. 🐛 Crea un issue: https://github.com/Eugeny/tabby-web/issues

## 📝 Variables de Entorno Esenciales

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `DJANGO_SECRET_KEY` | Clave secreta de Django (única) | ✅ Sí |
| `DATABASE_URL` | URL de conexión a base de datos | ✅ Sí |
| `FRONTEND_URL` | URL pública del dominio | ✅ Sí |
| `BACKEND_URL` | URL del backend | ✅ Sí |
| `SOCIAL_AUTH_*_KEY` | Client ID OAuth | ✅ Sí* |
| `SOCIAL_AUTH_*_SECRET` | Client Secret OAuth | ✅ Sí* |
| `MYSQL_ROOT_PASSWORD` | Contraseña de MariaDB | ✅ Sí |

*Al menos un proveedor OAuth es requerido

Ver [.env.example](.env.example) para la lista completa de variables.

## 🎉 ¿Todo Listo?

Si has seguido todos los pasos:

```bash
# Verifica el acceso
https://tabby.serviciosylaboratoriodomestico.site
```

Deberías ver la página de login de Tabby Web. ¡Disfruta tu terminal web! 🚀

## 🔗 Enlaces Útiles

- [Tabby Terminal](https://github.com/Eugeny/tabby)
- [Tabby Web Original](https://github.com/Eugeny/tabby-web)
- [Tabby Connection Gateway](https://github.com/Eugeny/tabby-connection-gateway)
- [Nginx Proxy Manager](https://nginxproxymanager.com/)
- [Docker Documentation](https://docs.docker.com/)

## 📄 Licencia

Ver [LICENSE](LICENSE)

---

**Nota**: Esta configuración está optimizada específicamente para:
- Raspberry Pi 5 (ARM64)
- Dominio: `tabby.serviciosylaboratoriodomestico.site`
- Nginx Proxy Manager en RPi5 separada
- Integración con Tabby Connection Gateway

Para otras configuraciones, consulta el [README.md](README.md) original.
