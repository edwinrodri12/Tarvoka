# TARVOKA — Próxima entrega agrupada para Android
**Estado:** preparación interna · **Fecha:** 2026-11-10 · No es una APK publicada al usuario.
**Política acordada:** no ofrecer ni descargar APK por cada PR; compilar mediante CI para asegurar que el proyecto sigue exportando correctamente. Entregar un APK agrupado cuando se necesite una validación real del conjunto o el usuario lo solicite.

## Cambios incluidos desde el gameplay anterior
- PR #45–#47: interfaz horizontal adaptable, resultado VICTORIA/DERROTA y aviso de error de autoguardado.
- PR #48–#51: recuperación desde respaldo validado, confirmación de movimiento/ataque, resumen enemigo y prueba real de victoria/derrota.
- PR #53: IA con prioridad de eliminaciones y persecución que rodea terrenos impasables.
- PR #54: tres campos originales (abierto, bosque y puentes) con aspectos/costos de movimiento distintos, selector antes de Nueva partida.
- PR #55: caché de información táctica; evita repetición de cálculo de rutas con pantalla inactiva.
- PR #56: siluetas aliadas circulares y enemigas cuadradas, HP numérico y bajas/supervivientes.
- PR #57: bloqueo de guardados malformados y victorias incoherentes.
- PR #58–#59: 12 batallas simuladas IA×IA, modo Entrenamiento vs Simétrico, elección de fuerza inicial transparente.
- PR #52: integrado en main, comprueba biblioteca nativa ARM64 y registra huella pública de certificado en pipeline. La firma de depuración sigue siendo efímera.

## Verificaciones automáticas
Cada PR integrado tuvo su Godot 4.3 headless SUCCESS y Android debug APK export SUCCESS. TESTS.md contiene IDs y alcance. Las 12 simulaciones terminan sin deadlocks; Entrenamiento azul 6–0, Simétrico 3–3. Esto no demuestra funcionamiento del nuevo conjunto en hardware Android, ni balance competitivo general.

## Pruebas imprescindibles al entregar una APK consolidada
1. Instalar en móvil Android ARM64; la firma debug CI puede variar entre compilaciones y obligar a desinstalar (se perderían archivos user://).
2. Confirmar diseño horizontal, legibilidad de casillas, diferencias de terreno, cuadros de selección y HP/unidades por forma.
3. Elegir Bosque o Puentes y confirmar Nueva partida; observar agua bloqueada, costos de terreno y que las unidades no crucen zonas impasables.
4. Seleccionar una unidad, tocar destino una vez (solo previsualiza), tocar segunda vez o Confirmar orden (ejecuta), probar Cancelar selección sin gastar acción.
5. Probar Entrenamiento y Simétrico. En Simétrico, ambos bandos inician HP10/ATQ5; en entrenamiento X/Y HP8/ATQ4.
6. Terminar turno, verificar movimientos/ataques IA, informe del turno, estados de victoria/derrota y bloqueo de acciones posteriores.
7. Guardar manualmente y autoguardar, cerrar completamente aplicación, volver a abrir y comprobar posiciones/vidas/facción/terreno. **No declarar PASS antes del ensayo físico.**
8. Rotar dispositivo, revisar barras laterales/scroll y que los botones conserven áreas táctiles cómodas.
9. Registrar rendimiento percibido, congelamientos, temperatura y errores al cargar.
10. No describir la nueva firma como estable mientras las claves sigan siendo efímeras.

## Condiciones de salida
- PR y GitHub CI de la fuente consolidada en verde.
- Comprobación de certificado APK y arquitectura por pipeline; no confundir export exitosa con instalación real.
- Ninguna nueva fuente de pagos, anuncios o cuenta obligatoria.
- Reportar bugs de gameplay con commit/run y evidencia; corregirlos antes de declarar P0 cerrado.

## Cambios nuevos 2026-11-10 — niebla y reconocimiento
- PR #61–#65 integrados en main: visión por facción y exploración persistente, observación restringida de IA, modo Niebla y reconocimiento opcional, exploradores S/Z con visión5 frente a soldados3, casillas desconocidas oscuras y conocidas pero fuera de visión atenuadas, filtros de unidades ocultas para interfaz, ayudas y motor; IA tampoco conoce obstáculos de casillas no exploradas.
- La versión inicial usa distancia Manhattan; no simula sombras visuales de montañas/bosques ni posiciones enemigas recordadas.
- CI 42915400561/554, 42916085450/399, 42916908716/658, 42917319561/443, 42917859860/845 SUCCESS. 12 partidas fog automáticas sin bloqueos ni trampas observadas.
**Agregar al plan de pruebas físicas agrupadas:** iniciar niebla con ambos modos de fuerza; comprobar scouts S/Z (HP6/ATQ2/MOV4/visión5), limitar destinos a celdas visibles; confirmar que enemigo fuera de visión no se dibuja ni aparece en previews; acercarse y descubrir enemigo; retirarse y ver terreno atenuado sin enemigo visible; guardar, cerrar completamente y reanudar manteniendo casillas exploradas y modo elegido; alternar a partida clásica confirmada y comprobar que no queda niebla. Registrar capturas de comportamiento y FPS/legibilidad real. No afirmar visibilidad física verificada hasta recibir evidencia de teléfono. Sin APK por cada PR.

## Siguientes validaciones tras PR #66–#67
La nueva versión agrupada también incorpora montañas que ocultan casillas detrás de ellas y niebla totalmente opaca para terreno nunca explorado. Probar en mapa con montañas: esconder un enemigo detrás, comprobar que no aparece en el mapa ni en ataque/previa, trasladar explorador por otro lado y confirmar que aparece al estar a la vista; comprobar que la montaña en sí es visible. Revisar esquinas diagonales y terreno forestal (bosques no bloquean visión todavía). Godot 42918936432/42919298522 SUCCESS, Android 42918936216/42919298370 SUCCESS. No hay validación real de pantalla ni firma debug persistente todavía.
