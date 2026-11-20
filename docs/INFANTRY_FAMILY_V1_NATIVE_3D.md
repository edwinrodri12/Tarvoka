# TARVOKA · Familia de infantería V1 | Modelo 3D nativo

**Estado: EN DESARROLLO / revisión visual pendiente.** Rama aislada, no es unidad finalizada ni APK publicada. Diseñado y conectado al **mismo TARVOKA Estudio 3D**, sin visor alternativo ni imágenes simuladas.

## Objetivo

Establecer un soldado original, contemporáneo, creíble y reutilizable para las ocho facciones; conservar especializaciones que cambien decisiones tácticas, no añadir seis clases redundantes a la producción.

| Selector del visor | Familia del catálogo | Equipo y silueta 3D | Papel previsto |
| --- | --- | --- | --- |
| `line` | G01 Guardia | Peto, casco, fusil, placas y equipo estándar | Infantería de línea y captura |
| `infantry_urban` | G01, kit urbano | Protección mandibular, escudo plegado, arma compacta | Defensa urbana / reducción de cobertura a campo abierto como contrapartida |
| `infantry_defense` | G01, kit defensivo | Coraza extra y visor reforzado | Defensa de posición a coste de movilidad/flexibilidad |
| `scout` | G03 Rastreador | Óptica doble y antena/sensores | Explorar con niebla, no revelar mapa completo |
| `infantry_antitank` | G04 Rompedor | Lanzador dedicado y reserva de equipo | Contrarrestar blindados sin ser inmune a infantería |
| `infantry_engineer` | G05 Ingeniero | Caja de herramientas y equipo plegable | Obras/despeje/reparación con turnos y recursos, no cura gratis |

**Los kits urbano y defensivo son especializaciones visuales de G01, no IDs nuevos de combate.** G03, G04 y G05 conservan sus familias funcionales independientes. Los roles `infantry_*` son entradas de **previsualización artística**, no están registrados en `ModernArsenal.gd` ni desbloqueados en partidas.

## Geometría nativa

- Solidez 360°: botas, extremidades, articulaciones, peto, mochila, guantes, casco y visor son **MeshInstance3D** con materiales PBR de transparencia deshabilitada; no planos 2D ni mallas vacías.
- Un solo rig de pivotes para piernas, brazos, torso, casco y armamento. La cámara puede girar sin que se exponga un rostro hueco.
- **Ocho facciones:** pinturas de alto contraste en pecho, casco, ambos hombros, cintura, espalda, mochila y arma/equipo. Uniforme táctico neutral para no cubrir el soldado con un único color.
- LOD13 = inspección detallada (cinchas, bolsillos, hebillas, auriculares); LOD8 = mapa móvil, menos geometrías pero misma identidad visual y silueta.
- Estados de daño D0 a D4: marcas físicas progresivas y postura de destrucción; `restore` devuelve el modelo intacto. **No cambia los HP del motor.**
- Poses V1: caminar, apuntar, ataque/retroceso de arma, captura, ingeniería/trabajo e impacto.

## Integración real y límites

- `scripts/ui/InfantryFamilyV1.gd`: constructor, rig, materiales, animación, impactos, reparación visual.
- `scripts/ui/UnitModels3D.gd`: conserva los índices existentes; reemplaza el viejo blockout de `line` y `scout`, añade cuatro variantes sólo artísticas. Las unidades tácticas existentes mantienen rol y reglas.
- `scripts/ui/BastionStudioAdapter.gd`: agrega nombres en el selector original, escenas hero, animación/daño y restablecimiento dentro de las pestañas de inspección existentes.
- `.github/workflows/tarvoka-3d-pages.yml`: copia también `InfantryFamilyV1.gd` desde la misma revisión que `UnitModels3D.gd` para evitar referencia ausente en la compilación unificada.

## QA exigida antes de aprobar

1. Ejecutar `tests/test_infantry_family_v1.gd` con Godot 4.3 y revisar **96 combinaciones** (6 configuraciones × 8 facciones × dos LOD).
2. Guardar y revisar **13 capturas Godot genuinas**: ocho facciones de Guardia y cinco configuraciones adicionales de la primera facción.
3. Inspeccionar costuras y silueta 360°, longitud de brazos y articulaciones; comprobar que no haya transparencias, intersecciones de equipo ni movimiento rígido.
4. Probar selección, animaciones y daño dentro del **mismo TARVOKA Estudio 3D publicado**; después verificar legibilidad a zoom de batalla y rendimiento Android real.
5. No fusionar a `main` ni decir «finalizada» hasta pasar QA y aprobación visual. El tanque, los edificios, G15 y G16 quedan intactos.

## Próximas iteraciones de arte (no incluidas en V1)

- V2: rasgos, visores, correas, pliegues de tela, manos y encajes de armas a la altura de brazos.
- V3: caminar/correr/cubrirse con mayor articulación y animaciones independientes para las variantes.
- V4: niveles tecnológicos I–III, cambios visibles de equipo y pruebas de contorno/colisión a escala de Android.
- V5: impactos, polvo, heridas no gráficas, muerte y transiciones pulidas; balance después de sesiones reales.

**No se han ejecutado pruebas en un Android físico.** Ningún nuevo equipo de ingeniería, disparo antiblindaje, capturas aceleradas o bonificación de tecnología debe declararse implementado en gameplay.
