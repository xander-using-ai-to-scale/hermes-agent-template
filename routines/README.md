# Routines

Prompt files for scheduled Hermes cron jobs. Each file is the job's prompt; the matching skill is attached with `--skill`, so the prompt only says what to do this run.

| File | Skill | Default schedule (`<TIMEZONE>`) |
|---|---|---|
| `daily-status-brief.md` | `daily-status-brief` | Weekdays 08:00 (`0 8 * * 1-5`) |
| `weekly-report.md` | `weekly-report` | Fridays 16:00 (`0 16 * * 5`) |

`deploy/setup.sh` asks whether to register them (or reads `PM_ROUTINES`), and prints the exact commands when you skip. See the README section "Routines" for the commands and the cost note.

Cron jobs run inside the Hermes gateway: if the gateway is not running, nothing fires.
