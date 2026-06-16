# Limitaciones conocidas del harness QA

Registro de defectos conocidos no resueltos — con alcance preciso de lo que sí funciona,
lo que no, y la solución propuesta. Ninguna limitación está silenciada; todas están
documentadas aquí y comentadas en el código.

---

## LIMIT-01 — `not_expected` solo en el último turno

**Estado:** 🟡 WIP — funcional con restricción de alcance  
**Archivo:** `qap/petal_qa.py` (~línea 270) · `qap/petal_tests.yaml` (campo `not_expected`)

### Qué hace

`not_expected` es la lista negra de un TC: palabras que no deben aparecer en la respuesta
de Petal. Si aparecen → FAIL, aunque los `checks` (lista blanca) estén todos en verde.

### Qué sí cubre (usar con confianza)

- TCs de **1 turno**: la lista negra se evalúa en ese único turno. ✅
- **Guardia de estado final**: cazar confirmaciones imposibles, PII o intrusiones
  al cierre de la conversación. ✅

### Qué NO cubre (falso negativo)

TCs de **varios turnos**: la lista negra solo se aplica al **último** turno. Si Petal
mete la pata en un turno intermedio (por ejemplo, menciona `confirmado` antes de tiempo
o filtra datos internos a mitad de conversación), el test PASA silenciosamente.

### Diseño objetivo

Mover `not_expected` dentro de cada turno del YAML, simétrico a `checks`:

```yaml
turns:
- user: "quiero rosas negras"
  checks: [no disponible|no tenemos]
  not_expected: [confirmado|pedido realizado]   # guardia en ESTE turno
- user: "¿qué alternativas hay?"
  checks: [opcion|alternativa]
```

Con una lista global separada para invariantes que aplican en **todos** los turnos
(fontanería interna, PII, directivas CX ejecutables). El `static_leak_gate.py`
ya cubre el caso más crítico de este tipo (fugas de $var, PASO N, etc.).

### Impacto actual

Bajo: los TCs multi-turno que usan `not_expected` hoy vigilan el estado final,
que es el caso de uso principal. El falso negativo ocurre solo si la violación
sucede en un turno intermedio y el último turno es limpio — escenario poco frecuente
pero posible en TCs de registro o checkout multi-paso.

### Solución y cómo probarla

1. Migrar el campo `not_expected` dentro de cada turno en `petal_tests.yaml`.
2. Actualizar `check_turn` y el bloque de evaluación en `petal_qa.py`.
3. Test: crear un TC multi-turno donde el turno intermedio contiene la palabra negra
   pero el último turno no. Con el diseño actual → PASS (falso negativo). Con el fix → FAIL.

---

## LIMIT-02 — Regex `checks` con 6 patrones demasiado laxos

**Estado:** 🟡 WIP — calibración manual pendiente  
**Archivo:** `qap/petal_tests.yaml` (campos `checks` de TCs marcados)

### Problema

El audit del 16-jun-2026 detectó 6 checks core con patrones de una sola palabra
genérica que dan falsos positivos: el patrón matchea también mensajes de error de CX.

Caso documentado: TC-R02 check `precio` → matchea `"no puedo consultar el precio"` (error)
→ el TC pasa aunque Petal no respondió correctamente.

**TCs afectados:** TC-R02, TC-R04, TC-PRESUPUESTO-01, TC-FUNERAL-01, TC-COLOR-01, TC-REG06.

### Solución

Apretar cada patrón: usar alternativas más específicas (`euro|€` en vez de `precio`)
o combinar con `not_expected` para excluir la respuesta de error.
Trabajo manual, ~30 min.

---

## LIMIT-03 — `judge.py` sin calibrar

**Estado:** 🟡 WIP — funcional, sin patrón oro  
**Archivo:** `qap/sim/judge.py`

### Problema

El juez LLM (Gemma vía Ollama, $0 local) evalúa 6 dimensiones blandas por TC.
Acuerdo actual con criterio humano: ~54-64%. Sin patrón oro humano definido,
la métrica no es fiable para decisiones de calidad.

### Solución

Construir ~20-30 casos discriminantes por dimensión (PASS/FAIL/dudosos),
medir % de acuerdo, iterar el prompt hasta >80%. Trabajo estimado: 1-2 días.
