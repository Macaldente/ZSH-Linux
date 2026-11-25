# ZSH-Linux
Dieses Repository enthält meine `.zshrc` für Linux.

## Inhalt
| Datei | Zweck |
|---|---|
| `.zshrc` | Haupt-Shell-Konfiguration (Antidote, zsh-autocomplete-Stack, Aliase, Tools) |
| `.zsh_plugins.txt` | Antidote Plugin-Manifest (Ladereihenfolge wichtig) |
| `ZSH-AUTOCOMPLETE.md` | Doku zu zsh-autocomplete, compinit-Regel und Tastenkonflikten |
| `sudo-via-fido-pam.md` | Doku zu sudo-Bestätigung per FIDO2/U2F-Stick (`pam_u2f`), inkl. Fedora-Unterschiede |

## Installation auf einem zweiten Rechner

> **Nur auf Linux ausführen.** Auf dem Mac würde Schritt 4 die `.zshrc` aus
> [`ZSH-Mac`](https://github.com/Macaldente/ZSH-Mac) überschreiben (dort ist
> `~/.zshrc` ein `stow`-Symlink ins Repo), und Schritt 5 kollidiert mit dem
> vorhandenen `git-look`-Link. Zur Absicherung bricht die `.zshrc` beim Laden auf
> einem Nicht-Linux-System sofort mit einer Meldung ab; die Mac-`.zshrc` hat den
> umgekehrten Wächter. Versehentlich überschrieben? Im `ZSH-Mac`-Repo
> `git restore .zshrc .zsh_plugins.txt` ausführen.

1. Repository klonen:
   `git clone https://github.com/Macaldente/ZSH-Linux.git`
2. In das Verzeichnis wechseln:
   `cd ZSH-Linux`
3. Bestehende ZSH-Konfiguration sichern:
   `cp ~/.zshrc ~/.zshrc.backup`
4. Konfiguration installieren:
   `cp .zshrc .zsh_plugins.txt ~/`
5. `git look` installieren (zeigt, ob es in den Repos unter `~/Git` Updates vom Remote gibt):
   `mkdir -p ~/.local/bin && ln -s "$PWD/.local/bin/git-look" ~/.local/bin/git-look`
6. ZSH neu laden:
   `source ~/.zshrc`
