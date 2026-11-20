# TARVOKA — G16 V3 · mecánica 6×6, servicio logístico y daños 3D

**Estado:** programación nativa implementada sobre el modelo V1/V2 de la G16 en la rama `feat/g16-v1-armored-logistics-studio-20261119`. No fusionado ni desplegado todavía; ejecutar Godot QA antes de aprobar.

## Nueva geometría de V3

### 1. Suspensión y transmisión, sin flotantes
- Seis conjuntos separados de ballestas (uno por rueda), con hojas metálicas escalonadas, grilletes, abrazaderas, amortiguadores compuestos por cuerpo y vástago, y soportes de buje. El conjunto es físicamente 3D y visible desde los bajos.
- Tres ejes transversales con carcasa de diferencial central y componentes de rodadura; transmisión central protegida. Los neumáticos y la dirección visual V1/V2 no se reemplazan.
- LOD13: 4 hojas por ballesta, 8 elementos de detalle por arco existentes V2. LOD8: 2 hojas y menos polígonos en cuerpos cilíndricos. Mantiene seis ruedas en ambas versiones.

### 2. Abastecimiento visual real
- **Combustible:** conexiones, tuberías sólidas, válvulas metálicas, dos bocas de llenado, dos volantes de válvula y enrollador de manguera junto a los depósitos V1.
- **Munición:** dos tapas blindadas en bisagra, con pasadores y juntas opacas, sobre los **dos** cofres V1. Se ocultan las dos tapas V1 únicamente mientras V3 esté activada, evitando solapamientos y permitiendo una comparación verdadera.
- Animaciones: `resupply` levanta las dos tapas; `unload` levanta la segunda; `camp` las mantiene abiertas; `pack` las cierra; `idle/move/deploy/hit` preservan las tapas cerradas. La grúa hidráulica V2 y rampa V1 permanecen sincronizadas.
- Rampa: guías, placas de agarre y nervaduras sólidas que siguen la bisagra real de V1.
- **Sin reglas nuevas**: el campamento es temporal y puramente gráfico; no se crea ningún edificio de suministros permanente.

### 3. Cuatro niveles de daños acumulativos y reversibles
| Estado | Mallas añadidas (no destruyen el casco original) |
|---|---|
| 0 | Carrocería y cargas V1–V3 intactas |
| 1 | Rayones, abolladuras y desgaste frontal |
| 2 | Daños laterales, defensa trasera y fracturas superficiales sobre vidrio físico opaco |
| 3 | Marcas, deformaciones en tanque y cajas, mallas geométricas de humo |
| 4 | Carrocería ennegrecida, depósitos chamuscados, humo volumétrico opaco y brasas |

Ninguna etapa suprime la cabina `BoxMesh`, las cuatro ventanas PBR opacas, el techo cerrado ni los seis neumáticos. Los daños son gráficos, no influyen en HP o en el balance.

### 4. Integración obligatoria: el MISMO Estudio TARVOKA 3D
- `scripts/ui/G16LogisticsMechanicsDamageV3.gd`: escultura y estados artísticos; API `apply`, `has_model`, `sync`, `restore`, `show_finish`, `set_damage`, `stage`.
- `scripts/ui/UnitModels3D.gd`: G16 V1 → V2 → V3 en la **misma instancia** `logistics_mobile`; sincronización después de la animación de V1 y cilindro V2; restauración conserva nivel visual de daño.
- `scripts/ui/BastionStudioAdapter.gd`: opciones V3 mostrar, V2 comparar, daño 0–4, movimiento, descargar, abastecer, montar y plegar campamento. V2 oculto fuerza ocultación de V3; restaurar V2 vuelve a presentar V3.
- `.github/workflows/tarvoka-3d-pages.yml`: copia `G16*.gd` desde el snapshot de la misma rama; exige `G16LogisticsMechanicsDamageV3.gd` y sus menús, preserva preload durante la integración G09, **ejecuta prueba G16 V3 en el checkout del Studio web ensamblado**, no solo en el PR.

### 5. QA / entrega verificable
- `tests/test_g16_v3_logistics_qa.gd`: 8 facciones × LOD8/13, seis ballestas y amortiguadores, tres diferenciales, tuberías, dos tapas con ángulos reales, 5 estados de daños, cuatro ventanas PBR opacas y comparativa V2/V3.
- `.github/workflows/g16-v1-native-logistics-qa.yml`: prueba V1 (16 PNG), V2 (24 PNG) y V3 (**28 PNG reales**, 16 comparativas por facción, 8 ángulos 360° y 4 niveles de daño).
- Gate adicional del ensamblado Web 3D: 28 PNG producidos **dentro del mismo Godot que exporta el Studio público**.

## Jugabilidad que NO se altera
`scripts/core/ModernArsenal.gd`: rol táctico `logistics`, código G16, HP **8**, movimiento **4**, ataque **0**, coste **300**, fábrica, reglas de reabastecimiento existentes sin cambios. `logistics_mobile` continúa siendo un rol **exclusivamente artístico**.

**Pendiente final:** resultados CI, inspección de los 28 PNG y publicación comprobada. No declarar el modelo final mientras existan huecos, transparencias o fallas del visor.
