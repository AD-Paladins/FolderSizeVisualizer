---
name: codegraph-first
description: "Trigger: find definition, locate symbol, where is type/class/actor/protocol/function defined, navigate FolderSizeVisualizer, before grep or rg for symbols. Query the local Neo4j code graph first."
license: Apache-2.0
metadata:
  author: "andres"
  version: "1.0"
---

# CodeGraph-First Navigation

## Activation Contract

Load when working in the FolderSizeVisualizer repo and about to search WHERE a symbol lives (struct, class, enum, actor, protocol, extension, function, property, initializer) or what surrounds it. Fires before ANY grep/glob for a symbol name.

## Hard Rules

- Symbol-definition lookups go to the Neo4j graph FIRST. Grep is the fallback, never the default.
- Take `file` and `line` verbatim from graph rows; never reconstruct paths from memory.
- After editing `.swift` files, refresh the graph before trusting locations again (step 4).
- Grep IS correct for: comments, string literals, UI copy, config keys — anything that is not a declaration.
- If the graph answers nothing, say so explicitly; do not silently switch to grep.

## Decision Gates

| Need | Tool |
|---|---|
| Where is X defined, its kind + line | ask.py or direct Cypher |
| Context pack around a topic for reasoning | ask.py |
| Precise cross-file callers/references | Not available yet (F4 pending); graph gives name-based hints only |
| Non-symbol text (comments, literals) | grep/rg |

## Execution Steps

1. Quick context pack:
   `~/Developer/ios/codegraph/.venv/bin/python ~/Developer/ios/codegraph/extractor/ask.py "question" --budget 4000`
2. Exact symbol lookup:
   ```
   ~/Developer/ios/codegraph/.venv/bin/python - <<'EOF'
   from neo4j import GraphDatabase
   d = GraphDatabase.driver("bolt://127.0.0.1:7687", auth=("neo4j", "codegraph-dev"))
   with d.session() as s:
       q = ("MATCH (f:File)-[:CONTAINS]->(s:Symbol {name:$n}) "
            "RETURN s.kind AS kind, f.path AS file, s.line AS line")
       for r in s.run(q, n="FileSystemHelper"):
           print(dict(r))
   d.close()
   EOF
   ```
3. If Bolt refuses connection, start Neo4j per `docs/knowledge/tools/codegraph-setup.md`; do not fall back to grep silently.
4. Refresh after Swift edits (extract → load → summaries):
   `extract.py && load.py && summaries/build_summaries.py && summaries/load_summaries.py` (all with the venv python above).

## Output Contract

Report every hit as `kind + file:line` exactly as returned by the graph. State which lookup method you used; if you used grep, justify why the graph could not serve it.

## References

- `docs/knowledge/tools/codegraph-setup.md` — setup, day-to-day commands, glossary, extractor internals.
- `docs/knowledge/state/handoff-2026-08-25.md` — current pipeline status and next steps.
