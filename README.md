# agent-validation-engine

**Línea QAP** del sistema de automatización CD — un **método + motor para validar agentes conversacionales** de forma barata, antes de pagar la plataforma real.

> Estado: en construcción. Primera instancia: **Petal** (agente de floristería en Dialogflow CX).
> El método es **agnóstico de plataforma**; el adaptador (Dialogflow CX / ADK) es una pieza intercambiable.

---

## El problema

Validar y optimizar un agente conversacional es caro: cada prueba contra la plataforma real (Dialogflow CX, etc.) cuesta dinero por petición. Iterar sobre 40 playbooks × 300 variables a ese precio es inviable.

## La idea — el embudo

```
Cribador LOCAL ($0)  →  propone y criba candidatos    →  Plataforma real  →  confirma solo los finalistas
  · reconstrucción del agente en ADK + LLM local (Ollama)
  · llama al webhook real, aplica la misma rúbrica
  → barato e ilimitado; no necesita fidelidad perfecta (solo ordenar bien)
```

El cribador no decide: **propone y filtra gratis**; la plataforma real **confirma barato** solo los 2-3 mejores.

## El método de validación (¿es de fiar el cribador?)

Un instrumento de medida no se usa sin validar. La secuencia:

```
1. Mutation testing  → inyecta defectos conocidos, mide la tasa de detección   (la métrica reina; no necesita casos nuevos)
2. Acuerdo con CX    → recall@k sobre ground truth
3. Holdout           → generalización (casos que el afinador nunca vio)
4. Calibración       → ¿el juez reproduce veredictos conocidos?
5. Throughput        → paralelismo + subconjunto (sin esto, el bucle es inviable)
```

Métrica del cribador: **recall@k** (de los candidatos buenos, ¿cuántos sobreviven al filtro). El error grave es el **falso negativo** (perder un bueno) → un sesgo **pesimista** es el lado seguro.

## Hallazgo de rigor (registrado, no escondido)

La reconstrucción **no es determinista entre hardware**: el mismo software (Qwen-14B-q4, temp=0, multi-agente) dio **88% en Mac (Metal)** vs **82% en GPU Kaggle (CUDA)**, discrepando en 9/51 TCs. `temp=0` no garantiza reproducibilidad cross-backend → **el fingerprint debe incluir el hardware**. Lo que aguanta en ambos: **0 falsos negativos** (la propiedad segura).

---

## Estructura (cuando se pueble)

```
qap/adk_fidelity/   → el cribador (reconstrucción ADK + harness de fidelidad)
qap/adk_fidelity/kaggle/  → ejecución en GPU gratis (Kaggle)
definitions/        → artefactos del agente bajo prueba (instancia Petal)
EVAL_DESIGN.md      → diseño completo del eval (catálogo agnóstico + perfil por cliente)
```

## Relación con las otras líneas

- **ACT** (despliegue a CX) — repo aparte.
- **QAP** (este) — validación / optimización.
- **GEN / RES** — por construir.
