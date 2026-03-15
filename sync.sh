#!/bin/bash
# Sidekick sync — runs at SessionStart via Claude Code hook
# Extracts recent session content to a pending file.
# Claude reads the pending file at session start and synthesizes the update.

CONFIG_FILE="$HOME/.claude/sidekick_config"
TIMESTAMP_FILE="$HOME/.claude/sidekick_last_sync"
PENDING_FILE="$HOME/.claude/sidekick_pending.txt"
PROJECTS_DIR="$HOME/.claude/projects"

# Load path from config file
if [ -f "$CONFIG_FILE" ]; then
  SIDEKICK_FILE=$(cat "$CONFIG_FILE")
else
  SIDEKICK_FILE="$HOME/.claude/sidekick.md"
fi

# Exit silently if sidekick.md doesn't exist (not set up yet)
[ -f "$SIDEKICK_FILE" ] || exit 0

# Create timestamp file if missing
if [ ! -f "$TIMESTAMP_FILE" ]; then
  date +%s > "$TIMESTAMP_FILE"
  exit 0
fi

# Find session files newer than last sync with at least 1 tool call
NEW_SESSIONS=()
while IFS= read -r -d '' file; do
  if grep -q '"tool_use"' "$file" 2>/dev/null; then
    NEW_SESSIONS+=("$file")
  fi
done < <(find "$PROJECTS_DIR" -name "*.jsonl" -newer "$TIMESTAMP_FILE" -print0 2>/dev/null)

# Nothing substantial — exit silently
[ ${#NEW_SESSIONS[@]} -eq 0 ] && exit 0

# Extract readable text from sessions (cap at 6000 chars to control token cost)
SESSION_CONTENT=$(python3 - "${NEW_SESSIONS[@]}" <<'PYEOF'
import json, sys

files = sys.argv[1:]
chunks = []
total_chars = 0
CHAR_LIMIT = 6000

for filepath in files:
    try:
        with open(filepath) as f:
            lines = f.readlines()

        session_chunks = []
        for line in lines:
            if total_chars >= CHAR_LIMIT:
                break
            try:
                obj = json.loads(line.strip())
                msg_type = obj.get('type')

                if msg_type == 'user':
                    msg = obj.get('message', {})
                    for block in msg.get('content', []):
                        if isinstance(block, dict) and block.get('type') == 'text':
                            text = block.get('text', '').strip()
                            if text:
                                session_chunks.append(f"USER: {text[:300]}")
                                total_chars += len(text[:300])

                elif msg_type == 'assistant':
                    msg = obj.get('message', {})
                    for block in msg.get('content', []):
                        if isinstance(block, dict):
                            if block.get('type') == 'text':
                                text = block.get('text', '').strip()
                                if text:
                                    session_chunks.append(f"CLAUDE: {text[:200]}")
                                    total_chars += len(text[:200])
                            elif block.get('type') == 'tool_use':
                                session_chunks.append(f"[used: {block.get('name', '?')}]")
            except:
                pass

        if session_chunks:
            chunks.append("--- session ---\n" + "\n".join(session_chunks))
    except:
        pass

print("\n".join(chunks))
PYEOF
)

# Nothing extracted — exit silently
[ -z "$SESSION_CONTENT" ] && exit 0

# Write pending file for Claude to pick up and synthesize at session start
cat > "$PENDING_FILE" << PENDING
SIDEKICK_PENDING_UPDATE
Sessions to learn from: ${#NEW_SESSIONS[@]}

$SESSION_CONTENT
PENDING

# Bump timestamp so we don't re-read these sessions next time
date +%s > "$TIMESTAMP_FILE"

# Brief message — Claude handles the EA-style opener after synthesizing
echo "I've got some catching up to do from your last session. Give me a moment..."
