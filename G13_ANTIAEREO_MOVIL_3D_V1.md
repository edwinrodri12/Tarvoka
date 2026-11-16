# TARVOKA — G13 Antiaéreo móvil, primer modelo 3D

**Estado:** MODELO VISUAL V1 EN DESARROLLO. **No es una unidad jugable** y no modifica el motor táctico.  
**Sucesión artística:** G11 Lanzador finalizado y protegido en `G11_FINAL_ART_APPROVAL_V33.md`.

## Identidad

La auditoría `UNIT_ROSTER_AUDIT_V02.md` recomienda mantener G13 como familia propia de defensa antiaérea y absorber el antiguo G14 SAM como una configuración/evolución, no otra unidad redundante. El primer diseño es **original y ficticio**, inspirado únicamente en categorías contemporáneas generales: un blindado móvil compacto **4×4** con torreta antiaérea de **dos cañones**, radar direccional sobre mástil, cristales blindados y ocho pinturas de facción.

La silueta se diferencia deliberadamente del G11 (orugas y batería de cohetes), del G09 (tanque con cañón principal) y del P06 (transporte 6×6): rueda 4×4, carrocería corta, dos cañones finos elevados y radar visible.

## V1 construida en Godot 4.3

Archivo principal `scripts/ui/G13MobileAirDefenseV1.gd`, activado por el rol de **visualización** `aa_mobile` al final de `UnitModels3D.ROLES` (no se modifica ninguna de las ocho posiciones de rol existentes).

- Casco blindado sellado de dos cuerpos, parabrisas dividido, portón trasero y escotillas de mantenimiento.
- Dos ejes 4×4, cuatro ruedas compartidas en un `MultiMeshInstance3D`; bujes agrupados solo en vista detallada; holgura lateral entre ruedas y casco.
- Torreta de azimut independiente, doble elevación de cañones, dos bocas originales y módulo óptico.
- Mástil y radar independientes con su propio barrido, sin mover la torreta.
- Materiales PBR compartidos para acero, blindaje, goma, óptica y esmalte de cada facción, sin imágenes pegadas ni geometría propia de otros juegos.
- Poses de inspección: rodaje, radar, orientación de armas y reposo. Todas restaurables, sin proyectiles reales ni mecánica de combate.

Se integra en el mismo selector del **Estudio 3D**, etiquetado como *G13 — Antiaéreo móvil — boceto 3D V1*, con controles propios. Las ocho facciones se validan con `tests/test_g11_final_lock_g13_v1.gd` y las 16 imágenes de Godot proceden de `tests/test_g13_native_v1_capture.gd`.

## Tres niveles visuales previstos — pendientes de diseño y balance

| Evolución | Silueta visual propuesta | Función táctica pendiente |
|---|---|---|
| **Nivel I** | 4×4, radar compacto y dos cañones de corto alcance | Defensa antiaérea económica de proximidad |
| **Nivel II** | Mejor cubierta de sensores, radar reforzado y protección de electrónica | Mayor detección/control de espacio con contrapartidas |
| **Nivel III** | Módulo de misiles SAM opcional, claramente distinguible del Nivel I | Alcance superior frente a aeronaves, con vulnerabilidad cercana/coste |

Estos son **conceptos de evolución**, no niveles ni habilidades ya aprobadas o programadas. Antes de implementarlos deben revisarse detección, alcance, contramedidas, munición, coste, IA, niebla de guerra y equilibrio entre facciones. El SAM no será una segunda familia G14 independiente si no demuestra una mecánica nueva.

## Próximos trabajos

1. Revisar en el visor 3D las ocho facciones y vistas desde arriba, abajo, frontal, costados y trasera; localizar solapes o huecos reales.
2. Refinar geometría de cabina, torreta, radar, cañones y ruedas sin elevar innecesariamente el coste Android.
3. Cuando la escultura sea reconocible y esté aprobada, preparar LOD8/LOD10 y sprites con rango visible para el motor; **no activarlo en partidas** hasta validar el sistema antiaéreo y las cinco clases existentes.
