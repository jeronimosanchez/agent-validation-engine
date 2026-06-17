# Sistema A — motor de optimización (QAP)

Ciclo que mejora un agente cuando falla pruebas de QA: **diagnostica → repara → valida**.
Lo **dirige QAP** (detecta, diagnostica, valida) usando **GEN** (genera los arreglos) y **ACT** (los despliega).

## Los tres pasos

- **[DIAGNOSTICA](sistema_a_diagnostica.md)** — convierte los FAILs en hipótesis de causa falsables.
- **[REPARA](sistema_a_repara.md)** — de la causa al fix; genera candidatos y los **criba en local ($0)** antes de gastar en la plataforma.
- **[VALIDA](sistema_a_valida.md)** — confirma que el fix resuelve el fallo **sin introducir regresiones**.

Si no se resuelve, vuelve a la siguiente hipótesis; si se resuelve, el arreglo se destila en conocimiento reutilizable (Sistema B).

## Respaldo

- **[Respaldo del sector 2026](respaldo_sector_2026.md)** — cómo lo resuelve el sector: *LLM-as-judge guiado por taxonomía* (diagnóstico) · *generate-and-validate APR* (reparación) · *memoria gobernada de fixes* (aprendizaje).

## Estado

Diseño completo (v1.1 de QAP). **Parcialmente operativo**: partes de DIAGNOSTICA y VALIDA ya funcionan; el bucle completo y la criba $0 (ADK) están en construcción.
