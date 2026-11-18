"""Presentación de existencias calculadas en SWI-Prolog, sin reglas de banco."""
from pathlib import Path


def guardar(filas, ruta):
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    if len(filas) != 8 or any(int(n) < 0 for _, n in filas):
        raise ValueError("Se requieren los ocho conteos de rojos de Prolog")
    tipos = [str(t) for t, _ in filas]
    valores = [int(n) for _, n in filas]
    fig, ax = plt.subplots(figsize=(9, 4))
    barras = ax.bar(tipos, valores, color="#0d9488")
    ax.bar_label(barras, padding=3)
    ax.set_ylim(0, max(valores) + 1)
    ax.set_ylabel("Unidades utilizables")
    ax.set_title("Fotografía ficticia · glóbulos rojos · situación 1")
    ax.tick_params(axis="x", rotation=25)
    fig.tight_layout()
    destino = Path(ruta)
    destino.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(destino, dpi=140)
    plt.close(fig)
    return str(destino)
