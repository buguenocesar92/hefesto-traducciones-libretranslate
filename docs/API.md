# API y ejemplos
Contratos nativos relevantes: GET /languages y POST /translate. Consultar el esquema/documentación de la versión desplegada antes de ampliar integraciones.

Solicitud JSON de traducción:

```json
{"q":"Hola mundo","source":"es","target":"en","format":"text"}
```

Respuesta típica: objeto con translatedText. La traducción no es determinista en calidad entre versiones/modelos y necesita revisión humana cuando se publica contenido.

## Cliente incluido
Desde el host, con Python 3.11+ y un endpoint HTTPS propio:

`HEFESTO_BASIC_USER=hefesto python3 scripts/translate.py --url https://traducciones.tudominio.cl < ejemplos/texto-es.txt`

Solicita contraseña de forma oculta por terminal. Valida HTTPS, no sigue redirecciones, limita texto de entrada y no guarda la respuesta ni imprime secretos. El texto sí se envía al servidor que el operador indique. No usar dominios de terceros con credenciales propias.

## Claves y cuotas nativas
Se habilita SQLite en /app/db/api_keys.db. Para emitir una clave, después del primer arranque:

`docker compose exec app ltmanage keys --api-keys-db-path /app/db/api_keys.db add 60 --char-limit 3000`

La CLI imprime el secreto: guardarlo en un gestor de contraseñas, no en Git ni capturas. Para listar claves usar la misma ruta sin add. Para eliminar, usar `ltmanage keys --api-keys-db-path /app/db/api_keys.db remove CLAVE` en un terminal de confianza; la CLI original recibe la clave por argumento. No publicar salidas ni historial. La caché nativa puede retrasar la revocación; reiniciar app y verificar con una solicitud nueva si se necesita revocación inmediata.

El cliente opcionalmente lee HEFESTO_API_KEY del entorno y la envía como api_key en JSON. En n8n almacenar Basic Auth y clave en credenciales protegidas; enviar texto mediante HTTP Request POST a /translate. Esta es una guía de conexión, no un workflow instalado ni sincronización implementada.

El límite base es 30 peticiones/minuto, 3000 caracteres y lote de hasta 4. Las claves pueden modificar cuotas. Probar el comportamiento real incluyendo lotes. No confundir una cuota en memoria con facturación por consumo ni un token con aislamiento multicliente.
