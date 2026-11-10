# TARVOKA — Juego original de estrategia militar por turnos para Android

Prototipo táctico en **Godot 4.3 + GDScript**, construido para funcionar **offline**, con diseño mobile-first y recursos gráficos originales. **TARVOKA es un nombre comercial candidato**; no debe utilizarse comercialmente sin revisión legal de marcas USPTO/WIPO y de propiedad intelectual.

## Estado actual (2026-11-10)
- Tablero 10×8, movimiento, combate, turnos, IA básica, victoria lógica y persistencia programados.
- Primera APK ARM64 de prueba compilada; hotfix de botones Android integrado en `main` (PR #39).
- Usuario confirmó en teléfono: selección/movimiento táctil, tres botones inferiores y ciclo de IA que devuelve el turno.
- Aún es un prototipo. Falta validar partida completa hasta victoria/derrota, recuperación real de guardado, diseño táctico legible y rendimiento.

## Documentos oficiales
- [GAME_DESIGN.md](GAME_DESIGN.md): visión, identidad original, pilares de diseño y 30 riesgos de juegos de estrategia históricos que debemos prevenir.
- [DESIGN_ROADMAP.md](DESIGN_ROADMAP.md): fases P0–P3, dependencias, experimentos y criterios de aceptación.
- [DESIGN_QA.md](DESIGN_QA.md): pruebas de comportamiento, criterios en Android y separación entre funcionalidades probadas y pendientes.
- [PROJECT_STATUS.md](PROJECT_STATUS.md): estado técnico y evidencias.
- [BACKLOG.md](BACKLOG.md): pendientes y prioridades.
- [DECISIONS.md](DECISIONS.md): decisiones de producto y arquitectura.
- [TESTS.md](TESTS.md): registros de validación y GitHub Actions.

## Prioridad inmediata
**Completar la experiencia táctica Android (P0) antes de expandir sistemas**: ciclo de victoria/derrota, guardar/reanudar, información visual de movimiento y ataques, confirmación/cancelación, velocidad de turnos y rendimiento.

La investigación de críticas de Advance Wars inspira los **problemas de producto a resolver**, no autoriza copiar arte, mapas, unidades, UI, música, guion u otros materiales protegidos.

No tocar `EKANVORA` ni `centro-operativo-atlanta`. Sin gastos, servicios externos ni lanzamiento público no autorizado.
