# Propuesta de interfaz para Google Stitch · gemelo lógico #44

Diseña una interfaz **móvil primero**, en español, para un simulador académico
de banco de sangre (nunca para uso hospitalario). Debe ser distinta de la web
operativa en Erlang: este gemelo muestra **decisiones justificadas por Prolog**
sobre una fotografía ficticia de 30 unidades. Estilo sobrio: fondo blanco/gris
claro, vino profundo como color principal, verde azulado para unidades
utilizables, ámbar para dudas y rojo solo para alertas. Texto muy legible y
contraste AA. Evitar imágenes de pacientes reales.

Pantalla inicial funcional (situación 1): cabecera «Gemelo digital · banco de
sangre» + aviso «datos ficticios», barra con fecha/hora lógica fija (hora 100),
ocho tarjetas de inventario de glóbulos rojos por tipo con cantidad utilizable,
formulario para seleccionar solicitud ficticia (`s1`, `s2`, `s3`) y botón
«Preguntar al gemelo». Mostrar la propuesta preferida destacada, las otras
alternativas en orden y **una explicación legible para cada una**. Si hay dos
fuentes de tipo incompatibles, destacar «no se sabe»; no mostrar unidad
asignada. Aclarar que consultar no reserva ni entrega una unidad.

Sección funcional para la situación 2: mostrar `cir1` (reacomodo de la reserva
`u4` por `u11`), `cir2` (sin cobertura en esta fotografía) y `cir3` (propuesta
de liberar `u9` tras confirmación explícita de no uso y margen **ficticio** de
2 horas). Separar visualmente propuestas de acciones ejecutadas: ninguna
reserva se mueve, y `u9` no se suma al inventario. La urgencia `s2` explica
la propuesta de reacomodo.

Sección funcional para la situación 3: separar visualmente la fotografía base
en hora 100 de la vista prospectiva en hora 102. Mostrar cuatro grupos de
resultados de Prolog: unidades a retirar, receptores a avisar, unidades
transfundidas sin receptor conocido («no se sabe») y cirugías cuya reserva
se ve afectada. Mostrar la cadena donante → donación → unidad y el evento
que justifica cada respuesta. No presentar la propuesta como un retiro real.
Incluir secciones funcionales para situaciones 4 y 5, **sin mezclarlas con la
foto base**: falla con exposición confirmada, duda por hueco de lecturas mayor
de 2 horas y unidades sin exposición detectada bajo los supuestos declarados;
equipo de respaldo hipotético del subescenario. Accidente contrafactual en
hora 94: 2 O− consumidas, 1 restante, asignación única a `s2`, `s4` sin
cobertura, `s3` con fuentes de tipo contradictorias y alerta de nivel crítico.
Cada tarjeta debe mostrar evidencia y explicación enviada por Prolog. Ninguna
decisión se ejecuta; no mezclar los relojes 94, 100 y 102. Mostrar claramente
que la validación médica y la interfaz exportada de Stitch **no existen** aún.
Futuro: pestaña para trazabilidad donante → donación → unidad → paciente;
estados confirmado/no/no se sabe; consulta «qué tendría que cambiar».

Toda decisión, orden, umbral y compatibilidad llega desde la API SWI-Prolog;
JavaScript solo hace `fetch`, presenta datos y controla estados de carga/error.
No inventar respuestas en la maqueta. Los campos no disponibles se muestran
como «pendiente», no como datos reales. Incluir diseño desktop y móvil.

## Resultado del diseño generado

Diseño generado con la API de Google Stitch (MCP `generate_screen_from_text`,
proyecto `9032971181814234071`, pantalla `869263c325b6476797b7d0044ab1d904`,
tamaño exportado 2560×5076, desktop).

- Captura del diseño en [`design/stitch/captura.png`](stitch/captura.png).
- HTML exportado en [`design/stitch/export.html`](stitch/export.html).

### Cambios posteriores al diseño

- La página funcional [`web/index.html`](../web/index.html) se **reescribió**
  con un lenguaje visual de ese diseño (cabecera granate, acento turquesa para
  decisiones, ámbar para dudas, serif para títulos, mono para datos; aviso
  académico sticky; hero con `decide/3`; panel de inventario de 8 tipos; secciones
  independientes por situación) y se **adaptó** para consumir la API Prolog.
- La adaptación **no** incorporó las cifras de la maqueta: el HTML lee los
  resultados de `/api/inventario`, `/api/decidir`, `/api/reservas`,
  `/api/incidente`, `/api/falla` y `/api/accidente` y nunca replica reglas en
  JavaScript.
- Ajustes posteriores a la revisión visual: columna de alternativas alineada y
  tarjetas de reparto con etiquetas legibles en español.

**Estado:** diseño generado en Stitch y **integrado** en la interfaz funcional;
las decisiones y datos siempre provienen de Prolog. No afirmar que la maqueta
ya se generó en Stitch.

## Cómo volver a generar (sin API key nueva)

```bash
npm exec --yes --package=@google/stitch -- stitch generate screen \
  --schema '{"resource":"screen","project":"9032971181814234071","body":{"prompt": "...","deviceType":"DESKTOP"}}'
```

Con tu clave propia (`STITCH_API_KEY` o `--api-key`), con tu cuenta propietaria
del proyecto privado. Documentar aquí solo el prompt, no la clave.
