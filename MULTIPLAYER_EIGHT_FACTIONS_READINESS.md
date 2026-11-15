# TARVOKA — Estado verificable para partidas de hasta ocho jugadores

Fecha: 15 de noviembre de 2026. Documento técnico vinculado al PR #330.
Objetivo a largo plazo: partidas por turnos con hasta ocho facciones humanas
o controladas por IA, incluso en mapas grandes y Android.

## Qué funciona actualmente

- El arte de las **ocho facciones** está definido y se visualiza en modelos
  G09, P06 y Cuartel General. Los escenarios de estrés 3D utilizan las
  ocho apariencias, pero NO son partidas con ocho bandos activos.
- `BattleSession.gd` dirige actualmente partidas de **dos** bandos (0 y 1).
  `BattleSession.start` valida la facción inicial dentro de `[0,1]`,
  `end_turn` cambia explícitamente a `1 - faction`.
- `UnitRoles.make_unit` y `BasicAI.step` validan solo 0 y 1.
- `Visibility` almacena observación, exploración y contactos de 0 y 1.
  La separación de información privada es crítica: la IA y el cliente
  jamás deben ver las unidades ocultas de un rival.
- `UrbanEconomy` conserva `credits=[..., ...]`, con dos presupuestos;
  `RelayControl` conserva `scores=[0,0]`.
- `SaveCodec` valida el estado actual para dos facciones, incluidos
  créditos, visibilidad, contactos y propietarios. No hay que cambiar
  silenciosamente el formato guardado o romper las partidas anteriores.
- `TouchBoard` asume la facción 0 humana y la 1 controlada por IA
  cuando `ai_enabled` está activado. Aún no es un cliente de red.

## Fundamento ya añadido sin romper las batallas existentes

`scripts/core/FactionTurnOrderV1.gd` es un planificador puro,
**no conectado todavía al motor de combate**. Valida listas de 2 a
8 facciones, recorre el orden, salta facciones eliminadas y detecta
si queda un único ejército vivo. No contiene sockets, lobbies,
acciones de red ni turnos simultáneos.

`tests/test_eight_faction_turn_order_v1.gd` comprueba las ocho
posiciones, rotación, eliminación, victoria y compatibilidad de la
detección de ganador con el motor clásico de dos facciones.

`scripts/core/FactionVisibilityV1.gd` crea vistas de niebla independientes
para listas de 2–8 facciones. Reutiliza la misma línea de visión que
`Visibility.gd` para no introducir diferencias en la versión de dos
jugadores. Su `observed_state` construye una lista explícita de campos
públicos: solo incluye unidades propias o visibles, oculta terreno sin
explorar, presupuestos y puntuaciones de rivales, y **nunca devuelve**
`contacts`, `explored` privados ni datos de autorización. Una economía
con el número de cuentas incoherente se omite por seguridad.

`tests/test_eight_faction_fog_privacy_v1.gd` prueba ocho puntos de
vista, recuento de exploración, ocultación de equipos lejanos,
desconocimiento de créditos/relés y equivalencia exacta de visión de
dos bandos con el motor actual. **No se ha conectado aún a partidas ni
a clientes de red**: la persistencia multiusuario deberá definirse
antes de activarlo.

## Plan de migración segura

1. **Estado de partida versionado**: introducir un campo explícito de
   facciones y orden; adaptar el decodificador a guardados v1,
   preservando 0/1 para partidas antiguas. Rechazar identificadores
   repetidos, listas vacías o estados corruptos.
2. **Operaciones de turno**: conectar el planificador cuando el estado
   declare el nuevo modo; preservar el comportamiento actual en v1.
3. **Visibilidad multiusuario**: crear exploración/contactos privados
   por facción, probados para 2, 4 y 8 participantes; garantizar
   que `observed_state` no filtre información de rivales.
4. **Economía y territorios**: ampliar presupuestos, propiedad de
   ciudades, fábricas, relés y victoria con pruebas de captura y
   desempate en rondas de 2 a 8 facciones.
5. **IA por facción**: separar decisiones legales de cada actor,
   revalidar reglas, suministros, contraataques y objetivos
   con o sin niebla; ningún plan puede consultar el estado privado
   de otra facción.
6. **Interfaz y perfiles visuales**: asociar los ocho escudos y colores
   oficiales a facciones activas y ofrecer un HUD compacto para
   móviles sin renderizar 80 modelos 3D en todas las casillas.
7. **Red determinista**: implementar sesiones autorizadas, validación
   del actor, reconexión, reenvío idempotente, comprobación de turnos,
   sincronización y recuperación; NO confiar en acciones arbitrarias
   enviadas por clientes.
8. **QA comercial**: partida completa de ocho participantes, turnos
   consecutivos, abandonos, CPU/IA, exportaciones, guardados,
   niebla privada, memoria y FPS en Android físico, más pruebas
   de conexiones malas y desconexiones.

## Presupuesto gráfico y pruebas integradas

- `tests/test_pathfinding_index_parity.gd`: 150 comparaciones contra
  el buscador de movimiento anterior, con casillas bloqueadas, tres
  dominios y tableros 10×8, 24×18 y 40×30. Los caminos conservan
  las mismas reglas; las lecturas de CPU se deben repetir por ruido CI.
- `tests/test_large_map_gameplay_stress.gd`: **40×30**, despliegues
  mixtos de **24 y 48 unidades**, dos bandos reales, IA, niebla,
  economía, relés, combustible/munición, guardado/carga y
  renderizado isométrico Godot.
- `tests/test_mixed_eight_faction_art_stress.gd`: arte 3D con
  **32/64 P06, ocho G09 y ocho HQ** con ocho pinturas distintas.
  No activa el motor de ocho jugadores.
- `tests/test_android_benchmark_suite_v2.gd`: protocolo de
  renderización de seis fases con evaluación provisional de FPS.
  No incluye carga de CPU, red ni temperatura del hardware.
- El informe de CPU de GitHub **no predice** automáticamente FPS de
  un teléfono. Los FPS Android reales siguen sujetos a pruebas
  físicas con la APK Estudio 3D.

## Condición para anunciar «multijugador hasta ocho jugadores»

No presentarlo como completo hasta que:
- se pueda crear, guardar, cargar y terminar una partida de 8 actores;
- las reglas y la niebla de guerra sean válidas para cada facción;
- el servidor rechace turnos falsificados y gestione reconexión;
- existan pruebas de rendimiento sostenido en Android físico.

**Estado actual:** ocho facciones visuales sí; ocho ejércitos/jugadores
activos en una misma partida todavía no.
