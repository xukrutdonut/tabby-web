# Lista de Verificación para Despliegue en Raspberry Pi 5

Usa esta lista para asegurarte de que no olvides ningún paso durante la instalación de Tabby Web.

## Pre-instalación

### Hardware y Sistema Operativo

- [ ] Raspberry Pi 5 con al menos 4GB RAM (8GB recomendado)
- [ ] Raspberry Pi OS de 64-bit instalado y actualizado
- [ ] Conexión a red estable (Ethernet recomendado)
- [ ] Suficiente espacio en disco (32GB mínimo, 64GB+ recomendado)
- [ ] (Opcional) SSD USB para mejor rendimiento

### Software Requerido

- [ ] Docker Engine instalado
  ```bash
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  ```
- [ ] Docker Compose instalado
  ```bash
  sudo apt install docker-compose -y
  ```
- [ ] Usuario agregado al grupo docker
  ```bash
  sudo usermod -aG docker $USER
  # Cerrar sesión y volver a iniciar
  ```
- [ ] Git instalado
  ```bash
  sudo apt install git -y
  ```

### Configuración de Red y Dominio

- [ ] Dominio configurado: `tabby.serviciosylaboratoriodomestico.site`
- [ ] DNS apuntando correctamente (público o local)
- [ ] Nginx Proxy Manager instalado en otra RPi5
- [ ] Port forwarding configurado (si es acceso público)
  - Puerto 80 → NPM
  - Puerto 443 → NPM

## Configuración de OAuth

### GitHub OAuth (Recomendado)

- [ ] Cuenta de GitHub creada
- [ ] OAuth App creada en https://github.com/settings/developers
- [ ] Application name: `Tabby Web` (o el que prefieras)
- [ ] Homepage URL: `https://tabby.serviciosylaboratoriodomestico.site`
- [ ] Authorization callback URL: `https://tabby.serviciosylaboratoriodomestico.site/api/1/auth/social/complete/github/`
- [ ] Client ID copiado y guardado
- [ ] Client Secret copiado y guardado

### Otros Proveedores OAuth (Opcional)

- [ ] GitLab OAuth configurado (si aplica)
- [ ] Google OAuth configurado (si aplica)
- [ ] Microsoft OAuth configurado (si aplica)

## Instalación de Tabby Web

### Descarga y Configuración Inicial

- [ ] Repositorio clonado
  ```bash
  git clone https://github.com/xukrutdonut/tabby-web.git
  cd tabby-web
  ```
- [ ] Archivo `.env` creado desde plantilla
  ```bash
  cp .env.example .env
  ```

### Configuración de Variables de Entorno

Editar `.env` con `nano .env`:

#### Variables Críticas (OBLIGATORIAS)

- [ ] `DJANGO_SECRET_KEY` - Generada con:
  ```bash
  python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
  ```
- [ ] `DATABASE_URL` - Configurada (cambiar contraseña)
- [ ] `MYSQL_ROOT_PASSWORD` - Contraseña segura configurada
- [ ] `MARIADB_PASSWORD` - Contraseña segura configurada
- [ ] `FRONTEND_URL` - Configurada: `https://tabby.serviciosylaboratoriodomestico.site`
- [ ] `BACKEND_URL` - Configurada: `https://tabby.serviciosylaboratoriodomestico.site`

#### OAuth (Al menos UNO es obligatorio)

- [ ] `SOCIAL_AUTH_GITHUB_KEY` - Client ID de GitHub
- [ ] `SOCIAL_AUTH_GITHUB_SECRET` - Client Secret de GitHub
- [ ] O configuradas credenciales de otro proveedor OAuth

#### Variables Opcionales

- [ ] `TABBY_PORT` - Puerto local (default: 9090)
- [ ] `APP_DIST_STORAGE` - Configurado si usas S3 o GCS
- [ ] Gateway certificates configurados (si usas tu propio gateway)

### Construcción y Ejecución

- [ ] Docker BuildKit habilitado
  ```bash
  export DOCKER_BUILDKIT=1
  ```
- [ ] Imágenes construidas (20-40 minutos)
  ```bash
  docker-compose build
  ```
- [ ] Servicios iniciados
  ```bash
  docker-compose up -d
  ```
- [ ] Contenedores verificados en ejecución
  ```bash
  docker-compose ps
  ```
- [ ] Logs verificados sin errores críticos
  ```bash
  docker-compose logs -f tabby
  ```

### Configuración de Tabby

- [ ] Versión de Tabby agregada
  ```bash
  docker-compose run --rm tabby /manage.sh add_version 1.0.187
  ```
- [ ] Acceso local verificado
  ```bash
  curl http://localhost:9090
  ```

## Configuración de Nginx Proxy Manager

### Proxy Host Básico

En Nginx Proxy Manager (otra RPi5):

- [ ] Nuevo Proxy Host creado
- [ ] Domain Name: `tabby.serviciosylaboratoriodomestico.site`
- [ ] Scheme: `http`
- [ ] Forward Hostname/IP: IP de la RPi5 con Tabby (ej: `192.168.1.100`)
- [ ] Forward Port: `9090`
- [ ] Cache Assets: ✓ Habilitado
- [ ] Block Common Exploits: ✓ Habilitado
- [ ] **Websockets Support: ✓ HABILITADO** (CRÍTICO)

### Configuración SSL

- [ ] SSL Certificate solicitado (Let's Encrypt)
- [ ] Email válido proporcionado
- [ ] Force SSL: ✓ Habilitado
- [ ] HTTP/2 Support: ✓ Habilitado
- [ ] HSTS Enabled: ✓ Habilitado

### Configuración Avanzada (Recomendado)

- [ ] Custom configuration agregada en pestaña "Advanced":
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_http_version 1.1;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_buffering off;
proxy_read_timeout 86400;
```

## Verificación y Pruebas

### Pruebas Básicas

- [ ] Página principal carga correctamente
  ```
  https://tabby.serviciosylaboratoriodomestico.site
  ```
- [ ] Certificado SSL válido (sin advertencias)
- [ ] Login OAuth funciona correctamente
- [ ] Puede crear/guardar configuraciones
- [ ] Terminal web funciona correctamente
- [ ] WebSocket conecta sin errores

### Verificación de Logs

- [ ] Sin errores críticos en logs de Tabby
  ```bash
  docker-compose logs tabby | grep -i error
  ```
- [ ] Sin errores en logs de base de datos
  ```bash
  docker-compose logs db | grep -i error
  ```
- [ ] Sin errores CORS en consola del navegador

## Tabby Connection Gateway (Opcional)

Si planeas usar SSH/Telnet:

- [ ] Gateway decision tomada:
  - [ ] Usar gateway público
  - [ ] O instalar gateway propio
- [ ] Gateway configurado en settings de Tabby Web
- [ ] Conexión SSH/Telnet probada

## Seguridad

### Configuración Básica

- [ ] Todas las contraseñas por defecto cambiadas
- [ ] DJANGO_SECRET_KEY única generada
- [ ] HTTPS configurado y funcionando
- [ ] Sistema operativo actualizado
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```

### Firewall (Recomendado)

- [ ] UFW instalado
  ```bash
  sudo apt install ufw -y
  ```
- [ ] Reglas configuradas
  ```bash
  sudo ufw allow 22/tcp   # SSH
  sudo ufw allow 9090/tcp # Tabby (opcional, solo si acceso local)
  sudo ufw enable
  ```

### Backups

- [ ] Script de backup de base de datos creado
  ```bash
  #!/bin/bash
  cd ~/tabby-web
  docker-compose exec db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} tabby > backup_$(date +%Y%m%d_%H%M%S).sql
  ```
- [ ] Cronjob de backup configurado (opcional)
  ```bash
  0 2 * * * /home/user/backup-tabby.sh
  ```

## Optimizaciones (Opcional)

### Rendimiento

- [ ] Límites de memoria configurados en docker-compose.yml
- [ ] SSD USB configurado en lugar de microSD
- [ ] Docker data movido a SSD

### Monitoreo

- [ ] Monitoring configurado
  ```bash
  docker stats
  ```
- [ ] Alertas configuradas (opcional)

## Post-Instalación

### Documentación

- [ ] Credenciales guardadas en lugar seguro
- [ ] URLs importantes documentadas
- [ ] Procedimientos de backup documentados

### Información de Acceso

- [ ] URL principal: `https://tabby.serviciosylaboratoriodomestico.site`
- [ ] Puerto local: `9090` (o el configurado)
- [ ] Usuario admin creado en primera ejecución
- [ ] Gateway configurado (si aplica)

### Comandos Útiles Guardados

```bash
# Ver logs
docker-compose logs -f

# Reiniciar servicios
docker-compose restart

# Detener servicios
docker-compose down

# Actualizar Tabby Web
git pull && docker-compose build && docker-compose up -d

# Backup manual
docker-compose exec db mysqldump -u root -p tabby > backup.sql

# Ver uso de recursos
docker stats
```

## Verificación Final

- [ ] ✅ Tabby Web accesible desde navegador
- [ ] ✅ OAuth login funciona correctamente
- [ ] ✅ Terminal web funciona
- [ ] ✅ Configuraciones se guardan
- [ ] ✅ HTTPS funciona sin advertencias
- [ ] ✅ Logs sin errores críticos
- [ ] ✅ Backups configurados
- [ ] ✅ Documentación completa

## ¡Felicidades! 🎉

Si todos los items están marcados, tu instalación de Tabby Web en Raspberry Pi 5 está completa y lista para usar.

---

## Recursos Adicionales

- 📖 Guía completa: [INSTALL_RPI5.md](INSTALL_RPI5.md)
- 🚀 Inicio rápido: [QUICKSTART_RPI5.md](QUICKSTART_RPI5.md)
- 🔧 Config de Nginx: [NGINX_PROXY_MANAGER_CONFIG.md](NGINX_PROXY_MANAGER_CONFIG.md)
- 📝 Variables de entorno: [.env.example](.env.example)

## Soporte

Si encuentras problemas, consulta:
1. Sección de troubleshooting en [INSTALL_RPI5.md](INSTALL_RPI5.md)
2. Sección de solución de problemas en [NGINX_PROXY_MANAGER_CONFIG.md](NGINX_PROXY_MANAGER_CONFIG.md)
3. Issues del proyecto: https://github.com/Eugeny/tabby-web/issues
