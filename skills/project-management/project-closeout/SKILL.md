---
name: project-closeout
description: Close a finished project, verify, archive, log lessons.
version: 1.0.0
metadata:
  hermes:
    category: project-management
    tags: [project-management, closeout, archive, retrospective]
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

# Project closeout

Close a project only when its acceptance test passes: confirm the evidence, capture what is still open and what is worth reusing, then move the project from `Projects/` to `Archive/`.

## When to Use

| Situation | Use this skill? |
|---|---|
| "This is done" / "close it out" / "wrap up <project>" | **Yes** |
| All actions in a project note are ticked | **Yes** — propose closing it |
| A project is cancelled or paused indefinitely | **Yes** — close with the reason, no acceptance test needed |
| One milestone is finished but the project continues | No — update the project note |

## Inputs

| Input | Required | Source |
|---|---|---|
| Project note | Yes | `Projects/<Project>/<Project>.md` |
| Acceptance criteria and evidence | Yes | Project note; ask the owner for missing evidence |
| Open tasks | Yes | Project note and `operator.pm_system` |
| Closure decision | Yes | The owner |

## Procedure

1. Read the project note, its meetings and decisions.
2. Check each acceptance criterion against evidence (a delivered file, a record, an approval). List any criterion without evidence.
3. List loose ends: open actions, unresolved questions, follow-ups owed to others. For each, propose: finish, hand over (to whom), or drop (with reason).
4. Draft a **Closeout** section for the project note: final status (Complete / Cancelled), date, evidence links, loose-end dispositions, and 1–3 lessons worth reusing.
5. Show the owner the draft and the proposed move.
6. **After approval:** append the Closeout section, set `status: Complete` (or `Cancelled`), move `Projects/<Project>/` to `Archive/<Project>/` (write the files to the new path, then ask the owner to delete the old folder — you cannot delete files), and if a PM system is connected, propose closing its tasks as a separate approval.
7. If a lesson is reusable across projects, propose adding it to `Resources/Lessons.md`.

## Output format

```
Closeout: <Project> — <Complete | Cancelled> — YYYY-MM-DD
Acceptance: <n>/<n> criteria with evidence (missing: ...)
Loose ends: <item> → <finish | hand over to X | drop: reason>
Lessons: <1–3 bullets>
Proposed writes: <files, move, PM changes>
```

## Approval gates

- **Draft → owner approves → write.** Closing is a decision only the owner makes.
- Never delete records. Archiving is a copy-then-owner-deletes move.
- Closing tasks in an external PM system is its own approval.

## Pitfalls

- Closing on "it's basically done". Missing evidence goes in the report, and the owner decides.
- Losing loose ends: every open item gets an explicit disposition.
- Lessons that are complaints. Write them as reusable practice ("Confirm X before Y").

## Verification

- `Archive/<Project>/<Project>.md` exists, has the Closeout section and `status: Complete` or `Cancelled`.
- Links from other notes (reports, decisions) still resolve or are updated.
- The owner has been told which old folder to delete.
