#!/usr/bin/env bash
# Installiert die lokalen Factory-Skills (init, write-spec, to-factory) einmalig auf deinem Rechner.
# Sie gelten dann in allen Projekten. Updates: im Factory-Repo "git pull", fertig (es sind Verknüpfungen).
#   ./scripts/install-local-skills.sh
# Unter Windows in Git Bash ausführen (aus PowerShell: & "C:\Program Files\Git\bin\bash.exe" ./scripts/install-local-skills.sh).
# Dort werden Verzeichnis-Junctions angelegt: Sie brauchen weder Admin-Rechte noch den Entwicklermodus.
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)/local-skills"
DEST="$HOME/.claude/skills"
# Sicherungen liegen außerhalb des Skill-Ordners, sonst zeigt Claude Code sie als zusätzliche Skills an
BACKUP="$HOME/.claude/skills-backup"
STAMP=$(date +%Y%m%d%H%M%S)
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WINDOWS=1 ;; *) WINDOWS=0 ;; esac
mkdir -p "$DEST"

# Sicherungen älterer Versionen dieses Skripts aus dem Skill-Ordner räumen
for old in "$DEST"/*.backup-*; do
  [ -e "$old" ] || continue
  mkdir -p "$BACKUP" && mv "$old" "$BACKUP/"
  echo "  alte Sicherung $(basename "$old") nach $BACKUP verschoben"
done

unlink_skill() { # PFAD: entfernt eine vorhandene Verknüpfung, nie ihr Ziel
  if [ "$WINDOWS" = 1 ]; then MSYS_NO_PATHCONV=1 cmd /c rmdir "$(cygpath -w "$1")" >/dev/null; else rm "$1"; fi
}
link_skill() { # QUELLE ZIEL
  # MSYS_NO_PATHCONV verhindert, dass Git Bash die Schalter /c und /J in Pfade umschreibt
  if [ "$WINDOWS" = 1 ]; then MSYS_NO_PATHCONV=1 cmd /c mklink /J "$(cygpath -w "$2")" "$(cygpath -w "$1")" >/dev/null
  else ln -sfn "$1" "$2"; fi
}

for skill in "$SRC"/*/; do
  name=$(basename "$skill")
  if [ -L "$DEST/$name" ]; then
    unlink_skill "$DEST/$name"
  elif [ -e "$DEST/$name" ]; then
    mkdir -p "$BACKUP"
    mv "$DEST/$name" "$BACKUP/$name.backup-$STAMP"
    echo "  vorhandenen Skill '$name' nach $BACKUP gesichert"
  fi
  link_skill "${skill%/}" "$DEST/$name" || true
  [ -f "$DEST/$name/SKILL.md" ] || { echo "Fehler: /$name konnte nicht verknüpft werden ($DEST/$name)." >&2; exit 1; }
  echo "  ✓ /$name"
done
echo "Fertig. Die Skills stehen in jedem Projekt zur Verfügung (persönliche Skills haben Vorrang vor Projekt-Skills)."
echo "Eine laufende Claude-Code-Sitzung vorher neu starten."
