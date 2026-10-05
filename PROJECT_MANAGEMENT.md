# Project Management Playbook

Company-neutral operating procedure for a Hermes PM agent. Customize the system names and cadence before use.

This is the human-readable playbook. The agent runs it through the skills in `skills/project-management/`, each of which turns one section below into a step-by-step procedure with inputs, an output format, approval gates and verification:

| Playbook section | Skill |
|---|---|
| 1–3. Intake, check before creating, plan | `project-intake` |
| 4. Track and maintain (daily view) | `daily-status-brief` |
| 4. Blockers and slipping dates | `blocker-escalation` |
| 5. Meeting and conversation follow-up | `meeting-follow-up` |
| 6. Status reporting | `weekly-report` (weekly or monthly) |
| 7. Project closeout | `project-closeout` |

Change the playbook and the matching skill together, so the agent and the humans follow the same process.

## 1. Work intake

→ Skill: `project-intake`

For each request capture, as available:

- Project or outcome
- Requester and accountable owner
- Deliverable and acceptance criteria
- Priority and deadline (including timezone)
- Dependencies, constraints, and risks
- Approval required and who can grant it
- Evidence source and target system of record

If details are missing, use low-risk assumptions only when reversible; label them. Ask a focused question if the ambiguity changes scope, ownership, timing, cost, permissions, privacy, legal exposure, or external commitments.

## 2. Check before creating

Search the chosen project system and durable knowledge for an existing project, task, decision, or duplicate. Confirm the record is current and relevant. Do not treat an old note as current status without checking the designated live tracker.

## 3. Plan work

Create a small set of outcome-oriented deliverables. Break them into actions that have:

- One accountable owner
- A clear verb and concrete result
- Due date or explicit timing, if known
- Dependencies / blockers
- Completion evidence
- Acceptance test

Sequence work where dependencies matter. Mark unknown owners or dates as unassigned / TBD rather than fabricating them. Identify the critical path and the smallest unblock needed.

## 4. Track and maintain

Use exactly one approved execution tracker for task status. Keep durable decisions, requirements, and reusable knowledge in the approved documentation repository. The two layers should link to each other when practical, not maintain competing task state.

Use only the organization's configured status vocabulary. A status update should be supported by evidence (artifact, system record, approval, or explicit owner report). Record blocker owner and next review point. Do not close work until its acceptance test passes.

Before any write, check the target, fields, and scope. For consequential or externally visible writes, preview and obtain approval when required by the organization's policy.

## 5. Meeting and conversation follow-up

→ Skill: `meeting-follow-up`

When authorized to process a transcript or conversation:

1. Identify decisions, action items, owners, dates, blockers, and unresolved questions.
2. Distinguish an explicit commitment from a suggestion or discussion.
3. Verify names and project context against trusted records; flag ambiguity rather than guessing.
4. File durable decisions in the appropriate knowledge location and tasks in the execution tracker.
5. Deduplicate against existing records before creating new ones.
6. Verify saved updates and provide a concise change summary.

Do not treat attendance, a calendar booking, or a transcript mention as proof that work was completed. Do not expose unrelated personal or confidential content.

## 6. Status reporting

→ Skills: `daily-status-brief` (daily), `weekly-report` (weekly or monthly), `blocker-escalation` (anything blocked)

A useful report answers:

- What outcome matters now?
- What is complete, with evidence?
- What is in progress, and who owns it?
- What is at risk or blocked, why, and by whom?
- What decision or approval is needed, from whom, by when?
- What is the next action and acceptance test?

Keep routine reports brief. Escalate material changes to scope, deadline, cost, capacity, quality, privacy, legal risk, customer experience, or reputation.

## 7. Project closeout

→ Skill: `project-closeout`

Close only after deliverables pass acceptance criteria and the record is verified. Capture final links, unresolved follow-up, lessons worth reusing, and the closure decision. Archive according to the organization's retention rules; do not delete material records without explicit authorization.

## 8. Review checklist

- [ ] Existing work checked; no duplicate tracker created.
- [ ] Outcome and acceptance criteria are explicit.
- [ ] Every active action has an owner or is visibly unassigned.
- [ ] Dates, dependencies, and blockers are evidence-based.
- [ ] Approval boundaries respected.
- [ ] Records saved to the correct system and verified.
- [ ] Final report states evidence, risk, approval needs, and next step.
- [ ] No credentials, customer personal data, or unrelated confidential content copied into reusable documentation.

## Integration notes

This playbook does not assume a PM platform or tool connector. By default the agent's vault (`vault-template/`, a PARA structure) is the system of record. To use another PM platform, connect it as an MCP server (see README, "Connecting your PM system"), configure least-privilege access, document approved operations, and test reads before writes. Keep secrets in the deployment's approved secret store and out of prompts, logs, and version control.
