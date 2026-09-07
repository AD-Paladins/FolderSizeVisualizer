# Plan de Tareas (Findings & Backlog)

> Estado: backlog activo. Priorizar por valor para el usuario.

## Contexto del repo

- App macOS 15+ / Swift 6 / SwiftUI 5, MVVM + actores. Analiza disco por **herramientas de desarrollo**.
- PR #19 (merged): `FileSystemHelperRunProcessTests` — coverage del timeout/termination.
- PR #20 (merged): `scanAll()` corrie detectores en paralelo con `withTaskGroup`.
- C2 resuelto: dual-mode es intencional, no cambiar nada.

---

## Tareas nuevas

### T1 — Benchmark de velocidad de scan

**Objetivo:** Medir el tiempo real de `scanAll()` antes/después del parallel-scan (PR #20) para validar el mejora.

**Qué implementar:**
- Un `@MainActor` helper en tests que cronetee `Date()` around `scanService.scanAll(...)`.
- Reportar tiempo por detector y total en ms.
- Ejecutable via `xcodebuild test` con un `@Test` dedicado.

**Dependencias:** `ArtifactScanService`, `DeveloperTool`, `FileSystemHelper`.

---

### T2 — Reporte de dependencias Homebrew instaladas

**Objetivo:** Generar un reporte de **todas las dependencias homebrew instaladas** (no solo el cache/cellar).

**Qué implementar:**
- Nuevo detector o extensión que corra `brew list --formula` y `brew list --cask`.
- Parsear salida en `[HomebrewDependency]` (nombre, version, cask/formula, deps).
- View en la UI (DashboardView o ToolDetailView) que muestre el listado.
- Opcional: export a JSON/PDF del reporte.

**Dependencias:** `DeveloperTool.homebrew`, `FileSystemHelper.runProcess`, `CommonArtifactDetectors.swift`.

---

## Tarea descartada (no implementar)

### PDF Export (`feat/export-pdf_report`) — INACTIVA

Rama creada por error. Idea: exportar el scan a PDF con `ImageRenderer`/`PDFPageRenderer`. **No era parte de la solicitud del usuario.** La rama quedó vacía (sin commits). Se puede eliminar o dejar como referencia.

---

## Estado

- [ ] T1: Benchmark de velocidad
- [ ] T2: Reporte de dependencias Homebrew
- [ ] PDF export: descartado
