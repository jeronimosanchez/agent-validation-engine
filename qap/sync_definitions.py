#!/usr/bin/env python3
"""qap/sync_definitions.py — Puente temporal: copia definitions/ desde ACT a QAP.

SOLUCIÓN INTERINA. La definitiva es un repo único (`petal-definitions`) consumido
como submodule por ACT y QAP — ver el brief de migración en
`cx-automation-template/docs/migracion_definitions_submodule.md`. Mientras eso no
exista, este script mantiene la copia de QAP igual a la de ACT (la fuente de verdad).

Qué hace:
  - Lee definitions/ de ACT (read-only sobre ACT).
  - Sobrescribe definitions/ de QAP con esa copia.
  - No toca CX, IAM ni hace ningún push. Solo copia ficheros locales.

Uso:
  python qap/sync_definitions.py                 # ACT en ~/cx-automation-template (default)
  python qap/sync_definitions.py --act /ruta/act # otra ubicación de ACT
  python qap/sync_definitions.py --dry-run       # muestra qué copiaría, sin tocar nada
"""
import argparse
import shutil
import sys
from pathlib import Path

DEFAULT_ACT = Path.home() / "cx-automation-template"
QAP_ROOT = Path(__file__).resolve().parent.parent  # repo raíz de QAP


def main():
    ap = argparse.ArgumentParser(description="Sincroniza definitions/ desde ACT a QAP (puente temporal).")
    ap.add_argument("--act", type=Path, default=DEFAULT_ACT,
                    help=f"Ruta al repo ACT (default: {DEFAULT_ACT})")
    ap.add_argument("--dry-run", action="store_true",
                    help="Muestra qué se copiaría sin escribir nada.")
    args = ap.parse_args()

    src = args.act / "definitions"
    dst = QAP_ROOT / "definitions"

    if not src.is_dir():
        print(f"ERROR: no existe definitions/ en ACT: {src}", file=sys.stderr)
        print("       Pasa la ruta correcta con --act /ruta/a/cx-automation-template", file=sys.stderr)
        sys.exit(1)

    n_files = sum(1 for _ in src.rglob("*") if _.is_file())
    print(f"Fuente (ACT): {src}  ({n_files} ficheros)")
    print(f"Destino (QAP): {dst}")

    if args.dry_run:
        print("\n[dry-run] No se ha copiado nada. Quita --dry-run para sincronizar.")
        return

    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    print(f"\n✅ Sincronizado: definitions/ de QAP ahora es idéntico al de ACT.")


if __name__ == "__main__":
    main()
