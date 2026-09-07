# Plan de Hallazgos (Findings)

> Generado por sesión pi. Estado: **borrador de planificación**, no ejecutado.
> Prioridad = severidad × impacto. Marcar ✅ cuando se resuelva.

---

## 0. Contexto del repo

- App macOS 15+ / Swift 6 / SwiftUI 5, MVVM + actores. Analiza disco por **herramientas de desarrollo** (Xcode, Simuladores, Docker, Node, Python/Venv, Rust, LLMs locales).
- ~5,700 líneas en `FolderSizeVisualizer/` + tests unitarios y UI.
- Pipeline externo `~/Developer/ios/codegraph/` (tree-sitter → Neo4j → GraphRAG), skill `codegraph-first`.
- Última rama `main`, HEAD `96d945b fix: restore build and respect skip-hidden-files toggle`. Sin cambios sin commitear.

---

## 1. Hallazgos por severidad

### 🔴 Críticos (bug / riesgo de build o datos)

| # | Área | Finding |
|---|---|---|
| C1 | `FileSystemHelper.runProcess` | Timeout 15s con escalada terminate→kill. Verificar que el timeout se aplique a todos los detectores y no cause falsos "tool not found". Ver `tools/codegraph-diagnostics.md`. |
| C2 | `ScanViewModel` / `ContentView.swift` | **Arquatura dual-mode** (RESUELTO 2026-09-06): `ContentView.swift` + `ScanViewModel` (normal) y `ArtifactContentView` + `ArtifactScanViewModel` (developer) son dos stacks paralelos, ambos activos vía toggle `isDeveloperMode`. **No es código muerto.** Decisión del usuario: *ambos modos son intencionales, no cambiar nada.* |
| C3 | `runProcess` con `skip-hidden-files` toggle | El fix `96d945b` respeta el toggle; verificar que los detectores no escanean ocultos cuando está desactivado (consumo de tiempo en macOS). |

### 🟠 Altos (calidad / consistencia)

| # | Área | Finding |
|---|---|---|
| A1 | `patterns/swiftui-view.md` | Documenta `@StateObject` pero la app usa `@Observable` (confirmado en `ScanViewModel`, `ArtifactScanViewModel`). Doc desactualizado. |
| A2 | `architecture/swiftui-uikit-bridge.md` y docs relacionados | El doc se llama uikit-bridge pero es **macOS puro (AppKit)**. Múltiples docs lo heredan como "legacy". Normalizar terminología. |
| A3 | `specs/navigation-bridge/` | Specs/DESIGN/TASKS/TESTS existen en disco pero el índice marca N/A (SwiftUI puro, sin UIKit). Limpiar o archivar. |
| A4 | `standards/accessibility.md` | Refleja estado limitado: sin `.accessibilityLabel/Hint`, sin Dynamic Type infra, sin identifiers de test. El doc es honesto pero no hay plan de mejora. |

### 🟡 Medios (mejora / tech debt)

| # | Área | Finding |
|---|---|---|
| M1 | `README.md` TODO | Pendiente: actualizar `install-ai-commands.sh` para leer estructura del repo y seguir SDD. |
| M2 | `workflows/feature.md` y `bugfix.md` | Referencian `/sdd-new` (no disponible en OpenCode) y bridge specialist (AppKit, no UIKit). Corregir referencias. |
| M3 | `agents/bridge-specialist.md` | Descripción genérica "SwiftUI ↔ AppKit"; ajustar a macOS/AppKit real del repo. |
| M4 | `docs/ux-design/specifications.md` | Referenciado en README como spec Figma-ready; confirmar que existe y está vigente. |

### 🟢 Bajos (cosmético / follow-up)

| # | Área | Finding |
|---|---|---|
| B1 | `README.md` | Badge macOS dice 15.6 pero AGENTS/index dice 15+. Unificar versión. |
| B2 | `handoff-2026-08-25.md` | F4 pendiente en macOS; actualizar estado real tras los fixes recientes. |

---

## 2. Propuesta de ejecución (orden sugerido)

1. **Verificar C1/C3** — confirmar que el timeout/`skip-hidden-files` no degrada scans en el work Mac.
2. **A1/A2/A3** — limpiar docs desactualizados (bajo costo, alto valor para futuros agentes).
3. **C2** — decidir si se elimina el escáner legacy o se marca como deprecated.
4. **A4/M2/M3** — actualizar estándares y workflows.
5. **B1/B2/M1** — cosméticos y follow-up final.

---

## 3. Estado

- [ ] Plan revisado y priorizado con el usuario
- [ ] C1/C3 verificados
- [ ] Docs actualizados (A1–A4)
- [ ] Legacy escáner resuelto (C2)
- [ ] Workflows/agents corregidos (M2/M3)
- [ ] Cosméticos (B1/B2/M1)
