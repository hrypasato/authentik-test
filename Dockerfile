# Dockerfile simple para Authentik en Render (sin script personalizado)
FROM ghcr.io/goauthentik/server:2024.8.3

# Variables de entorno por defecto para Render
ENV AUTHENTIK_LISTEN__HTTP=0.0.0.0:8000
ENV AUTHENTIK_LISTEN__METRICS=0.0.0.0:9300
ENV AUTHENTIK_INSECURE=true
ENV AUTHENTIK_DISABLE_UPDATE_CHECK=true
ENV AUTHENTIK_ERROR_REPORTING__ENABLED=false
ENV AUTHENTIK_LOG_LEVEL=info

# Usar usuario authentik por seguridad
USER authentik

# Exponer puerto
EXPOSE 8000

# Comando directo - Authentik maneja las migraciones automáticamente
CMD ["python", "-m", "lifecycle.web"]
