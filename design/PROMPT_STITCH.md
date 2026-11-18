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
la propuesta de reacomodo. Reservar espacio para situaciones 3–5 (retiro de
donante, refrigeradores y accidente), sin presentarlas como implementadas.
Futuro: pestaña para trazabilidad donante → donación → unidad → paciente;
estados confirmado/no/no se sabe; consulta «qué tendría que cambiar».

Toda decisión, orden, umbral y compatibilidad llega desde la API SWI-Prolog;
JavaScript solo hace `fetch`, presenta datos y controla estados de carga/error.
No inventar respuestas en la maqueta. Los campos no disponibles se muestran
como «pendiente», no como datos reales. Incluir diseño desktop y móvil.

**Estado:** prompt preparado para Stitch; la interfaz HTML funcional inicial
se implementa a mano como prototipo hasta que el autor exporte el diseño de
Stitch. No afirmar que la maqueta ya se generó en Stitch.
