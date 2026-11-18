# TARVOKA v3.8.0 — Resultado verificado del arreglo de fuego coordinado

**18 noviembre 2026.** PR draft #583; resultados reales de GitHub Actions.

## Incidente corregido y verificación

- En v3.7.9 el escenario **24×18, seed 317, niebla desactivada** divergía en el fotograma 137 (fase 10, orden 6): un bando elegía el atacante `C`, el otro el nuevo `N1`, para atacar el mismo enemigo, tras 136 fotogramas idénticos.
- El planificador `CoordinatedFireV34.gd` analizaba hasta **8 objetivos**, preordenados por **ID literal**; una unidad `A` cambia a `X` al reflejar y una fabricada `N1` mantiene el ID, de modo que el filtro puede escoger amenazas distintas.
- En el candidato v3.8.0 se ordenan por coordenada X **local del atacante**, luego Y, rol e ID solo al final. El cupo de ocho, las puntuaciones y los límites de tiro son idénticos.
- [CI focalizada](https://github.com/edwinrodri12/Tarvoka/actions/runs/44262106963): **4/4 trabajos correctos**. Incluye nuevo test con 11 enemigos que produce el mismo subconjunto de 8 objetivos y una descarga coordinada equivalente por reflejo.
- [CI completa contrafactual](https://github.com/edwinrodri12/Tarvoka/actions/runs/44262106909): **17/17 trabajos correctos**, 16 shards más agregado, **64 partidas reales** (32 condiciones y sus 32 reflejos), sin nuevos estados divergentes. La matriz 24×18/317/sin niebla ahora pasa para los dos iniciadores.

## Balance observado con el candidato

| Mapa | Condiciones originales | Victorias iniciador | Victorias respondedor | Censuradas |
|---|---:|---:|---:|---:|
| 10×8 | 16 | 10 | 6 | 0 |
| 24×18 | 8 | 4 | 4 | 0 |
| 40×30 | 8 | 0 | 0 | 8 |
| **Total** | **32** | **14** | **10** | **8** |

Los 32 reflejos prueban simetría, **no duplican el denominador estadístico**.

### Observaciones medibles
- 10×8: 1322 acciones, 394 ataques, 240 compras a lo largo de 16 condiciones originales.
- 24×18: 952 acciones, 100 ataques, 126 compras a lo largo de 8 condiciones originales.
- 40×30: 568 acciones, **solo 2 ataques**, 92 compras a lo largo de 8 condiciones originales; los ocho casos concluyeron por el tope de **8 medios turnos**. Se registraron dos líderes de señal para el segundo jugador y seis empates de señal, pero ninguno constituye un ganador.
- De los 16 grupos con iniciativa intercambiada, 12 tienen **ambos** resultados con ganador; en los cuatro restantes los dos iniciadores terminan censurados por la ventana corta.

### Decisión de investigación
No implementar **ningún** ingreso, ataque, defensa, movimiento, producción ni orden adicional como compensación. No presentar las 24 partidas decisivas como un estudio suficiente para demostrar ausencia de ventaja estadística.

**Siguiente prioridad propuesta**: aumentar progresivamente las ventanas de observación del mapa 40×30 y medir tiempo de acercamiento, primeras capturas, primeros encuentros, uso de suministros y rendimiento de IA. El tope actual no permite evaluar desenlaces.

**Alcance del PR #583**: un solo archivo de producción modificado en rama experimental (`scripts/core/CoordinatedFireV34.gd`), tres archivos nuevos de contrato/CI/documentos y un disparador de matriz completa. Sin cambios en `main` ni APK; PR todavía draft y dependiente de los PR experimentales anteriores. No autoriza una fusión automática.
