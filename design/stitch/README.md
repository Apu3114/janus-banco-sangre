# Diseño de Google Stitch — Janus · Gemelo digital del banco de sangre #44

Referencia del diseño generado en Google Stitch para el gemelo #44.

- Proyecto: <https://stitch.google.com/projects/9032971181814234071> (privado,
  propietario `l23211951@tectijuana.edu.mx`).
- Pantalla: `869263c325b6476797b7d0044ab1d904` · «Janus · Gemelo digital del
  banco de sangre #44» · 2560×5076 px · desktop.
- Captura: [`captura.png`](captura.png) (screenshot descargado del diseño).
- Exportación HTML: [`export.html`](export.html).

## Contenido de la pantalla generada

Pantalla de escritorio con los cinco bloques funcionales descritos en
[`../PROMPT_STITCH.md`](../PROMPT_STITCH.md):

1. Hero «Preguntar al gemelo» con selector de solicitud ficticia y botón
   «Consultar decisión».
2. Panel de inventario de 8 tipos ABO/Rh con conteos utilizables.
3. Sección de reservas y cirugías (situación 2) con propuestas de solo lectura.
4. Sección de prueba positiva tardía (situación 3) con trazabilidad y grupos de
   respuesta.
5. Sección de falla de refrigeración (situación 4) con equipo de respaldo
   hipotético y huecos de lecturas.
6. Sección de accidente (situación 5) con consumo ficticio y reparto.

## Archivos generados

| Archivo | Contenido |
| --- | --- |
| `captura.png` | Captura del canvas de Stitch (1 pantalla única). |
| `export.html` | Código HTML/CSS de la pantalla exportada por Stitch. |

## Cómo obtenerlos (con clave propia)

1. Abrir el proyecto en Stitch: <https://stitch.google.com/projects/9032971181814234071>
   con la cuenta propietaria.
2. Generar la pantalla con el MCP `generate_screen_from_text` usando el prompt
   del [`../PROMPT_STITCH.md`](../PROMPT_STITCH.md) (o ajustar título/dispositivo).
3. Descargar el archivo HTML y la captura (`download_file`).

La clave API de Stitch es secreta: se genera en la consola de Google Cloud con
el servicio Stitch y solo debe usarse en el flujo de generación.

## Estado del diseño en el repositorio

- **Generado**: sí, vía Stitch MCP (sin duplicados; una sola pantalla).
- **Integrado**: sí, adaptación funcional del HTML exportado a la API Prolog en
  [`web/index.html`](../../web/index.html).
- **Tokens**: granate `#631c33`, turquesa `#0d9488`, ámbar `#f59e0b`,
  canvas `#f4f6f7`, serif Newsreader + mono Fira Code, Tailwind CDN para la
  generación.
