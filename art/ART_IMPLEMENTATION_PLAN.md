# TARVOKA — Fase de implementación visual (inicio 2026-11-12)

## Objetivo
Convertir conceptos visuales aprobados en recursos reutilizables y componentes reales del proyecto Godot, sin alterar el motor táctico funcional. **Los mockups no son sprites finales ni pantallas funcionales.**

## Dirección de arte aprobada
- Isométrico estilizado, colorido, moderno, legible en Android horizontal.
- Terrenos continuos (sin bloques separados), carreteras, ríos, puentes, costas, montañas y bosques.
- Facciones: Alianza Norte (azul), Pacto Escarlata (rojo), Unión Verde (verde), Confederación Solar (dorado), Sindicato Violeta (violeta), Legión Ámbar (naranja), Dominio Turquesa (cian), Orden Ónix (oscuro).
- Conservar identidad propia: símbolos, retratos, unidades y edificios originales.
- Capas de mapa: Normal (por defecto), Territorial, Logística, Táctica (al seleccionar unidad); selector compacto, sin galería de miniaturas durante partida.
- HUD: unidad seleccionada, salud, combustible, munición, movimiento/ataque diferenciados, botón visible Finalizar Turno.

## Reglas de juego que el arte NO debe contradecir
- Ciudades precolocadas, no construibles; generan créditos, tres tamaños y tres niveles económicos.
- Instalaciones militares producen unidades; mejoras compradas con créditos dentro de su edificio según nivel. Sin centro de investigación separado.
- Solo infantería de cualquier especialidad puede capturar ciudades/instalaciones; ocupación múltiple de infantería exclusivamente dentro de edificio capturable; más tropas aceleran captura.
- Abastecimiento físico en depósito (turno de permanencia) o mediante unidades logísticas adyacentes. No suministro remoto desde listas.
- Construcción militar solo en Conquista Estratégica y misiones de campaña específicas. Central energética experimental, no aprobar mecánica definitiva.
- Destrucción, reparación y reconstrucción visuales; números ilustrativos no son balance final.

## Orden de integración
1. Auditar escena principal y render del mapa, establecer resolución/escala de sprites y atlas.
2. Importar referencias y crear **assets originales aislados**: terreno, una unidad de infantería, un tanque, una ciudad, una fábrica, iconos.
3. Sustituir placeholders en una escena de prueba sin cambiar reglas ni cálculos.
4. HUD compacto y selector de vistas.
5. Variantes por facción, edificios por nivel, animaciones, daños y efectos.
6. QA: legibilidad táctil, FPS, consumo de memoria, pruebas de movimiento/ataque/captura/logística y APK.

## Gestión de referencias
Los conceptos visuales creados en conversación deben guardarse como archivos de referencia en `art/reference/` o en un paquete externo versionado, con manifiesto y atribución interna. **No considerar una imagen subida hasta verificar su presencia real en GitHub.** Evitar utilizar screenshots enteros como texturas del juego. Crear sprites y elementos por separado.

## Primer recurso versionado
`art/ui/icons/map-layers.svg` es un icono vectorial original de ejemplo para la interfaz; no depende de los PNG conceptuales.

## Pendientes
- Transferir al repositorio el lote completo de imágenes conceptuales disponibles localmente; comprobar cantidad, hashes y tamaños tras la subida.
- Verificar compatibilidad del importador SVG en Godot y crear versiones rasterizadas si procede.
- Implementar en GDScript el selector de capas con pruebas, tras revisar estructura de escena.
