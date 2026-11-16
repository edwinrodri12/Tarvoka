# TARVOKA · Cuartel de Infantería V5 — revisión final de uniones y proporciones

## Corrección de geometría
La V4 pasó la validación nativa, pero al revisar el volumen del N3 encontramos dos contactos que necesitaban arreglarse:

**Bases de torres:** con la torre N3 inicial centrada en Z=3.65, el borde delantero de su cubierta (profundidad 2.15) quedaba en **Z=2.575**. El muro trasero del ala acaba en **Z=2.905**: había 0.33 m de intersección entre cubierta y ala. La V5 desplaza hacia atrás **+0.45 m** ambas torres, junto con sus detalles de arriostramiento/escalera, y **también los restos** cuando el edificio está en daño crítico.

Cálculo después del desplazamiento:
- Bordillo delantero de cubierta: `3.65 + 0.45 - 2.15 / 2 = 3.025`; ala termina en `2.905`: **0.120 m de separación real**.
- Base de cada torre, profundidad 1.62: su borde comienza en `3.65 + 0.45 - 1.62 / 2 = 3.290`: **0.385 m separado del ala**.
- Fin de la pista N3: Z=2.51; la torre empieza después, permitiendo inspección libre.

**Tablero de entrenamiento:** la V4 lo situaba en el final de la pista N3 (centro Z=2.46); V5 lo mueve **+0.22 m**. Al colocarse su extremo cercano en Z=2.595, queda después del final de pista Z=2.51. Su extremo posterior termina en Z=2.765, antes del inicio de la cubierta de torre Z=3.025: **0.260 m de separación**.

El repositorio conserva la V4 por separado, y la V5 modifica posiciones reales de los nodos 3D, no fotografía ni UV falsa.

## Refinamiento de fachada y mantenimiento
- Unión metálica muy estrecha y bajantes posteriores con abrazaderas en **cada módulo**, sin cerrar los huecos de ventana abiertos en V4.
- Remates de las rejillas de ventilación superior únicamente en el edificio **operativo**, con niveles 2 y 3. No crea ventilaciones en nivel 1.
- Una escalera de mantenimiento exterior en la cara este del ala oriental del N3. Queda **fuera de los huecos de ventana**, no atraviesa el edificio ni choca con la torre posterior desplazada. Conserva 12 peldaños en operativo, 10 en leve; se elimina en daños medio, crítico y destruido.
- No crea nuevos edificios, alas, torres o plantas. Preserva las tres siluetas N1 (barraca baja), N2 (L con una torre) y N3 (U con dos torres).
- Cinco estados de daño y colores de las ocho facciones; V5 añade **cero mallas** sobre edificio destruido y crítico (aunque mueve los restos de torre crítica).

## Visualizador Godot
`Edificios 3D → Cuartel de Infantería V5 · uniones y remates 360°`:

- Tres niveles; ocho facciones; cinco daños.
- Comparación reversible V1 / V2 / V3 / V4 / V5, con nueva opción para V5.
- **Ocho cámaras**, incluyendo una nueva vista cercana sobre las torres y sus uniones en N3.

La pasada V5 usa `InfantryBarracksFinishV5.gd` aplicada **solo después de** `InfantryBarracksFacadeV4.gd` y sus predecesoras. Nunca cambia `UrbanEconomy.gd`, combate, guardados ni APK.

## QA verificable
`tests/test_infantry_barracks_v5_gpu.gd` ejecuta Godot 4.3/OpenGL nativo en **120 variantes** (8 facciones × 3 niveles × 5 daños). Comprueba con valores y mallas reales:
- Separación entre cubiertas/bases de torres y alas posteriores del N3.
- Relocalización y separación del tablero respecto a pista y torre.
- Fachadas V4 aún abiertas y muros originales ocultos.
- Dos uniones traseras por módulo, ventilaciones del nivel correcto, peldaños de la escalera exterior y ausencia en daños altos.
- Estado destruido sin nuevos elementos, regresión en HQ, Base Aérea y Base Naval.
- 18 capturas nativas (niveles, traseras, laterales, pista, torre, comparación V4/V5, daños y facción).

**No declarar terminado ni publicado hasta aprobar QA y revisar sus capturas**. El objetivo de V5 es resolver defectos observados, no añadir complejidad visual por sí misma.

## Próxima fase sugerida
Una inspección final de 360° a escala de pantalla de juego y ajuste de las ventanas de la esquina si revelan intersecciones. Después, clasificar el modelo de arte como aprobado y pasar a Fábrica Militar, dejando la integración a la APK pendiente por separado.
