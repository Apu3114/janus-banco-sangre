# janus-banco-sangre — gemelo digital educativo (en desarrollo)

Repositorio **independiente** de `erlang-proyectos`: no lee la API de Erlang,
no escribe en DETS y no modifica la demo pública. La referencia de la tarea es
el [gemelo #44 del repositorio del curso](https://github.com/tectijuana/logicfun-proyectos/blob/main/proyectos/44-banco-de-sangre/gemelo/PROBLEMA.md)
y su [contexto técnico](https://github.com/tectijuana/logicfun-proyectos/blob/main/proyectos/44-banco-de-sangre/gemelo/CONTEXTO_AGENTES.md).
**No usar para decisiones clínicas.** Todos los nombres, unidades, horas y
lecturas son inventados para pruebas repetibles.

## Estado de la implementación

**Situaciones 1 y 2 (simulación parcial).** `hechos.pl` contiene
una fotografía fija de 30 unidades, 3 equipos y 6 pacientes. `reglas.pl`
implementa compatibilidad ABO/Rh **solo para glóbulos rojos**, distingue
disponible de reservada o vencida y expone `decide/3`, `situacion/3` y
`existencias/3`. La solicitud `s1` (A+) no tiene tipo exacto utilizable:
Prolog propone `u1` A− antes de `u2` O+ y `u3` O−. La explicación conserva
O− para `s2`, paciente O− confirmado. `s3` tiene expediente y pulsera
incompatibles: responde `no_se_sabe(tipo_paciente)`; no elige uno al azar.

En la **situación 2**, la urgencia `s2` permite proponer el reacomodo de `u4`
(reservada para `cir1`, pero vence en la hora 109 antes de su cirugía en 120)
con `u11` (repuesto libre y vigente hasta 125). La cirugía `cir2` tiene una
reserva que vence antes de comenzar y ningún repuesto en esta fotografía:
se marca **sin cobertura**. `u3` permanece como alternativa libre para `s2`.
Para `cir3`, terminada en la hora 95, se registró
explícitamente en la hora 97 que `u9` no fue utilizada. Con `ahora(100)` y un
**margen ficticio de liberación de 2 horas**, se propone liberarla. Ni esa
propuesta ni el reacomodo cambian los hechos: `u9` sigue fuera del inventario
utilizable hasta que exista un evento de liberación. Sin confirmación de no
uso, la ausencia de transfusión no autoriza liberar una reserva.

La prioridad de sustitución **es un supuesto educativo tomado del proyecto
Erlang previo**: primero tipo exacto, después menor versatilidad y, dentro de
un tipo, FEFO. Desempate por nombre del tipo e ID. Que otra solicitud O−
quede protegida es parte de esta fotografía, no una política médica.
`ahora(100)` es una hora del modelo, no el reloj del sistema. El valor de
caducidad se expresa en las mismas horas. La tabla de rangos de temperatura
está en los hechos como preparación para la situación 4, **todavía no se usa
para certificar que una unidad es segura**.

`servidor.pl` ofrece **API Prolog de solo lectura** y la página funcional
[`/app`](web/index.html). La interfaz muestra inventario y decisiones desde
la API, sin reglas de compatibilidad en JavaScript. Su diseño móvil inicial
está descrito en [`design/PROMPT_STITCH.md`](design/PROMPT_STITCH.md); **todavía
no es una exportación de Google Stitch**.

- `GET /api/inventario`: existencias utilizables de glóbulos rojos por tipo.
- `GET /api/decidir?id=s1`: propuestas en orden y explicación de cada una.
- `GET /api/decidir?id=s2`: reacomodo propuesto para la urgencia, sin escritura.
- `GET /api/reservas`: `cir1` reacomodable, `cir2` sin cobertura y `cir3`
  liberable **solo como propuesta**, con explicaciones redactadas en Prolog.

`grafico.pl` llama **desde Prolog** a `grafica_python.py` por Janus; Python
únicamente dibuja el inventario calculado por Prolog. La gráfica es opcional:
las pruebas lógicas y la API no dependen de Matplotlib.

## Ejecutar y probar

Requisitos: SWI-Prolog 9.2.7+ (para Janus) y, solo para el PNG, Python con
Matplotlib accesible a SWI-Prolog. Desde la raíz de este repositorio:

```bash
swipl -q -s tests/reglas_tests.pl -s tests/api_tests.pl -g run_tests -t halt
swipl -q -s reglas.pl
```

Ejemplos en el intérprete:

```prolog
?- decide(s1, Decision, Explicacion).
?- decide(s3, Decision, Explicacion).
?- decide(s2, Decision, Explicacion).
?- situacion(u4, utilizable, Evidencia). % falla: u4 está reservada
?- situacion(u9, reserva_liberable(cir3), Evidencia).
?- existencias(globulos, o_neg, Numero).
```

Interfaz local: `swipl -q -s servidor.pl`, después `?- iniciar(8064).` y abre
**`http://localhost:8064/app`** en tu navegador. La interfaz permite elegir
una de las tres solicitudes ficticias y explica la respuesta. También puedes
consultar `curl 'http://localhost:8064/api/decidir?id=s1'`. Para detener
el servidor: `?- detener.` **No publicarlo en Internet**: no tiene control
de acceso y no está listo como aplicación web final.

Gráfica opcional: instala Matplotlib en el Python elegido por Janus y corre
`swipl -q -s grafico.pl -g "graficar('salida/inventario_rojos.png')" -t halt`.
En Windows, la carpeta de `python3.dll` debe estar en `PATH`; con SWI-Prolog
10.0.2 y un venv de Windows puede aparecer una advertencia de Janus sobre
`lib/pythonX.Y/site-packages`. `grafico.pl` agrega la ruta Windows real. El
archivo `salida/` está ignorado por Git.

## Pendiente (no afirmar como terminado)

1. Situación 2: ampliar casos de reasignación conjunta y cambios efectivos
   documentados; hoy solo hay propuestas de lectura y una foto fija.
2. Situación 3: trazabilidad de donaciones positivas y destinos desconocidos.
3. Situación 4: exposición de unidades a lecturas fuera de rango y a huecos de datos.
4. Situación 5: accidente, asignación conjunta y nivel crítico **solo de unidades utilizables**.
5. Pruebas plunit por situación, tres valores (sí/no/no se sabe) para todas las
   decisiones, consultas contrafactuales («qué falta»), API restante y posible
   adaptación de la interfaz a un diseño de Stitch.

No existe sincronización con Erlang: esta fotografía no es el inventario vivo.
El gemelo **no decide sobre plasma ni plaquetas**, aunque consten
en la fotografía, porque sus reglas de compatibilidad difieren de las de rojos.
