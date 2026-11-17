# TARVOKA — auditoría de iniciativa y apertura equilibrada

## Hallazgo basado en las 32 partidas completas de v3.6.3

[El experimento v3.5 contra v3.6.3](https://github.com/edwinrodri12/Tarvoka/actions/runs/44188309021) terminó con 14 victorias v3.6.3 y 18 v3.5. Pero **30 de las 32 partidas fueron ganadas por el bando que empezó**. Esto dificulta atribuir diferencias pequeñas a la calidad de la IA; la primera fase es una variable muy influyente incluso con intercambio de bandos.

El motor ya incluye `OpeningBalance.gd`: la primera facción tiene **un límite de tres órdenes legales** antes de pasar su turno. Las partidas nuevas de la interfaz pueden activar este sistema; las comparaciones previas llamaron `BattleSession.start` sin `balanced_opening=true`, por lo que lo omitieron.

## Cambio prioritario (solo QA)

No se alteran estadísticas, mapas, IA, economía, reglas ni APK. Se añade un experimento reproducible **en la rama aislada** para medir correctamente:

1. **32 partidas A/B v3.5 vs v3.6.3**: dos mapas, niebla sí/no, dificultad 10/12, intercambio del primero y del bando que usa cada política. Todas usan `Session.start(..., balanced_opening=true)`.
2. **32 partidas de control espejadas**: 16 v3.5 contra v3.5 y 16 v3.6.3 contra v3.6.3, con los mismos mapas, dificultades, niebla e iniciativa. Así se mide el efecto de empezar primero *sin* confundirlo con diferencias entre políticas.
3. Para las 64 partidas se conservan movimientos, daño, compras, capturas, validación de visibilidad y estados de victoria reales de `BattleSession`.
4. Los registros contienen `BAL363_MATCH`, `BAL363_MIRROR` y un resumen JSON/Markdown. El agregador verifica exactamente los 64 emparejamientos únicos, sin simular victorias o resultados.

**Criterio:** si con apertura equilibrada persiste un sesgo de iniciativa, la prioridad pasa a examinar la condición de victoria por relés y su captura, sin cambiar ni ajustar reglas antes de cuantificar la causa. Si el sesgo desaparece pero v3.6.3 sigue perdiendo, revisar secuencias reales de captura/ataque como parte de la IA.

CI: `.github/workflows/ai-balanced-opening-v363.yml`.

No se fusiona nada a `main` ni se publica APK. La auditoría **no** significa que la IA v3.6.3 ya sea apta para producción.
