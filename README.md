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
  petal_qa.py      → runner + rúbrica de QA contra la plataforma real (51 TCs)
  static_audit.py           → auditoría de diseño 100% offline (sin coste) (auto-sincroniza umbrales desde ~/CD/kb/ si está disponible)
  sync_static_config.py     → genera static_audit_config.yaml desde bloques `static:` del KB (llamado automáticamente por static_audit.py; usar manualmente solo para dry-run o forzar sync)
  regenerate_html.py        → regenera HTML desde JSONs sin llamar a CX
  rebuild_history.py        → genera history.json para el histórico del dashboard
  list_fails.py             → lista FAILs del último run con estado de análisis
  surgical_run.py           → corre TCs específicos sin relanzar la suite completa
  publish_html.sh           → publica reportes en GitHub Pages
  sim/                      → el cribador local (reconstrucción ADK + harness de fidelidad)
  tc_analysis/              → reportes y dashboard histórico de QA
  tests/                    → tests unitarios (60, verdes)
definitions/                → artefactos del agente bajo prueba (instancia Petal)
.github/workflows/qa.yml    → CI: corre la suite contra CX y publica el dashboard
```

> La URL pública de los reportes es `/qa/` (no `/qap/`) — desacoplada del nombre de carpeta para no romper enlaces existentes.

## Tres sistemas de control

QAP evalúa con tres mecanismos complementarios:

| Sistema | Qué hace | Estado | Pieza |
|---|---|---|---|
| **Hard eval** (regex) | Verificación determinista — ¿la respuesta contiene/evita los datos exactos? (precio, email, tool call) | ✅ operativo | `check_turn()` en `petal_qa.py` |
| **Juez** (LLM) | Calidad conversacional blanda que el regex no mide (tono, naturalidad, vocabulario) vs rúbricas/principios | ✅ funciona · 🟡 **sin calibrar** — pendiente de validar con la IA local (ver LIMIT-03) | `qap/sim/judge.py` (Gemma) |
| **Adversarial** | Genera candidatos y los enfrenta entre sí para cribar los débiles | 🔵 en construcción | motor de **GEN** (otro repo) |

Hard eval y juez viven en QAP; el adversarial es de la línea **GEN**. La calibración del juez y la fidelidad del cribador quedan **pendientes de probar con la IA local**.

## Estado (honesto)

| Pieza | Estado |
|---|---|
| Auditoría estática (`static_audit`) | ✅ funciona, offline, $0 |
| Suite QA contra CX (`petal_qa`) | ✅ funciona — CI verde, 51 TCs |
| Tests unitarios | ✅ 60 verdes |
| Cribador local (`sim`) | 🟡 screener funcional (≈64% acuerdo, 0 falsos negativos); fidelidad en optimización |

## Cómo se ejecuta

```bash
# auditoría de diseño (offline, sin credenciales)
python qap/static_audit.py

# un caso de QA contra la plataforma real (requiere auth: gcloud)
python qap/petal_qa.py --test TC-C29 --runs 1

# tests unitarios
python -m pytest qap/tests/ -q
```

## Limitaciones conocidas

Defectos documentados, con alcance preciso de lo que sí funciona. Detalle completo en [`docs/known_limitations.md`](docs/known_limitations.md).

| ID | Dónde | Qué falla | Impacto |
|---|---|---|---|
| LIMIT-01 | `not_expected` en `petal_qa.py` | Solo evalúa en el último turno — no caza violaciones en turnos intermedios de TCs multi-turno | Falso negativo silencioso en multi-turno |
| LIMIT-02 | 6 checks en `petal_tests.yaml` | Patrones regex demasiado laxos — matchean también mensajes de error de CX | Falso positivo en TC-R02, R04, PRESUPUESTO-01, FUNERAL-01, COLOR-01, REG06 |
| LIMIT-03 | `judge.py` | Sin patrón oro humano — acuerdo actual ~54-64% | No usar para decisiones de calidad hasta calibrar |

---

## Roadmap

- Subir la fidelidad del cribador (refactor de playbooks largos → cabe modelo mayor en local/cloud $0).
- Mutation testing como métrica reina de detección.
- Generalizar el adaptador a otras plataformas (más allá de Dialogflow CX).

## Dónde encaja

QAP es una de las **4 líneas** del sistema de Automatización CD (ACT · QAP · GEN · RES) coordinadas por el hub **CD**. El **mapa completo y el estado de cada línea** está en **[SISTEMA.md](https://github.com/jeronimosanchez/CD/blob/main/SISTEMA.md)** (fuente única — no se duplica aquí).

**Sobre la knowledge base (kb):** la kb es conocimiento **de todo el sistema** y vive en **CD** (fuente única de verdad), no dentro de QAP. QAP la **consume** (p. ej. `sync_static_config.py` deriva su config desde la kb) y commitea el resultado → **QAP corre standalone**, sin depender de CD en ejecución. Cuando un script de QAP necesite la kb en runtime, se hará vía **submodule o sync-and-commit**, nunca con rutas locales hardcodeadas.
