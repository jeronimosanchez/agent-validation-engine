# CLAUDE.md — agent-validation-engine (línea QAP)

Instrucciones para trabajar en este repo. El detalle de qué hace cada cosa está en el [README](README.md).

## Qué es

QAP = **método + motor para validar agentes conversacionales** de forma barata (estático + dinámico + cribador local), antes de pagar la plataforma real. Primera instancia: Petal (Dialogflow CX). El método es **agnóstico de plataforma**.

## Reglas de arquitectura (no negociables)

1. **La knowledge base (kb) vive en el repo CD, no aquí.** Es conocimiento de todo el sistema (lo usan también GEN/RES/futuros), no solo de QAP. CD es la **fuente única de verdad**.

2. **QAP debe correr STANDALONE.** Nada en `qap/` puede depender de que CD esté presente en ejecución. Lo que QAP necesite de la kb se **deriva y se commitea** (patrón de `sync_static_config.py`: lee la kb → genera config → el config queda versionado en QAP).

3. **NUNCA hardcodear rutas locales tipo `~/CD/kb/`.** Cuando un script necesite la kb:
   - paso de mantenimiento (regenerar config) → por parámetro (`--kb-root`), como hoy.
   - dependencia en runtime (futuro) → **git submodule** o **sync-and-commit**, nunca asumir que CD está al lado.
   - El test: *¿alguien que clona SOLO este repo puede correrlo?* Si no, está mal.

4. **Validación = solo contra ground truth ESTABLE.** Un validador local determinista (temp 0) solo se puntúa contra referente estable. Referente flaky → hallazgo de calidad, no fidelidad. Salida degenerada → INVALID, no cuenta.

## Relación con los otros repos

- **ACT** ([cx-automation-template](https://github.com/jeronimosanchez/cx-automation-template)) — despliegue a CX. ACT y QAP son pares, ninguno depende del otro en runtime.
- **CD** — conocimiento/método (kb). QAP es consumidor, no propietario.

## Cómo correr (local)

```bash
python qap/static_audit.py                              # auditoría de diseño (offline, $0)
python qap/test_qa_playbooks.py --test TC-C29 --runs 1  # 1 caso contra CX (requiere gcloud auth)
python -m pytest qap/tests/ -q                          # tests unitarios
```

## CI

`.github/workflows/qa.yml` corre la suite contra CX vía WIF. Requiere las GitHub Variables `GCP_WIF_PROVIDER` y `GCP_SERVICE_ACCOUNT` + que el WIF confíe en este repo (ya configurado).
