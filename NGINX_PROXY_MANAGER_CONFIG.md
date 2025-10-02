# Configuración de Nginx Proxy Manager para Tabby Web

Esta guía proporciona la configuración específica para Nginx Proxy Manager cuando Tabby Web se ejecuta en una Raspberry Pi 5 separada.

## Escenario

- **Nginx Proxy Manager**: RPi5 #1 (por ejemplo: `192.168.1.50`)
- **Tabby Web**: RPi5 #2 (por ejemplo: `192.168.1.100`)
- **Dominio**: `tabby.serviciosylaboratoriodomestico.site`

## Configuración del Proxy Host

### 1. Información Básica

| Campo | Valor |
|-------|-------|
| **Domain Names** | `tabby.serviciosylaboratoriodomestico.site` |
| **Scheme** | `http` |
| **Forward Hostname / IP** | `192.168.1.100` (IP de la RPi5 con Tabby Web) |
| **Forward Port** | `9090` |
| **Cache Assets** | ✓ Habilitado |
| **Block Common Exploits** | ✓ Habilitado |
| **Websockets Support** | ✓ **HABILITADO** (Crítico para Tabby) |

### 2. Certificado SSL

Configura SSL en la pestaña "SSL":

| Campo | Valor |
|-------|-------|
| **SSL Certificate** | Request a new SSL Certificate (Let's Encrypt) |
| **Force SSL** | ✓ Habilitado |
| **HTTP/2 Support** | ✓ Habilitado |
| **HSTS Enabled** | ✓ Habilitado |
| **HSTS Subdomains** | ✓ Habilitado (opcional) |

**Email para Let's Encrypt**: Tu correo electrónico válido

### 3. Configuración Avanzada (Opcional pero Recomendado)

En la pestaña "Advanced", agrega esta configuración personalizada para mejorar el soporte de WebSockets y proxy:

```nginx
# Mejorar el soporte de WebSocket y proxy headers
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_http_version 1.1;

# Headers de proxy estándar
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port $server_port;

# Timeouts para sesiones largas
proxy_connect_timeout 7d;
proxy_send_timeout 7d;
proxy_read_timeout 7d;

# Deshabilitar buffering para mejor experiencia en terminal
proxy_buffering off;
proxy_request_buffering off;

# Tamaños de buffer
client_max_body_size 100M;
proxy_max_temp_file_size 0;
```

### 4. Configuración del Dominio

Asegúrate de que tu dominio `tabby.serviciosylaboratoriodomestico.site` apunte a la IP pública de tu Nginx Proxy Manager o, si es solo para red local, configura tu DNS local/router para que apunte a la IP local de Nginx Proxy Manager.

#### DNS Público (si es accesible desde Internet)

Crea un registro A en tu proveedor DNS:

```
Tipo: A
Nombre: tabby.serviciosylaboratoriodomestico (o @)
Valor: [IP_PUBLICA_DE_TU_RED]
TTL: 3600
```

No olvides configurar **port forwarding** en tu router:
- Puerto externo: `443` → Puerto interno: `443` → IP: `192.168.1.50` (NPM)
- Puerto externo: `80` → Puerto interno: `80` → IP: `192.168.1.50` (NPM)

#### DNS Local (solo red interna)

Opción A - Configurar en tu router/DNS local:
```
tabby.serviciosylaboratoriodomestico.site → 192.168.1.50
```

Opción B - Editar `/etc/hosts` en cada cliente:
```
192.168.1.50 tabby.serviciosylaboratoriodomestico.site
```

## Verificación

### 1. Probar conectividad básica

Desde la RPi5 con Nginx Proxy Manager:

```bash
# Verificar que Tabby Web esté accesible
curl http://192.168.1.100:9090

# Debería retornar HTML de la aplicación
```

### 2. Probar el proxy

```bash
# Desde cualquier máquina en la red
curl -I https://tabby.serviciosylaboratoriodomestico.site

# Deberías ver:
# HTTP/2 200
# server: nginx
# ...
```

### 3. Probar en el navegador

Abre: `https://tabby.serviciosylaboratoriodomestico.site`

Deberías ver la página de login de Tabby Web.

## Solución de Problemas

### Error 502 Bad Gateway

**Causa**: Nginx Proxy Manager no puede conectarse a Tabby Web.

**Solución**:
1. Verifica que Tabby Web esté ejecutándose:
   ```bash
   # En la RPi5 con Tabby Web
   docker-compose ps
   ```
2. Verifica conectividad:
   ```bash
   # Desde la RPi5 con NPM
   telnet 192.168.1.100 9090
   ```
3. Verifica la IP y puerto en la configuración del proxy host

### Error 504 Gateway Timeout

**Causa**: Timeout de conexión.

**Solución**:
1. Aumenta los timeouts en la configuración avanzada de NPM
2. Verifica que Tabby Web no esté sobrecargado:
   ```bash
   docker stats
   ```

### Errores de CORS

**Síntoma**: Errores en la consola del navegador sobre CORS.

**Solución**:
1. Verifica que `FRONTEND_URL` en `.env` sea exactamente: `https://tabby.serviciosylaboratoriodomestico.site`
2. Verifica que `BACKEND_URL` en `.env` sea exactamente: `https://tabby.serviciosylaboratoriodomestico.site`
3. Reinicia Tabby Web:
   ```bash
   docker-compose restart tabby
   ```

### Problemas con OAuth

**Síntoma**: Redirección fallida después de login OAuth.

**Solución**:
1. Verifica las URLs de callback en tu proveedor OAuth
2. Para GitHub OAuth, debe ser exactamente:
   ```
   https://tabby.serviciosylaboratoriodomestico.site/api/1/auth/social/complete/github/
   ```
3. Asegúrate de que el dominio en OAuth coincida con `FRONTEND_URL`

### Terminal no se conecta (WebSocket)

**Síntoma**: El terminal no carga o se desconecta inmediatamente.

**Solución**:
1. **Verifica que "Websockets Support" esté habilitado** en Nginx Proxy Manager
2. Agrega la configuración avanzada de WebSocket (ver arriba)
3. Verifica los logs:
   ```bash
   # En la RPi5 con Tabby Web
   docker-compose logs -f tabby
   ```

### Certificado SSL inválido

**Síntoma**: Advertencia de certificado en el navegador.

**Solución**:
1. Verifica que el dominio esté correctamente configurado en DNS
2. Verifica que Let's Encrypt pueda alcanzar tu dominio (si es público)
3. Para dominios locales, considera usar certificados auto-firmados o [mkcert](https://github.com/FiloSottile/mkcert)

## Monitoreo

### Ver logs de Nginx Proxy Manager

```bash
# Acceder al contenedor de NPM
docker logs nginx-proxy-manager

# Ver logs en tiempo real
docker logs -f nginx-proxy-manager
```

### Ver logs de Tabby Web

```bash
# En la RPi5 con Tabby Web
cd ~/tabby-web
docker-compose logs -f tabby
```

## Mejoras de Seguridad

### 1. Restricción por IP (Opcional)

Si solo necesitas acceso desde ciertas IPs, agrega en "Advanced":

```nginx
# Permitir solo IPs específicas
allow 192.168.1.0/24;  # Red local
allow 10.0.0.0/8;       # Otra red permitida
deny all;               # Denegar todo lo demás
```

### 2. Rate Limiting

Protege contra ataques de fuerza bruta:

```nginx
# Limitar requests por IP
limit_req_zone $binary_remote_addr zone=tabby_limit:10m rate=10r/s;
limit_req zone=tabby_limit burst=20 nodelay;
```

### 3. Headers de Seguridad

Agrega headers de seguridad adicionales:

```nginx
# Headers de seguridad
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

## Configuración Alternativa: Múltiples Instancias

Si necesitas ejecutar múltiples instancias de Tabby Web (por ejemplo, para desarrollo y producción):

### Instancia de Producción
- Dominio: `tabby.serviciosylaboratoriodomestico.site`
- IP: `192.168.1.100:9090`

### Instancia de Desarrollo
- Dominio: `tabby-dev.serviciosylaboratoriodomestico.site`
- IP: `192.168.1.100:9091`

Crea un proxy host separado para cada instancia y configura el puerto correspondiente en el `.env` de cada instancia:

```bash
# Producción
TABBY_PORT=9090

# Desarrollo
TABBY_PORT=9091
```

## Referencias

- [Nginx Proxy Manager Documentation](https://nginxproxymanager.com/guide/)
- [Nginx WebSocket Proxying](http://nginx.org/en/docs/http/websocket.html)
- [Let's Encrypt](https://letsencrypt.org/)
