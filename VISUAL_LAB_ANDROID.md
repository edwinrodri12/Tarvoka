# TARVOKA — Laboratorio Visual (Android)

## Acceso
- En batalla, abrir **Opciones** → **Laboratorio visual · 32 unidades**.
- En la interfaz de mapa ampliado, pulsar el botón **Lab**.
- Cerrar con **Volver a la partida**. El laboratorio es independiente: no usa guardado automático, no ejecuta la IA y nunca modifica el turno, las unidades, HP, combustible, munición o progreso de la partida principal.

## Comparador de unidades
- Escoger **Atacante** y **Defensor** entre las **32 familias programadas**.
- Elegir dos colores de las **8 facciones aprobadas**. Solo cambia la apariencia, no quién posee la unidad ni sus características.
- Seleccionar terreno (llanura, bosque, carretera, montaña, agua), distancia de 1 a 5 y velocidad de 0.5×, 1× o 1.5×.
- La pantalla utiliza el tablero isométrico verdadero de TARVOKA, no una simulación dibujada fuera del motor, con zoom y un interruptor de mallas 3D / sprites provisionales.

## Controles de pruebas
- **Mover**: ejecuta un movimiento realmente permitido por la lógica, y reproduce su recorrido animado sin extender la movilidad.
- **Ataque real**: ejecuta el ataque y su contraataque cuando las reglas y las armas permiten el enfrentamiento. El resultado mostrado corresponde a la lógica verdadera de HP.
- **Disparo visual (sin daño)**: reproduce solo trayectoria, destello e impacto. Un ataque imposible entre dos unidades NO se convierte artificialmente en un ataque legal ni genera números de daño falsos.
- **Repetir**: restaura el escenario de práctica y repite la última acción.
- **Restablecer**: reinicia únicamente la prueba.
- **Examinar atacante/defensor en 3D**: abre el visor para clases que ya tienen modelos 3D. Las demás se señalan como sprites provisionales.

## Daños recibidos y destrucción del tanque principal
El selector **Etapa del vehículo** permite inspeccionar 5 fases acumulativas:
0. **Intacto**: pintura y piezas intactas.
1. **Impactos leves**: marcas de proyectiles y pintura desprendida.
2. **Daño moderado**: faldones desprendidos, placas abiertas y humo.
3. **Daño crítico**: banda de oruga cortada, eslabones sueltos, humo denso y torre inclinada.
4. **Destruido**: cañón afectado, torreta vencida, fragmentos, fuego y humo negro.

**Ver daños 3D** permite girar y acercar el vehículo en la fase elegida. **Recibir impacto** avanza una fase y reproduce una sacudida de impacto. Dentro del visor se encuentran controles **Recibir impacto**, **Destruir** y **Reparar / intacto**. Regresar a intacto restituye piezas y posiciones del modelo.

Estos cinco diseños son implementaciones de **geometría tridimensional real en Godot**, pero aún necesitan acabado artístico final, UV/texturas PBR creadas por artista y revisión de efectos en dispositivos físicos. Su selección es **solo visual**, no una falsificación de combate o de estadísticas.

**Sincronización con combate real (rama de revisión)**: cuando «Ataque real» afecta a un tanque, el selector de destrucción toma la etapa correspondiente a su HP autorizado: ≥90 % intacto, 65–89 % impactos leves, 40–64 % daño moderado, 1–39 % crítico y 0 HP destruido. Se prioriza el tanque defensor; si solo el atacante es tanque, se refleja el daño recibido en la respuesta. «Ver daños 3D» enseña el estado resultante, sin modificar HP. Durante las animaciones en el tablero los tanques 3D conservan las marcas y piezas rotas en el fotograma estacionado después del ataque; las capturas estáticas originales siguen neutrales hasta que hay una animación visible, para evitar renderizar constantemente modelos en móviles. La vista de unidades ocultas sigue protegida por niebla.

## Datos y arquitectura
- `VisualLab.gd`: pantalla separada con estado efímero de `BattleSession`.
- `Unit3DInspector.gd`: vista orbital 3D con controles táctiles y estados.
- `TankDamage3D.gd`: geometría incremental, separable y reversible sin alterar perfiles de combate.
- `tests/test_visual_laboratory.gd`, `tests/test_tank_damage_laboratory.gd`: reglas reales, UI, reversibilidad y protección de partidas.
- `tests/test_visual_lab_render.gd`, `tests/test_tank_damage_render.gd`: screenshots reales de OpenGL y cinco fases de destrucción.

Las pruebas se ejecutan en GitHub Actions. Los archivos `tarvoka_tank_5_destruction_stages.png`, `tarvoka_damage_inspector_android.png` y `tarvoka_visual_lab_android.png` se recopilan como evidencia visual cuando el pipeline Godot pasa. Android se compila como APK ARM64 experimental en el workflow correspondiente.
