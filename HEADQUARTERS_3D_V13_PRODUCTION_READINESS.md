# TARVOKA · Cuartel General V13 — preparación real para producción Android

## Problema de la V12

El Cuartel General detallado se compone de cientos/miles de mallas editables, lo que es útil para arquitectura, pero no es adecuado para repetirlo decenas de veces en un mapa Android. El conmutador experimental de V5 conservaba **la geometría completa, aunque invisible**, en memoria para poder comparar LOD. Además, el proxy lejano V5 no incluía las grandes curvas V12 ni el escudo oficial: podían perderse identidad visual y silueta.

La V13 separa **el activo completo de presentación** del **activo táctico independiente**. Una partida no necesita construir el original para renderizar su versión táctica.

## Entrega implementada

`scripts/ui/HeadquartersProductionV13.gd` ofrece `build(level,faction,condition,quality,selection)` con dos calidades:
- `tactical`: 1 malla agrupada con **9 superficies de material** (6 del LOD histórico, 3 nuevas para perfiles curvos) + 1 malla del **escudo oficial exacto** del atlas aprobado. **10 superficies / 2 mallas** en total, en lugar de miles de nodos ocultos. No incluye geometría completa invisible.
- `hero`: sigue construyendo la V12 original de calidad de estudio, sin instalar el modelo de mapa oculto.
- 3 niveles × 8 facciones × 4 estados = **96 combinaciones oficiales**, cacheadas por combinación de forma compartida entre instancias. Las tres superficies nuevas reconstruyen el perfil V12 (las alas y la torre, con piezas rotas en el estado destruido).
- `Area3D` opcional **únicamente para selección**; usa una capa dedicada y `collision_mask = 0`. No afecta movimiento, colisiones, ocupación, suministro, IA, captura ni reglas del juego.
- `render_budget` revela cantidad de mallas/superficies y permite un umbral estricto de QA (2 y 10) para el modo táctico.

**Nota sobre arte:** La malla táctica conserva el color aprobado en el volumen y un escudo texturizado oficial como objeto físico, con material compartido por facción. No se han inventado escudos alternativos.

## TARVOKA Estudio 3D

En **EDIFICIOS 3D → Cuartel General** se agrega:
- Casilla **«Perfil táctico V13 (sin miles de mallas ocultas)»**.
- Indicador real de las mallas y superficies utilizadas.
- Conmutación inmediata al modelo V12 para comparar proporciones con la misma cámara; pruebas de día/noche y ocho tarjetas de facción conservadas.

Se mantiene el modelo detallado como predeterminado: el perfil táctico es una opción explícita para inspeccionar rendimiento y legibilidad, no se degradan los renders de presentación.

## QA

`tests/test_headquarters_v13_production.gd` comprueba en Godot GPU:
- Las 96 combinaciones, cache de malla, sin árbol detallado oculto, geometría curvada, 2 mallas/10 superficies y textura oficial correcta.
- Proxy de selección aislado, parámetros inválidos, estados y metadatos.
- Comparación V12/V13 y 8 variantes visibles en el navegador, estado dañado y retorno al visor de unidades.
- Exportación `TARVOKA_CuartelGeneral_V13_Nivel3_Tactico_Optimizado.glb`, más GLB detallado histórico V12.

## Pendientes para certificación comercial

**No debe afirmarse que ya está integrado en una batalla real.** La versión jugable de `main` usa un tablero isométrico **2D** y el Cuartel General 3D aún se expone en un proyecto/ramas de arte con el Estudio 3D. El siguiente bloqueo es diseñar y probar un puente visual aprobado para el tablero real (sprite horneado del mismo 3D, o futura escena 3D), sin reinterpretar ciudades/fábricas como cuarteles ni modificar reglas de captura de manera improvisada.

Antes de certificación: verificar rendimiento real en dispositivos Android de gama baja, occlusión y orden de dibujo bajo terreno, memoria real por escena y niveles de detalle en mapas grandes; revisar el modelo con perspectiva de arte humano y variaciones de suelo/clima. Las **96 combinaciones** están soportadas por el generador, pero no sustituyen pruebas visuales exhaustivas en todos los dispositivos.

No se ha prometido comercialización ni se han implementado compraventa o mecánicas nuevas.
