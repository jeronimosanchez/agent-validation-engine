# agent-validation-engine

**Línea QAP** del sistema de automatización CD — un **método + motor para validar agentes conversacionales** de forma barata, antes de pagar la plataforma real.

> Primera instancia: **Petal** (agente de floristería en Dialogflow CX).
> El método es **agnóstico de plataforma**; el adaptador (Dialogflow CX / ADK) es una pieza intercambiable.

---

## El problema

Validar y optimizar un agente conversacional es caro: cada prueba contra la plataforma real (Dialogflow CX, etc.) cuesta dinero por petición. Iterar sobre decenas de playbooks × cientos de variables a ese precio es inviable.

## La idea — el embudo

```
Cribador LOCAL ($0)  →  propone y criba candidatos    →  Plataforma real  →  confirma solo los finalistas
  · reconstrucción del agente en ADK + LLM local
  · llama al webhook real, aplica la misma rúbrica
  → barato e ilimitado; no necesita fidelidad perfecta (solo ordenar bien)
```

El cribador no decide: **propone y filtra gratis**; la plataforma real **confirma barato** solo los mejores.

## El método de validación (¿es de fiar el cribador?)

Un instrumento de medida no se usa sin validar. Principio cerrado: **un validador local y determinista (temp 0) solo se puntúa contra ground truth ESTABLE.** Tres buckets:

1. **Referente estable** (PASS/FAIL fiable) → se mide fidelidad.
2. **Referente flaky** (no-determinista) → no se mide; es un **hallazgo de calidad** del sistema bajo prueba.
3. **Salida degenerada** del validador (loop, error) → INVALID, no cuenta.

Métrica del cribador: **recall@k**. El error grave es el **falso negativo** (perder un candidato bueno) → un sesgo **pesimista** es el lado seguro.

---

## Qué hay aquí (implementado y funcionando)

```
qap/
  test_qa_playbooks.py      → runner + rúbrica de QA contra la plataforma real (51 TCs)
  static_audit.py           → auditoría de diseño 100% offline (sin coste)
  correlate_static_dynamic.py → correlación estático ↔ dinámico
  adk_fidelity/             → el cribador local (reconstrucción ADK + harness de fidelidad)
  tc_analysis/              → reportes y dashboard histórico de QA
  tests/                    → tests unitarios (60, verdes)
definitions/                → artefactos del agente bajo prueba (instancia Petal)
.github/workflows/qa.yml    → CI: corre la suite contra CX y publica el dashboard
```

## Estado (honesto)

| Pieza | Estado |
|---|---|
| Auditoría estática (`static_audit`) | ✅ funciona, offline, $0 |
| Suite QA contra CX (`test_qa_playbooks`) | ✅ funciona — CI verde, 51 TCs |
| Tests unitarios | ✅ 60 verdes |
| Cribador local (`adk_fidelity`) | 🟡 screener funcional (≈64% acuerdo, 0 falsos negativos); fidelidad en optimización |

## Cómo se ejecuta

```bash
# auditoría de diseño (offline, sin credenciales)
python qap/static_audit.py

# un caso de QA contra la plataforma real (requiere auth: gcloud)
python qap/test_qa_playbooks.py --test TC-C29 --runs 1

# tests unitarios
python -m pytest qap/tests/ -q
```

## Roadmap

- Subir la fidelidad del cribador (refactor de playbooks largos → cabe modelo mayor en local/cloud $0).
- Mutation testing como métrica reina de detección.
- Generalizar el adaptador a otras plataformas (más allá de Dialogflow CX).

## El sistema completo

- **ACT** — despliegue a Dialogflow CX ([cx-automation-template](https://github.com/jeronimosanchez/cx-automation-template)).
- **QAP** (este) — validación / optimización de agentes.
- **GEN / RES** — generación e investigación (por construir).
