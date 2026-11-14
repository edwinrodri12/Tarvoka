# TARVOKA — Ejército y Producción horizontal

**Bloque del 13 de noviembre de 2026.** Implementación funcional para Godot 4.3 Android en horizontal, con diseño base 1280×720 y control de recortes a 960×540.

## Ejército

La pestaña **Ejército** presenta dos columnas independientes:
- **Catálogo desplazable:** todas las unidades vivas y propias del bando observado, sin el antiguo recorte silencioso a 30. Muestra icono de unidad teñido con su facción, identificador real, rol, HP y si aún puede atacar.
- **Ficha:** detalle de la unidad seleccionada con valores HP, ataque, defensa, movimiento, alcance mínimo y máximo, dominio y, cuando existen en el estado, combustible y munición. También diferencia una acción de movimiento ya gastada de un ataque realizado.
- **Ficha** actualiza solo el panel informativo; **Mapa** y **Localizar en el mapa** reutilizan la señal existente `inspect_unit_requested`. No emiten órdenes de combate.

Se usa únicamente el inventario propio; el panel no consulta tropas rivales ocultas.

## Producción

- **Columna izquierda:** instalación propia real, coordenadas, créditos propios y comparador A/B usando `UnitComparisonData.compare`; estadísticas y disponibilidad provenientes del motor.
- **Columna derecha:** catálogo de los modelos que el edificio seleccionado realmente fabrica. Cada ficha muestra nombre, coste exacto `Economy.cost`, ataque, defensa, movimiento, alcance, motivo de disponibilidad y botones **Ficha A / Comparar B / Comprar**.
- Si faltan fondos, la base ya produjo o la casilla está bloqueada, **Comprar** queda deshabilitado con el motivo que calcula `UnitComparisonData.candidate`, que a su vez consulta `Economy.can_purchase`.
- El botón disponible sigue enviando la señal original `purchase_requested(role)`. La transición real de compra y el descuento de créditos permanecen exclusivamente en el núcleo existente.
- La comparativa muestra el **color auténtico de la facción**, no un azul fijo.
- Cuando no hay economía o no se seleccionó una instalación propia, el panel presenta instrucciones sin inventar modelos ni créditos.

## Calidad y pruebas

`tests/test_army_production_landscape.gd` verifica listado de más de 30 unidades propias, ficha de solo lectura, paneles lado a lado, precios, bloqueo de compra, selección A/B y estado de batalla intacto.

La galería real `tests/capture_ui_gallery.gd` se amplía de 14 a **18 capturas**, incluyendo Ejército y Producción en horizontal 1280×720 y 960×540, usando para la producción un escenario de prueba en memoria. En ninguna captura se ejecuta una compra ni se cambia una partida del usuario.

**Sin alteraciones** de arte aprobado, balance, IA, facciones, niebla de guerra, lógica de producción, economía ni esquema de guardado. Sigue pendiente la QA física de Android (gestos, FPS, densidades).
