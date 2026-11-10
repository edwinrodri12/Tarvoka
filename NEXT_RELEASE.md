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
- PR #52: trabajo separado de seguridad de compilación por automatización, verificar estado antes de incluirlo.

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
