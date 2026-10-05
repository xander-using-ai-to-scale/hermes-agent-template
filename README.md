# The Operator — Project Management Agent Template

A deployable, company-neutral template for a [Hermes Agent](https://github.com/NousResearch/hermes-agent) project-management agent ("the Operator"). It keeps a PARA notes vault, turns requests and meetings into owned actions, and writes a daily status brief and a weekly report. It contains an operating style, skills, a config, scheduled routines and a setup script, and no company's data, credentials or history.

**Built and checked against Hermes Agent v0.21.5 (release tag `v2026.9.24`).** `deploy/setup.sh` installs exactly that version.

## Quick start (about 10 minutes, Linux)

```bash
git clone <this-repo-url> ~/operator-agent && cd ~/operator-agent
mkdir -p ~/.operator && cp agent.example.env ~/.operator/agent.env && chmod 600 ~/.operator/agent.env
nano ~/.operator/agent.env        # owner, org, timezone, OpenRouter key, model id
./deploy/setup.sh                 # installs Hermes, configures everything, starts the gateway
hermes                            # talk to the agent
```

`setup.sh` asks one question: whether to schedule the daily brief and weekly report now. [INSTALL.md](INSTALL.md) walks through every step and the checks to run afterwards.

## Layout

| Path | What it is |
|---|---|
| `SOUL.md` | The agent's identity, principles and authority limits. Installed as `~/.hermes/SOUL.md` with your placeholders filled in. |
| `PROJECT_MANAGEMENT.md` | The human-readable PM playbook. Each section maps to a skill. |
| `skills/project-management/` | Six Hermes skills: `project-intake`, `daily-status-brief`, `meeting-follow-up`, `weekly-report`, `project-closeout`, `blocker-escalation`. |
| `hermes/config.template.yaml` | The Hermes config, rendered to `~/.hermes/config.yaml`. No secrets. |
| `agent.example.env` | Every setting `setup.sh` reads. Copy to `~/.operator/agent.env`. |
| `routines/` | Prompt files for the scheduled daily brief and weekly report. |
| `vault-template/` | The PARA vault (`Projects/`, `Areas/`, `Resources/`, `Archive/`) plus note templates: project, meeting note, decision, weekly report. |
| `examples/sample-vault/` | Fictional, read-only data for testing the skills. |
| `deploy/setup.sh` | Idempotent installer and updater. |
| `INSTALL.md` | Step-by-step install and verification. |

Where things land on the machine: Hermes in `~/.hermes/` (config, `.env`, `SOUL.md`, memory, cron jobs, logs); your settings in `~/.operator/`; the vault in `VAULT_DIR` (default `~/operator-vault`). The skills are not copied: `skills.external_dirs` points Hermes at this repo's `skills/` folder.

## Tool permissions (defaults)

| Toolset | Default | Why |
|---|---|---|
| `file` (read, write, patch, search) | **On, writes confined to the vault** | The vault is the agent's working area: project pages, meeting notes, decisions, reports. `setup.sh` sets `HERMES_WRITE_SAFE_ROOT` to `VAULT_DIR`, so Hermes hard-blocks `write_file` and `patch` anywhere else, including its own config. Reads are not confined. Checkpoints are on, so `/rollback` undoes a bad write. |
| `terminal`, `code_execution` | **Off** | A shell or code runner can do anything the OS user can. To opt in, set `OPERATOR_ENABLE_SHELL=true` in `agent.env` and re-run `setup.sh`. Approvals stay in manual mode, so flagged commands still ask first. |
| `browser`, `computer_use` | Off | They would drive this machine's browser and desktop. |
| `cronjob` | Off | Only the owner schedules jobs, with `hermes cron`. |
| `delegation`, `image_gen`, `video_gen`, `tts` | Off | Not needed for PM work; delegation multiplies cost out of the owner's sight. |
| `memory`, `skills`, `web`, `todo`, `clarify`, `session_search`, `vision` | On | Normal assistant work. Edits to skills are staged for owner approval (`skills.write_approval: true`). |

Set `OPERATOR_FILE_ACCESS=off` for a chat-and-draft-only agent with no file tools. Approvals run in `manual` mode: every flagged action waits for a human, and an unanswered prompt is denied after 5 minutes.

## Routines

Two scheduled jobs, run by the Hermes gateway's built-in scheduler:

| Job | Default schedule (`<TIMEZONE>`) | Skill | Prompt |
|---|---|---|---|
| Operator daily status brief | Weekdays 08:00 · `0 8 * * 1-5` | `daily-status-brief` | `routines/daily-status-brief.md` |
| Operator weekly report | Fridays 16:00 · `0 16 * * 5` | `weekly-report` | `routines/weekly-report.md` |

**Each run is a model call billed to your OpenRouter credits**, so they are only scheduled when the owner says yes. `setup.sh` asks "Schedule the daily status brief and weekly report now? [y/N]" plus the timezone and times. Pre-answer it with `--routines yes|no`, or `PM_ROUTINES`, `PM_DAILY_TIME` and `PM_WEEKLY_TIME` in `agent.env` or the environment. If you skip, it prints the exact commands. They are:

```bash
cd ~/operator-agent
hermes cron create --name "Operator daily status brief" --deliver local --workdir "$HOME/operator-vault" \
  --skill daily-status-brief "0 8 * * 1-5" "$(cat routines/daily-status-brief.md)"
hermes cron create --name "Operator weekly report" --deliver local --workdir "$HOME/operator-vault" \
  --skill weekly-report "0 16 * * 5" "$(cat routines/weekly-report.md)"
```

Schedules use `timezone` from the config. `--deliver local` keeps output on the machine (`hermes cron runs`, `~/.hermes/cron/output/`); with Slack on, `setup.sh` uses `--deliver slack` (the Slack home channel). Manage them with `hermes cron list`, `hermes cron pause <name>`, `hermes cron edit <name> --schedule "…"` and `hermes cron remove <name>`. **Jobs only fire while the gateway is running.**

## Slack is optional and off by default

Out of the box the owner uses the agent through the Orgo desktop (or any terminal) with the `hermes` CLI, and routine output stays local. To add Slack, create a Socket Mode Slack app, then set `OPERATOR_ENABLE_SLACK=true`, `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_ALLOWED_USERS` and `SLACK_HOME_CHANNEL` in `agent.env` and re-run `setup.sh`. `GATEWAY_ALLOW_ALL_USERS=false` is always written, so only the listed members can talk to the agent. See the Hermes messaging docs for creating the Slack app.

## Connecting your PM system

By default the vault is the system of record (`PM_SYSTEM=the vault`). To use a PM tool, add its MCP server in `~/.operator/mcp_servers.yaml`. `setup.sh` appends that file to the rendered config, so re-runs keep it. Do not use `hermes mcp add` on a machine managed by `setup.sh`, because the next run would drop it. Put the token in `agent.env` as `PM_SYSTEM_TOKEN` and reference it, never inline it:

```yaml
mcp_servers:
  pm:
    command: npx
    args: ["-y", "<pm-mcp-package>@<pinned-version>"]
    env:
      PM_API_TOKEN: "${PM_SYSTEM_TOKEN}"
    trust: untrusted        # every write-capable tool call asks the owner first
```

Then set `PM_SYSTEM` to the tool's name, re-run `setup.sh` and check it with `hermes mcp test pm`.

## Deploying on Orgo

Orgo cloud desktops behave differently from a server. These steps come from earlier Hermes installs on Orgo:

1. **Install `cron` and `xz-utils` first.** The Hermes installer needs `xz-utils` to unpack Node.js. `cron` is needed for `--autostart`. Either run `sudo apt-get install -y git curl xz-utils cron procps`, or run `./deploy/setup.sh --install-prereqs`.
2. **There is no systemd**, so the gateway cannot be a service. `setup.sh` detects this and starts `hermes gateway run` in the background: in a `tmux` session called `hermes-gateway` if tmux is installed, otherwise with `nohup` (log: `~/.hermes/logs/gateway.console.log`).
3. **After a reboot the gateway is not running, and no routine fires until it is.** Restart it with:
   ```bash
   cd ~/operator-agent && ./deploy/setup.sh --gateway-only
   ```
   Or run `./deploy/setup.sh --autostart` once to add an `@reboot` crontab line that does this for you. That needs the `cron` daemon running on the desktop.
4. **The owner works on the desktop itself:** open a terminal and run `hermes`. Slack is not required.
5. **Check it:** `hermes cron status` should say the scheduler is alive.

## Upgrading Hermes

`setup.sh` pins one release and refuses to run over a different installed version. To upgrade on purpose:

1. Read the upstream release notes.
2. In `deploy/setup.sh`, update `HERMES_TAG`, `HERMES_COMMIT` (the commit the tag points to) and `HERMES_INSTALLER_SHA256` (the SHA-256 of `scripts/install.sh` at that tag).
3. Run `hermes update` or reinstall, then run `hermes config check` and `./deploy/setup.sh`.

Upstream does not publish a checksum file for the installer, so the pinned SHA-256 is one computed from the tagged `scripts/install.sh`. `setup.sh` refuses to run the installer when the downloaded file does not match it.

## Customization checklist

- [ ] Set the agent's display name and the human decision-maker (`AGENT_NAME`, `OWNER_NAME`, `ORG_NAME` in `agent.env`).
- [ ] Choose one authoritative project/task system and document its status vocabulary (`PM_SYSTEM`; status words in `vault-template/Templates/Project.md`).
- [ ] Define what may be read, drafted, written, sent, or deleted (tool permissions above; approval gates in each skill).
- [ ] Add team-specific intake channels and escalation routes.
- [ ] Add project templates and reporting cadence (`vault-template/Templates/`, routine times).
- [ ] Add approved tool-specific skills only after reviewing their contents and licensing.
- [ ] Decide whether to schedule the routines (each run costs OpenRouter credits).
- [ ] Check the repository for secrets, personal data, and organization-specific material before publishing.

## Security

- Do not put API keys, tokens, passwords, customer information, internal URLs, private business records, or personal contact details in this repository. Use placeholders in documentation and configure real credentials outside version control.
- Secrets live only in `~/.operator/agent.env` and `~/.hermes/.env` (both `chmod 600`). `config.yaml` holds none. `setup.sh` never prints a secret value.
- The vault holds real project data. Keep it out of this repository (`.gitignore` excludes common vault paths). If you sync it with git, use a private remote.
- Content the agent processes (transcripts, documents, messages) is data, not instructions. `SOUL.md` says so, and anything consequential needs the owner's approval anyway.
- `setup.sh` backs up any `config.yaml`, `.env` or `SOUL.md` it is about to change into `~/.hermes/backups/operator-<timestamp>/`.

## Verify against your Hermes version

These points could not be fully confirmed from upstream docs or source for v0.21.5. Check them on your install:

- That the gateway runs and ticks cron with no messaging platform configured (`hermes cron status` after setup).
- That `HERMES_WRITE_SAFE_ROOT` limits only `write_file` and `patch`, and not the memory, skill or cron tools, which write under `~/.hermes/` themselves. The docs describe it that way.
- Re-running the installer over an existing install with `--branch <tag>` (only needed when upgrading). A fresh install is the tested path.

## License

No license: all rights reserved. Used by <ORG_NAME> to set up agents for its clients; others may view but not reuse.
