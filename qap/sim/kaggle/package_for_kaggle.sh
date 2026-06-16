#!/usr/bin/env bash
# Empaqueta el MÍNIMO necesario para correr el harness de fidelidad en Kaggle.
# Preserva la estructura del repo (definitions/ + qap/) para que el ROOT que
# run_fidelity.py calcula con __file__ resuelva igual que en local.
#
# Salida: qap/sim/kaggle/build/petal-fidelity.zip  → subir como Kaggle Dataset.
# Coste: €0. No incluye secretos (el path Ollama no usa GEMINI key; va un .env dummy).
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"   # ruta ABSOLUTA al dir del script
cd "$SCRIPT_DIR/../../.."                      # raíz del repo
OUT="qap/sim/kaggle/build/petal-fidelity"
rm -rf "$OUT"; mkdir -p "$OUT"

# --- definiciones (playbooks + examples) ---
mkdir -p "$OUT/definitions"
cp -R definitions/playbooks "$OUT/definitions/playbooks"
cp -R definitions/examples  "$OUT/definitions/examples"

# --- harness ---
mkdir -p "$OUT/qap/sim"
cp qap/petal_qa.py "$OUT/qap/petal_qa.py"
cp qap/sim/petal_agent.py        "$OUT/qap/sim/"
cp qap/sim/petal_agent_multi.py  "$OUT/qap/sim/"
cp qap/sim/static_leak_gate.py          "$OUT/qap/sim/"   # pre-gate anti-fuga (run_fidelity lo importa)
cp qap/sim/run_fidelity.py       "$OUT/qap/sim/"
cp qap/sim/smoke_test.py         "$OUT/qap/sim/" 2>/dev/null || true

# --- .env dummy (run_fidelity.py:17 abre .env; Ollama NO usa la key) ---
echo "GEMINI_API_KEY=unused-on-kaggle" > "$OUT/.env"

# --- zip ---
cd "$SCRIPT_DIR/build"
rm -f petal-fidelity.zip
zip -qr petal-fidelity.zip petal-fidelity
echo "✅ Bundle listo: qap/sim/kaggle/build/petal-fidelity.zip"
echo "   $(find petal-fidelity -name '*.yaml' | wc -l | tr -d ' ') yaml + harness, $(du -sh petal-fidelity.zip | cut -f1)"
echo "   → Súbelo a Kaggle como Dataset (New Dataset → upload zip)."
