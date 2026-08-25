# Diagnóstico: cuelgue al escanear Simulators (Mac del trabajo)

## Síntoma

La app se queda cargando infinitamente cuando el scan llega al paso de simulators. Los demás detectores nunca arrancan (el ciclo es secuencial).

## Causa raíz

`SimulatorArtifactDetector` corría `xcrun simctl list ... -j` con `waitUntilExit()` sin timeout y leyendo el pipe recién después del exit. Si `xcrun` se cuelga — licencia de Xcode pendiente, MDM corporativo, componentes instalándose, o JSON mayor al buffer del pipe (~64KB) — el actor esperaba para siempre.

## Test en la máquina afectada

```bash
# 1. ¿simctl responde? ¿cuánto tarda?
time xcrun simctl list devices -j | wc -c

# 2. ¿Hay tareas de primer arranque pendientes (licencia/componentes)?
xcodebuild -checkFirstLaunchStatus; echo $?
```

| Resultado | Lectura |
|---|---|
| #1 tarda >10s o se cuelga | Confirmado: `xcrun`/`simctl` es el culpable |
| #1 rápido pero #2 devuelve != 0 | Licencia/componentes pendientes — abrir Xcode una vez, aceptar, re-testear |
| Ambos OK | El fix igual protege; sospechar MDM u otra interferencia y mirar Console.app |

## Fix aplicado

`FileSystemHelper.runProcess(launchPath:arguments:timeout:)` en
`FolderSizeVisualizer/Services/ArtifactDetectors/ArtifactDetector.swift`:

- corre el proceso fuera del actor (utility thread),
- drena stdout concurrentemente (elimina el deadlock de pipe lleno),
- timeout de 15s → `terminate()` → `kill()` escalonado,
- `stderr` a `nullDevice`.

Usado por `SimulatorArtifactDetector` (devices + runtimes) y por el
`isToolInstalled` de `PythonArtifactDetector`, que tenían el mismo patrón.

**Comportamiento esperado post-fix**: si `simctl` se cuelga, a los ~15s el
detector degrada a "Error scanning iOS Simulator" y el scan continúa con los
demás detectores en vez de colgar para siempre.

## Después del fix

Rebuild en la Mac afectada, correr un scan completo y verificar que llegue a
"Scan completed". Si el paso de simulators reporta error pero el resto avanza,
el problema de fondo es del entorno (`simctl`), no de la app — resolverlo con
la tabla de arriba.
