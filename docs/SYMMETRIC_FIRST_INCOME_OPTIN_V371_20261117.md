# TARVOKA — implementación experimental opt-in de ingresos iniciales simétricos (v3.7.1)

**Estado: PR en borrador, no fusionado.** El código jugable y la UI existentes conservan su comportamiento cuando no se activa expresamente la nueva opción.

## Evidencia que motiva la implementación

El usuario señaló que el segundo jugador cobra ingresos de su ciudad al empezar su primer turno, y el primero no. El [estudio v3.7.0 de 256 partidas de Godot](https://github.com/edwinrodri12/Tarvoka/actions/runs/44226290001) confirmó:

- Ambas facciones clásicas empiezan con **300 créditos**, pero el segundo recibe **100** al comenzar su primera fase y entonces tiene 400.
- Quitar **solo ese primer pago** y conservar todos los siguientes no cambió el ganador de ninguna de las **128 parejas de partidas** (256 partidas nuevas). Hubo cambios de compra en 4 parejas y ningún cambio de capturas del segundo por esa variante.
- La muestra investigó cuatro mapas pequeños, dos niveles y dos políticas de IA. No establece cuál regla resulta más justa con humanos ni cuál explica el desequilibrio de iniciativa.

La propuesta es razonable como **preferencia de diseño económico** aunque no haya demostrado cambiar el balance global.

## Implementación de producción en rama aislada, desactivada por defecto

Se añade un argumento **opcional al final** de `BattleSession.start`:
`symmetric_first_income: bool = false`.

Cuando es `true` y la sesión tiene economía, el estado de esa nueva partida guarda `economy.symmetric_first_income = true`. En `UrbanEconomy.begin_turn`, **únicamente si `economy.turn == 1`** (primera transición tras el turno inicial), omite el pago a la facción que acaba de recibir el turno. En todas las demás fases aplica el cálculo de ingresos existente, sin cambios.

- Clásico: ambos tienen 300 créditos al comenzar su primer turno; después reciben sus ciudades con normalidad.
- Economía moderna: ambos tienen 2,500 créditos al comenzar su primer turno; el pago que se evita inicialmente es 250 por ciudad propia.
- Las compras, daños, rutas, control de relés, clima y suministros no cambian.
- Las llamadas existentes a `BattleSession.start` omiten el último argumento y mantienen exactamente el comportamiento histórico.
- El campo opcional se valida como booleano; se conserva en `SaveCodec` sin cambiar versión ni romper partidas anteriores. El campo ausente sigue significando comportamiento clásico.

La opción **no se expone todavía en los menús de juego**, por lo que no se ha cambiado la economía por defecto ni se ha incorporado a una APK oficial. Se puede activar explícitamente mediante la API al crear una partida nueva, solo en esta rama experimental.

## Pruebas

`tests/test_symmetric_first_income_optin_v371.gd` incluye **32 configuraciones**: cuatro mapas, niebla sí/no, ambos bandos como iniciadores y modo de economía clásica/moderna. En cada caso:

- Verifica que `BattleSession.start` clásico y `symmetric_first_income=false` sean idénticos.
- Comprueba que la nueva opción conserva unidades, terreno y relés, y que ambos bandos parten con el mismo crédito.
- Ejecuta **tres transiciones de turno reales**: primera respuesta sin ingreso adicional, primer turno de regreso con ingreso normal y segunda respuesta con ingreso normal.
- Verifica guardado/carga antes y después, así como rechazo de un campo de tipo inválido.
- Reejecuta el contrato existente `test_save_codec.gd` para compatibilidad antigua.

## Puerta de decisión

Si CI confirma la equivalencia con el experimento y la compatibilidad, la siguiente fase es decidir **si cambiar el comportamiento por defecto** o ofrecer una opción de partida nueva en los menús, además de validar humanos, escenarios modernos, mapas grandes y Android. Esto requiere decisión explícita de producto, no una fusión automática.

No fusionar directamente con `main`; esta rama se basa en la cadena de PR experimentales v3.7.0.
