# QATU: El Reino Compilado

An educational 2D metroidvania built with Godot 4.7.2. The game turns software-development topics into explorable zones, enemies, abilities, puzzles, and boss encounters.

## Features

- Ten themed zones covering web development, architecture, security, asynchronous programming, identity, containers, testing, and related software-engineering topics.
- Data-driven educational content stored as JSON.
- Custom combat, movement, abilities, bosses, maps, saves, shops, and progression systems.
- Keyboard and controller support.
- Automated Godot test scenes for gameplay, content, routes, scripts, and progression.

## Requirements

- [Godot Engine 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) or a compatible 4.7.x release.
- Godot export templates for the same engine version when creating builds.
- Optional: [NSIS](https://nsis.sourceforge.io/) for the Windows installer.
- Optional: `dpkg-deb` on Debian, Ubuntu, or WSL for the Linux `.deb` package.

## Run from source

Open `project.godot` in Godot and press **F5**, or run:

```bash
godot --path .
```

### Controls

| Action | Keyboard | Controller |
|---|---|---|
| Move | Arrow keys or `A` / `D` | Left stick or D-pad |
| Look up/down | `W` / `S` | Left stick or D-pad |
| Jump | `Z` or `Space` | A |
| Attack | `X` or `J` | X |
| Ability | `C` or `K` | RB |
| Heal | Hold `F` or `L` while grounded | B |
| Interact | Up arrow | D-pad up |
| Map | Hold `Tab` | Select |
| Codex | `I` | Y |
| Pause | `Escape` | Start |

Controls can be remapped from the in-game options menu.

## Run the tests

Open the project once in the Godot editor so it can import resources and build its script-class cache. Then run:

```bash
godot --headless --path . res://tests/runner.tscn
```

## Build for Windows

Install the matching Godot export templates, then run from the repository root:

```powershell
New-Item -ItemType Directory -Force dist/windows | Out-Null
godot --headless --path . --export-release "Windows Desktop" dist/windows/QATU.exe
```

Because the preset does not embed the PCK, distribute both `QATU.exe` and `QATU.pck`.

To create a portable ZIP:

```powershell
Compress-Archive -Path dist/windows/* -DestinationPath dist/QATU-Windows.zip -Force
```

To generate a Windows installer, install NSIS and run:

```powershell
makensis packaging/windows/QATU.nsi
```

The installer is written to `dist/QATU-Windows-Setup.exe`.

## Build for Linux

Install the matching Godot export templates, then run:

```bash
mkdir -p dist/linux
godot --headless --path . --export-release "Linux" dist/linux/QATU.x86_64
chmod +x dist/linux/QATU.x86_64
```

Because the preset does not embed the PCK, distribute both `QATU.x86_64` and `QATU.pck`.

To create a portable archive:

```bash
tar -czf dist/QATU-Linux-x86_64.tar.gz -C dist/linux QATU.x86_64 QATU.pck
```

To generate a Debian/Ubuntu installer:

```bash
bash packaging/linux/build-deb.sh
```

The package is written to `dist/qatu_1.0.0_amd64.deb` and can be installed with:

```bash
sudo apt install ./dist/qatu_1.0.0_amd64.deb
```

## Project structure

```text
assets/     Runtime images used by the game
autoload/   Global state, saves, content, audio, settings, and routing
content/    Educational content and game data in JSON
fonts/      Runtime fonts and their licenses
rooms/      Room layouts and entity definitions
scenes/     Main menu and world scenes
scripts/    Player, enemies, bosses, objects, UI, and world systems
shaders/    Visual effects
tests/      Headless gameplay and content tests
packaging/  Windows and Linux installer definitions
```

## Credits

Created by Rodrigo Machaca Aruquipa.

The project uses the Cinzel and EB Garamond fonts under the SIL Open Font License. Godot Engine is available under the MIT License.
