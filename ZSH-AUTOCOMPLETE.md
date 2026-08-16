# zsh setup — `zsh-autocomplete` + Antidote

Dokumentation für die interaktive zsh-Umgebung auf diesem Rechner.
Zuletzt verifiziert: **2026-08-16** (Fedora Linux, zsh 5.9).
Portiert und angepasst aus dem `ZSH-Mac`-Repository (Commit `27dfec7`, 2026-08-15).

Das Kernfeature ist [`zsh-autocomplete`](https://github.com/marlonrichert/zsh-autocomplete),
das ein Vervollständigungsmenü **live beim Tippen** anzeigt, ohne Tastendruck.
Der Großteil der Konfiguration besteht nicht darin, es zu installieren — sondern
zu verhindern, dass andere Tools ihm die dafür nötigen Tasten wegnehmen.

---

## 1. Layout

```
~/.zshrc                        # einziger Einstiegspunkt, gesamte Konfiguration
~/.zsh_plugins.txt              # Antidote Plugin-Manifest (Ladereihenfolge wichtig)
~/.antidote/                    # Plugin-Manager (wird beim ersten Start geklont)
~/.zsh/plugins/                 # $ANTIDOTE_HOME — geklonte Plugins + Antidote-Cache
~/.cache/zsh/zcompdump          # Completion-Dump ($ZSH_COMPDUMP)
```

`ZDOTDIR` ist **nicht** gesetzt, zsh liest also `~/.zshrc` direkt.

---

## 2. Installation von Grund auf

Das Setup bootstrapt sich selbst. Auf einem neuen Rechner:

1. Externe Tools installieren (alle optional außer zsh selbst), z. B. via `dnf`:

   ```sh
   sudo dnf install zsh fzf atuin starship zoxide eza xclip
   ```

2. `~/.zshrc` an die richtige Stelle kopieren.

3. Neue Shell starten. `~/.zshrc` wird automatisch:
   - Antidote nach `~/.antidote` klonen, falls nicht vorhanden,
   - eine Standard-`~/.zsh_plugins.txt` schreiben, falls sie fehlt,
   - jedes im Manifest gelistete Plugin beim ersten `antidote load` klonen.

Der erste Start dauert ein paar Sekunden, weil Plugins geklont werden;
spätere Starts nutzen Antidotes statischen Cache (`~/.zsh/plugins/.antidote.load`).

> **Hinweis:** Das Manifest wird nur erzeugt, wenn `~/.zsh_plugins.txt` noch nicht
> existiert. Wird das Heredoc in `~/.zshrc` später verändert, wird eine bereits
> vorhandene Datei *nicht* überschrieben — dann `~/.zsh_plugins.txt` direkt bearbeiten.

---

## 3. Plugins und Ladereihenfolge

`~/.zsh_plugins.txt` — **Reihenfolge ist entscheidend**:

```
marlonrichert/zsh-autocomplete
mafredri/zsh-async
zsh-users/zsh-autosuggestions
Aloxaf/fzf-tab
zsh-users/zsh-syntax-highlighting
```

| # | Plugin | Warum an dieser Stelle |
|---|---|---|
| 1 | `zsh-autocomplete` | Muss vor jedem `compdef`-Aufruf laden; initialisiert das Completion-System selbst. |
| 2 | `zsh-async` | Abhängigkeit; muss vor ihren Konsumenten geladen werden. |
| 3 | `zsh-autosuggestions` | Wrappt ZLE-Widgets, lädt daher nach autocomplete. |
| 4 | `fzf-tab` | Erfasst die aktuelle Tab-Bindung beim Laden, autocomplete muss seine Widgets bereits gesetzt haben. |
| 5 | `zsh-syntax-highlighting` | **Muss zuletzt laden.** Wrappt jedes zuvor definierte Widget; danach geladene Dinge werden nicht mehr hervorgehoben. |

Plugin-Manager: `mattmc3/antidote`.

---

## 4. Die `compinit`-Regel

`zsh-autocomplete` ruft `compinit` selbst auf und entfernt die Funktion danach,
damit sie nicht doppelt aufgerufen werden kann. Die Upstream-Doku sagt klar:
*"Remove any calls to `compinit`."*

Daher enthält `~/.zshrc` **keinen `compinit`-Aufruf** mehr. Stattdessen wird nur
der Dump-Pfad exportiert:

```sh
export ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.cache/zsh/zcompdump"
mkdir -p "${ZDOTDIR:-$HOME}/.cache/zsh"
```

`ZSH_COMPDUMP` ist die Variable, die das Plugin tatsächlich liest. Ein anderer
Variablenname (z. B. `ZCOMPDUMP`) wird stillschweigend ignoriert und der Dump
landet stattdessen am XDG-Standardort.

Completion wird lazy über autocompletes `precmd`-Hook initialisiert, ist also
in einem nicht-interaktiven `zsh -c`-Aufruf **nicht** befüllt. In einer echten
interaktiven Shell testen (siehe §7).

---

## 5. Tastenkonflikte

Mehrere Tools konkurrieren um dieselben Tasten. Aktuelle Auflösung:

| Taste | Geht an | Widget |
|---|---|---|
| *(Tippen)* | zsh-autocomplete Live-Menü | — |
| Tab | fzf-tab | `fzf-tab-complete` |
| ↑ | zsh-autocomplete Historie | `.autocomplete__up-line-or-search__zle-widget` |
| ↓ | zsh-autocomplete Menü | `.autocomplete__down-line-or-select__zle-widget` |
| Ctrl + R | atuin | `_atuin_search` |
| Ctrl + T | fzf Datei-Picker | `fzf-file-widget` |
| Alt + C | fzf cd-Picker | `fzf-cd-widget` |

### 5.1 Tab — fzf-tab vs. zsh-autocomplete

Beide ersetzen die Tab-Completion-UI; sie können sie nicht beide besitzen.
**fzf-tab gewinnt hier bewusst.** Trade-off: das Live-Menü und die Historien-
Navigation von autocomplete bleiben erhalten, aber Tab-Completion läuft über
fzf statt über autocomplete. `~/.zshrc` bindet Tab nach dem Laden von fzf
zurück an fzf-tab, abgesichert durch einen `$+widgets`-Check:

```sh
if (( $+widgets[fzf-tab-complete] )); then
  bindkey -M emacs '^I' fzf-tab-complete
  bindkey -M viins '^I' fzf-tab-complete
fi
```

Der Guard sorgt dafür, dass dies sicher entfällt, falls fzf-tab je entfernt wird.

### 5.2 Pfeiltaste hoch — atuin vs. zsh-autocomplete

Standardmäßig bindet `atuin init zsh` sowohl ↑ als auch Ctrl+R. Da atuin am
Ende von `~/.zshrc` initialisiert wird, würde es sonst beide gewinnen.
`ATUIN_NOBIND` deaktiviert das gesamte Standard-Keymap von atuin, sodass die
Pfeiltasten bei autocomplete bleiben; Ctrl+R wird danach manuell zurückgebunden:

```sh
export ATUIN_NOBIND=true
eval "$(atuin init zsh)"
bindkey -M emacs '^R' atuin-search
bindkey -M viins '^R' atuin-search
```

### 5.3 Ctrl+R — atuin vs. fzf

Beide wollen diese Taste. **atuin besitzt sie**; fzf behält nur Ctrl+T und Alt+C.
Um das umzukehren, die beiden `bindkey ... atuin-search`-Zeilen entfernen —
dann übernimmt fzfs eigene Ctrl+R-Bindung.

---

## 6. Faustregel für neue Tools

Alles, was `bindkey` aufruft — `fzf`, `atuin`, `zoxide`, `mcfly`, `navi` —
konkurriert mit zsh-autocomplete, wenn es sich *nach* `antidote load`
initialisiert. Beim Hinzufügen eines neuen Tools:

1. Prüfen, was es sich genommen hat: `bindkey | grep -i <taste>`
2. Die eigene Opt-out-Option des Tools bevorzugen (`ATUIN_NOBIND`,
   `FZF_DEFAULT_OPTS`, `--no-bind`).
3. Andernfalls die betroffene Taste direkt nach dem `eval` des Tools
   zurückbinden, abgesichert mit `(( $+widgets[...] ))`.

---

## 7. Setup verifizieren

> **Nicht mit `whence autocomplete` testen.** `zsh-autocomplete` definiert nie
> einen Befehl mit diesem Namen — es stellt nur ZLE-Widgets und Punkt-
> präfigierte Funktionen bereit. Dieser Check meldet auch bei einer perfekt
> funktionierenden Installation immer einen Fehlschlag.

Korrekte Checks — **an einem Prompt eintippen**, nicht per `zsh -c` ausführen.
`zsh -c` rendert nie einen Prompt, der `precmd`-Hook feuert also nie,
`compinit` läuft nie, und `${#_comps}` meldet fälschlich `0`:

```sh
# Plugin tatsächlich geladen?
(( $+functions[.autocomplete__main] )) && echo loaded

# precmd-Hook installiert (sollte zuerst stehen)
print $precmd_functions

# wer besitzt welche Taste (einzeln abfragen — mehrere Argumente
# an bindkey würden sie *zuweisen* statt sie aufzulisten)
for k in '^I' '^[[A' '^R'; do bindkey "$k"; done

# Completion-System aktiv (ein paar Tausend erwartet, nicht 0)
print ${#_comps}
```

Schnellster End-to-End-Test: neue Shell öffnen und `ls --` eintippen — es sollte
von selbst ein Menü mit Optionen erscheinen, ohne weitere Tastendrücke.

Die fzf/atuin-Overlays lassen sich nur visuell durch Drücken von Tab und
Ctrl+R bestätigen. Sie lassen sich nicht über einen `zpty`-Harness verifizieren,
da `zpty` keine Terminal-Fenstergröße liefert und beide Programme ohne diese
nicht zeichnen.

Änderungen mit `exec zsh` anwenden.

---

## 8. Backups

Vor Änderungen empfiehlt es sich, Zeitstempel-Kopien anzulegen, z. B.:

```
~/.zshrc.bak.<timestamp>
~/.zsh_plugins.txt.bak.<timestamp>
```

Wiederherstellen mit `cp ~/.zshrc.bak.<timestamp> ~/.zshrc && exec zsh`.
