# Benchmark de fidelidad — cribador ADK local

Registro de versiones de la reconstrucción + su fidelidad vs CX. Cada fila = un config
(fingerprint) + su número de acuerdo. Permite ver QUÉ cambió, CUÁNTO mejoró, y cuál es
el **estado óptimo actual** a reusar la próxima vez.

Para reproducir cualquier versión: `./start_ollama.sh` (config Ollama) + `petal_agent.py`
(modelo/temp/params). Cada cambio se mapea a una User Story de la épica
`epic_fidelidad_cribador_adk`.

| Ver | Fecha | Cambios vs anterior | Fingerprint (config) | Acuerdo | Estado |
|---|---|---|---|---|---|
| **v0** | 11-jun | plano, los 6 playbooks inline | Qwen14b-q4 · ctx 4096 · temp~0.8 · sin flash · sin params | 54% | ❌ DESCARTADO — confound: ctx 4096 < prompt ~32k → truncación |
| **v1** | 12-jun | + ctx 32k (US1) + temp=0 (US2) + flash + params N1 (US3) | Qwen14b-q4 · ctx 32768 · temp 0 seed 42 · flash ON · params N1 · KV fp16 | ⏳ pendiente | ← BASELINE VÁLIDO (re-run en curso) |
| v2 | — | + multi-agente (US5) | Qwen14b-q4 · multi · ctx ~16k | — | 🔜 |
| v3 | — | + params Nivel 2 / estado (US6) | + state+callbacks | — | 🔜 |
| v4 | — | + calibración del sesgo (US8) | + corrección a·local+b | — | 🔜 condicional |

## Estado óptimo actual
**v1** (pendiente del número del baseline válido). Para usarlo:
```
./start_ollama.sh                                   # flash + ctx 32k
python run_fidelity.py                              # plano (v1)
ADK_RECON=multi python run_fidelity.py              # multi-agente (v2, cuando se valide)
```

## Cómo se lee el impacto
El DELTA de "Acuerdo" entre versiones = el impacto de ese cambio. Si v2 (multi-agente)
sube mucho el acuerdo en TCs de enrutado → el enrutado era el gap. Si no sube → no era ahí.
Cada fila debe llevar su fingerprint completo (Fable: "un resultado sin fingerprint es una anécdota").

> Auto-llenado futuro: cuando el harness escriba el fingerprint por run (US-T2 preflight),
> esta tabla se actualiza sola. Por ahora, se mantiene a mano tras cada run.

## Bitácora de cambios (qué hicimos y qué observamos)

- **11-jun** — Montaje de la reconstrucción plana (6 playbooks + 23 examples + webhook real). Primer run → 54% acuerdo. Diagnóstico inicial "reconstrucción rota" (tool-calling/enrutado).
- **12-jun — CONFOUND detectado** — El 54% estaba envenenado: contexto Ollama = 4096 < prompt ~32k → los playbooks se truncaban (el modelo veía ~4k de 32k). Las "23 falsas alarmas" eran el modelo operando a ciegas, no reconstrucción mala. **v0 descartado.**
- **12-jun — v1 (cambios bundleados)** — Aplicados a la vez: contexto 32k (US1, cierra truncación) · temp=0+seed (US2, era 0.8 → ruido de sampling) · flash attention (~30% más rápido prefill, output idéntico) · params Nivel 1 (US3, el modelo conoce input/output params). Re-run en curso → número pendiente. **OJO: bundle → v1 mide el efecto COMBINADO, no por-cambio.**
- **12-jun — En paralelo** — Scaffold multi-agente (`petal_agent_multi.py`, sin testear) · análisis determinista vs generativo destapó deuda de Petal (contadores/clasificación en el LLM, DT5) y alimentó el KB (A7/A8/V5). `start_ollama.sh` creado (config-as-code).

### Nota metodológica sobre la atribución
v1 **bundlea** varios cambios (contexto+temp+flash+params) → vemos el delta v0→v1, pero NO el impacto de CADA uno por separado. Para atribución limpia: aislar (un cambio = un run). De v2 en adelante, isolar (v2 = solo multi-agente) da el impacto por-cambio.
