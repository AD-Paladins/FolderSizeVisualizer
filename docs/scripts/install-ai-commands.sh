#!/bin/bash
set -euo pipefail

# ==========================================
# SDD command configuration
# ==========================================
CMD_NAME="sdd-new"
CMD_DESC="Start a new Spec-Driven Development session for a feature"
CMD_PROMPT="Start a new SDD session. Ask me: (1) the feature name in kebab-case, (2) one sentence describing the problem it solves, (3) whether it involves SwiftUI ↔ UIKit bridge work. Then scaffold the full spec folder under docs/knowledge/specs/<feature-name>/ with SPEC.md, DESIGN.md, TASKS.md, TESTS.md, and depends-on.md using the templates defined in docs/knowledge/workflows/sdd.md. Finally, add a stub row for this feature to the Specs table in docs/knowledge/index.md and tell me the next steps."

# ==========================================
# Installation functions
# ==========================================

install_opencode() {
    echo "Installing command for OpenCode..."

    # OpenCode searches in order: local config (opencode.json in the project)
    # and markdown files in .opencode/commands/ (filename = command name)
    # We use the markdown approach because it is simpler to generate/edit than modifying an existing JSON.

    local CMD_DIR=".opencode/commands"
    mkdir -p "$CMD_DIR"

    cat > "$CMD_DIR/${CMD_NAME}.md" <<EOF
---
description: ${CMD_DESC}
---
${CMD_PROMPT}
EOF

    echo "✅ Installed for OpenCode -> ${CMD_DIR}/${CMD_NAME}.md"
    echo "   Use it in the TUI with: /${CMD_NAME}"
}

install_claude() {
    echo "Installing command for Claude Code..."

    # Current recommended format: .claude/skills/<name>/SKILL.md
    # (the legacy format .claude/commands/<name>.md still works,
    # but skills/ also allows autonomous invocation by Claude)

    local SKILL_DIR=".claude/skills/${CMD_NAME}"
    mkdir -p "$SKILL_DIR"

    cat > "$SKILL_DIR/SKILL.md" <<EOF
---
description: ${CMD_DESC}
---
${CMD_PROMPT}
EOF

    echo "✅ Installed for Claude Code -> ${SKILL_DIR}/SKILL.md"
    echo "   Use it in the session with: /${CMD_NAME}"
}

# ==========================================
# Selection based on argument
# ==========================================

usage() {
    echo "Usage: $0 [opencode|claude|all]"
    echo ""
    echo "  opencode  Installs the command only for OpenCode (current project)"
    echo "  claude    Installs the command only for Claude Code (current project)"
    echo "  all       Installs for both"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

case "$1" in
    opencode)
        install_opencode
        ;;
    claude)
        install_claude
        ;;
    all)
        install_opencode
        install_claude
        ;;
    *)
        usage
        ;;
esac

echo "------------------------------------------------"
echo "🎉 Done."