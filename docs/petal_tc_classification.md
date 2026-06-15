# Clasificación de TCs — Petal QA

Versión: 1.0 | Fecha: 2026-06-15

## Las 3 dimensiones

Cada TC en `petal_tests.yaml` tiene exactamente 3 campos de clasificación:

| Campo | Pregunta | Valores | Cambia con el tiempo |
|---|---|---|---|
| `difficulty` | ¿Tipo de caso? | `core` / `edge` | No — es intrínseco al TC |
| `domain` | ¿Qué playbook ejercita? | ver tabla abajo | No — es estructural |
| `status` | ¿Está calibrado? | `stable` / `experimental` | Sí — sube cuando pasa |

### `difficulty`

- **`core`** — flujo principal esperado. El agente debe manejarlo siempre. Si falla un `core`, hay un bug crítico.
- **`edge`** — caso límite, ambigüedad, robustez, zona gris. Puede fallar ocasionalmente sin bloquear un release.

### `domain` — alineado a los 6 playbooks reales del agente

| Valor | Playbook | Qué cubre |
|---|---|---|
| `orquestador` | `petal_cx_orchestrator` | Routing, saludo, info de negocio, robustez de input |
| `compra` | `compra` | Catálogo, selección, refinamiento, stock, urgencia |
| `checkout` | `checkout` | Confirmación, pago, email, dirección de entrega |
| `registro` | `registro_task` | Alta de cliente nuevo |
| `gestion_deuda` | `gestion_deuda` | Saldo, deuda, moroso |
| `handoff` | `handoff` | Escalado a humano |

### `status`

- **`stable`** — verde 2-3 runs consecutivos. Forma parte de la suite de regresión.
- **`experimental`** — en calibración: FAIL conocido, flaky, o TC nuevo sin historial.

**Regla de transición:** `experimental` → `stable` cuando pasa limpio 2-3 runs seguidos.
No hay transición automática inversa: si un `stable` empieza a fallar, la suite lo detecta y se investiga manualmente.

**Suite de regresión = todos los TCs con `status: stable`**, independientemente de si son `core` o `edge`.

---

## Matriz de cobertura

Estado a 2026-06-15. Revisar antes de cada release para detectar huecos.

| domain | core | edge | total | stable | experimental |
|---|---|---|---|---|---|
| `orquestador` | 3 | 7 | 10 | 10 | 0 |
| `compra` | 7 | 21 | 28 | 23 | 5 |
| `checkout` | 1 | 3 | 4 | 4 | 0 |
| `registro` | 2 | 2 | 4 | 4 | 0 |
| `gestion_deuda` | 2 | 1 | 3 | 3 | 0 |
| `handoff` | 1 | 1 | 2 | 2 | 0 |
| **total** | **16** | **35** | **51** | **45** | **6** |

**Huecos actuales:** `gestion_deuda` (3 TCs) y `handoff` (2 TCs) tienen cobertura mínima — candidatos a nuevos TCs.

### TCs en estado `experimental`

| TC | domain | por qué |
|---|---|---|
| `TC-FRUSTRACION-01` | compra | FAIL robusto (0/3 runs) |
| `TC-STOCK-EXCESO-01` | compra | FAIL robusto (0/3 runs) |
| `TC-URGENCIA-03` | compra | FAIL robusto (0/3 runs) |
| `TC-MULTI-PRODUCTO-01` | compra | FAIL robusto (0/3 runs) |
| `TC-C40` | compra | Flaky (2/3 runs) |
| `TC-CAMBIO-OP-01` | compra | Flaky (2/3 runs) |

---

## Cómo añadir un TC

Añadir directamente en `petal_tests.yaml` siguiendo esta estructura:

```yaml
- id: TC-NUEVO-01
  name: Descripción corta del caso
  turns:
  - user: Mensaje del usuario
    checks:
    - palabra_clave|otra_palabra
  not_expected:
  - expresion_que_no_debe_aparecer
  domain: compra          # orquestador | compra | checkout | registro | gestion_deuda | handoff
  difficulty: edge        # core | edge
  status: experimental    # siempre experimental al crear; sube a stable tras 2-3 runs verdes
```

**Regla:** todo TC nuevo arranca en `status: experimental`.

---

## Cómo consultar la suite

```bash
# Ver todos los TCs con su clasificación
python3 qap/petal_qa.py --list

# Filtrar por dimensión
python3 qap/petal_qa.py --difficulty core          # los 16 flujos principales
python3 qap/petal_qa.py --domain compra            # los 28 TCs de compra
python3 qap/petal_qa.py --stability experimental   # los 6 en calibración

# Ejecutar un TC concreto
python3 qap/petal_qa.py --test TC-C29 --runs 1
```
