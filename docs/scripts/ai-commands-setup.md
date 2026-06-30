# AI Commands Setup

Installs custom slash commands for AI coding tools in this project.

## Requirements

- Bash
- The script [`install-ai-commands.sh`](../install-ai-commands.sh) in the project root

## Usage

```bash
# Grant execution permissions
chmod +x install-ai-commands.sh

# Install only for OpenCode
./install-ai-commands.sh opencode

# Install only for Claude Code
./install-ai-commands.sh claude

# Install for both
./install-ai-commands.sh all
```

## What it installs

| Command | Tool | Location |
|---|---|---|
| `/sdd-new` | OpenCode | `.opencode/commands/sdd-new.md` |
| `/sdd-new` | Claude Code | `.claude/skills/sdd-new/SKILL.md` |

Starts a new Spec-Driven Development session. Run `/sdd-new` inside the AI tool after installation.
