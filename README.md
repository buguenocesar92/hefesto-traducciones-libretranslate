# Hefesto Traducciones · LibreTranslate 1.9.6
Kit nativo para traducción automática de textos español/inglés, con interfaz web y API REST. Utiliza modelos locales mediante Argos Translate. Es una solución diferente de los kits de inventario, wiki o gestión documental.

## Stack y alcance
Imagen oficial fijada por digest, Caddy como puerta de acceso, modelos persistentes y SQLite nativo para claves API. No se usa Supabase: esta aplicación no necesita PostgreSQL para este despliegue. No requiere OpenAI ni API de un proveedor de traducción de pago. El costo del VPS y su capacidad siguen siendo responsabilidad del operador.

Incluye Compose/Coolify, Basic Auth en toda la web/API, límites nativos, modelos ES/EN, scripts de copia/restauración y cliente Python de ejemplo. La traducción de archivos se desactiva deliberadamente: este producto inicial traduce texto. No incluye OCR, traducción certificada, cobros automáticos, portal multicliente ni conector Odoo.

## Inicio
1. Leer docs/INSTALACION.md y generar hash bcrypt cost 12 con Caddy.
2. `python3 scripts/configure.py` crea .env sin sobrescribirlo; solicita usuario y hash, no almacena la contraseña en claro.
3. `docker compose config --quiet`
4. `docker compose -f compose.yaml -f compose.bootstrap.yaml up -d gateway`
5. Abrir por túnel SSH según guía. La primera carga puede tardar por descarga de modelos; revisar logs.
6. Completar docs/ACEPTACION.md y configurar HTTPS en Coolify hacia gateway:8080. Retirar override bootstrap antes de producción.

La autenticación Basic protege también la API. Las claves nativas asignan cuotas y no sustituyen esta puerta: en esta configuración un cliente autenticado puede traducir sin api_key bajo el límite general. No hay usuarios individuales ni facturación por cliente. Usar una instancia por cliente si se requiere separación.

## Estado
Kit preparado, sintaxis y guardas comprobadas localmente. No se ejecutó Docker, descarga de modelos, traducción, HTTP real ni restauración en este entorno. El ZIP contiene configuración y scripts, no los modelos ni el código fuente completo de LibreTranslate; se obtiene la aplicación mediante su imagen oficial.
