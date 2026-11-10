# TARVOKA — Consolidacion del prototipo tactico (2026-11-10)

## Alcance de esta rama
Rama creada desde `automation/board-edge-touch-regressions-20261110` (commit `6671011efcbda060a45fb346260033a1214d59e3`) para presentar **una sola propuesta de integracion contra `main`**. No se reescribieron historias ni se borraron ramas. La comparacion con `main` mostro 209 commits de ventaja, 0 detras y 27 rutas modificadas antes de agregar este informe.

El objetivo es consolidar, no agregar nuevas caracteristicas, y conservar todos los antecedentes de los PR apilados.

## Modulos incluidos (codigo, no verificacion Android)
- `scripts/core/Rules.gd`: matriz 10x8 y navegacion sobre terrenos.
- `scripts/core/Combat.gd`, `BattleActions.gd`: combate y validaciones.
- `scripts/core/Turns.gd`, `BattleSession.gd`, `MoveActions.gd`: estado de batalla, turnos y movimiento.
- `scripts/core/BasicAI.gd`: adversario basico offline.
- `scripts/core/SaveCodec.gd`, `SaveStore.gd`: serializacion y almacenamiento de partidas.
- `scripts/ui/Main.gd`, `TouchBoard.gd`: tablero tactil, acciones, guardado/carga y respuesta de victoria.
- `.github/workflows/godot-rules.yml`: diez suites Godot 4.3 headless.

## Evidencia disponible
- GitHub Actions run `42851246633` correspondiente al commit `6671011efcbda060a45fb346260033a1214d59e3`: SUCCESS; las 10 suites del job `rules` terminaron correctamente.
- Las pruebas headless no equivalen a prueba grafica ni a validacion en telefono Android.
- La rama de integracion requiere SU PROPIA ejecucion CI posterior a los nuevos commits.
- **APK**: NO COMPILADA / NO VERIFICADA; no afirmar que existe.
- **Version local v1.1**: NO importada; requiere comparacion tecnica para evitar sobrescribir codigo consolidado.

## Plan de integracion
1. Ejecutar el workflow sobre el PR de consolidacion apuntando a `main`. No fusionar si falla o se cancela.
2. Revisar visualmente escena Godot y verificar partida completa humano/IA (movimiento, ataque, turnos, victoria, guardado/carga).
3. Si pasa, fusionar el PR de consolidacion a `main` de forma no destructiva; preservar todos los PR originales hasta confirmar equivalencia.
4. Revisar los PR independientes #1-#4: no asumir que sus optimizaciones esten contenidas; comparar diffs/funcionalidad antes de cerrar cualquiera.
5. Resolver los PR apilados #5-#36 solo despues de fusionar y verificar que sus cambios ya estan integrados. Evitar fusionarlos individualmente de nuevo.
6. Configurar exportacion Godot para Android, crear APK de depuracion y verificar en dispositivo real.

## Bloqueos y seguridad
- El repositorio GitHub sigue **PUBLICO** a fecha de auditoria; cambiar visibilidad desde Settings si se desea privado.
- No se modificaron `EKANVORA` ni `centro-operativo-atlanta`.
- Marca TARVOKA: aprobacion comercial condicionada a busqueda juridica de marcas.

## Conciliación adicional de movimiento (#1-#4)
- Comparados los archivos `Rules.gd` de los PR #2, #4 y la rama de integración.
- Incorporado rechazo de origen bloqueado (#1/#2) y cola con cursor para reducir el costo de `pop_front` en rutas ponderadas (#2), manteniendo la validación estricta de terrenos de la cadena posterior.
- Añadidas regresiones de origen bloqueado, cero/negativo presupuesto, mapa corto y rutas con costos ponderados. Los tests usan `Array[Vector2i]` para evitar el fallo de tipado detectado anteriormente.
- No se cerraron los PR #1-#4; la equivalencia y la nueva ejecución CI se deben confirmar antes de hacerlo.
- Commits de conciliación: `05848915`, `39c6cbc1`. **Aún sin ejecución CI confirmada** para estos cambios.
