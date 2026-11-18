# TARVOKA — G15 Guerra Electrónica: modelado 3D nativo V1

**Estado:** primera versión artística implementada en rama independiente, pendiente de revisión de QA, aprobación visual del usuario y publicación web. **No es una unidad jugable**.

## Decisión de catálogo

- G15 conserva el rol de guerra electrónica independiente frente a la G13 antiaérea.
- G14 no se fabrica como unidad separada: sus funciones SAM serían una especialización posterior de la familia G13, según la auditoría de redundancias.
- La G15 no dispone de cañones, lanzamisiles ni daño directo. El pulso de interferencia es SOLO un efecto de demostración visual, no altera enemigos ni niebla.
- Los costes y estadísticas de G15 de MILITARY_UNIT_CATALOG.md siguen siendo propuestas, no balance aprobado.

## Modelo original V1

- Chasis blindado militar de tres ejes **6×6**, centro de ruedas elevado y refugio electrónico sellado, con identidad diferente al G13 de cuatro ruedas y torreta.
- Seis neumáticos reales de caucho mate **metallic=0, roughness=0.93**, con bloques geométricos de banda de rodadura y bujes.
- Llantas de aleación mecanizada **metallic=0.83, roughness=0.27**.
- Acero, blindaje y vidrio con materiales PBR propios; franja de esmalte de facción con clearcoat, sin recolorear el caucho.
- Cabina, ventanas protegidas, divisores, parrillas de refrigeración, costados, paneles de servicio, escalera, faros y luces traseras.
- Mástil independiente articulado con módulos de antenas, matriz direccional y plato con radomo, sin artillería oculta.
- Ocho acabados de las facciones oficiales y LOD de inspección/Android con la misma silueta esencial.

## Animaciones del modelo

| Pose del Estudio | Contenido visual |
|---|---|
| Rodaje 6×6 | Gira las seis ruedas y repliega el mástil para transporte |
| Desplegar | Eleva el mástil desde plegado |
| Barrido | Rota la matriz direccional |
| Interferencia | Pulso visual de señal; **no ejecuta interferencia jugable** |
| Daño | Inclinación física limitada del vehículo y mástil |
| Restaurar | Devuelve chasis, mástil, antenas y ruedas a estado intacto |

Las seis opciones están enlazadas al selector único del **Estudio 3D** mediante `BastionStudioAdapter.gd`, sin crear una web separada. `UnitModels3D.gd` incorpora `ew_mobile` como rol **exclusivamente visual**, sin alterar `BattleSession`, economía, IA, mapa, armas, ni guardados. `tarvoka-3d-pages.yml` incorpora el script G15 al empaquetado nativo que ya reúne las demás unidades.

## Verificación y riesgos pendientes

`tests/test_g15_native_art_v1.gd` comprueba:
1. Las ocho paletas diferentes y la separación real de materiales metálicos/caucho.
2. Los seis pivotes de ruedas; mástil y antena independientes; ausencia de armas G13.
3. Animaciones de movimiento, despliegue, barrido, interferencia y restauración.
4. Misma silueta básica bajo LOD8.
5. **16 imágenes PNG auténticas del motor Godot** (dos cámaras × ocho facciones), exportadas a `build/qa/g15-v1/`.

El workflow `.github/workflows/g15-native-art-qa.yml` debe verificar parseo, render y capturas en Godot 4.3 antes de marcar el modelo como validado. **No afirmar que el test ha pasado, que las capturas se han generado, o que Pages ya publica G15 sin las respectivas ejecuciones exitosas.** Para la web pública se requiere fusionar el código validado y confirmar `build` y `deploy` del workflow de Pages.

## Siguiente prioridad de arte

Una vez superada la revisión inicial: reemplazar los bloques principales del refugio por geometría biselada esculpida, integrar pasos de rueda en la carrocería, ruedas más naturales, bisagras de soportes del mástil, cables protegidos, microtexturas y animación de destrucción por piezas, respetando rendimiento Android. No introducir habilidades de guerra electrónica al motor sin especificación y pruebas separadas.
