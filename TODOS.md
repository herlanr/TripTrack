# 📝 TripTrack - Offene Punkte, Fragen & Roadmap

Diese Datei enthält alle identifizierten Fehler (Bugs), Formular-Korrekturen, UI-Erweiterungen und offenen Fragen für **TripTrack**.

---

## 🐛 Identifizierte Bugs & Formular-Korrekturen

- [x] **Formulare verbessern (Felder werden abgeschnitten / Overflow)**
  - *Problem*: Bei geöffneter Bildschirmtastatur werden Eingabefelder in Dialogen oder Formularen teilweise abgeschnitten.
  - *Lösung*: `SingleChildScrollView` und flexibles Tastatur-Padding (`MediaQuery.of(context).viewInsets.bottom`) in Dialogen sicherstellen.
  - *Verantwortlich*: Nils

- [x] **Routenverlauf zeigt nicht alle GPS-Punkte**
  - *Problem*: In der `RouteList` / `TripSummaryDialog` werden Zwischenpunkte der Fahrt gefilterte oder unvollständig angezeigt.
  - *Lösung*: Alle erfassten GPS-Punkte chronologisch und vollständig in der Zeitleiste auflisten.
  - *Verantwortlich*: Herlan

- [x] **Automatische Aktualisierung des Kilometerstands**
  - *Problem*: Der Kilometerstand des Fahrzeugs (`Vehicle.currentKm`) muss nach dem Speichern einer Fahrt verlässlich im `VehicleRepository` aktualisiert werden.
  - *Verantwortlich*: Herlan

- [ ] **Aktueller Standort wird nicht automatisch aktualisiert**
  - *Problem*: Der aktuelle Standort auf der Home-Seite wird nur einmalig beim Start abgefragt.
  - *Lösung*: Periodische Live-Aktualisierung der GPS-Position und Straßenadresse.
  - *Verantwortlich*: Herlan

---

## 🎨 UI/UX-Optimierungen & Erweiterungen

- [ ] **Erweiterung des Stop-Buttons**
  - *Ziel*: Erweiterte Optionen beim Beenden einer Fahrt (z. B. sofortige Schnellspeicherung oder Bestätigungsdialog).
  - *Verantwortlich*: Herlan

- [x] **Zwei separate Knöpfe im Fahrtbuch: Datumsfilter & Sortierung**
  - *Ziel*: Im `FahrtbuchScreen` neben der Suchleiste zwei dedizierte Schaltflächen bereitstellen:
    1. 📅 **Datumsfilter-Button**: Öffnet ein Kalender-Pop-Up zur Auswahl von Start- und Enddatum.
    2. 🔀 **Sortierungs-Button**: Bietet Sortieroptionen (Neueste zuerst, Älteste zuerst, Längste Strecke).
  - *Verantwortlich*: Herlan

- [X] **Visuelle Unterscheidung von Feldern auf der Home-Seite**
  - *Ziel*: Schreibgeschützte Felder (Fahrer, Start-Ort) deutlicher von editierbaren Feldern (Fahrzeug, Kilometerstand) abgrenzen.
  - *Verantwortlich*: Nils

- [X] **Aufklappbare "Last Fahrt"-Karte auf dem Home-Screen**
  - *Ziel*: Einklappbare/aufklappbare Zusammenfassungskarte auf der Home-Seite zur Platzersparnis.
  - *Verantwortlich*: Nils

- [X] **Sicherheitsabfrage beim Abmelden (Logout-Guard)**
  - *Ziel*: Bestätigungsdialog (*„Möchtest du dich wirklich abmelden?“*) vor dem Logout inklusive Warnung bei aktiver Fahrt.
  - *Verantwortlich*: Nils

---

## ⚙️ Funktionserweiterungen & Backend-Roadmap

- [x] **Profil & Fahrzeug bearbeiten**
  - *Ziel*: Bearbeiten-Dialoge für Fahrer-Profile und Fahrzeugdaten auf der Profilseite.
  - *Verantwortlich*: Nils

- [ ] **Backend Cloud-API Anbindung (AWS)**
  - *Ziel*: Kilometerstand kann anhand eines Bildes gelesen werden (Nutzer macht ein Foto von Kilometerstand, das wird dann bewertet und als KM (Z.B 12333) züruckgegeben)
  - *Verantwortlich*: Herlan

---

## ❓ Offene Fragen & Architektur-Diskussionen

1. **Soll der Kilometerstand nach der Fahrt manuell anpassbar sein?**
   - *Diskussion*: Soll der Fahrer den berechneten End-Kilometerstand vor dem Speichern manuell korrigieren dürfen (z. B. wenn GPS Abweichungen hatte)?

2. **Aktueller Standort: Behalten oder verwerfen?**
   - *Diskussion*: Wie soll verfahren werden, wenn das GPS-Signal beim Stoppen der Fahrt fehlschlägt? Soll die letzte bekannte Adresse automatisch übernommen oder der Nutzer nach manueller Eingabe gefragt werden?

3. **Wo soll die automatische Fahrterkennung platziert werden?**
   - *Diskussion*: In welchem Screen/Menü soll eine automatische Fahrterkennung (z. B. via Bluetooth-Verbindung zum Auto) konfiguriert werden?
