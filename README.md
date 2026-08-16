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
1. Repository klonen:
   `git clone https://github.com/Macaldente/ZSH-Linux.git`
2. In das Verzeichnis wechseln:
   `cd ZSH-Linux`
3. Bestehende ZSH-Konfiguration sichern:
   `cp ~/.zshrc ~/.zshrc.backup`
4. Konfiguration installieren:
   `cp .zshrc .zsh_plugins.txt ~/`
5. ZSH neu laden:
   `source ~/.zshrc`
