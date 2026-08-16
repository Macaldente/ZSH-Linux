# sudo-Bestätigung per FIDO2/U2F-Hardwareschlüssel (`pam_u2f`)

Dokumentation zur Nutzung eines FIDO2/U2F-Sicherheitsschlüssels (hier: Thetis/ExcelSecu
FIDO2 Security Key) zur `sudo`-Authentifizierung im Terminal via `pam_u2f`.
Ursprünglich eingerichtet auf **Pop!_OS** (Debian/Ubuntu-Basis). Dieser Abschnitt
enthält zusätzlich die Abweichungen für **Fedora** (dnf-basiert).

---

## 1. Prinzip

`pam_u2f` wird als `auth sufficient`-Zeile in `/etc/pam.d/sudo` eingehängt.
`sufficient` bedeutet: Ist der Stick gesteckt und die Berührung erfolgt, reicht das
zur Authentifizierung; ist der Stick nicht gesteckt, fällt PAM auf die normale
Passwortabfrage zurück (kein Lockout-Risiko durch fehlenden Stick).

---

## 2. Installation

| Distribution | Befehl | Paketname(n) |
|---|---|---|
| Pop!_OS / Ubuntu / Debian | `sudo apt install libpam-u2f` | `libpam-u2f` (enthält `pamu2fcfg`) |
| Fedora | `sudo dnf install pam-u2f pamu2fcfg` | `pam-u2f` + `pamu2fcfg` (zwei Subpakete) |

**Fedora-Unterschied:** Das Modul heißt `pam-u2f`, nicht `libpam-u2f` wie unter
Debian/Ubuntu. Das CLI-Tool `pamu2fcfg` ist ein eigenes Subpaket und muss auf
Fedora explizit mitinstalliert werden.

---

## 3. Stick registrieren

Auf beiden Systemen identisch:

```sh
mkdir -p ~/.config/Yubico
pamu2fcfg -o pam://$(hostname) -i pam://$(hostname) > ~/.config/Yubico/u2f_keys
```

Ablauf: PIN eingeben → Enter → Stick berühren (Metallfläche/Logo halten, **nicht**
den Kunststoffrand; ca. 1–2 Sekunden halten oder mehrfach antippen).

**Fedora-Hinweis (udev/Berechtigungen):** Fedora nutzt kein `plugdev`-Gruppenmodell
wie Debian/Ubuntu. Der USB-Sicherheitsschlüssel wird stattdessen über systemd/udev
per `uaccess`-Tag automatisch für den aktuell angemeldeten Seat-Benutzer freigegeben.
Es ist also normalerweise **keine** manuelle Gruppenzuordnung nötig. Vor der
Registrierung lässt sich mit
```sh
fido2-token -L
```
prüfen, ob der Stick als normaler Benutzer sichtbar ist. Erscheint er nicht, fehlt
in der Regel die aktive Seat-Session (z. B. bei SSH-Sitzungen ohne grafisches Login)
oder eine udev-Regel — dann hilft `udevadm trigger` nach dem Einstecken.

---

## 4. PAM-Konfiguration

### 4.1 Pop!_OS / Debian / Ubuntu

Default-Inhalt von `/etc/pam.d/sudo` enthält `@include common-auth`. Oberhalb
davon einfügen:

```
auth    sufficient    pam_u2f.so cue
@include common-auth
```

### 4.2 Fedora

Fedoras `/etc/pam.d/sudo` sieht standardmäßig anders aus — es gibt kein
`common-auth`, sondern:

```
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    optional     pam_keyinit.so revoke
session    include      system-auth
```

Analog zur Pop!_OS-Lösung die `pam_u2f`-Zeile oberhalb der bestehenden
`auth include system-auth`-Zeile einfügen:

```
auth       sufficient   pam_u2f.so cue
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    optional     pam_keyinit.so revoke
session    include      system-auth
```

**Wichtiger Fedora-Unterschied — `authselect`:** Fedora verwaltet
`/etc/pam.d/system-auth`, `password-auth`, `smartcard-auth`, `fingerprint-auth`
und `postlogin` automatisiert über `authselect`; manuelle Änderungen an diesen
Dateien werden bei einem `authselect apply-changes`/`select`-Aufruf ohne Weiteres
überschrieben. **`/etc/pam.d/sudo` gehört nicht zu diesen verwalteten Dateien** —
eine direkte, manuelle Bearbeitung wie oben ist daher sicher vor Überschreiben
durch `authselect` und bleibt auf `sudo` beschränkt (Login, GDM, `su` etc. sind
nicht betroffen).

Alternativ bietet Fedora den offiziell unterstützten Weg über `authselect`:

```sh
sudo authselect select sssd with-pam-u2f
sudo authselect apply-changes
```

Das trägt `pam_u2f.so cue` in `system-auth`/`password-auth` ein — und wirkt damit
**systemweit** auf alle Dienste, die `system-auth` includieren (Login, GDM, `su`,
`sudo` usw.), nicht nur auf `sudo`. Das ist ein bewusst breiterer Eingriff als die
Pop!_OS-Lösung und wird hier **nicht** empfohlen, wenn nur `sudo` betroffen sein
soll — dafür reicht die manuelle Zeile in `/etc/pam.d/sudo` (4.2 oben).

> **Vorsicht bei `authselect`-Variante:** Es gibt einen dokumentierten Fedora-Bug,
> bei dem die Reihenfolge von `pam_u2f.so` relativ zur `substack`/`include
> system-auth`-Zeile über funktionierenden vs. komplett blockierten Login
> entscheidet. Vor Experimenten an `system-auth`/`password-auth` unbedingt eine
> zweite root-Sitzung offen halten. Dieses Risiko besteht bei der reinen
> `sudo`-only-Lösung (4.2) nicht, da dort nur eine isolierte Datei verändert wird.

---

## 5. Besonderheiten des Thetis-Sticks

Gilt für Pop!_OS und Fedora gleichermaßen:
- Sensor ist die **Metallfläche/das Logo**, nicht der Kunststoffrand.
- Erfordert echten Hautkontakt (kein Kunststoff/Papier).
- LED-Blinken kann schwach sein — direkt nach der PIN-Eingabe berühren.
- Kurzes Halten (~1–2 s) oder mehrfaches Antippen kann nötig sein.

---

## 6. Weitere Fedora-Besonderheiten

- **SELinux (enforcing per Default):** Anders als Pop!_OS läuft Fedora
  standardmäßig mit SELinux im Enforcing-Modus. Schlägt die Authentifizierung
  unerwartet fehl, lohnt ein Blick auf AVC-Denials:
  ```sh
  sudo ausearch -m avc -ts recent
  ```
  bzw. `sealert -a /var/log/audit/audit.log`, falls `setroubleshoot` installiert ist.
- **`cue` im Terminal vs. grafischem Login:** Die `cue`-Option (Hinweistext „Please
  touch the device“) funktioniert für `sudo` im Terminal auf jedem Desktop
  zuverlässig. Nur relevant, falls der Schlüssel zusätzlich für den grafischen
  Login aktiviert wird (siehe `authselect`-Variante oben): Bei KDE/SDDM ist ein
  bekannter Fehler dokumentiert, bei dem `cue` den Login-Screen blockiert (GNOME/GDM
  ist nicht betroffen). Für die reine `sudo`-Lösung in dieser Doku spielt das keine
  Rolle.

---

## 7. Sicherheits-Best-Practice (optional, beide Distributionen)

Mapping-Datei statt in `$HOME` root-owned unter `/etc/u2f_mappings` ablegen und in
der PAM-Zeile referenzieren:

```sh
pamu2fcfg -o pam://$(hostname) -i pam://$(hostname) | sudo tee /etc/u2f_mappings
sudo chown root:root /etc/u2f_mappings
sudo chmod 600 /etc/u2f_mappings
```

```
auth    sufficient    pam_u2f.so cue authfile=/etc/u2f_mappings
```

`openasuser` ist bei einer global unter `/etc` liegenden `authfile` nicht nötig,
da die Datei root-owned ist und von sudo (das ohnehin als root läuft) ohne
Nutzerwechsel gelesen werden kann.

---

## 8. Bekannte Einschränkungen

LUKS-Entschlüsselung beim Booten und der GNOME-Keyring greifen nicht auf PAM
zurück und benötigen weiterhin das Passwort — auf beiden Distributionen.
