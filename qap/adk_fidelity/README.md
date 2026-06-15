# adk_fidelity — Simulador local (adaptador Dialogflow CX)

**Capa:** adaptador CX — este módulo es **específico de Dialogflow CX**.

Reconstruye el agente en local usando [ADK (Agent Development Kit)](https://google.github.io/adk-docs/) de Google para simular conversaciones sin llamar a CX real. Actúa como cribador $0: propone y filtra candidatos antes de gastar llamadas a la plataforma.

```
Simulador local (ADK + LLM $0)  →  propone y criba  →  CX real  →  confirma solo los mejores
```

## Scripts

| Script | Qué hace |
|---|---|
| `petal_agent.py` | Reconstrucción del agente Petal en ADK (un sub-agente por playbook) |
| `petal_agent_multi.py` | Versión multi-agente con contexto compartido |
| `run_fidelity.py` | Harness: corre los TCs contra el simulador y compara con ground truth |
| `judge.py` | Juez LLM que evalúa las respuestas del simulador contra la rúbrica |
| `leak_gate.py` | Detecta fuga de ground truth en el prompt del juez |
| `static_leak_gate.py` | Versión estática del leak gate (sin llamada a LLM) |
| `smoke_test.py` | Test rápido de que el simulador arranca y responde |
| `kaggle/_gen_notebook.py` | Genera el notebook para correr el simulador en Kaggle (GPU cloud $0) |

## Relación con el sistema

Este módulo es el **adaptador CX** del cribador. En una arquitectura multi-plataforma, cada plataforma tendría su propio adaptador (`adapters/cx/`, `adapters/lex/`, etc.). La lógica de evaluación (rúbrica, juez, métricas) es agnóstica y vive en el núcleo de QAP.

## Estado

🟡 Funcional como screener — 64% acuerdo con CX, 0 falsos negativos. Fidelidad en optimización (palanca principal: refactor de playbooks a <5k tokens).
