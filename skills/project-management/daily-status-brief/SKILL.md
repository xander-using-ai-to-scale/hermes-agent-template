---
name: daily-status-brief
description: Daily status brief across active projects and blockers.
version: 1.0.0
metadata:
  hermes:
    category: project-management
    tags: [project-management, status, daily, briefing, routine]
    config:
      - key: operator.vault_path
        description: Absolute path to the Operator's PARA vault
        default: "~/operator-vault"
        prompt: Path to the Operator vault
      - key: operator.pm_system
        description: System of record for task status
        default: "the vault"
        prompt: Which system holds task status?
---

# Daily status brief

A short morning read for the owner: what changed, what is due, what is at risk, and the one or two decisions only they can make. It runs as a scheduled routine (`routines/daily-status-brief.md`) or on request ("what's on today?", "status?").

## When to Use

| Situation | Use this skill? |
|---|---|
| The scheduled weekday routine fires | **Yes** |
| The owner asks for today's status or "where are we?" | **Yes** |
| The owner asks about one project only | No — read that project note and answer directly |
| End of week summary | No — use `weekly-report` |

## Inputs

| Input | Required | Source |
|---|---|---|
| Active project notes | Yes | `Projects/*/` in the vault (`operator.vault_path`) |
| Task status | Yes | `operator.pm_system` (the vault itself, or a connected PM tool) |
| Yesterday's brief | If present | `Areas/Reports/Daily/` — for "what changed" |
| Today's date | Yes | The system prompt clock (timezone from config) |

## Procedure

1. List active projects: every `Projects/<Project>/<Project>.md` whose `status` is not `Complete`.
2. For each, read the frontmatter and the open actions. If a PM system is connected, read task status from it; it wins over the vault for task state.
3. Compare with the most recent brief in `Areas/Reports/Daily/` to find what changed.
4. Sort items into: **Due today / overdue**, **At risk or blocked**, **Changed since last brief**, **Waiting on others**.
5. Pick the decisions that only the owner can make (at most three).
6. Write the brief in the format below. Keep it under about 250 words; link to project notes instead of repeating them.
7. Save it as a new note `Areas/Reports/Daily/YYYY-MM-DD.md`. Do not edit other notes during a brief.

## Output format

```
Daily brief — YYYY-MM-DD
Decisions for you: <1–3 items, or "none">
Due today / overdue:
- <project> — <action> — <owner> — <due>
At risk / blocked:
- <project> — <why> — <smallest unblock> — <who>
Changed since last brief: <short bullets>
Waiting on others: <who owes what, since when>
```

## Approval gates

- The brief is read-and-report. Its only write is its own new note under `Areas/Reports/Daily/`.
- It never changes task status, sends messages, or edits project notes. It proposes those changes; the owner approves them in a normal session.
- Run unattended (cron), it cannot ask for approval, so anything that needs one is listed under "Decisions for you".

## Pitfalls

- Reporting stale status as current. Say where each status came from and how old it is when older than a day.
- Padding. If nothing changed, say so in one line.
- Treating a calendar invite or a transcript mention as proof of progress.

## Verification

- The note exists at `Areas/Reports/Daily/YYYY-MM-DD.md` with today's date.
- Every overdue item names an owner.
- No file other than the new brief changed (check the checkpoint list if unsure).
