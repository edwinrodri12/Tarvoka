# TARVOKA — G13 V48: corrección de las formas principales del vehículo 3D

**Estado:** cambios de geometría **nativa Godot 4.3** guardados en GitHub, integrados en LOD13/LOD8 y en el Estudio 3D. **Pendiente:** validar el render nuevo V48 en el flujo real de GitHub Actions y revisar su aspecto. No se considera terminada la unidad.

## Diagnóstico fundado en imágenes reales, no conceptuales

Se recuperó el artefacto `tarvoka-g13-v43-native-360-design` de la ejecución **#1508** (publicación exitosa). Aunque el nombre del artefacto es histórico, el encabezado de sus capturas muestra **G13 V46**, por lo que documenta el modelo real con sus ruedas mecanizadas. Las ocho vistas incluyen varios ángulos de cabina, techo, frente, trasera y torreta. El contraste frente a las unidades aprobadas muestra **formas grandes todavía poco expresivas**: cabina con frontal muy plano, cubierta superior demasiado uniforme y carcasa de armamento aún muy cuadrada. El usuario había pedido explícitamente nivelar el acabado, no seguir sumando detalles minúsculos.

## Cambio V48 (mallas reales, no imágenes)

`scripts/ui/G13SculptFinishV48.gd` reemplaza tres **recursos `Mesh` sobre los mismos nodos existentes**, utilizando lofts tridimensionales cerrados, con perfiles de varias alturas que sustituyen la silueta anterior. Se conservan y pueden restaurarse los recursos V47 mediante `show_finish(root, enabled)`.

- **Cabina:** seis niveles facetados, 96 triángulos, frente prolongado hasta la proximidad de los cristales frontales reales (`Z≈-1.10` en `Y≈1.22`); mayor transición del parabrisas al blindaje y costados más deliberadamente biselados. Se conserva el pivote real `G13_SealedCab` y el contorno de techo.
- **Torreta:** seis niveles cerrados, 96 triángulos, anillo inferior más compacto, cintura estructural y coronación más estrecha. Se trabaja el `G13_V10_ChamferedTurretShell` en LOD13 y `G13_RemoteWeaponHousing` en LOD8; ambos se mantienen bajo el pivote original `G13_TorretaAzimut`.
- **Techo:** cuatro niveles cerrados, 64 triángulos. Sustituye la cubierta plana por una coronación moderada y borde exterior de dos planos, sin superar los refuerzos del techo V37 ni sus marcas V45.
- **Identidad de facción:** se acercan los dos paneles originales `G13_TurretFaction_±1` y las cuatro placas V44 `G13_V44_FactionTurretGuards` al nuevo costado de la torreta. Conserva **los ocho colores** existentes. Se corrige la apariencia de placas que quedaban separadas varios centímetros del blindaje; las transformaciones previas se guardan y restauran en la comparación.

**No se crean nodos de dibujo nuevos.** Son tres recursos de malla reales sustituidos in situ. No se modifica colorimetría PBR V47, ruedas V46, radar, dos autocañones, movimientos, escenas de las otras unidades ni reglas del combate.

## Ruta nativa

- `scripts/ui/G13SculptFinishV48.gd`: generación y sustitución geométrica.
- `scripts/ui/UnitModels3D.gd`: `G13SculptV48.apply(model)` después de V47 en **LOD13 y LOD8**.
- `scripts/ui/BastionStudioAdapter.gd`: selector **G13 V48** y controles **Silueta blindada refinada** / **Comparar con V47**, aplicados sobre el mismo modelo, cámara y facción.
- `tests/test_g13_studio_web_v1.gd`: exige tres mallas cerradas de 96/96/64 triángulos, cambio reversible de los recursos originales, colocación de pintura, la misma geometría de armas y escultura también en LOD8. Mantiene las pruebas del G11 aprobado.

## Límites honestos

Se inspeccionó la **V46 renderizada** mediante el artefacto real del run #1508; eso sirve para identificar los defectos estructurales de partida, **no** para aprobar el aspecto de V48 sin volver a renderizarlo. El trabajo de CI/publicación puede seguir en cola en GitHub. Conservar la prioridad sobre formas principales y corregir cualquier intersección visible es preferible a multiplicar detalles por versión.
