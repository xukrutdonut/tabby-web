# Inicio Rápido - Tabby Web en Raspberry Pi 5

## Resumen de 5 Minutos

Esta es una guía de inicio rápido. Para instrucciones detalladas, consulta [INSTALL_RPI5.md](INSTALL_RPI5.md).

### Pre-requisitos

✅ Raspberry Pi 5 con Docker instalado  
✅ Credenciales OAuth de GitHub (u otro proveedor)  
✅ Nginx Proxy Manager configurado en otra RPi5  
✅ Dominio: `tabby.serviciosylaboratoriodomestico.site`

### Paso 1: Obtener OAuth Credentials

Ve a https://github.com/settings/developers y crea una nueva OAuth App:

- **Callback URL**: `https://tabby.serviciosylaboratoriodomestico.site/api/1/auth/social/complete/github/`

Guarda el **Client ID** y **Client Secret**.

### Paso 2: Clonar y Configurar

```bash
# Clonar repositorio
git clone https://github.com/xukrutdonut/tabby-web.git
cd tabby-web

# Copiar y editar configuración
cp .env.example .env
nano .env
```

**Edita al menos estas variables:**

```bash
# Generar clave secreta
DJANGO_SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

# URLs
FRONTEND_URL=https://tabby.serviciosylaboratoriodomestico.site
BACKEND_URL=https://tabby.serviciosylaboratoriodomestico.site

# OAuth GitHub
SOCIAL_AUTH_GITHUB_KEY=tu_client_id
SOCIAL_AUTH_GITHUB_SECRET=tu_client_secret

# Base de datos
DATABASE_URL=mysql://root:PASSWORD_SEGURO@db/tabby
MYSQL_ROOT_PASSWORD=PASSWORD_SEGURO
MARIADB_PASSWORD=PASSWORD_SEGURO
```

### Paso 3: Ejecutar Script de Instalación

```bash
chmod +x setup-rpi5.sh
./setup-rpi5.sh
```

O manualmente:

```bash
export DOCKER_BUILDKIT=1
docker-compose build    # ~30 minutos en RPi5
docker-compose up -d
```

### Paso 4: Agregar Versión de Tabby

```bash
docker-compose run --rm tabby /manage.sh add_version 1.0.187
```

### Paso 5: Configurar Nginx Proxy Manager

En tu Nginx Proxy Manager (otra RPi5):

1. **Crear Proxy Host:**
   - Domain: `tabby.serviciosylaboratoriodomestico.site`
   - Forward to: `IP_DE_ESTA_RPI5:9090`
   - ✅ Websockets Support (CRÍTICO)

2. **SSL:**
   - Request Let's Encrypt certificate
   - ✅ Force SSL
   - ✅ HTTP/2 Support

3. **Advanced config:**
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_http_version 1.1;
proxy_buffering off;
proxy_read_timeout 86400;
```

Ver [NGINX_PROXY_MANAGER_CONFIG.md](NGINX_PROXY_MANAGER_CONFIG.md) para detalles.

### Paso 6: ¡Listo!

Accede a: `https://tabby.serviciosylaboratoriodomestico.site`

## Comandos Útiles

```bash
# Ver logs
docker-compose logs -f tabby

# Reiniciar
docker-compose restart

# Detener
docker-compose down

# Ver estado
docker-compose ps

# Agregar nueva versión de Tabby
docker-compose run --rm tabby /manage.sh add_version 1.0.188

# Backup base de datos
docker-compose exec db mysqldump -u root -p tabby > backup.sql
```

## Configurar Tabby Gateway (Opcional)

Para SSH/Telnet:

1. Instala [tabby-connection-gateway](https://github.com/Eugeny/tabby-connection-gateway)
2. Después de login, ve a Settings en Tabby Web
3. Ingresa la dirección y token del gateway

## Solución de Problemas Rápida

### No puedo acceder
```bash
# Verificar servicios
docker-compose ps

# Ver logs
docker-compose logs -f
```

### Error 502 en Nginx
- Verifica que Tabby Web esté corriendo: `docker-compose ps`
- Verifica conectividad: `telnet IP_RPI5 9090`

### Errores de OAuth
- Verifica URLs de callback en GitHub
- Verifica `FRONTEND_URL` en `.env`

### Terminal no carga (WebSocket)
- ✅ Habilita "Websockets Support" en Nginx Proxy Manager
- Agrega config avanzada de WebSocket

## Estructura de Archivos

```
tabby-web/
├── .env                          # Tu configuración (no versionar)
├── .env.example                  # Plantilla de configuración
├── docker-compose.yml            # Orquestación de contenedores
├── setup-rpi5.sh                # Script de instalación
├── INSTALL_RPI5.md              # Guía completa (LEER)
├── NGINX_PROXY_MANAGER_CONFIG.md # Config de Nginx (LEER)
└── QUICKSTART_RPI5.md           # Esta guía
```

## Variables de Entorno Esenciales

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `DATABASE_URL` | Conexión a base de datos | ✅ Sí |
| `DJANGO_SECRET_KEY` | Clave secreta única | ✅ Sí |
| `FRONTEND_URL` | URL pública de tu dominio | ✅ Sí |
| `BACKEND_URL` | URL del backend (usualmente igual a FRONTEND_URL) | ✅ Sí |
| `SOCIAL_AUTH_GITHUB_KEY` | Client ID de GitHub OAuth | ✅ Sí* |
| `SOCIAL_AUTH_GITHUB_SECRET` | Client Secret de GitHub OAuth | ✅ Sí* |
| `MYSQL_ROOT_PASSWORD` | Contraseña de MariaDB | ✅ Sí |

*Al menos un proveedor OAuth es requerido (GitHub, GitLab, Google o Microsoft)

## Puertos

- **9090**: Puerto local de Tabby Web (configurable con `TABBY_PORT`)
- **3306**: Puerto interno de MariaDB (no expuesto)

## Seguridad Básica

1. ✅ Cambia todas las contraseñas en `.env`
2. ✅ Genera una clave secreta única para Django
3. ✅ Usa HTTPS (vía Nginx Proxy Manager)
4. ✅ Mantén el sistema actualizado
5. ✅ Haz backups regulares de la base de datos

## Siguiente Nivel

- 📖 Lee [INSTALL_RPI5.md](INSTALL_RPI5.md) para optimizaciones
- 🔒 Configura firewall con `ufw`
- 💾 Usa SSD USB en lugar de microSD
- 🔐 Ejecuta tu propio tabby-connection-gateway
- 📊 Configura monitoreo con `docker stats`

## Soporte

- 📚 Documentación completa: [INSTALL_RPI5.md](INSTALL_RPI5.md)
- 🔧 Config de Nginx: [NGINX_PROXY_MANAGER_CONFIG.md](NGINX_PROXY_MANAGER_CONFIG.md)
- 🐛 Issues: https://github.com/Eugeny/tabby-web/issues
- 📖 Wiki de Tabby: https://github.com/Eugeny/tabby/wiki

---

**¿Primera vez?** → Lee [INSTALL_RPI5.md](INSTALL_RPI5.md) para instrucciones paso a paso.
