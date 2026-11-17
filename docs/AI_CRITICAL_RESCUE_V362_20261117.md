# TARVOKA — IA v3.6.2: rescate crítico sin retirada en masa
**17 noviembre 2026 | Sólo experimental | NO integrar a main/APK**

## Resultado confirmado anterior
El [primer A/B v3.5 versus v3.6](https://github.com/edwinrodri12/Tarvoka/actions/runs/44167616688) produjo 22 victorias para v3.5 y 10 para v3.6, con 8 versus 84 retiradas. El [A/B v3.5 versus v3.6.1](https://github.com/edwinrodri12/Tarvoka/actions/runs/44170419096) finalizó 19–13, todavía con 7 versus 70 retiradas, 60 versus 51 capturas, y casi idéntica supervivencia inicial (87 versus 88 tropas acumuladas). Aunque v3.6.1 ganó más que v3.6 en baterías independientes, el resultado no justifica integrar su conducta a la APK.

## Hipótesis nueva
La estimación de DOS ataques del rival en el próximo turno es una posibilidad conservadora, no necesariamente una secuencia obligatoria. Retirar unidades sanas para impedir esa suma hipotética sacrifica asalto y ciudades sin mejorar claramente el número de tropas supervivientes.

Se añade una capa **opt-in de laboratorio**, `_ab_critical_rescue_v362=true` (junto a la disciplina v3.6.1), con reglas verificables:

1. **Solo amenaza individual letal:** exige que UNO de los enemigos visibles pueda infligir por sí mismo el HP restante; no suma dos supuestos ataques para forzar retirada.
2. **Solo unidades de alta prioridad:** artillería y especialistas de apoyo (logística, reconocimiento, misiles, guerra electrónica), soldados gravemente heridos (HP hasta 4), o capturadores disputando ciudades con HP de 6 o menos.
3. **No abandonar un disparo útil:** si la unidad puede infligir inmediatamente al menos 3 daños y la mitad de los HP del blanco, sobrevivir al contraataque legal y usar una orden disponible, conserva la oportunidad de combatir.
4. **Repliegue de poca distancia:** busca primero destinos cercanos con cobertura y menor gasto de movimiento, con evaluación posterior de supervivencia real contra ataques observables.
5. Todos los movimientos siguen siendo únicos y legales mediante `BattleSession.move`. La información se deriva del `Visibility.observed_state`; no se tocan ni estadísticas, ni visión, ni recursos de las unidades ni poderes de comandantes.

## Validación y límites
- `tests/test_ai_anticipation_critical_v362.gd`: artillería amenazada, capturador herido, frente sano con amenaza combinada hipotética e invariancia ante recursos privados.
- `tests/test_ai_v35_v362_full_matches.gd`: 32 partidas A/B con mismo esquema reproducible: mapas 0/2, niebla sí/no, niveles 10/12, iniciativa y asignación de versiones cruzadas.
- Workflow `.github/workflows/ai-v35-v362-duels.yml`, resultados en logs JSON `AB362_MATCH`, resumen agregado exacto `AB362_ALL`, archivos Markdown/JSON.
- Sin pruebas humanas ni rendimiento Android físico. Si 3.6.2 no mejora victorias/capturas o protección útil, no se promociona. El comparador no cambia ningún dato de la APK existente.

Esta rama hereda v3.6 y v3.6.1 **sin activar las nuevas opciones por defecto** y no se debe fusionar hasta validar contra v3.5.
