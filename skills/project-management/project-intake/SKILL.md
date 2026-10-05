---
name: project-intake
description: New project or request to scope, dedupe and file.
version: 1.0.0
metadata:
  hermes:
    category: project-management
    tags: [project-management, intake, scoping, planning]
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

# Project intake

Turn a new request ("can we…", "we need to…", "new client wants…") into a scoped project record with an owner, a next action and an acceptance test — without creating a duplicate of work that already exists.

## When to Use

| Situation | Use this skill? |
|---|---|
| Someone asks for new work that will take more than one sitting | **Yes** |
| A meeting or message reveals a new commitment with no project record | **Yes** (after `meeting-follow-up` extracts it) |
| The owner says "add this as a project" / "track this" | **Yes** |
| A one-off question or a five-minute favour | No — just do it |
| An update to a project that already exists | No — update that project note |

## Inputs

| Input | Required | Source |
|---|---|---|
| The request, in the requester's words | Yes | Chat, message, transcript |
| Requester and accountable owner | Yes | Ask if not stated; never assume |
| Desired outcome and acceptance criteria | Yes | Ask one focused question if missing |
| Deadline (with timezone) | If known | Request, or mark `TBD` |
| Dependencies, constraints, approvals needed | If known | Request, existing records |
| Vault path | Yes | `operator.vault_path` (skill config) |

## Procedure

1. **Restate** the request in one sentence: outcome, requester, deadline.
2. **Check before creating.** Search `Projects/` and `Archive/` in the vault (`search_files` on the key nouns), and the PM system if one is connected. If a matching project exists, stop and propose an update to it instead.
3. **Fill the gaps.** Capture owner, outcome, acceptance criteria, deadline, dependencies, risks and the approval needed. If a gap changes scope, owner, timing, cost, permissions, privacy or external commitments, ask one focused question. Otherwise make a labelled, reversible assumption.
4. **Plan.** Break the work into 3–7 actions. Each action has one owner (or visibly `Unassigned`), a verb and a concrete result, a due date or `TBD`, and its completion evidence. Mark the critical path.
5. **Draft the project note** from `Templates/Project.md` at `Projects/<Project Name>/<Project Name>.md`. Show the draft to the owner.
6. **After approval,** write the note. If the PM system is connected, propose the matching tasks there as a separate approval step.
7. **Verify** by reading the saved note back, then report.

## Output format

```
Intake: <Project Name>
Outcome: <one sentence> · Owner: <name> · Due: <YYYY-MM-DD or TBD>
Acceptance test: <how we will know it is done>
Plan:
- [ ] <action> — <owner> — <due>
Assumptions: <labelled, or "none">
Needs from you: <the one decision or approval, or "nothing">
```

## Approval gates

- **Draft → owner approves → write.** Show the project note before saving it.
- Creating tasks or projects in an external PM system is a separate approval.
- Never assign work to a person who has not agreed to it; list it as proposed.

## Pitfalls

- Duplicates: an old project with a slightly different name. Search by client, deliverable and owner, not just title.
- Fabricated dates or owners. `TBD` and `Unassigned` are honest; invented values are not.
- Over-planning. Seven actions is plenty; detail belongs in the work, not the intake.

## Verification

- The note exists at the expected path and its frontmatter has `status`, `owner`, `due` and `updated`.
- Every action has an owner or says `Unassigned`.
- The report you gave matches what was saved.
