# Usa la imagen oficial de Authentik (basada en Alpine)
FROM ghcr.io/goauthentik/server:2023.10

# Instala supervisor (usando apt-get para Debian)
RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor && \
    rm -rf /var/lib/apt/lists/*

# Configuración de supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# =============================================
# Variables de entorno (se configuran en Render)
# =============================================

# Configuración PostgreSQL (Neon)
ENV AUTHENTIK_POSTGRESQL__HOST=${AUTHENTIK_POSTGRESQL__HOST}
ENV AUTHENTIK_POSTGRESQL__PORT=${AUTHENTIK_POSTGRESQL__PORT}
ENV AUTHENTIK_POSTGRESQL__USER=${AUTHENTIK_POSTGRESQL__USER}
ENV AUTHENTIK_POSTGRESQL__NAME=${AUTHENTIK_POSTGRESQL__NAME}
ENV AUTHENTIK_POSTGRESQL__PASSWORD=${AUTHENTIK_POSTGRESQL__PASSWORD}
ENV AUTHENTIK_POSTGRESQL__SSLMODE=require

# Configuración Redis (Upstash)
ENV AUTHENTIK_REDIS__HOST=${AUTHENTIK_REDIS__HOST}
ENV AUTHENTIK_REDIS__PORT=${AUTHENTIK_REDIS__PORT}
ENV AUTHENTIK_REDIS__PASSWORD=${AUTHENTIK_REDIS__PASSWORD}
ENV AUTHENTIK_REDIS__TLS=true

# Configuración básica Authentik
ENV AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}

# Configuración Mailtrap
ENV AUTHENTIK_EMAIL__HOST=${AUTHENTIK_EMAIL__HOST}
ENV AUTHENTIK_EMAIL__PORT=${AUTHENTIK_EMAIL__PORT}
ENV AUTHENTIK_EMAIL__USERNAME=${AUTHENTIK_EMAIL__USERNAME}
ENV AUTHENTIK_EMAIL__PASSWORD=${AUTHENTIK_EMAIL__PASSWORD}
ENV AUTHENTIK_EMAIL__FROM=${AUTHENTIK_EMAIL__FROM}

# Puerto expuesto
EXPOSE 9000
EXPOSE 9443

# Punto de entrada
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
