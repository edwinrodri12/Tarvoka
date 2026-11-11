# TARVOKA — Firma persistente de APK de depuración

## Estado
El flujo de GitHub Actions admite **dos modos**:
1. En `pull_request` y en despachos no autorizados para `main`, genera una firma de depuración **efímera**. Sirve para comprobar exportación, **NO** para actualizar encima de una APK instalada con otra firma.
2. En `workflow_dispatch` ejecutado desde la rama `main`, usa **firma persistente** solo cuando se han configurado los tres secretos completos; si los tres faltan, usa la firma efímera y lo anuncia en los logs. Una configuración parcial provoca fallo explícito.

No se almacena ningún archivo JKS/P12, contraseña o clave privada en Git. El flujo verifica el alias/contraseña, comprueba APK firmada/ARM64 e imprime **solo la huella pública SHA-256** del certificado. El almacén temporal se borra del runner.

## Configuración manual requerida (NO realizada por CI)
Conservar una copia privada y duradera de la clave fuera del repositorio; si se pierde, no será posible firmar futuras actualizaciones compatibles. Usar JDK/keytool para generar una clave nueva con alias único y contraseña fuerte. La contraseña de la clave debe coincidir con la del almacén para este flujo de exportación debug.

Ejemplo interactivo (no escribas contraseñas en argumentos de línea de comandos):

```bash
keytool -genkeypair -keystore tarvoka-debug.jks -alias tarvoka-debug -keyalg RSA -keysize 3072 -validity 10000 -dname "CN=TARVOKA Debug,O=TARVOKA Development,C=US"
```

En GitHub, abrir los secretos de **Actions** del repositorio y configurar:
- `TARVOKA_DEBUG_KEYSTORE_BASE64`: contenido íntegro del archivo keystore codificado en base64, en una sola línea (ejemplo Linux: `base64 -w 0 tarvoka-debug.jks`). **Tratar como secreto**, nunca subirlo a commits, issues, logs o mensajes.
- `TARVOKA_DEBUG_STORE_PASSWORD`: contraseña fuerte del almacén (y de la clave).
- `TARVOKA_DEBUG_KEY_ALIAS`: alias de la clave (p. ej. `tarvoka-debug`).

Los valores solo se usan al ejecutar manualmente el workflow `TARVOKA Android debug APK` seleccionando **main**. No están disponibles para el código de los PR. Tras la ejecución, comprobar en el log `Debug signing identity mode: persistent` y guardar la huella pública del certificado; repetir manualmente y verificar **la misma huella**. Solo entonces considerar la firma estable en CI.

## Límites
- **Sin secretos configurados, la firma persistente NO está activa**. Que el pipeline pase en `pull_request` solo demuestra la ruta efímera.
- La primera APK firmada con una clave **nueva** puede no instalarse encima de una APK previa con firma efímera, aunque el `applicationId` coincida. Una desinstalación podría borrar datos `user://`. Confirmar la política de respaldo/restauración antes de migrar dispositivos.
- Firma de depuración para pruebas, **no** equivale a la firma/publicación comercial en tiendas.
- Falta prueba Android física: actualizar en el mismo dispositivo entre dos compilaciones manuales firmadas con la misma clave, manteniendo partidas y autoguardado.
