# TARVOKA · HAT-29 A01 · V14.3 · acabado y luz de inspección nocturna

## Motivo
Continuación de la V14.2.1 ya fusionada a main: ahora la prioridad es refinar superficies externas y revisar que la aeronave conserve una lectura clara de noche. Los ocho colores militares moderados y las animaciones previas no se alteran.

## Arte 3D real (sin imágenes simuladas)
Se amplía `AttackHelicopterFactionV14.gd` con piezas individuales bajo `A01V14_1_AccesosYJuntasTacticas`:
- Dos escudos térmicos metálicos sobre registros de motores y seis nervios de acabado en aluminio cepillado.
- Dos juntas finas inferiores de puerta, con neopreno muy mate.
- Dos marcos brillantes, dos sellos negros y cuatro cierres de acero sobre las compuertas existentes de cola.
- Los metales tienen metalicidad 0.60–0.71, rugosidad 0.39–0.48; las juntas son mates (metal ≤0.04, rugosidad 0.94). No se sustituyen materiales del casco ni superficies esmaltadas.
- Los nuevos elementos solo aparecen en el LOD alto de inspección del HAT-29; LOD10 de combate Android se conserva.

## Estudio 3D compartido
Se añade bajo **Unidades → HAT-29 → Detalles**:
1. `V14.3: acabado de motores` y `V14.3: sellos de cola` para enfocar nuevos relieves 3D.
2. `V14.3: activar noche táctica` / `volver a iluminación diurna`. Es la misma cámara y el mismo modelo, no un visor independiente.
3. La noche atenúa el sol del escenario, el relleno global y el cielo; añade una única luz azul suave de revisión sin sombras extra (WebGL).
4. Al regresar al día o seleccionar APC, G09, G11, G13 o edificios, restaura la iluminación original. Al cambiar facción del HAT-29, mantiene opcionalmente el modo noche sin tocar la pintura.

## Validación
- `tests/test_attack_helicopter_v14.gd`: verifica las ocho facciones, metal y goma diferenciados y el sistema de daño, rotor, dos misiles y LOD10.
- `tests/test_attack_helicopter_v9_studio.gd`: valida el botón nocturno real, reducción de intensidad, integridad del esmalte y restauración al cambiar de unidad.
- `tests/test_attack_helicopter_v14_capture.gd`: genera 25 cuadros anteriores más 3 tomas nocturnas nativas, total **28 PNG**.
- `.github/workflows/a01-v14-hat29-visual-qa.yml`: bloquea integración si no se generan los 28 cuadros y se aprueba la regresión de ocho ejércitos.

En ninguna fase se considera finalizado artísticamente el HAT-29 sin aprobación del usuario; este paquete es un avance verificable, no una aprobación definitiva.
