# PROJ-7: Observability und Watchdog

**Status:** Planned
**Typ:** Plattform
**Erstellt:** {{DATE}}

## Abhängigkeiten
- PROJ-4 (Deploy nach staging)

## Voraussetzungen (Mensch)
<!-- nur wenn: observability an -->
- [ ] Observability-Stack auf dem Factory-Server eingerichtet (`ops/observability/` im Factory-Repo, über `setup.sh`), Grafana unter seiner Domain erreichbar
<!-- nur wenn: observability an -->
- [ ] Zugangsdaten für den Log- und Metrik-Empfang je Umgebung in Infisical, Namen laut Anleitung des Observability-Stacks
<!-- nur wenn: watchdog healthchecks -->
- [ ] healthchecks.io-Konto, je Umgebung ein Check für den Heartbeat (Zeitraum 5 Minuten), Ping-URL als `HC_PING_URL` in Infisical
<!-- nur wenn: watchdog healthchecks -->
- [ ] API-Schlüssel (nur lesend) von healthchecks.io in der Runner-Konfiguration der Factory, damit Alarme als Issue `incident` ankommen
<!-- nur wenn: externer HTTP-Check -->
- [ ] UptimeRobot-Monitor für `https://{{PRODUCTION_DOMAIN}}/readyz`, Alarm per E-Mail

## User Stories
- Als Projektverantwortliche:r möchte ich Logs und Ressourcen jeder Umgebung an einer Stelle sehen, damit ich Fehler finde, ohne mich auf einem Server anzumelden.
- Als Projektverantwortliche:r möchte ich bei einem Ausfall automatisch ein Issue bekommen, das bei Erholung wieder geschlossen wird, damit ich Ausfälle nicht selbst entdecken muss.
- Als Projektverantwortliche:r möchte ich auch dann benachrichtigt werden, wenn der Factory-Server selbst ausfällt.

## Außerhalb des Umfangs
- Den Observability-Stack auf dem Factory-Server bauen (Teil der Factory)
- Automatische Bearbeitung von Incidents durch die Factory (nur mit Label `factory` durch den Menschen)

## Akzeptanzkriterien
- [ ] AK-1: Angenommen das Repo, dann entsprechen `observability` und `watchdog` in `.factory/delivery.json` den Entscheidungen in `docs/operations.md` (Abschnitt „Observability und Watchdog“), und der Check `delivery-config` ist grün.
- [ ] AK-2: Angenommen die App läuft, dann schreibt sie Logs als eine JSON-Zeile pro Eintrag nach stdout/stderr mit mindestens Zeit, Level und Nachricht, und weder Secrets noch Tokens erscheinen in Logs.
<!-- nur wenn: metrics an -->
- [ ] AK-3: Angenommen eine Anfrage an `/metrics`, dann liefert die App Metriken im Prometheus-Format (mindestens Anfragen, Fehler und Antwortzeit je Route), aber nur mit `Authorization: Bearer <HEALTH_TOKEN>` oder aus dem internen Netz.
- [ ] AK-4: Angenommen `docs/operations.md`, dann listet es jeden Watchdog-Check mit Name, was er meldet und was ein Ausbleiben bedeutet, und der Abschnitt „Runbooks“ beschreibt den Ablauf bei einem Incident.
<!-- nur wenn: observability an -->
- [ ] AK-5: Angenommen staging läuft, dann erscheinen die Logs der App in Grafana mit den Labels für Projekt `{{PROJECT}}`, Umgebung und Dienst, und das Projekt-Dashboard zeigt Health, Fehlerrate, Ressourcen und letzte Deploys. _(nach dem Merge)_
<!-- nur wenn: watchdog healthchecks -->
- [ ] AK-6: Angenommen staging läuft, dann meldet der Host alle 5 Minuten einen Heartbeat, aber nur solange `/readyz` grün ist. _(nach dem Merge)_
<!-- nur wenn: watchdog healthchecks -->
- [ ] AK-7: Angenommen die App in staging ist länger als die Karenzzeit des Checks nicht bereit, dann öffnet der Runner genau ein Issue mit Label `incident`, und nach der Erholung kommentiert und schließt er es. _(nach dem Merge)_
<!-- nur wenn: github-probe an -->
- [ ] AK-8: Angenommen die GitHub-Actions-Probe ist eingeschaltet, dann ruft sie `/readyz` im eingestellten Intervall auf und öffnet bzw. schließt das Issue `incident` selbst. _(nach dem Merge)_

## Edge Cases
- EC-1: Der Factory-Server fällt aus → healthchecks.io benachrichtigt per E-Mail, weil der Runner kein Issue mehr anlegen kann.
- EC-2: Ein Alarm hält an → kein zweites Issue, nur Kommentare am bestehenden.
- EC-3: Observability ist für staging aus → nur production schickt Logs, Abweichung in `docs/operations.md`.

## Technische Anforderungen (optional)
- Grafana Alloy auf dem Host kommt aus factory-pipelines bzw. der cloud-init-Vorlage, im Projekt nur Konfiguration.
- Watchdog-Anbieter: {{WATCHDOG}}.

## Offene Fragen
- [ ] _keine_

## Product Decisions
- Alarme werden Issues mit Label `incident`, nie automatisch Aufgaben der Factory ({{DATE}}).
