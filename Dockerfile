# Usa la imagen oficial de Authentik
FROM ghcr.io/goauthentik/server:2023.10

# Instala supervisord para manejar múltiples procesos
RUN apt-get update && apt-get install -y supervisor \
    && rm -rf /var/lib/apt/lists/*

# Configuración de supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Variables de entorno (se sobrescriben desde Render)
ENV AUTHENTIK_POSTGRESQL__HOST=postgres
ENV AUTHENTIK_REDIS__HOST=redis
ENV AUTHENTIK_WORKER__APP=authentik_worker
ENV AUTHENTIK_ERROR_REPORTING__ENABLED=false

# Puerto expuesto
EXPOSE 9000
EXPOSE 9443

# Punto de entrada
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
