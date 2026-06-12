# Cribador ADK en Kaggle (GPU, $0)

Mover la **inferencia del LLM** fuera del Mac a una GPU gratis (Kaggle T4). El harness,
el webhook y la rúbrica no cambian — solo el hardware donde corre el modelo.

## Por qué (y qué esperar de verdad)

| | |
|---|---|
| **Modelo** | el MISMO que en local: `qwen2.5:14b` q4 vía Ollama → **fidelidad idéntica** (no es otro modelo, es el mismo en GPU). |
| **Coste** | €0. Kaggle da ~30 h/semana de GPU gratis. Sin secretos (rúbrica determinista, webhook público). |
| **Velocidad** | **probable mejora, NO garantía de ×3-4.** La GPU gana sobre todo en el *prefill* del prompt de ~32k (el cuello). En generación, T4 ≈ 1-2× M4 Air. |
| **Wins seguros** | (1) **libera el Mac** — sigues trabajando; (2) **presupuesto** de 30 h/sem para barridos overnight; (3) entorno **reproducible**; (4) margen para escalar (2ª T4, batching) después. |

> Honestidad: el premio de Kaggle es *throughput + presupuesto + off-Mac*, con un
> speedup por-TC probable pero no un múltiplo prometido. El cuello sigue siendo la
> inferencia; podar el prompt sigue siendo complementario.

## Pasos

1. **Empaquetar** (en el Mac, una vez):
   ```bash
   bash qap/adk_fidelity/kaggle/package_for_kaggle.sh
   # → qap/adk_fidelity/kaggle/build/petal-fidelity.zip
   ```
2. **Subir** ese zip a Kaggle como **Dataset** (Datasets → New Dataset → arrastra el zip).
3. **Crear un Notebook** y subir `kaggle_fidelity.ipynb` (o pegar sus celdas).
4. En el notebook: `Settings → Accelerator → GPU T4 x2`, `Internet → ON`, `Add Input → tu dataset`.
5. **Run All.** Al final, celda 5 da el enlace de descarga de `fidelity_result.json`.

## Riesgos / notas

- **VRAM**: 14B-q4 (~9 GB) + KV de 32k cabe en una T4 (16 GB), pero va justo. Si hay OOM:
  bajar `OLLAMA_CONTEXT_LENGTH`, o usar la 2ª T4 / `OLLAMA_KV_CACHE_TYPE=q8` (q8 degrada
  algo el recall en contexto largo — medir antes de fijarlo).
- **Sesión Kaggle**: máx. 12 h, con idle-timeout. Para los 51 TCs sobra; para barridos
  largos, trocear.
- **Paridad de medición**: mismo modelo/quant/temp(0)/ctx(32k)/flash que local → el número
  es comparable con el baseline. Anotar el fingerprint en `BENCHMARK.md` (fila "Kaggle-T4").
- **2ª T4 libre**: de momento sin usar. Palanca futura: 2 instancias de Ollama (una por GPU)
  + sharding de los 51 TCs ≈ throughput ×2. O vLLM con quant AWQ (cambia el quant → revalidar
  fidelidad antes de fiarse).
