# Instalación y Coolify
Inicio orientativo: CPU amd64/arm64 compatible con la imagen, 2 vCPU, 4 GB RAM y 10 GB libres. Es una estimación, no capacidad medida; medir consumo y latencia con los modelos reales. Un worker limita memoria inicial, pero también rendimiento. No anunciar concurrencia ni SLA sin ensayo.

## Credenciales
Generar un hash con contraseña solicitada de forma interactiva:

`docker run --rm -it caddy:2-alpine@sha256:d8542f48d34a9cf4e4c11a478865229840e87e4c96ea3f439101f31a5d35f75f caddy hash-password --algorithm bcrypt --bcrypt-cost 12`

Ejecutar `python3 scripts/configure.py` y pegar solo el hash. .env queda modo 0600 y con el bcrypt entre comillas simples para preservar los signos $. No copiar el hash en argumentos de shell sin comillas. En Coolify cargarlo como valor literal de BASIC_AUTH_HASH y verificar que no se altere por interpolación. Nunca versionar .env.

## Primera descarga
Compose conserva el entrypoint nativo que inicializa la aplicación y ejecuta Gunicorn. El servicio permissions ajusta los dos volúmenes para UID/GID 1032. El primer inicio necesita salida a Internet para obtener los modelos; el healthcheck permite hasta 20 minutos de arranque, pero el tiempo real depende de la red. Revisar logs antes de ampliar plazos. LT_LOAD_ONLY=en,es limita idiomas; LT_UPDATE_MODELS=false evita actualizaciones deliberadas en cada arranque, no garantiza por sí solo ausencia de red. Verificarlo con la prueba sin egress.

El volumen models conserva todo /home/libretranslate, incluidas .local y las cachés de modelos auxiliares que se creen en el home.

Los modelos descargados no quedan fijados por el digest de la imagen. Registrar cuáles se instalaron y respaldar el volumen models para reproducir la instalación. Revisar sus licencias y procedencia, además de la licencia del motor.

## Acceso privado de prueba
En servidor usar el override bootstrap indicado en README. Desde tu equipo:

`ssh -N -L 8118:127.0.0.1:8118 usuario@servidor`

Abrir http://localhost:8118 y usar Basic Auth. Solo por túnel SSH en equipo de confianza; no publicar HTTP directamente en Internet.

Para finalizar, `docker compose -f compose.yaml -f compose.bootstrap.yaml down` sin -v. Iniciar producción sin ese override.

## Coolify
Importar repositorio privado, conservar ops/, cargar variables y volúmenes keys/models. Asignar dominio HTTPS únicamente al servicio gateway, puerto interno 8080. No asignar dominio ni puerto publicado a app:5000: eso eludiría Basic Auth. No publicar filetools. El TLS pertenece al proxy de Coolify; Caddy interno escucha HTTP y no solicita certificados.

Caddy sobrescribe X-Forwarded-For y retira Authorization antes de enviar al motor. Detrás de Coolify, el límite por IP puede agrupar clientes bajo la IP del proxy. No se promete medición individual por persona. Un solo worker usa límites en memoria que se reinician con el proceso: no son un sistema de cobro o auditoría persistente.

No habilitar traducción de archivos, sugerencias, métricas ni más idiomas sin volver a comprobar recursos y superficie de exposición.
