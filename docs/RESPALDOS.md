# Respaldos, recuperación y actualización
`python3 scripts/backup.py` detiene app, copia SQLite y modelos en dos tar, incluye .env y configuración, y genera manifiesto completed solo al finalizar. Reinicia app si antes estaba activa incluso si falla el respaldo. Gateway puede responder error temporal mientras app está detenida.

`python3 scripts/check_backup.py backups/FECHA` comprueba hashes, lista exacta y seguridad de rutas/tipos del tar. No acepta symlinks ni archivos especiales. Si un futuro modelo usa enlaces, no eliminar la comprobación sin revisar un procedimiento seguro. El checksum detecta daños accidentales, no autentica un manifiesto alterado por un atacante.

Las copias contienen claves API en claro dentro de la SQLite nativa y hash Basic Auth: cifrar, restringir acceso y guardar fuera del VPS. Los textos no se archivan como función de este kit, pero no se promete que bibliotecas, proxy, memoria o logs nunca conserven fragmentos; revisar retención y configuración del entorno.

Restaurar en servidor/Compose nuevos con el mismo kit, versión y arquitectura, servicios detenidos y ambos volúmenes vacíos. Mantener configuración igual al respaldo; .env puede cambiar para rotar la puerta de acceso. No ejecutar permissions ni app antes de la comprobación de vacío si un despliegue ya escribió datos.

`python3 scripts/restore.py /ruta/respaldo`

Valida todo antes de escribir, exige volúmenes vacíos y no borra ni sobrescribe. Restaura archivos, corrige propietarios y deja servicios detenidos. No hay transacción conjunta entre volúmenes: si falla a mitad, descartar ese destino incompleto y repetir en otro vacío.

Para ensayar sin egress una vez recuperados los modelos:

`docker compose -f compose.yaml -f compose.bootstrap.yaml -f compose.rehearsal.yaml up -d gateway`

El override marca la red interna y permite probar solo por loopback/túnel. Si intenta descargar algo faltante y falla, la prueba offline no está aceptada. No usar el override de aislamiento para la primera descarga.

Las claves recuperadas pueden volver a habilitar accesos revocados: revisar y rotar antes de producción. Conservar copias de modelos con la versión de app. Para actualizar, respaldar, ensayar versión/modelos nuevos en otro entorno y aceptar antes de cambiar tráfico; volver atrás requiere recuperar el conjunto anterior, no solo degradar la imagen.
