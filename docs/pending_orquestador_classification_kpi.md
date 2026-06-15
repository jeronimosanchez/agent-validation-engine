# Pendiente de decisión — KPI de clasificación del Orquestador

Estado: ⏳ pendiente de decisión | Detectado: 2026-06-16 (auditoría post-migración de schema)

## El problema

El dashboard QA tiene un KPI que mide **si el Orquestador clasifica bien cada consulta**: compara la categoría que CX asigna en su trace (`grupo_intent`) contra la categoría declarada del TC.

Al migrar el schema de clasificación de TCs (`group` G1-G7 → `domain` orquestador/compra/...), ese KPI se rompió:

- **CX sigue emitiendo** `grupo_intent` en la taxonomía vieja (G1-G7, COMPRA-INV, COMPRA-ZG, ESP) — eso es del lado CX, no lo tocamos.
- **El TC ahora declara** `domain` (orquestador/compra/...), no el G-código.
- La comparación `gi_expected = r["group"]` (ahora domain) vs `gi_observed` (G-código de CX) **nunca coincide** → el KPI muestra ~0% de clasificación correcta, que es falso.

## Alcance (código afectado)

Todo en `qap/petal_qa.py`:

1. **Bloque 2 — KPI clasificación** (`build_kpis`, ~líneas 793-816): el cálculo `orq_ok / orq_total` comparando `r["group"]` vs `grupo_intent`.
2. **Render per-TC "Clasificación"** (~línea 1842): muestra "esperado: {domain} vs observado: {G-código}" → casi siempre ⚠️ mismatch.
3. **Mapas de traducción** (~líneas 1694-1714): `_gi_map`, `_gi_to_playbook`, `_gi_to_file` traducen los G-códigos que CX emite a etiquetas legibles. Estos siguen siendo correctos *si CX emite G-códigos*; el problema no son ellos, es la comparación contra el domain.

**No afectado:** la COBERTURA por dominio (ya arreglada, usa los 6 domains) y el slot-filling de Compra (lee params de CX directamente).

## Qué perdemos mientras tanto

Solo ese KPI de "% de clasificación correcta del Orquestador" en el modal Metodología. Es una métrica de **routing/estructura** (¿enruta a la categoría correcta?), útil pero no crítica. NO afecta a:
- el PASS/FAIL de los TCs (eso lo decide la rúbrica regex, intacta),
- la cobertura por dominio,
- ningún otro KPI.

Es decir: la suite QA mide bien el comportamiento; solo falta este indicador secundario de clasificación.

## Pregunta a decidir

¿Qué emite Petal 1.1 en `grupo_intent`? De eso depende la solución:

- **Si 1.1 sigue clasificando en G1-G7** → necesitamos un mapeo `domain → G-código(s) esperado(s)`, o mejor, un campo `grupo_intent_esperado` por TC en `petal_tests.yaml`.
- **Si 1.1 cambió la taxonomía** (p.ej. ya clasifica por domain) → el KPI casi se arregla solo, y los mapas `_gi_*` habría que actualizarlos.
- **Si ya no es útil** → retirar el bloque 2 + el render per-TC de clasificación.

## Solución sugerida (la más limpia)

Añadir un campo explícito `grupo_intent_esperado` por TC en `petal_tests.yaml` (lo que el Orquestador DEBE clasificar, en la taxonomía que CX realmente emite). Ventajas:
- Desacopla la clasificación esperada (CX-específica) de la dificultad/dominio (agnóstico).
- No fuerza un mapeo domain→G frágil (la relación no es 1:1: "compra" abarca G5 + COMPRA-INV + COMPRA-ZG).
- El KPI compara `grupo_intent_esperado` (del TC) vs `grupo_intent` (de CX) — manzanas con manzanas.

Pasos:
1. Verificar con 1 TC real qué pone CX en `params.grupo_intent` (correr `petal_qa.py --test TC-R01 --runs 1` y mirar el JSON de log → `runs[0].turns[0].params.grupo_intent`).
2. Anotar `grupo_intent_esperado` en los TCs (empezar por los core).
3. Cambiar el bloque 2: `gi_expected = r_test.get("grupo_intent_esperado")` en vez de `r["group"]`.

## Cómo probar la solución

1. **Verificar qué emite CX** (prerequisito, 1 llamada):
   ```bash
   python3 qap/petal_qa.py --test TC-R01 --runs 1
   # leer ~/petal-qa/qa_<TS>_logs/TC-R01.json → runs[0].turns[0].params.grupo_intent
   ```
   ⚠️ Requiere el webhook `petal-sheet-api` arriba (estaba caído el 16-jun).
2. **Tras anotar + cambiar el bloque:** regenerar el dashboard sin gastar CX:
   ```bash
   python3 qap/regenerate_html.py --logs-dir ~/petal-qa/qa_<TS>_logs/ --out /tmp/kpi_test.html
   grep -i "clasificaci" /tmp/kpi_test.html   # el KPI ya no debe dar 0% falso
   ```
3. **Validar coherencia:** para un TC cuyo `grupo_intent_esperado` coincide con lo observado, el render per-TC debe mostrar ✅, no ⚠️.
