# TARVOKA — Centro de Drones V1 · edificio original nativo 3D

## Objetivo
La economía moderna ya contiene **dos instalaciones de tipo `drone_center`**, una de cada bando, que producen drones de acuerdo con las reglas vigentes. Solo se mostraban cubos genéricos en el mapa 3D. Esta versión desarrolla el **modelo artístico original**, sin crear un edificio redundante ni modificar la producción, economía, capturas o IA.

## Lenguaje visual distinto de la Base Aérea
- Hangar horizontal compacto de dos bahías de servicio, no pista de aviación.
- Plataforma circular de drones con marcas de aterrizaje y aparato estático de mantenimiento en detalle cercano.
- Radar de cubierta, antenas y sensores. Los niveles altos añaden torre de operaciones y módulos de control.
- Ocho pinturas oficiales de facción y neutro gris, con franjas legibles desde la cámara táctica.
- N1–N3 con arquitectura realmente diferente; D0–D4 con derrumbes progresivos y sin piezas intactas tras destrucción.
- Cristales translúcidos en la torre N2/N3 (D0–D2), sin crear un enorme bloque de vidrio opaco.

## Rendimiento Android
Una malla 3D nativa por edificio, con cuatro superficies por defecto o cinco en zoom cercano con torre acristalada. Histéresis 118/85 píxeles, máximo una sustitución por actualización. Las piezas estáticas de drones de decoración **no son unidades jugables**. La etiqueta `game_visual_only` impide confundir arte con lógica.

## Validación y próximas fases
`tests/test_drone_center_v1_native.gd` valida 120 variantes, las dos instalaciones reales en `UrbanEconomy`, proyección de modelos dentro de una casilla, zoom y retorno, lectura FPS, niebla y economía inmutable. Capturas `close.png` y `distant.png` se generan desde el renderizador Godot GL Compatibility en Linux Mesa. No se extrapolan FPS de Android hasta la prueba física.

**Estado artístico:** V1 funcional y en revisión, no declarar terminado hasta inspeccionar las capturas y el modelo en el visor 3D compartido.
