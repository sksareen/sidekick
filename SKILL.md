---
name: sidekick
description: Use for /sidekick setup, /sidekick view, or /sidekick reset — manages persistent cross-session memory and identity so Claude knows who you are across every session.
---

## Overview

Sidekick gives Claude persistent memory. It builds a living profile of the user from observed behavior across sessions — not self-report. The profile loads automatically every time Claude Code starts.

---

## /sidekick setup

Run once. Do all steps in order. Ask for confirmation before modifying any existing files.

### Step 1: Choose memory location
Ask the user: "Where should I store your Sidekick profile? Default is ~/.claude/sidekick.md — press enter to confirm or give me a path."
Resolve the full absolute path (expand ~ to the actual home directory).
Write that absolute path to `~/.claude/sidekick_config` (a single line, no quotes).

### Step 2: Build the initial profile
Read the following in order — most current first:

**Session history (most important — reflects real current state):**
- List all directories in ~/.claude/projects/
- Find the 5 most recently modified .jsonl files across all project directories
- Read them to understand what the user has actually been working on

**Then read static files for background:**
- ~/.claude/CLAUDE.md (global preferences)
- Any CLAUDE.md in the current working directory

Then write the initial sidekick.md to the chosen path using the template below.

**Critical:** Do NOT restate what's in CLAUDE.md. Go one layer deeper:
- What does the gap between stated priorities and actual behavior suggest?
- What tensions or contradictions are visible?
- What would this person not think to write about themselves but is clearly true?

Write in short, direct prose — not bullet points. Write things that would make the user think "that's true and I didn't tell it that."

### Step 3: Add sidekick.md to global CLAUDE.md
Read ~/.claude/CLAUDE.md. Show the user the line you're about to add:
```
@/absolute/path/to/sidekick.md
```
Make a backup at ~/.claude/CLAUDE.md.bak. Add the line at the very end. Only after user confirms.

### Step 4: Install the sync hook
Read ~/.claude/settings.json (create if missing with `{}`).
Add the SessionStart hook — show user before writing:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash /Users/USERNAME/.claude/skills/sidekick/sync.sh"
          }
        ]
      }
    ]
  }
}
```
Use the actual absolute path to sync.sh (expand ~). If hooks already exist, merge carefully.

### Step 5: Create timestamp file
Write a Unix timestamp for 7 days ago to ~/.claude/sidekick_last_sync so the first sync picks up a full week of real sessions.
- macOS: `date -v-7d +%s > ~/.claude/sidekick_last_sync`
- Linux: `date -d '7 days ago' +%s > ~/.claude/sidekick_last_sync`

### Step 6: Confirm
Tell the user: "You're set up. I'll update my memory of you automatically at the start of each session. Run /sidekick view anytime to see what I know."

---

## /sidekick view

Read the path from ~/.claude/sidekick_config (fallback: ~/.claude/sidekick.md).
Read sidekick.md and present only the user-facing sections: "What I know about you", "Active right now", "How you work best", and "Corrections".
Skip any instruction sections. Narrate it conversationally — don't dump the markdown.

---

## /sidekick reset

Warn the user: "This will wipe everything I've learned about you and start fresh. Your CLAUDE.md and settings stay intact. Are you sure?"

If confirmed:
- Overwrite sidekick.md with the blank template below
- Reset ~/.claude/sidekick_last_sync to current timestamp
- Delete ~/.claude/sidekick_pending.txt if it exists

---

## sidekick.md Template

```markdown
# Sidekick

<!-- Auto-maintained by Sidekick. Sync runs at session start. -->
<!-- Last synced: TIMESTAMP -->

## What I know about you

[2-4 short paragraphs of genuine insight — things inferred, not restated.
Second person, direct prose. At least one tension or contradiction if visible.
No bullet points.]

## Active right now

[3-5 lines max. Specific projects, states, deadlines, commitments.]

## How you work best

[2-3 lines. Specific conditions for flow vs. what stalls you.]

## Corrections

<!-- User-editable. Things I got wrong or should never infer again. -->
<!-- Sync never overwrites this section. -->
```

---

## How to behave when sidekick.md is loaded

You are an executive assistant, not a briefing document.

**At the start of every session:**
1. Check if `~/.claude/sidekick_pending.txt` exists
2. If it does: read it, silently update sidekick.md (observe don't restate, preserve ## Corrections, update Active right now), delete the pending file
3. Surface ONE thing — the most pressing item — and ask a single question. Stop.

Do not summarize the profile. Do not list everything. One thing, one question, wait for a response.

If the profile is more than 5 days old: "My picture of you is from [date] — what's changed?"

**Mid-session:** If the user shares something significant (new project, priority shift, life update), update sidekick.md immediately without being asked. Say: "Noted." That's it.

**Profile rules:**
- Never restate what's already in CLAUDE.md — that's self-report
- ## Corrections is sacred — never modify it during any update
- Keep under 250 lines — compress aggressively when approaching the limit
- CLAUDE.md preferences take priority; sidekick records observed behavior
