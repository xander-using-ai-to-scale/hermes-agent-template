#!/usr/bin/env bash
# Install or update the Operator (project-management) agent on one Linux machine.
#
#   ./deploy/setup.sh                       install / update (safe to re-run after every git pull)
#   ./deploy/setup.sh --routines yes|no     pre-answer "schedule the daily brief and weekly report?"
#                                           (default: ask when run in a terminal, otherwise no)
#   ./deploy/setup.sh --autostart           also restart the gateway at boot (crontab @reboot) where
#                                           there is no systemd, e.g. an Orgo desktop
#   ./deploy/setup.sh --gateway-only        just (re)start the gateway, e.g. after a reboot
#   ./deploy/setup.sh --install-prereqs     apt-get the missing prerequisites first (uses sudo)
#   ./deploy/setup.sh --no-gateway          configure everything but do not start the gateway
#
# Reads ~/.operator/agent.env (copy agent.example.env there). Never prints secret values.
set -euo pipefail
shopt -u patsub_replacement 2>/dev/null || true   # keep '&' literal in ${var//x/y} (bash 5.2+)

# ---- Pinned Hermes release ----------------------------------------------------------------------
# Upgrade deliberately: change all three together after reading the upstream release notes.
HERMES_TAG="v2026.9.24"                                  # Hermes Agent v0.21.5
HERMES_COMMIT="f97608f178d1ffeca59860195ab7da295f7c8e5f"   # commit the tag points to
HERMES_INSTALLER_SHA256="2017ddf0cc7bc6cfb70d40dc9fba1d916f47dbcccf5fe73bdee2cf93a11262af"  # scripts/install.sh at that tag
HERMES_INSTALLER_URL="https://raw.githubusercontent.com/NousResearch/hermes-agent/${HERMES_TAG}/scripts/install.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPERATOR_HOME="${OPERATOR_HOME:-$HOME/.operator}"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
ENV_FILE="$OPERATOR_HOME/agent.env"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HERMES_HOME/backups/operator-$STAMP"
export PATH="$HOME/.local/bin:$PATH"

# Routines can also be pre-answered with environment variables (or the same keys in agent.env):
#   PM_ROUTINES=yes|no   PM_DAILY_TIME=08:00 (weekdays)   PM_WEEKLY_TIME=16:00 (Fridays)
ROUTINES_FLAG="" AUTOSTART=false GATEWAY_ONLY=false INSTALL_PREREQS=false START_GATEWAY=true
while [ $# -gt 0 ]; do
  case "$1" in
    --routines)          ROUTINES_FLAG="${2:-}"; shift ;;
    --routines=*)        ROUTINES_FLAG="${1#*=}" ;;
    --autostart)         AUTOSTART=true ;;
    --gateway-only)      GATEWAY_ONLY=true ;;
    --install-prereqs)   INSTALL_PREREQS=true ;;
    --no-gateway)        START_GATEWAY=false ;;
    -h|--help)           sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
  esac
  shift
done
case "$ROUTINES_FLAG" in ""|yes|no) ;; *) echo "--routines takes yes or no" >&2; exit 2 ;; esac

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
fail() { printf '\nSetup stopped: %s\n' "$*" >&2; exit 1; }

# ---- Gateway (also runs the cron scheduler: without it no routine fires) ------------------------
has_systemd() { [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; }
# Match the real process only (its command line ends in "gateway run"), not the tmux server.
gateway_pids() { pgrep -f "hermes gateway run\$" 2>/dev/null || true; }
start_gateway() {
  say "Gateway"
  mkdir -p "$HERMES_HOME/logs"
  if has_systemd && hermes gateway install </dev/null >/dev/null 2>&1; then
    hermes gateway restart </dev/null >/dev/null 2>&1 || hermes gateway start </dev/null >/dev/null 2>&1 \
      || fail "the systemd gateway service would not start (check: hermes gateway status)"
    info "running as a systemd service (survives reboots)"
    return
  fi
  # No systemd (Orgo desktops, most containers): run it in the background instead.
  if [ -n "$(gateway_pids)" ]; then
    hermes gateway stop </dev/null >/dev/null 2>&1 || true
    sleep 2
    for pid in $(gateway_pids); do kill "$pid" 2>/dev/null || true; done
    sleep 1
  fi
  if command -v tmux >/dev/null 2>&1; then
    tmux kill-session -t hermes-gateway 2>/dev/null || true
    tmux new-session -d -s hermes-gateway "exec hermes gateway run >> '$HERMES_HOME/logs/gateway.console.log' 2>&1"
    info "running in tmux session 'hermes-gateway' (attach: tmux attach -t hermes-gateway)"
  else
    nohup hermes gateway run </dev/null >> "$HERMES_HOME/logs/gateway.console.log" 2>&1 &
    info "running in the background with nohup (log: $HERMES_HOME/logs/gateway.console.log)"
  fi
  sleep 5
  [ -n "$(gateway_pids)" ] || fail "the gateway exited at once; see $HERMES_HOME/logs/gateway.console.log"
  info "no systemd here: after a reboot run ./deploy/setup.sh --gateway-only (or use --autostart)"
}

if [ "$GATEWAY_ONLY" = true ]; then
  command -v hermes >/dev/null || fail "Hermes is not installed; run ./deploy/setup.sh first"
  start_gateway
  exit 0
fi

# ---- 1. Prerequisites ---------------------------------------------------------------------------
say "1/9 Checking prerequisites"
[ "$(uname -s)" = "Linux" ] || info "warning: this script is written and tested for Linux"
missing=()
for cmd in git curl sha256sum xz pgrep; do command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd"); done
if [ "$AUTOSTART" = true ] && ! has_systemd; then command -v crontab >/dev/null 2>&1 || missing+=("crontab"); fi
if [ "${#missing[@]}" -gt 0 ]; then
  pkgs=()
  for m in "${missing[@]}"; do
    case "$m" in xz) pkgs+=(xz-utils) ;; sha256sum) pkgs+=(coreutils) ;; crontab) pkgs+=(cron) ;; pgrep) pkgs+=(procps) ;; *) pkgs+=("$m") ;; esac
  done
  if [ "$INSTALL_PREREQS" = true ] && command -v apt-get >/dev/null 2>&1; then
    SUDO=(); [ "$(id -u)" -ne 0 ] && SUDO=(sudo)
    { "${SUDO[@]}" apt-get update -qq && "${SUDO[@]}" apt-get install -y -qq "${pkgs[@]}"; } || fail "could not install: ${pkgs[*]}"
  else
    fail "missing: ${missing[*]}. Install with: sudo apt-get install -y ${pkgs[*]}  (or re-run with --install-prereqs)"
  fi
fi
info "git, curl, sha256sum, xz, pgrep: ok"

[ -f "$ENV_FILE" ] || fail "missing $ENV_FILE. Run: mkdir -p $OPERATOR_HOME && cp $REPO_DIR/agent.example.env $ENV_FILE && chmod 600 $ENV_FILE, then fill it in"
chmod 600 "$ENV_FILE"

# Parse KEY=VALUE lines without executing the file. Values may be quoted; $HOME and ~ are expanded.
declare -A CFG=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%$'\r'}"
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ "$line" =~ ^[[:space:]]*([A-Z][A-Z0-9_]*)=(.*)$ ]] || continue
  key="${BASH_REMATCH[1]}" val="${BASH_REMATCH[2]}"
  val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
  if [[ "$val" =~ ^\"(.*)\"$ || "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"; fi
  val="${val//\$HOME/$HOME}"; val="${val//\$\{HOME\}/$HOME}"
  [[ "$val" == "~"* ]] && val="$HOME${val:1}"
  CFG["$key"]="$val"
done < "$ENV_FILE"
cfg() { printf '%s' "${CFG[$1]:-${2:-}}"; }

for k in OPENROUTER_API_KEY OPERATOR_MODEL OWNER_NAME ORG_NAME TIMEZONE; do
  [ -n "$(cfg "$k")" ] || fail "$k is empty in $ENV_FILE"
done
AGENT_NAME="$(cfg AGENT_NAME "The Operator")"
PM_SYSTEM="$(cfg PM_SYSTEM "the vault")"
VAULT_DIR="$(cfg VAULT_DIR "$HOME/operator-vault")"
TIMEZONE="$(cfg TIMEZONE)"
[[ "$VAULT_DIR" == /* ]] || fail "VAULT_DIR must be an absolute path (got: $VAULT_DIR)"
FILE_ACCESS="$(cfg OPERATOR_FILE_ACCESS vault)"
case "$FILE_ACCESS" in vault|off) ;; *) fail "OPERATOR_FILE_ACCESS must be 'vault' or 'off'" ;; esac
ENABLE_SHELL="$(cfg OPERATOR_ENABLE_SHELL false)"
ENABLE_SLACK="$(cfg OPERATOR_ENABLE_SLACK false)"
if [ "$ENABLE_SLACK" = true ]; then
  for k in SLACK_BOT_TOKEN SLACK_APP_TOKEN SLACK_ALLOWED_USERS SLACK_HOME_CHANNEL; do
    [ -n "$(cfg "$k")" ] || fail "OPERATOR_ENABLE_SLACK=true needs $k"
  done
fi
info "settings: ok (owner, org, timezone, model, vault: $VAULT_DIR)"

# ---- Routines question (asked up front so the whole run is unattended afterwards) ---------------
# Precedence: --routines flag, then PM_ROUTINES in the environment, then agent.env, then ask.
ROUTINES="${ROUTINES_FLAG:-${PM_ROUTINES:-$(cfg PM_ROUTINES)}}"
DAILY_TIME="${PM_DAILY_TIME:-$(cfg PM_DAILY_TIME 08:00)}"
WEEKLY_TIME="${PM_WEEKLY_TIME:-$(cfg PM_WEEKLY_TIME 16:00)}"
if [ -z "$ROUTINES" ]; then
  if [ -t 0 ]; then
    echo
    echo "  The daily status brief (weekdays) and weekly report (Fridays) run on a schedule."
    echo "  Each run is a model call billed to your OpenRouter credits."
    read -r -p "  Schedule the daily status brief and weekly report now? [y/N] " answer || answer=""
    case "$answer" in [yY]|[yY][eE][sS]) ROUTINES=yes ;; *) ROUTINES=no ;; esac
    if [ "$ROUTINES" = yes ]; then
      read -r -p "  Timezone [$TIMEZONE]: " answer || answer="";                   TIMEZONE="${answer:-$TIMEZONE}"
      read -r -p "  Daily brief time, weekdays [$DAILY_TIME]: " answer || answer=""; DAILY_TIME="${answer:-$DAILY_TIME}"
      read -r -p "  Weekly report time, Fridays [$WEEKLY_TIME]: " answer || answer=""; WEEKLY_TIME="${answer:-$WEEKLY_TIME}"
    fi
  else
    ROUTINES=no
  fi
fi
case "$ROUTINES" in yes|no) ;; *) fail "PM_ROUTINES must be yes or no (got: $ROUTINES)" ;; esac
to_cron() { # HH:MM days -> "M H * * days"
  [[ "$1" =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]] || fail "time must be HH:MM (got: $1)"
  printf '%d %d * * %s' "$((10#${BASH_REMATCH[2]}))" "$((10#${BASH_REMATCH[1]}))" "$2"
}
DAILY_CRON="$(to_cron "$DAILY_TIME" 1-5)"
WEEKLY_CRON="$(to_cron "$WEEKLY_TIME" 5)"
[ -e "/usr/share/zoneinfo/$TIMEZONE" ] || info "warning: '$TIMEZONE' is not in /usr/share/zoneinfo; check the spelling"

backup() { # file -> copy into this run's backup dir, only when it is about to change
  local src="$1" new="$2"
  [ -f "$src" ] || return 0
  cmp -s "$src" "$new" && return 0
  mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
  cp -p "$src" "$BACKUP_DIR/$(basename "$src")"
  info "backed up $(basename "$src") -> $BACKUP_DIR/"
}

# ---- 2. Hermes (pinned, checksum-verified) ------------------------------------------------------
say "2/9 Hermes $HERMES_TAG"
installed=""
command -v hermes >/dev/null 2>&1 && installed="$(hermes --version 2>/dev/null | head -1 || true)"
if [[ "$installed" == *"${HERMES_TAG#v}"* ]]; then
  info "already installed: $installed"
elif [ -n "$installed" ]; then
  fail "found '$installed' but this template pins $HERMES_TAG. Upgrade on purpose: see README 'Upgrading Hermes'"
else
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  curl -fsSL --retry 3 "$HERMES_INSTALLER_URL" -o "$tmp/install.sh" || fail "could not download the Hermes installer"
  got="$(sha256sum "$tmp/install.sh" | cut -d' ' -f1)"
  [ "$got" = "$HERMES_INSTALLER_SHA256" ] || fail "installer checksum mismatch (got $got). Not running it."
  info "installer checksum verified"
  bash "$tmp/install.sh" --skip-setup --non-interactive --skip-browser --skip-computer-use \
    --branch "$HERMES_TAG" --commit "$HERMES_COMMIT" --force-commit || fail "the Hermes installer failed"
  hash -r
  command -v hermes >/dev/null || fail "hermes is not on PATH after install (open a new shell, then re-run)"
  info "installed: $(hermes --version 2>/dev/null | head -1)"
fi
mkdir -p "$HERMES_HOME"; chmod 700 "$HERMES_HOME"

# ---- 3. Vault ------------------------------------------------------------------------------------
say "3/9 Vault"
if [ -d "$VAULT_DIR" ]; then
  info "exists: $VAULT_DIR (left as is)"
else
  mkdir -p "$VAULT_DIR"
  cp -R "$REPO_DIR/vault-template/." "$VAULT_DIR/"
  info "created from vault-template/: $VAULT_DIR"
fi

# ---- 4. Render config.yaml ----------------------------------------------------------------------
say "4/9 Rendering ~/.hermes/config.yaml"
disabled=(browser computer_use cronjob delegation image_gen video_gen tts)
[ "$ENABLE_SHELL" = true ] || disabled=(terminal code_execution "${disabled[@]}")
[ "$FILE_ACCESS" = off ] && disabled=(file "${disabled[@]}")
DISABLED_TOOLSETS="$(IFS=,; echo "${disabled[*]}")"; DISABLED_TOOLSETS="${DISABLED_TOOLSETS//,/, }"

render() { # template -> stdout, replacing __KEY__ tokens
  local text; text="$(cat "$1")"
  text="${text//__TIMEZONE__/$TIMEZONE}"
  text="${text//__OPERATOR_MODEL__/$(cfg OPERATOR_MODEL)}"
  text="${text//__DISABLED_TOOLSETS__/$DISABLED_TOOLSETS}"
  text="${text//__REPO_DIR__/$REPO_DIR}"
  text="${text//__VAULT_DIR__/$VAULT_DIR}"
  text="${text//__PM_SYSTEM__/$PM_SYSTEM}"
  printf '%s\n' "$text"
}
new_cfg="$(mktemp)"
render "$REPO_DIR/hermes/config.template.yaml" > "$new_cfg"
if [ -f "$OPERATOR_HOME/mcp_servers.yaml" ]; then
  { echo; echo "# ---- appended from $OPERATOR_HOME/mcp_servers.yaml ----"; cat "$OPERATOR_HOME/mcp_servers.yaml"; } >> "$new_cfg"
  info "appended MCP servers from $OPERATOR_HOME/mcp_servers.yaml"
fi
if grep -q '__[A-Z_]*__' "$new_cfg"; then rm -f "$new_cfg"; fail "unrendered placeholders left in the config"; fi
HERMES_PY="$(dirname "$(readlink -f "$(command -v hermes)")")/python"
if [ -x "$HERMES_PY" ]; then
  "$HERMES_PY" -c 'import sys, yaml; d = yaml.safe_load(open(sys.argv[1])); assert isinstance(d, dict)' "$new_cfg" \
    || { rm -f "$new_cfg"; fail "the rendered config is not valid YAML (check $OPERATOR_HOME/mcp_servers.yaml)"; }
  info "YAML parses"
fi
backup "$HERMES_HOME/config.yaml" "$new_cfg"
install -m 600 "$new_cfg" "$HERMES_HOME/config.yaml"; rm -f "$new_cfg"
info "disabled toolsets: $DISABLED_TOOLSETS"

# ---- 5. Secrets into ~/.hermes/.env (values never echoed) ---------------------------------------
say "5/9 Writing ~/.hermes/.env"
managed=(OPENROUTER_API_KEY HERMES_WRITE_SAFE_ROOT GATEWAY_ALLOW_ALL_USERS PM_SYSTEM_TOKEN
         SLACK_BOT_TOKEN SLACK_APP_TOKEN SLACK_ALLOWED_USERS SLACK_HOME_CHANNEL)
new_env="$(mktemp)"; chmod 600 "$new_env"
if [ -f "$HERMES_HOME/.env" ]; then   # keep keys this script does not manage
  pattern="^($(IFS='|'; echo "${managed[*]}"))="
  grep -Ev "$pattern" "$HERMES_HOME/.env" | grep -v '^# ---- managed by operator setup.sh' >> "$new_env" || true
fi
{
  echo "# ---- managed by operator setup.sh (edit ~/.operator/agent.env instead) ----"
  echo "OPENROUTER_API_KEY=$(cfg OPENROUTER_API_KEY)"
  [ "$FILE_ACCESS" = vault ] && echo "HERMES_WRITE_SAFE_ROOT=$VAULT_DIR"
  echo "GATEWAY_ALLOW_ALL_USERS=false"
  [ -n "$(cfg PM_SYSTEM_TOKEN)" ] && echo "PM_SYSTEM_TOKEN=$(cfg PM_SYSTEM_TOKEN)"
  if [ "$ENABLE_SLACK" = true ]; then
    for k in SLACK_BOT_TOKEN SLACK_APP_TOKEN SLACK_ALLOWED_USERS SLACK_HOME_CHANNEL; do echo "$k=$(cfg "$k")"; done
  fi
} >> "$new_env"
backup "$HERMES_HOME/.env" "$new_env"
install -m 600 "$new_env" "$HERMES_HOME/.env"; rm -f "$new_env"
info "written (chmod 600). Slack: $([ "$ENABLE_SLACK" = true ] && echo on || echo off)"

# ---- 6. SOUL.md ------------------------------------------------------------------------------------
say "6/9 Installing SOUL.md"
new_soul="$(mktemp)"
soul="$(cat "$REPO_DIR/SOUL.md")"
soul="${soul//<AGENT_NAME>/$AGENT_NAME}"
soul="${soul//<OWNER_NAME>/$(cfg OWNER_NAME)}"
soul="${soul//<ORG_NAME>/$(cfg ORG_NAME)}"
soul="${soul//<TIMEZONE>/$TIMEZONE}"
soul="${soul//<PM_SYSTEM>/$PM_SYSTEM}"
soul="${soul//<VAULT_PATH>/$VAULT_DIR}"
printf '%s\n' "$soul" > "$new_soul"
render_left="$(grep -o '<[A-Z_]\+>' "$new_soul" | sort -u | tr '\n' ' ' || true)"
backup "$HERMES_HOME/SOUL.md" "$new_soul"
install -m 600 "$new_soul" "$HERMES_HOME/SOUL.md"; rm -f "$new_soul"
info "installed"
[ -n "$render_left" ] && info "still to fill in by hand in ~/.hermes/SOUL.md: $render_left"

# ---- 7. Skills -------------------------------------------------------------------------------------
say "7/9 Skills"
count="$(find "$REPO_DIR/skills" -name SKILL.md | wc -l | tr -d ' ')"
info "$count skills linked through skills.external_dirs -> $REPO_DIR/skills (no copies made)"

# ---- 8. Routines (only when the owner said yes: scheduled jobs spend credits unattended) -----------
say "8/9 Routines"
deliver="local"
[ "$ENABLE_SLACK" = true ] && deliver="slack"
job_registered() { hermes cron list --all 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -Eq "Name: +$1\$"; }
add_job() { # name schedule prompt-file skill
  local name="$1" schedule="$2" file="$3" skill="$4"
  if job_registered "$name"; then info "= $name (already registered; change it with hermes cron edit)"; return; fi
  hermes cron create --name "$name" --deliver "$deliver" --workdir "$VAULT_DIR" --skill "$skill" \
    "$schedule" "$(cat "$REPO_DIR/routines/$file")" >/dev/null || fail "could not register '$name'"
  info "+ $name ($schedule, $TIMEZONE)"
}
if [ "$ROUTINES" = yes ]; then
  add_job "Operator daily status brief" "$DAILY_CRON"  daily-status-brief.md daily-status-brief
  add_job "Operator weekly report"      "$WEEKLY_CRON" weekly-report.md      weekly-report
  info "delivery: $deliver · each run uses OpenRouter credits"
else
  info "not scheduled. To schedule them later, run:"
  # The $(cat ...) below is printed for the owner to run later, not expanded here.
  # shellcheck disable=SC2016
  printf '    hermes cron create --name "Operator daily status brief" --deliver %s --workdir "%s" --skill daily-status-brief "%s" "$(cat "%s/routines/daily-status-brief.md")"\n' \
    "$deliver" "$VAULT_DIR" "$DAILY_CRON" "$REPO_DIR"
  # shellcheck disable=SC2016
  printf '    hermes cron create --name "Operator weekly report" --deliver %s --workdir "%s" --skill weekly-report "%s" "$(cat "%s/routines/weekly-report.md")"\n' \
    "$deliver" "$VAULT_DIR" "$WEEKLY_CRON" "$REPO_DIR"
  info "(or re-run: ./deploy/setup.sh --routines yes)"
fi

if [ "$AUTOSTART" = true ]; then
  if has_systemd; then
    info "autostart: systemd service handles reboots"
  else
    line="@reboot cd '$REPO_DIR' && ./deploy/setup.sh --gateway-only >> '$HERMES_HOME/logs/gateway.autostart.log' 2>&1"
    { crontab -l 2>/dev/null | grep -v 'deploy/setup.sh --gateway-only' || true; echo "$line"; } | crontab -
    info "autostart: @reboot crontab entry added (remove with: crontab -e)"
    pgrep -x cron >/dev/null 2>&1 || info "warning: the cron daemon is not running, so @reboot will not fire"
  fi
fi

# ---- 9. Gateway and status -----------------------------------------------------------------------
[ "$START_GATEWAY" = true ] && start_gateway

say "9/9 Status"
info "hermes:   $(hermes --version 2>/dev/null | head -1)"
info "home:     $HERMES_HOME"
info "vault:    $VAULT_DIR"
info "routines: $ROUTINES (daily $DAILY_CRON, weekly $WEEKLY_CRON, $TIMEZONE)"
info "files:    $FILE_ACCESS · shell: $([ "$ENABLE_SHELL" = true ] && echo on || echo off) · slack: $([ "$ENABLE_SLACK" = true ] && echo on || echo off)"
info "gateway:  $( [ -n "$(gateway_pids)" ] && echo running || { has_systemd && hermes gateway status </dev/null 2>/dev/null | head -1; } || echo 'not running')"
hermes cron status 2>/dev/null | head -3 | sed 's/^/  /' || true
echo
echo "Next: run 'hermes' and try the test prompt in INSTALL.md (step 7)."
