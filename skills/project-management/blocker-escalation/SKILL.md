---
name: blocker-escalation
description: Blocked or slipping work that needs an owner decision.
version: 1.0.0
metadata:
  hermes:
    category: project-management
    tags: [project-management, blockers, escalation, risk]
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

# Blocker escalation

When work is blocked or about to miss a date, put one clear decision in front of the right person: what is stuck, why, what it costs to wait, the options, and your recommendation.

## When to Use

| Situation | Use this skill? |
|---|---|
| An action is overdue or will miss its due date | **Yes** |
| Work waits on a person, approval, access or budget | **Yes** |
| The daily brief or weekly report flags something At risk / Blocked | **Yes** — for the top items |
| A small delay with no effect on the outcome | No — note it in the project, no escalation |

## Inputs

| Input | Required | Source |
|---|---|---|
| The blocked item and its project | Yes | Project note or PM system |
| What it waits on, and since when | Yes | Project note, meeting notes, or ask |
| Impact of waiting (dates, cost, quality, client) | Yes | Project plan; estimate and label it |
| Who can unblock it | Yes | Owner or the named dependency |

## Procedure

1. State the blocker in one line: what is stuck, on whom or what, since when.
2. Check it is real: read the latest note, meeting and PM status. A blocker that was cleared yesterday is not escalated.
3. Size the impact: which dates move and by how much, what it costs, who notices. Label estimates as estimates.
4. Find the **smallest unblock**: the one decision, approval, access grant or answer that releases the work.
5. Give 2–3 options with trade-offs, and your recommendation.
6. Draft the escalation for the owner (and, if asked, a message the owner can send to the person who can unblock it).
7. **After approval,** record the escalation in the project note (`Blocked` status, date, waiting on, next review date). Send nothing yourself.
8. On the next review date, check again and close or re-escalate.

## Output format

```
Blocked: <item> (<project>) — waiting on <who/what> since YYYY-MM-DD
Impact: <dates / cost / client effect>  (estimate where labelled)
Smallest unblock: <one decision or action> — from <who> — by <date>
Options: 1) ... 2) ... 3) ...
Recommendation: <option and why>
```

## Approval gates

- **Draft → owner approves → write.** The owner decides whether and to whom it is escalated.
- Messages to people other than the owner are drafts for the owner to send.
- Never commit budget, dates or scope changes on the owner's behalf.

## Pitfalls

- Escalating everything. Escalate what changes an outcome; note the rest.
- Vague asks ("thoughts?"). Ask for one decision with a deadline.
- Blame. Describe the dependency, not the person's failings.

## Verification

- The project note shows `Blocked`, the waiting-on line and a next review date.
- The escalation names one decision, one person and one date.
- On the review date, the item is either cleared or re-escalated, never silently left.
