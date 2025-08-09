# Dockerfile para Authentik en Render
FROM ghcr.io/goauthentik/server:2024.8.3

# Variables de entorno por defecto para Render - SOLO HTTP
ENV AUTHENTIK_LISTEN__HTTP=0.0.0.0:8000
ENV AUTHENTIK_LISTEN__METRICS=0.0.0.0:9300
ENV AUTHENTIK_INSECURE=true

# Configuración para Render
ENV AUTHENTIK_DISABLE_UPDATE_CHECK=true
ENV AUTHENTIK_ERROR_REPORTING__ENABLED=false
ENV AUTHENTIK_LOG_LEVEL=debug

# Cambiar a root temporalmente para configurar archivos
USER root

# Script de inicio personalizado con permisos correctos
COPY start.sh /start.sh
RUN chmod +x /start.sh && chown authentik:authentik /start.sh

# Volver al usuario authentik por seguridad
USER authentik

# Exponer el puerto que usa Render
EXPOSE 8000

# Comando por defecto - usar el comando nativo de Authentik
CMD ["server"]
