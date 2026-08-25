# CodeGraph Setup

Pipeline que construye un grafo de conocimiento del código en Neo4j, para
exploración visual y luego GraphRAG. Documentado para poder replicarse en
cualquier repo Swift/Xcode desde cero.

```
repo (*.swift)
  │  tree-sitter-swift (parseo sintáctico, sin compilar)
  ▼
graph/nodes.jsonl + graph/edges.jsonl     (formato intermedio)
  │  load.py (idempotente)
  ▼
Neo4j (localhost:7474 Browser / :7687 Bolt)
  │  queries curadas + resúmenes jerárquicos
  ▼
Exploración (Browser) ──► GraphRAG para agentes (F6)
```

Todo lo generado vive **fuera** del repo, en un directorio hermano:

```
~/Developer/ios/codegraph/
├── dist/            tarballs descargados (borrables tras instalar)
├── tools/           JDK + Neo4j instalados (userspace, sin sudo)
├── extractor/       extract.py (AST -> JSONL) y load.py (JSONL -> Neo4j)
├── summaries/       generación de resúmenes jerárquicos (F5)
├── queries/         queries curadas para Neo4j Browser
└── .venv/           entorno Python del proyecto
```

---

## Herramientas instaladas

| Herramienta | Versión | Dónde vive | Para qué |
|---|---|---|---|
| OpenJDK (Temurin) | 21.0.12 LTS | `tools/jdk/` | Runtime que necesita Neo4j |
| Neo4j Community | 5.26.29 LTS | `tools/neo4j-community-5.26.29/` | Base de datos de grafos + Browser web |
| Python | 3.x del sistema | sistema | Lenguaje del pipeline |
| py-tree-sitter | 0.26.0 | `.venv/` | Motor de parseo incremental (bindings) |
| tree-sitter-swift | grammar C compilada | `.venv/` | Gramática de Swift para tree-sitter |
| neo4j (driver Python) | 5.x | `.venv/` | Carga de nodos/aristas por Bolt |

Credenciales locales: usuario `neo4j`, password `codegraph-dev`.
Solo escucha en `127.0.0.1` (no expuesto a la red).

## Comandos del día a día

```bash
# arrancar / parar / estado de Neo4j
export JAVA_HOME=~/Developer/ios/codegraph/tools/jdk
N=~/Developer/ios/codegraph/tools/neo4j-community-5.26.29/bin/neo4j
$N start    # stop / status

# re-extraer y recargar (tras cambiar código del repo)
~/Developer/ios/codegraph/.venv/bin/python ~/Developer/ios/codegraph/extractor/extract.py
~/Developer/ios/codegraph/.venv/bin/python ~/Developer/ios/codegraph/extractor/load.py

# resúmenes jerárquicos (F5)
~/Developer/ios/codegraph/.venv/bin/python ~/Developer/ios/codegraph/summaries/build_summaries.py
~/Developer/ios/codegraph/.venv/bin/python ~/Developer/ios/codegraph/summaries/load_summaries.py

# GraphRAG: context pack para un agente (F6)
~/Developer/ios/codegraph/.venv/bin/python ~/Developer/ios/codegraph/extractor/ask.py \
  "¿Quién implementa el protocolo ArtifactDetector?" --budget 6000
```

---

## Instalación desde cero (otra máquina u otro repo)

### 1. Workspace (sin sudo)

```bash
mkdir -p ~/Developer/ios/codegraph/{tools,dist,extractor,summaries,queries}
mkdir -p ~/Developer/ios/codegraph/tools/jdk
```

### 2. Descargas

```bash
cd ~/Developer/ios/codegraph/dist

# Neo4j Community LTS (verificar versión actual en neo4j.com/deployment-center;
# NO confiar en GitHub releases/latest: devuelve alphas viejos)
curl -fL -O https://dist.neo4j.org/neo4j-community-5.26.29-unix.tar.gz

# JDK 21 (endpoint redirige al binario más reciente de Temurin; soporta -C - para retomar)
curl -fL -C - -o jdk21.tar.gz \
  "https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jdk/hotspot/normal/eclipse"

# verificar integridad antes de extraer
gzip -t neo4j-community-5.26.29-unix.tar.gz && gzip -t jdk21.tar.gz
```

> Si la conexión corta: repetir el mismo curl con `-C -` retoma donde quedó,
> no empieza de cero.

### 3. Extracción

```bash
tar -xzf dist/neo4j-community-5.26.29-unix.tar.gz -C tools/
tar -xzf dist/jdk21.tar.gz -C tools/jdk --strip-components=1
tools/jdk/bin/java --version   # debe imprimir openjdk 21.x
```

### 4. Configurar y arrancar Neo4j

```bash
export JAVA_HOME=~/Developer/ios/codegraph/tools/jdk
N=~/Developer/ios/codegraph/tools/neo4j-community-5.26.29

cat >> $N/conf/neo4j.conf <<'EOF'
# --- codegraph local settings ---
server.default_listen_address=127.0.0.1
server.memory.heap.initial_size=512m
server.memory.heap.max_size=1g
server.memory.pagecache.size=256m
EOF

$N/bin/neo4j-admin dbms set-initial-password codegraph-dev
$N/bin/neo4j start          # daemoniza; hay delay de ~15s hasta Bolt listo
$N/bin/cypher-shell -a bolt://127.0.0.1:7687 -u neo4j -p codegraph-dev "RETURN 1"
```

### 5. Entorno Python

```bash
python3 -m venv ~/Developer/ios/codegraph/.venv
~/Developer/ios/codegraph/.venv/bin/pip install tree-sitter tree-sitter-swift neo4j
```

### 6. Adaptar a otro repo

En `extractor/extract.py` (hoy rutas hardcodeadas, ver TODO abajo):

| Constante | Qué es |
|---|---|
| `REPO` | ruta absoluta del repo a analizar |
| `OUT` | carpeta destino de los JSONL |

El resto es agnóstico del repo: descubre los `.swift` con `rglob`,
agrupa por primer directorio (`target`) y detecta keywords del lenguaje.
Para repos Kotlin/TS/C#/Java se cambia la gramática
(`tree-sitter-kotlin`, `@typescript-eslint/typescript-parser`... etc.)
y se ajustan los nombres de nodos del grammar — el pipeline es igual.

> **TODO próximo**: parametrizar `--repo` y `--out` por CLI en vez de constantes.

---

## Conceptos (glosario)

### AST y tree-sitter

Un **AST** (Abstract Syntax Tree) es el árbol que produce un parser al leer
código: `class Foo { func bar() }` se convierte en nodos anidados
(declaración → cuerpo → función). tree-sitter es un generador de parsers:
la gramática de Swift (escrita en JS, compilada a C) se distribuye como
`.so` y py-tree-sitter la invoca. **No compila ni entiende tipos**: ve la
estructura sintáctica, nada más. Por eso dos funciones llamadas `scan` en
archivos distintos son indistinguibles a este nivel — eso lo resuelve F4.

Escalera de precisión en Swift:

| Capa | Herramienta | Qué da | Costo |
|---|---|---|---|
| Sintaxis | tree-sitter | estructura, declaraciones, rápido, multi-lenguaje | bajo |
| Sintaxis rica | SwiftSyntax | AST completo fiel al token, usado por SourceKit | medio |
| Semántica | index store de xcodebuild / SourceKit-LSP | referencias cruzadas exactas (USR por símbolo) | alto (requiere compilar, macOS) |

tree-sitter es el piso; SwiftSyntax da fidelidad total del árbol pero
**tampoco resuelve tipos entre archivos**; la resolución real de "¿quién
llama a quién?" vive en el index store que genera el compilador (F4).

### Nodos y aristas (modelo de grafo de propiedades)

Neo4j guarda **nodos** (entidades, con etiqueta + propiedades) conectados
por **aristas** dirigidas (relaciones tipadas). Acá:

| Nodo | Ejemplo |
|---|---|
| `(:File)` | `FolderScanner.swift` |
| `(:Symbol {kind})` | actor `FolderScanner`, func `scan`, property `scanCache` |
| `(:Module)` | framework importado: `SwiftUI`, `Foundation` |
| `(:TypeNameRef)` / `(:FunctionNameRef)` | hub por *nombre* para aristas sintácticas |
| `(:Summary {level})` | resúmenes jerárquicos (F5) |

Aristas: `CONTAINS` (file→tipo→miembro), `INHERITS_SYNTACTIC`
(hereda/implementa, por nombre → baja confianza hasta F4),
`EXTENDS_SYNTACTIC`, `IMPORTS`, `CALLS_MENTIONED` (llamada por nombre),
`SUMMARIZES`.

Los nodos `*Ref` son intencionales: como F1 no resuelve tipos, una llamada
a `scan()` apunta a un hub `FunctionNameRef {name:"scan"}` y no a una
función concreta. Cuando llegue F4 (USRs), esas aristas se reemplazan por
aristas exactas símbolo-a-símbolo.

### Loader idempotente

Idempotente = ejecutarlo 2 veces deja el mismo resultado que ejecutarlo 1.
Se logra con `MERGE` (crea si no existe, matchea si existe) sobre `id`
único en vez de `CREATE`. Importancia práctica: podés correr extract+load
después de cada commit sin duplicar nada ni ensuciar el grafo.
El loader además borra el grafo previo (`DETACH DELETE`) porque los ids
incluyen número de línea: si una línea se mueve, el id cambia y quedarían
fantasmas; borrar-y-recargar es lo correcto mientras los ids sean frágiles.

### Queries curadas

Son consultas Cypher ya escritas y probadas para las preguntas frecuentes
("¿quiénes implementan este protocolo?", "¿qué hace este actor?",
"fan-in de este método"), guardadas en `queries/browser-queries.cypher`.
"Curada" = seleccionada y ajustada a mano contra este esquema, en vez de
improvisarla cada vez en el Browser.

### Resúmenes jerárquicos (F5)

Cada nodo del grafo puede tener un `(:Summary)-[:SUMMARIZES]->(nodo)` con
un nivel: `system` → `module` → `file` → `type` → `member`. La idea es que
un agente empiece leyendo arriba (barato, general) y baje solo donde
necesite detalle — en vez de RAG tradicional que busca fragmentos sueltos.
Los drafts se generan determinísticamente desde el grafo (estructura:
miembros, conformancias, imports); el texto fino humano/LLM va en
`summaries/manual.json` y **pisa** al draft en el merge.

### Cómo funciona extract.py por dentro

No hay magia: tree-sitter solo convierte texto en árbol; todo el
conocimiento lo aporta el visitor que escribimos.

1. **Parser**: carga la gramática Swift compilada (`tree_sitter_swift`
   expone un binario C), la envuelve en `Language` y crea `Parser`.
   Cada `.swift` (descubierto con `rglob`) entra como bytes y sale como
   árbol de nodos tipados con posiciones (línea/columna).
2. **Visitor recursivo** (`visit`): camina el árbol llevando contexto —
   archivo actual, tipo contenedor más cercano (`type_ctx`) y miembro
   actual (`member_ctx`). Cada nodo se despacha por su `type`.
3. **Reglas duras aprendidas contra este grammar** (lo que costó los
   probes):
   - Toda declaración de tipo llega como `class_declaration`; el kind real
     está en el token keyword anónimo interno. `protocol_declaration` sí es
     nodo propio.
   - Un miembro es real solo si su padre es `class_body`,
     `enum_class_body`, `protocol_body` o `source_file`. Una
     `property_declaration` bajo `statements` es una variable local de una
     función → se ignora (filtramos 584).
   - `computed_property` anidada dentro de `property_declaration` es la
     misma propiedad → no duplicar.
4. **Identidad determinista**: cada símbolo recibe
   `id = ruta::kind:nombre:línea`. Es único y re-ejecutable, pero frágil a
   movimientos de línea — por eso F4 cambiará a USRs del compilador.
5. **Aristas**: `CONTAINS` (jerarquía), `IMPORTS` (file→framework),
   `INHERITS_SYNTACTIC`/`EXTENDS_SYNTACTIC` (por nombre → hub
   `TypeNameRef`), `CALLS_MENTIONED` (callee detectado sintácticamente;
   solo si ese nombre existe definido en el repo → hub `FunctionNameRef`).
6. **Salida JSONL**: un JSON por línea, desacoplado de Neo4j. El loader
   lee eso; cuando exista F4 agrega campos (USR) sin tocar el esquema.

### GraphRAG / context packs (F6)

`ask.py` implementa el retrieval que usaría un agente:

1. Extrae términos de la pregunta (identificadores CamelCase/snake).
2. Busca *seeds* contra `Symbol.name`, `File.path`, `CodeModule.name` y
   texto de resúmenes, con scoring (exacto > prefijo > contiene).
3. Por seed: trae resúmenes manuales de sus anclas (tipo → archivo →
   módulo), implementaciones si es protocolo/clase, y vecindario k-hop
   tipado.
4. Ensambla un pack markdown dentro de un presupuesto de caracteres
   (`--budget`): sistema → matches → resúmenes → implementaciones →
   vecinos con `file:line`.

Corre 100% en Linux: consulta Neo4j por Bolt, no compila nada.

---

## Troubleshooting (cosas que nos pasaron)

| Síntoma | Causa | Solución |
|---|---|---|
| `docker: command not found` | esta guía usa userspace, no Docker | seguir sección Instalación |
| curl corta a mitad | conexión inestable | repetir con `-C -` (resume) |
| `tar: ... No such file or directory` | faltó `mkdir -p` del destino antes de extraer | crear dirs primero |
| Node has no attribute 'sexp' | py-tree-sitter 0.26 eliminó sexp() | usar `str(node)` |
| GitHub latest = alpha vieja | releases/latest poco confiable en neo4j | usar deployment-center oficial |
| Bash `eval` rompe Cypher | paréntesis interpretados por shell | usar driver Python o cypher-shell directo |
