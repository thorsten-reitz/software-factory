#!/usr/bin/env bash
# Richtet auf dem Factory-Server den Betrieb für ein Projekt ein, dessen staging bzw. production hier läuft
# (Stufen compose und kamal). Läuft als root im Factory-Ordner, mehrfach ausführen ist ok.
#
#   ./scripts/enable-operations.sh --repo besitzer/repo [--project name] [--pipelines v0.3.0]
#
# Einmal pro Server:  Host-Skripte von factory-pipelines, Infisical-CLI, Host-Identität (Infisical, Universal Auth),
#                     Deploy-Schlüssel, healthchecks.io-API-Schlüssel für den Incident-Intake.
# Einmal pro Projekt: Repo anbinden (Labels, GitHub-Umgebungen), Projekt dem Incident-Intake zuordnen.
#
# Vorher in Infisical: die Maschinen-Identität des Servers (Universal Auth) mit Lesezugriff auf die Umgebungen,
# die hier laufen. Nachher in Infisical: die Werte, die das Skript am Ende ausgibt.
set -euo pipefail
cd "$(dirname "$0")/.."
FACTORY_DIR="$(pwd)"
CONF=/etc/software-factory/config.json
SECRETS=/etc/software-factory/secrets.env
SITES=/etc/software-factory/sites.d
REPO=""; PROJECT=""; PIPELINES=v0.3.0

say() { printf "\n\033[1m▶ %s\033[0m\n" "$*"; }
die() { echo "FEHLER: $*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "Bitte als root ausführen"
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --pipelines) PIPELINES="$2"; shift 2 ;;
    *) die "Unbekannte Option: $1" ;;
  esac
done
[[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "--repo besitzer/repo fehlt"
[ -n "$PROJECT" ] || PROJECT=$(basename "$REPO" | tr '[:upper:]_.' '[:lower:]--' | cut -c1-40)
[[ "$PROJECT" =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]] || die "Ungültiger Projektname: $PROJECT"
[[ "$PIPELINES" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "--pipelines im Format vX.Y.Z"
for cmd in jq curl docker gh ssh-keygen systemd-creds; do command -v "$cmd" >/dev/null || die "$cmd fehlt"; done
[ -f "$CONF" ] || die "$CONF fehlt, erst ./setup.sh ausführen"

say "Repo $REPO anbinden (Labels, GitHub-Umgebungen staging und production)"
gh auth status 2>&1 | grep -q "'workflow'" || echo "  Hinweis: Dem GitHub-Login fehlt der Scope 'workflow'. Ohne ihn kann die Factory keine Pipeline-Dateien pushen: gh auth refresh -h github.com -s project,workflow"
"$FACTORY_DIR/scripts/add-repo.sh" "$REPO"

say "Infisical-CLI"
if command -v infisical >/dev/null; then
  echo "  ✓ vorhanden ($(infisical --version 2>/dev/null | head -1))"
else
  curl -1sLf https://artifacts-cli.infisical.com/setup.deb.sh | bash >/dev/null
  apt-get install -y -qq infisical >/dev/null
  echo "  ✓ installiert"
fi

say "Host-Skripte von factory-pipelines $PIPELINES"
NEW_KEY=""
PUB=$(awk '/factory-host --ssh/ {print $(NF-2)" "$(NF-1)" "$NF}' /home/deploy/.ssh/authorized_keys 2>/dev/null | head -1 || true)
if [ -z "$PUB" ]; then
  NEW_KEY=$(mktemp -d)
  ssh-keygen -q -t ed25519 -N '' -C "factory-deploy@$(hostname)" -f "$NEW_KEY/key"
  PUB=$(cat "$NEW_KEY/key.pub")
  echo "  Neuer Deploy-Schlüssel erzeugt (der private Teil wird unten einmal angezeigt)"
fi
if [ "$(cat /opt/factory/VERSION 2>/dev/null || true)" != "$PIPELINES" ]; then
  SRC="/opt/factory-pipelines-${PIPELINES#v}"
  [ -d "$SRC" ] || curl -fsSL "https://github.com/thorsten-reitz/factory-pipelines/archive/refs/tags/$PIPELINES.tar.gz" | tar -xz -C /opt
  # Caddy der Factory übernimmt Site-Dateien aus sites.d beim nächsten Durchlauf des Runners
  "$SRC/host/install.sh" --pubkey "$PUB" --sites-dir "$SITES" --caddy-reload true --secrets-provider infisical
  echo "$PIPELINES" > /opt/factory/VERSION
else
  echo "  ✓ $PIPELINES ist schon installiert"
fi

say "Host-Identität (Infisical, Universal Auth)"
CREDS=/etc/factory-host/credentials
if [ -f "$CREDS/infisical-client-secret.cred" ]; then
  echo "  ✓ vorhanden"
else
  read -rp "  Client-ID der Maschinen-Identität des Servers: " CID
  [[ "$CID" =~ ^[A-Za-z0-9-]+$ ]] || die "Ungültige Client-ID"
  read -rsp "  Client-Secret (wird nicht angezeigt): " CSECRET; echo
  [ -n "$CSECRET" ] || die "Client-Secret fehlt"
  install -d -m 0700 "$CREDS"
  printf '%s' "$CID" > "$CREDS/infisical-client-id"; chmod 0600 "$CREDS/infisical-client-id"
  printf '%s' "$CSECRET" | systemd-creds encrypt --name=infisical-client-secret - "$CREDS/infisical-client-secret.cred"
  unset CSECRET
  echo "  ✓ verschlüsselt gespeichert (systemd-creds)"
fi
CID=$(cat "$CREDS/infisical-client-id")
if infisical login --method=universal-auth --client-id="$CID" \
     --client-secret="$(systemd-creds decrypt --name=infisical-client-secret "$CREDS/infisical-client-secret.cred" -)" \
     --domain=https://eu.infisical.com --silent --plain >/dev/null 2>&1; then
  echo "  ✓ Anmeldung bei Infisical (EU) funktioniert"
else
  echo "  ! Anmeldung bei Infisical fehlgeschlagen. Client-ID und -Secret prüfen; zum Neueingeben $CREDS/infisical-client-secret.cred löschen und das Skript erneut starten."
fi

say "Incident-Intake (healthchecks.io)"
if grep -qE '^HEALTHCHECKS_API_KEY=.' "$SECRETS"; then
  echo "  ✓ API-Schlüssel vorhanden"
else
  read -rsp "  Nur lesender API-Schlüssel von healthchecks.io (Settings → API Access; leer = später): " HCKEY; echo
  if [ -n "$HCKEY" ]; then
    grep -v '^HEALTHCHECKS_API_KEY=' "$SECRETS" > "$SECRETS.tmp" || true
    printf 'HEALTHCHECKS_API_KEY=%s\n' "$HCKEY" >> "$SECRETS.tmp"
    install -m 600 "$SECRETS.tmp" "$SECRETS"; rm -f "$SECRETS.tmp"; unset HCKEY
    echo "  ✓ gespeichert"
  fi
fi
TMP=$(mktemp)
jq --arg p "$PROJECT" --arg r "$REPO" '.incidents.enabled = true
  | .incidents.projects = ((.incidents.projects // {}) | del(.["dein-projekt"]) + {($p): $r})' "$CONF" > "$TMP"
install -m 600 "$TMP" "$CONF"; rm -f "$TMP"
echo "  ✓ Projekt $PROJECT → $REPO"
systemctl restart software-factory

say "Werte für Infisical (Projekt $PROJECT, Umgebungen staging und production)"
HOST=$(jq -r '.preview.host // empty' "$CONF")
[ -n "$HOST" ] && [ "$HOST" != AUTO ] || HOST=$(curl -fsS4 https://ifconfig.me || hostname -I | awk '{print $1}')
echo "  DEPLOY_HOST      $HOST"
echo "  DEPLOY_HOST_KEY  $(awk '{print $1" "$2}' /etc/ssh/ssh_host_ed25519_key.pub)"
if [ -n "$NEW_KEY" ]; then
  echo "  DEPLOY_SSH_KEY   (der private Schlüssel, vollständig einschließlich der BEGIN/END-Zeilen kopieren):"
  echo
  cat "$NEW_KEY/key"
  echo
  shred -u "$NEW_KEY/key" 2>/dev/null || rm -f "$NEW_KEY/key"; rm -rf "$NEW_KEY"
  echo "  Der Schlüssel ist jetzt nur noch in deiner Zwischenablage bzw. in Infisical. Kein zweites Mal anzeigbar;"
  echo "  bei Verlust die Zeile in /home/deploy/.ssh/authorized_keys löschen und das Skript erneut starten."
else
  echo "  DEPLOY_SSH_KEY   unverändert (schon früher erzeugt und in Infisical eingetragen)"
fi
echo
echo "Fertig. Als Nächstes: Secrets in Infisical eintragen, dann im Projekt /init (bzw. die Plattform-Specs) weiterführen."
