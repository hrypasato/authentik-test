FROM ghcr.io/goauthentik/server:2024.8.3

# Cambiar al usuario authentik
USER authentik

# Exponer puerto
EXPOSE 8000

# Comando por defecto
CMD ["server"]
