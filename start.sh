#!/bin/bash
# start.sh - Script de inicio para Authentik en Render (Versión corregida)

set -e

echo "🚀 Iniciando Authentik en Render..."

# Función para verificar si PostgreSQL está disponible
check_postgres() {
    echo "⏳ Verificando conexión a PostgreSQL (Neon)..."
    max_attempts=15
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if python -c "
import os
import psycopg2
import sys

try:
    database_url = os.environ.get('DATABASE_URL')
    if database_url:
        if '?' not in database_url:
            database_url += '?sslmode=require&connect_timeout=30'
        elif 'sslmode=' not in database_url:
            database_url += '&sslmode=require&connect_timeout=30'
        
        conn = psycopg2.connect(database_url)
    else:
        conn = psycopg2.connect(
            host=os.environ.get('AUTHENTIK_POSTGRESQL__HOST'),
            port=os.environ.get('AUTHENTIK_POSTGRESQL__PORT', '5432'),
            user=os.environ.get('AUTHENTIK_POSTGRESQL__USER'),
            password=os.environ.get('AUTHENTIK_POSTGRESQL__PASSWORD'),
            database=os.environ.get('AUTHENTIK_POSTGRESQL__NAME'),
            sslmode='require',
            connect_timeout=30
        )
    
    cursor = conn.cursor()
    cursor.execute('SELECT version();')
    cursor.fetchone()
    cursor.close()
    conn.close()
    
    print('✅ PostgreSQL (Neon) conectado exitosamente')
    sys.exit(0)
except Exception as e:
    print(f'❌ Intento {attempt}/{max_attempts} - Error Neon: {e}')
    sys.exit(1)
        "; then
            echo "✅ Neon PostgreSQL disponible"
            break
        else
            echo "⏳ Esperando Neon compute startup... (intento $attempt/$max_attempts)"
            sleep 15
            attempt=$((attempt + 1))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "❌ Neon PostgreSQL no disponible después de $max_attempts intentos"
        exit 1
    fi
}

# Función para verificar Redis
check_redis() {
    echo "⏳ Verificando conexión a Redis..."
    max_attempts=10
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if python -c "
import os
import redis
import sys
try:
    ssl_cert_reqs = None
    if os.environ.get('AUTHENTIK_REDIS__TLS', 'false').lower() == 'true':
        import ssl
        ssl_cert_reqs = ssl.CERT_NONE
        
    r = redis.Redis(
        host=os.environ.get('AUTHENTIK_REDIS__HOST'),
        port=int(os.environ.get('AUTHENTIK_REDIS__PORT', '6379')),
        password=os.environ.get('AUTHENTIK_REDIS__PASSWORD'),
        ssl=os.environ.get('AUTHENTIK_REDIS__TLS', 'false').lower() == 'true',
        ssl_cert_reqs=ssl_cert_reqs,
        socket_timeout=10
    )
    r.ping()
    print('✅ Redis conectado')
    sys.exit(0)
except Exception as e:
    print(f'❌ Intento {attempt}/{max_attempts} - Error Redis: {e}')
    sys.exit(1)
        "; then
            echo "✅ Redis disponible"
            break
        else
            echo "⏳ Esperando Redis... (intento $attempt/$max_attempts)"
            sleep 5
            attempt=$((attempt + 1))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "❌ Redis no disponible después de $max_attempts intentos"
        exit 1
    fi
}

# Verificar conexiones
check_postgres
check_redis

echo "💾 Inicializando base de datos..."

# EJECUTAR MIGRACIONES DE DJANGO PRIMERO (esto crea django_migrations)
echo "📦 Ejecutando migraciones básicas de Django..."
python manage.py migrate --run-syncdb || {
    echo "⚠️  Error en migraciones básicas, intentando crear tablas manualmente..."
    python -c "
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lifecycle.settings')
django.setup()

from django.core.management import execute_from_command_line
from django.db import connection

try:
    # Crear las tablas básicas de Django
    execute_from_command_line(['', 'migrate', '--run-syncdb'])
    print('✅ Tablas básicas creadas')
except Exception as e:
    print(f'❌ Error creando tablas básicas: {e}')
    exit(1)
    "
}

# AHORA ejecutar el ciclo de vida de Authentik
echo "🔧 Ejecutando migraciones de Authentik..."
python -m lifecycle.migrate || {
    echo "❌ Error en migraciones de Authentik"
    exit 1
}

# Crear superusuario si no existe (solo en primera ejecución)
if [ "$CREATE_ADMIN_USER" = "true" ]; then
    echo "👤 Creando usuario administrador..."
    python -m lifecycle.bootstrap || {
        echo "⚠️  Usuario admin posiblemente ya existe"
    }
fi

# Determinar qué proceso ejecutar
if [ "$AUTHENTIK_MODE" = "worker" ]; then
    echo "🔧 Iniciando Authentik Worker..."
    exec python -m lifecycle.worker
else
    echo "🌐 Iniciando Authentik Server..."
    exec python -m lifecycle.web
fi
