# Aceptación obligatoria en servidor
- Compose válido e imágenes accesibles para arquitectura elegida.
- Primera descarga y arranque sin errores; GET /languages muestra es y en.
- Sin Basic Auth, web y /translate devuelven 401. Con contraseña incorrecta también. App:5000 no debe ser accesible públicamente.
- Traducir un texto de demostración en ambos sentidos desde web y cliente incluido. Evaluar fidelidad con un hablante competente; no usar textos sensibles para esta prueba.
- Emitir una clave, probarla, revocarla y comprobar rechazo tras vaciar caché/reiniciar si hace falta. Probar límites de caracteres, peticiones y lote.
- Reiniciar conserva modelos y claves. Traducción de archivos desactivada.
- Respaldar y restaurar en otro destino vacío; confirmar mismos modelos y acceso. Probar copia dañada y destino ocupado: deben rechazarse sin sobreescribir.
- Ensayar red interna después de descarga: traducir ES/EN sin egress. Registrar resultado, versiones de modelos y consumo RAM/CPU/latencia.
- Retirar bootstrap de producción; HTTPS y renovaciones del proxy comprobados.

## Oferta comercial
Servicio posible: traductor privado para equipos, API interna de pretraducción de fichas de productos, instalación, formación y soporte. Diferenciar traducción automática de revisión humana; no venderla como traducción certificada o precisión garantizada.

Odoo/WooCommerce: un sistema externo puede enviar campos de texto a /translate y guardar el resultado como borrador para revisión. No se incluye ese conector, modificación automática de catálogos ni publicación de contenido. Implementar permisos, trazabilidad y revisión antes de automatizar la escritura.

No hay cobros, usuarios independientes, créditos de consumo ni panel de suscripciones. Para vender acceso público masivo haría falta diseñar y validar esas funciones y la capacidad real. Es preferible comenzar como servicio dedicado por cliente.

LibreTranslate usa AGPL-3.0; conservar avisos y atender obligaciones aplicables si se modifica y ofrece por red. Los modelos pueden tener licencias propias y se deben revisar. Se adjunta la licencia del proyecto original; no se cambia su marca ni se atribuye su desarrollo a Hefesto.
