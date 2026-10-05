# Install and verify

These steps match `deploy/setup.sh` exactly. They target Linux (including Orgo cloud desktops) and Hermes Agent v0.21.5 (`v2026.9.24`). Official Hermes docs: https://hermes-agent.nousresearch.com/docs

## Before you start

- A Linux user account you will run the agent as (not a shared account).
- `git`, `curl`, `xz-utils`, `procps`, and `cron` if you want `--autostart`. On Debian/Ubuntu/Orgo: `sudo apt-get install -y git curl xz-utils procps cron`.
- An OpenRouter API key with credit, and a tool-calling model id from openrouter.ai/models.
- The owner's name, the organization's name, the timezone (IANA, for example `Europe/Berlin`), and where task status lives (`PM_SYSTEM`).
- If Hermes is already on this machine with its own `SOUL.md` or config, read them first. `setup.sh` backs them up, but the agent's identity will be replaced.

## 1. Get the template

```bash
git clone <this-repo-url> ~/operator-agent
cd ~/operator-agent
```

Read `SOUL.md`, `PROJECT_MANAGEMENT.md` and the skills before installing: they are what the agent will do.

## 2. Fill in the settings

```bash
mkdir -p ~/.operator
cp agent.example.env ~/.operator/agent.env
chmod 600 ~/.operator/agent.env
nano ~/.operator/agent.env
```

Required: `OWNER_NAME`, `ORG_NAME`, `TIMEZONE`, `OPENROUTER_API_KEY`, `OPERATOR_MODEL`. Check `VAULT_DIR`, `PM_SYSTEM` and the tool-permission lines. Slack stays off unless you set `OPERATOR_ENABLE_SLACK=true` and its four values. Never commit this file.

## 3. Run setup

```bash
./deploy/setup.sh
```

What it does, in order (re-running it is safe):

1. **Checks prerequisites** and reads `~/.operator/agent.env` without executing it. Add `--install-prereqs` to `apt-get` anything missing.
2. **Asks about routines:** "Schedule the daily status brief and weekly report now? [y/N]". On yes, it also asks for the timezone and the times (defaults: weekdays 08:00, Friday 16:00). Each run uses OpenRouter credits. Pre-answer with `--routines yes|no` or `PM_ROUTINES` / `PM_DAILY_TIME` / `PM_WEEKLY_TIME`. When run without a terminal and with no answer, the default is no.
3. **Installs Hermes `v2026.9.24`** if it is missing. It downloads `scripts/install.sh` from that tag, checks its SHA-256 against the value pinned in the script, then runs it with `--skip-setup --non-interactive --skip-browser --skip-computer-use --branch v2026.9.24 --commit <tag commit> --force-commit`. If a different Hermes version is installed, it stops (see README, "Upgrading Hermes").
4. **Creates the vault** at `VAULT_DIR` from `vault-template/`. An existing vault is left untouched.
5. **Renders `~/.hermes/config.yaml`** from `hermes/config.template.yaml`, appends `~/.operator/mcp_servers.yaml` if present, checks that the YAML parses, and backs up the old file if it changed.
6. **Writes `~/.hermes/.env`** (chmod 600): the OpenRouter key, `HERMES_WRITE_SAFE_ROOT=<VAULT_DIR>` (unless file access is off), `GATEWAY_ALLOW_ALL_USERS=false`, and the optional PM and Slack tokens. Other keys already in the file are kept. Values are never printed.
7. **Installs `~/.hermes/SOUL.md`** with your owner, org, timezone, PM system and vault path filled in. The old one is backed up.
8. **Links the skills** through `skills.external_dirs` (nothing is copied).
9. **Registers the routines** if you said yes. Otherwise it prints the two `hermes cron create` commands to run later.
10. **Starts the gateway:** as a systemd service where systemd exists, otherwise in the background (`tmux` session `hermes-gateway`, or `nohup`). The gateway also runs the cron scheduler. Skip this with `--no-gateway`.
11. **Prints a status summary.**

Backups go to `~/.hermes/backups/operator-<timestamp>/`.

## 4. Orgo desktops: survive reboots

There is no systemd on Orgo, so after a reboot run:

```bash
cd ~/operator-agent && ./deploy/setup.sh --gateway-only
```

Or run `./deploy/setup.sh --autostart` once to add an `@reboot` crontab entry that does it (needs the `cron` daemon running).

## 5. Verify the install

```bash
hermes --version        # Hermes Agent v0.21.5 (2026.9.24)
hermes doctor           # config, timezone and provider checks
hermes config get agent.disabled_toolsets
hermes skills list | grep -E 'project-intake|daily-status-brief|meeting-follow-up|weekly-report|project-closeout|blocker-escalation'
hermes cron status      # scheduler alive (needs the gateway)
hermes cron list        # your two routines, if you scheduled them
```

Expected: the version line above, six skills listed, `terminal` and `code_execution` in the disabled list (unless you opted in), and `hermes cron status` reporting a live ticker.

## 6. Check the guardrails

In `hermes`, ask the agent to write a file outside the vault, for example `~/test.txt`. The write should be refused with `Write denied: ... is outside HERMES_WRITE_SAFE_ROOT`. Then ask it to run a shell command: it should say it has no terminal tool.

## 7. Test prompt with read-only sample data

`examples/sample-vault/` is fictional. The agent can read it but cannot change it, because writes are confined to your real vault. Run:

```bash
cd ~/operator-agent
hermes chat --oneshot -s meeting-follow-up -q "Using only the read-only sample vault at $PWD/examples/sample-vault, process the meeting 'Projects/Website Refresh/Meetings/2030-03-17 Website weekly sync.md'. Show the decisions, actions with owners, and open questions, and list the writes you would propose. Do not write anything."
```

A good answer:

- **Decision:** dark mode is out of scope for this release (decided by Alex Kim).
- **Actions:** Alex Kim chases finance for pricing by Wednesday. Jordan Lee owns the accessibility check, due 2030-03-26 (this updates the existing `Unassigned` action).
- **Not an action:** "think about a dark mode at some point" was only a suggestion.
- **Proposed writes,** each waiting for approval. Nothing was written.

Then try `hermes chat --oneshot -s daily-status-brief -q "Give me a status brief for the sample vault at $PWD/examples/sample-vault as of 2030-03-18. Do not save it."`. It should flag Website Refresh as At risk because the copy is waiting on pricing.

## 8. Go live

- Confirm with the owner which writes the agent may make without asking (default: only its own report notes) and record any change in `SOUL.md` before re-running `setup.sh`.
- Connect the PM system only after the read-only tests pass (README, "Connecting your PM system").
- If you skipped the routines, schedule them when the owner agrees: `./deploy/setup.sh --routines yes`.

## Before publishing a customized fork

- Inspect every tracked file and git diff for tokens, passwords, private URLs, personal data, customer names, internal business facts, and generated logs.
- Use placeholders such as `<PM_SYSTEM>` or `<APPROVAL_CHANNEL>` where configuration examples are useful.
- Confirm all bundled content is yours to redistribute.
- Do not include `.env`, `agent.env`, local Hermes configuration, memory exports, session logs, vault data, client files, or machine-specific paths.
