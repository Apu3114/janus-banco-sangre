# janus-banco-sangre — gemelo digital educativo

Repositorio **independiente** de `erlang-proyectos`: no lee la API de Erlang,
no escribe en DETS y no modifica la demo pública. La referencia de la tarea es
el [gemelo #44 del repositorio del curso](https://github.com/tectijuana/logicfun-proyectos/blob/main/proyectos/44-banco-de-sangre/gemelo/PROBLEMA.md)
y su [contexto técnico](https://github.com/tectijuana/logicfun-proyectos/blob/main/proyectos/44-banco-de-sangre/gemelo/CONTEXTO_AGENTES.md).
**No usar para decisiones clínicas.** Todos los nombres, unidades, horas y
lecturas son inventados para pruebas repetibles.

**Relación con el repositorio del curso:** `logicfun-proyectos` aporta las cinco
situaciones y los criterios de entrega de `gemelo/PROBLEMA.md`; este repositorio
es la implementación independiente, no una copia ni un cambio al original.
En el proyecto previo, **Erlang** simula las operaciones y transiciones del
inventario; aquí **Prolog** relaciona hechos, explica propuestas y preserva
la incertidumbre sin ejecutar entregas. La página solo presenta esas respuestas.

## Estado de la implementación

**Cinco situaciones consultables (simulación parcial).** `hechos.pl` contiene
una fotografía fija de 30 unidades, 3 equipos y 6 pacientes. `reglas.pl`
implementa compatibilidad ABO/Rh **solo para glóbulos rojos**, distingue
disponible de reservada o vencida y expone `decide/3`, `situacion/3` y
`existencias/3`. La solicitud `s1` (A+) no tiene tipo exacto utilizable:
Prolog propone `u1` A− antes de `u2` O+, `u3` O− y `u6` O−. La explicación conserva
O− para `s2`, paciente O− confirmado. `s3` tiene expediente y pulsera
incompatibles: responde `no_se_sabe(tipo_paciente)`; no elige uno al azar.

En la **situación 2**, la urgencia `s2` permite proponer el reacomodo de `u4`
(reservada para `cir1`, pero vence en la hora 109 antes de su cirugía en 120)
con `u11` (repuesto libre y vigente hasta 125). La cirugía `cir2` tiene una
reserva que vence antes de comenzar y ningún repuesto en esta fotografía:
se marca **sin cobertura**. `u3` y `u6` permanecen como alternativas libres para `s2`.
Para `cir3`, terminada en la hora 95, se registró
explícitamente en la hora 97 que `u9` no fue utilizada. Con `ahora(100)` y un
**margen ficticio de liberación de 2 horas**, se propone liberarla. Ni esa
propuesta ni el reacomodo cambian los hechos: `u9` sigue fuera del inventario
utilizable hasta que exista un evento de liberación. Sin confirmación de no
uso, la ausencia de transfusión no autoriza liberar una reserva.

La **situación 3** usa una vista prospectiva ficticia en la **hora 102**:
pruebas positivas tardías de `d1` y `d12` en la hora 101. `d1` produjo `u1`
(libre), `u13` (plasma reservado para `cir4`) y `u22` (plaquetas transfundidas
a `p5`): se propone retirar las dos primeras y avisar al receptor de la última.
`u12` de `d12` figura como transfundida, pero **no existe registro de receptor**;
la respuesta es «no se sabe», no «no se transfundió». `cir4` pierde su reserva;
no se afirma que esté sin alternativas, pues aún no se implementa la
compatibilidad ni la búsqueda de reemplazos de plasma. La trazabilidad se
limita a las donaciones con prueba positiva documentada: **no** se extrapola
a otras donaciones del mismo donante. El incidente no ejecuta retiros ni avisos
y no altera las decisiones del inventario base en hora 100.

La **situación 4** es un escenario separado entre las horas 92 y 102. Un
**equipo de respaldo hipotético adicional** (`e_respaldo`) permite mostrar un
traslado seguro sin alterar los tres equipos de la fotografía base. Hay
lecturas fuera del rango didáctico de glóbulos en `e_rojos` en 94 y 96;
una lectura normal en 98 **no borra** la exposición. El hueco 98–102 supera
el **máximo educativo de 2 horas entre lecturas**: una unidad que entra en
99 responde `no_se_sabe` y debe evaluarse antes de usarla. Bajo el supuesto
de muestreo discreto y tramos documentados, `u2` (trasladada en 93) y `u25`
(plaquetas en su propio rango) figuran `salvada` **en este modelo**, no como
certificación de seguridad clínica. No se inventa una duración clínica
«tolerable» fuera de rango: cualquier muestra fuera del rango implica
exposición y retiro propuesto. El equipo extra es una variación explícita
del escenario, no una afirmación del enunciado de tres equipos.

La **situación 5** es otra foto contrafactual en hora 94, anterior a la reserva
de `u4`: **2 O− consumidas entre 30 unidades** (escala aproximada de 20 entre
300). `u4` y `u6` se descuentan como consumo ficticio; queda `u3` utilizable.
El umbral **educativo** de nivel crítico O− es *menos de 2 utilizables* antes
del reparto. En el reparto conjunto, `s2` (O− confirmado) tiene prioridad y
recibe `u3`; `s4` (sin tipificar) queda sin cobertura y `s3` (expediente y
pulsera incompatibles) responde `no_se_sabe`, sin fingir un tipo confirmado.
El desempate es la prioridad O− confirmado → sin tipificar, luego ID de
solicitud; las unidades se ordenan por caducidad e ID y no se duplican.
Es un supuesto de simulación, **no una política clínica**. No se mezclan las
horas 94, 100 y 102 como si fueran una sola foto.

La prioridad de sustitución **es un supuesto educativo tomado del proyecto
Erlang previo**: primero tipo exacto, después menor versatilidad y, dentro de
un tipo, FEFO. Desempate por nombre del tipo e ID. Que otra solicitud O−
quede protegida es parte de esta fotografía, no una política médica.
`ahora(100)` es una hora del modelo, no el reloj del sistema. El valor de
caducidad se expresa en las mismas horas. Los rangos ficticios de temperatura
se usan **solo** en la consulta aislada de la situación 4: no certifican
inventario utilizable en la situación 1 ni sustituyen una evaluación real.

`servidor.pl` ofrece **API Prolog de solo lectura** y la página funcional
[`/app`](web/index.html). La interfaz muestra inventario y decisiones desde
la API, sin reglas de compatibilidad en JavaScript.

El diseño base se **generó realmente en Google Stitch** y se adaptó a la
página funcional: proyecto privado
[`9032971181814234071`](https://stitch.google.com/projects/9032971181814234071),
pantalla `869263c325b6476797b7d0044ab1d904`. La captura y el HTML exportado
están en [`design/stitch/`](design/stitch/), con las notas de
[`design/PROMPT_STITCH.md`](design/PROMPT_STITCH.md). La adaptación conserva
los tokens del diseño (granate `#631c33`, turquesa `#0d9488`, ámbar `#f59e0b`,
canvas `#f4f6f7`, serif Newsreader, mono Fira Code), pero **no copia las cifras
de la maqueta**: todos los datos, órdenes y explicaciones vienen de Prolog.

- `GET /api/inventario`: hora lógica y existencias utilizables de glóbulos
  rojos por tipo.
- `GET /api/decidir?id=s1`: propuestas en orden y explicación de cada una.
- `GET /api/decidir?id=s2`: reacomodo propuesto para la urgencia, sin escritura.
- `GET /api/reservas`: `cir1` reacomodable, `cir2` sin cobertura y `cir3`
  liberable **solo como propuesta**, con explicaciones redactadas en Prolog.
- `GET /api/incidente`: listas de retirar, avisar, no se sabe y reservas
  afectadas en la hora 102, con cadena de evidencia y texto generado en Prolog.
- `GET /api/falla`: exposición, dudas por huecos y tramos sin exposición
  detectada; incluye evidencia y el supuesto del equipo auxiliar.
- `GET /api/accidente`: consumo, reparto sin duplicación y alerta crítica.

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
?- incidente(no_se_sabe, Unidad, Evidencia).
?- falla(u4, Estado, Evidencia).
?- accidente(Decision, Evidencia).
?- existencias(globulos, o_neg, Numero).
```

Interfaz local: `swipl -q -s servidor.pl`, después `?- iniciar(8064).` y abre
**`http://localhost:8064/app`** en tu navegador. La interfaz permite elegir
una de las tres solicitudes de la foto base y consultar los otros escenarios
en secciones independientes; cada tarjeta incluye la explicación y la
evidencia enviadas por Prolog. También puedes
consultar `curl 'http://localhost:8064/api/decidir?id=s1'`. Para detener
el servidor: `?- detener.` **No publicarlo en Internet**: no tiene control
de acceso y no está listo como aplicación web final.

### Acceder desde otra Windows a la VM

En la VM se instaló el servicio independiente
[`deploy/janus-banco-sangre.service`](deploy/janus-banco-sangre.service):
arranca automáticamente al encenderla y mantiene Prolog en
`127.0.0.1:8064`. No requiere instalar Prolog en Windows ni modificar el
servicio Erlang. Para comprobarlo en la VM:

```bash
sudo systemctl status janus-banco-sangre.service
curl -I http://127.0.0.1:8064/app
```

En **cada Windows desde donde quieras acceder**, necesitas OpenSSH y una
clave SSH con permiso para entrar a la VM. En PowerShell deja esta ventana
abierta (sustituye la ruta de la clave y la IP si la VM cambió de dirección):

```powershell
ssh -o ExitOnForwardFailure=yes -i "C:\ruta\a\tu_clave" -N -L 127.0.0.1:18064:127.0.0.1:8064 ubuntu@52.207.235.1
```

Abre **<http://127.0.0.1:18064/app>** en el navegador de *esa misma Windows*;
`Ctrl+C` cierra el túnel. Cada equipo necesita su propio túnel. La IP pública
de AWS Academy puede cambiar al reiniciar: consulta la nueva en EC2 y reemplázala
en el comando. SSH (puerto 22) debe ser accesible desde ese equipo; **no abras
8064 a Internet** ni compartas claves privadas. Si necesitas una URL pública
sin SSH, primero hay que agregar autenticación y TLS sin afectar la demo Erlang.

Gráfica opcional: instala Matplotlib en el Python elegido por Janus y corre
`swipl -q -s grafico.pl -g "graficar('salida/inventario_rojos.png')" -t halt`.
En Windows, la carpeta de `python3.dll` debe estar en `PATH`; con SWI-Prolog
10.0.2 y un venv de Windows puede aparecer una advertencia de Janus sobre
`lib/pythonX.Y/site-packages`. `grafico.pl` agrega la ruta Windows real. El
archivo `salida/` está ignorado por Git.

## Pendiente (no afirmar como terminado)

1. Situación 2: ampliar casos de reasignación conjunta y cambios efectivos
   documentados; hoy solo hay propuestas de lectura y una foto fija.
2. Situación 3: ampliar la trazabilidad a múltiples donaciones y verificar
   reemplazos de componentes distintos de glóbulos rojos.
3. Situación 4: ampliar a traslados y lecturas de todo el inventario; los
   cinco ejemplos actuales son un subescenario explícito.
4. Situación 5: ampliar a reparto de todos los tipos y a demanda variable;
   este ejercicio decide un único conflicto por O−.
5. Ampliar las pruebas plunit a todos los tipos y a consultas contrafactuales
   («qué falta»); hoy hay 44 pruebas, incluidas las cinco situaciones y la API.
6. Validación médica real: el umbral crítico, el margen de liberación y los
   rangos de temperatura son supuestos educativos, no protocolos.

No existe sincronización con Erlang: esta fotografía no es el inventario vivo.
El gemelo **no decide sobre plasma ni plaquetas**, aunque consten
en la fotografía, porque sus reglas de compatibilidad difieren de las de rojos.
