#!/usr/bin/env bash
set -euo pipefail

# Ejecutar en la VM, después de copiar nginx-gemelo.conf a este directorio.
# Sólo añade un include al server existente; no sustituye sus rutas Erlang.
site=/etc/nginx/sites-available/p44-banco-de-sangre
snippet=/etc/nginx/snippets/janus-banco-sangre.conf
include_line="    include ${snippet};"
backup=""

rollback() {
    if [[ $? -ne 0 && -n "$backup" ]]; then
        sudo cp -p "$backup" "$site"
        sudo nginx -t || true
        sudo systemctl reload nginx || true
    fi
}
trap rollback EXIT

test -f "$site"
sudo install -m 644 "$(dirname "$0")/nginx-gemelo.conf" "$snippet"

if ! sudo grep -Fq "$include_line" "$site"; then
    backup="${site}.bak-$(date +%Y%m%d%H%M%S)"
    sudo cp -p "$site" "$backup"
    sudo python3 - "$site" "$include_line" <<'PY'
import pathlib
import sys

site = pathlib.Path(sys.argv[1])
line = sys.argv[2]
original = site.read_text()
anchor = '    server_name _;\n'
if original.count(anchor) != 1:
    raise SystemExit('No se encontró una única línea server_name _;: revisar Nginx antes de editar')
site.write_text(original.replace(anchor, anchor + line + '\n', 1))
PY
fi

sudo nginx -t
sudo systemctl reload nginx
echo 'Ruta /gemelo/app habilitada; rutas previas sin cambios.'
