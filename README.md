# Sidekick

**Give Claude Code a memory. Make it yours.**

Claude Code forgets you every session. Sidekick fixes that — it builds a persistent profile of who you are from how you actually work, not from what you tell it about yourself. Every session, it picks up where it left off.

---

## The difference

**Without Sidekick**
```
You: help me structure this project
Claude: Sure! Here are some general approaches to project structure...
```

**With Sidekick**
```
You: help me structure this project
Claude: The Meta proposal still hasn't been written and it's due Friday.
        Want to do that first, or are we continuing on the build?
```

Claude doesn't ask who you are. It figures it out — and it tells you what actually matters.

---

## How it works

**One-time setup:** `/sidekick setup`

Sidekick reads your recent Claude Code session history (not just your CLAUDE.md — your actual sessions) and builds an initial profile. This file loads automatically into every Claude Code session going forward.

**Automatic sync:** runs at session start via hook

At the start of each new session, Sidekick checks if you've done meaningful work since it last updated (at least one tool call). If yes, it extracts the session content and writes a pending update. When the session opens, Claude reads the pending update, synthesizes what it learned, and surfaces the single most pressing thing with one question.

You'll see:
```
I've got some catching up to do from your last session. Give me a moment...
```

Then Claude opens with the one thing that matters most, and asks what you want to do about it.

---

## Install

```bash
# 1. Copy the skill to your Claude Code skills folder
cp -r sidekick ~/.claude/skills/

# 2. Start Claude Code in any project and run:
/sidekick setup
```

Setup reads your recent session history, builds your initial profile, adds it to your global CLAUDE.md, and installs the SessionStart hook. Takes about 1-3 minutes.

---

## What gets tracked

```
## What I know about you   — behavioral observations, tensions, patterns
## Active right now        — specific projects, states, deadlines
## How you work best       — flow conditions vs. what stalls you
## Corrections             — yours to edit, never overwritten by sync
```

Sidekick never asks you to describe yourself. Everything is observed, not reported. The gap between what you say you do and what you actually do — that's where the value is.

---

## Commands

| Command | What it does |
|---|---|
| `/sidekick setup` | First-time setup |
| `/sidekick view` | See your current profile |
| `/sidekick reset` | Wipe and start fresh |

Sync is automatic — no command needed.

---

## Architecture

```
SessionStart hook
  └── sync.sh
        ├── finds sessions newer than last sync with ≥1 tool call
        ├── extracts text content (capped at 6K chars)
        └── writes ~/.claude/sidekick_pending.txt

Session opens
  └── Claude reads sidekick.md (loaded via CLAUDE.md import)
        ├── checks for sidekick_pending.txt
        ├── synthesizes update if pending file exists
        └── surfaces one thing, asks one question
```

No separate API key required. Sync uses your existing Claude Code auth via the session. Profile lives as a plaintext file on your machine — nothing is sent anywhere.

---

## Token cost

- Loading sidekick.md every session: ~3,500–4,000 tokens (~1–2 cents at Sonnet pricing)
- Sync only fires when you had a real working session (at least one tool call)
- Profile has a hard 250-line limit to keep context cost predictable

---

## Why not just write a better CLAUDE.md?

CLAUDE.md is self-report. It captures who you think you are.

Sidekick captures who you actually are — the preferences you act on, the projects you keep returning to, the gap between what you said was priority and what you actually built. Those two things are different. Sidekick tracks the second one.

---

**Your Claude. Actually yours.**
