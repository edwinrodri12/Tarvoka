# TARVOKA — QA de escaramuzas con semilla (12 noviembre 2026)

## Alcance y evidencia
La PR #135 se fusionó en main (merge `70ffb4adf26987fc029b7d5c36dcfdc2ac7be37a`). Incluye terreno simétrico 10×8, semillas 1–999999, selección previa a confirmación, persistencia opcional `map_seed` y pruebas headless de 48 semillas y ocho partidas IA. **Este documento no afirma haber ejecutado esas pruebas en este turno ni que la versión esté validada en teléfono.** Verificar estado de ambos workflows Godot y Android de la revisión final antes de distribuir la APK consolidada.

## Pruebas reproducibles para la próxima APK agrupada
1. Nueva partida → Escaramuza aleatoria: escribir semilla `12345`, comprobar que la confirmación muestra `12345`; cancelar y verificar que el autoguardado anterior sigue intacto.
2. Confirmar la partida; guardar, cerrar por completo la aplicación y reabrir. Comparar terreno, unidades, turno, créditos, niebla, objetivos y semilla con la sesión previa. Repetir con guardado manual y autoguardado.
3. Crear dos partidas nuevas con la misma semilla y opciones idénticas; comparar el terreno. Cambiar la semilla a `12346`; comprobar que la selección cambia sin perder la capacidad de restaurar `12345`.
4. Introducir `0`, `1000000`, texto, vacío y caracteres no numéricos; no deben iniciar una partida inválida ni borrar la anterior sin confirmación.
5. Probar una semilla con niebla, economía, relés, primer turno rojo y combate IA completo. Verificar que la IA no revela terreno oculto ni ataca enemigos invisibles; comprobar resultado y guardado terminal.
6. Probar orientación vertical y horizontal, toques cerca de los bordes, botones grandes, rendimiento, FPS, temperatura y memoria en Android de gama media. Registrar dispositivo, versión Android y duración de sesión.
7. Instalar una APK nueva encima de una anterior **solo si coincide el certificado de firma**; de lo contrario, no desinstalar sin proteger antes los guardados. La firma debug efímera no garantiza actualización en sitio.

## Criterios de aceptación
- **PASÓ:** reproducible en el dispositivo indicado con captura/video o registro, sin pérdida de guardado, sin información oculta revelada, con resultado final correcto.
- **FALLÓ:** incluir semilla, opciones, pasos, resultado observado/esperado y versión exacta del APK.
- **NO EJECUTADO:** todas las pruebas físicas anteriores en esta revisión; no hay dispositivo conectado.
- Las pruebas CI y el export Android no sustituyen QA de teléfono. No cambiar el balance v0.1 de ocho facciones ni prometer campaña completa u online por este hito.

## Siguiente trabajo técnico
Priorizar corrección verificable que surja de QA, pruebas adversariales de semillas/persistencia y prototipo vertical C01 solo después de comprobar las regresiones existentes. No duplicar el generador de la PR #135.
