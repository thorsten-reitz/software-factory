# Design: <PROJ-ID> <Feature-Name>

**Spec:** [spec.md](spec.md)

## A) Komponenten
```
Seite
+-- Bereich
|   +-- Element
```

## B) Datenmodell
Jeder Eintrag hat:
- …

Gespeichert in: …

## C) Technische Entscheidungen
- **Entscheidung:** Begründung in einfachen Worten

## D) Abhängigkeiten
- Keine neuen Pakete

## E) Backend nötig?
Nein / Ja, weil …

## F) Betrieb
- **Neue Abhängigkeiten → Health-Check:** keine / `<komponente>` (kritisch ja/nein)
- **Neuer Zustand → `state`:** keiner / …
- **Neue Secrets (nur Namen):** keine / `…`
- **Feature-Flag:** keins / `<flag-name>`, in production zunächst aus

## Decision Log
- **Entscheidung:** … | **Alternative:** … | **Abwägung:** … (YYYY-MM-DD)
