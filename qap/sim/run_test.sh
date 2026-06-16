#!/usr/bin/env bash
# Lanza un run de fidelidad RESISTENTE a suspensión/interrupción.
#   · caffeinate -dimsu : sin idle/system/display/disk sleep (best-effort;
#                          si duerme por cierre de tapa, el proceso RESUME al despertar, no muere)
#   · nohup + disown    : detached → sobrevive a que se cierre la sesión/terminal
#   · python -u         : salida INCREMENTAL → si muere a mitad, los TCs completados
#                          quedan en el log (no se pierde todo como el run anterior)
#
# Uso:
#   ./run_test.sh --only TC-R01,TC-REG01         # subset (rápido, poca exposición)
#   ADK_RECON=multi ./run_test.sh --limit 12     # multi-agente, 12 TCs
#   ADK_RECON=multi ./run_test.sh                # multi-agente, los 51
#
# Monitor:  tail -f /tmp/fidelity_run.log   ·   grep "ADK=" /tmp/fidelity_run.log
cd "$(dirname "$0")/../.." || exit 1
LOG=/tmp/fidelity_run.log
: > "$LOG"
echo "MODO: ${ADK_RECON:-flat} | args: $* | inicio: $(date '+%H:%M:%S')" >> "$LOG"
nohup caffeinate -dimsu env ADK_RECON="${ADK_RECON:-flat}" OLLAMA_API_BASE=http://localhost:11434 \
  .venv-adk/bin/python -u qap/sim/run_fidelity.py "$@" >> "$LOG" 2>&1 &
PID=$!
disown
echo "✅ Run RESISTENTE lanzado (PID $PID, detached + caffeinate + incremental)."
echo "   Log: $LOG  ·  si muere a mitad, los TCs hechos siguen ahí."
