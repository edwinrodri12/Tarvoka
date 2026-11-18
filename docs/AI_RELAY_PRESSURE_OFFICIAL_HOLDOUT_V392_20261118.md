# TARVOKA v3.9.2 — Validar la táctica de relés en la apertura OFICIAL

**18 de noviembre de 2026. Investigación separada en rama DRAFT, no alterar el juego en producción.**

## Motivo
La [v3.9.1](https://github.com/edwinrodri12/Tarvoka/actions/runs/44384701271) **terminó 4/4 SUCCESS** en la semilla 636 con niebla y respuesta inicial experimentalmente limitada a cinco órdenes. Al activar la opción `_ab_relay_tie_pressure_v391` por prueba y sin cambiar ingresos, capturas ni puntos, el primer jugador ganó en **28 medios turnos (señal 8–6)** en lugar de que el respondedor ganara en **34 (señal 11–9)**. Ocurrió para ambas identidades de iniciador y los reflejos fueron exactos. La primera decisión distinta apareció en la fase 25, después de alcanzarse el empate de señal.

**Esto NO valida la táctica para el juego comercial:** esas ocho partidas correspondían a **una sola semilla** y a una regla de apertura que *no existe en producción*. La [v3.8.8](https://github.com/edwinrodri12/Tarvoka/actions/runs/44373996589) ya demostró que imponer un límite de cinco órdenes al respondedor no mejora el balance en ocho semillas nuevas y puede prolongar partidas.

## Comparación propuesta bajo reglas OFICIALES
- Ocho semillas deterministas, **634–641**, todas 40×30, con las cuatro plantillas de mapa incluidas.
- Dos ajustes de niebla × los dos iniciadores = **32 condiciones originales** emparejadas.
- En cada condición: ejecutar una partida con **IA actual y regla real**, su **reflejo exacto**, una partida con **IA opt-in v391 y regla real**, y su reflejo exacto.
- **128 partidas reales** contando reflejos, pero solamente **32 observaciones originales por política**; los reflejos comprueban paridad y no incrementan el tamaño de la muestra.
- El primer jugador mantiene su restricción real de **tres órdenes**; quien responde actúa libremente según todos sus movimientos legales (habitualmente 7–8). No se simula cap5.
- Horizonte de **48 medios turnos** para observar empates más prolongados. Una partida sin ganador es **censurada**, nunca un empate o victoria ficticios.
- Reutiliza el simulador validado `Study._play` añadiendo un parámetro **opcional** `experimental_options={}`, que por defecto deja la IA original intacta. El único código en producción sigue siendo la táctica opt-in existente de v391, desactivada por defecto.
- Antes de una primera diferencia, las decisiones y estados deben ser idénticos en ambas estrategias. En el momento de la **primera divergencia**, el marcador público del estado anterior debe estar empatado y ambos bandos deben haber alcanzado el objetivo: este requisito descarta que la opción provoque un cambio prematuro por una información que no debería observar.
- Además, las tres primeras órdenes del iniciador y las cinco primeras de quien responde deben ser exactamente las mismas entre control y candidato. Los reflejos deben reproducir todos los estados, ingresos y decisiones de cada política.

## Métricas y aceptación
El agregador requiere **32 casos distintos**, sin duplicados ni faltantes y con dos políticas y espejos validados; genera Markdown y JSON con victorias, censuras, duración, acciones, ataques, compras, fase de primera diferencia y desglose por niebla y terreno.

**No exigir que el candidato gane más para aprobar CI.** La CI sirve para validar simulación, legalidad e interpretación; un resultado neutro o negativo es un hallazgo legítimo. Si la táctica solo cambia partidas de un escenario concreto, no se recomienda habilitarla. Antes de adoptar cualquier comportamiento, repetir bajo otras configuraciones de IA y mapas 24×18 y revisar pérdidas defensivas.

## Estado de implementación
- `tests/test_ai_initiative_counterfactual_v379.gd`: parámetro final opcional que fusiona únicamente los ajustes de IA de la prueba, sin alterar llamadas antiguas.
- `tests/test_ai_relay_pressure_official_holdout_v392.gd`: 32 comparaciones realistas con reflejos, invariantes preintervención y primeros cinco movimientos del respondedor.
- `tests/aggregate_ai_relay_pressure_official_v392.py`: agregado estricto por condiciones completas, con 32 muestras originales por política.
- `.github/workflows/ai-relay-pressure-official-v392.yml`: 16 trabajos de Godot 4.3 + consolidación = 17, con artefactos JSON y Markdown.

**Sin cambios a OpeningBalance, RelayControl, contabilidad, IA predeterminada, combate, movimiento, niebla, recursos, guardados, APK ni main. PR DRAFT apilada sobre v3.9.1 #600, sin merge.**
