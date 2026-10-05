---
name: weekly-report
description: Weekly or monthly project report for the owner.
version: 1.0.0
metadata:
  hermes:
    category: project-management
    tags: [project-management, reporting, weekly, monthly, routine]
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

# Weekly report

A one-page view of the week across every active project: what got done (with evidence), what moved, what is at risk, and what needs a decision next week. The same procedure makes a monthly report when asked ("monthly report", "how did the month go?").

## When to Use

| Situation | Use this skill? |
|---|---|
| The scheduled Friday routine fires | **Yes** |
| The owner asks for a weekly or monthly report | **Yes** (monthly: widen the window) |
| The owner wants today's picture | No — use `daily-status-brief` |

## Inputs

| Input | Required | Source |
|---|---|---|
| Reporting window | Yes | Monday–today for weekly; the calendar month for monthly |
| Project notes, meeting notes, decisions in the window | Yes | `Projects/` in the vault |
| Daily briefs in the window | If present | `Areas/Reports/Daily/` |
| Task status | Yes | `operator.pm_system` |
| Last report | If present | `Areas/Reports/Weekly/` or `Monthly/` |

## Procedure

1. Set the window and list the project notes, meeting notes and decision notes updated inside it.
2. For each active project, record: status (On track / At risk / Blocked / Complete), what was completed **with evidence** (a file, a record, an approval), what is next, and who owns it.
3. Collect decisions made in the window (from `Decisions/` folders) and decisions still needed.
4. Compare with the last report: projects that changed status, slipped dates, new projects, closed projects.
5. Write the report from `Templates/Weekly Report.md`. Keep it to one screen; link to notes for detail.
6. Save it as a new note: `Areas/Reports/Weekly/YYYY-Www.md` (ISO week) or `Areas/Reports/Monthly/YYYY-MM.md`.

## Output format

Follow `Templates/Weekly Report.md`:

```
Week YYYY-Www (YYYY-MM-DD to YYYY-MM-DD)
Headline: <one sentence: the thing that matters most>
Projects: | Project | Status | Done (evidence) | Next | Owner |
Decisions made: ...
Decisions needed (from whom, by when): ...
Risks and blockers: ...
Next week's focus: 3 bullets
```

## Approval gates

- Read-and-report. The only write is the new report note.
- Status changes, task edits and messages to stakeholders are proposals in the report, applied later only with the owner's approval.
- Sharing the report outside the owner is the owner's call; draft the message if asked.

## Pitfalls

- "Done" without evidence. If you cannot point to the artifact or record, it is "reported done", not "done".
- Rewriting history: a project that slipped shows the slip and the new date, not just the new date.
- Monthly reports that are four weekly reports glued together. Summarise trends instead.

## Verification

- The report note exists at the expected path with the correct week or month.
- Every project with an active status appears exactly once.
- Each "Done" line has evidence or is marked "reported".
