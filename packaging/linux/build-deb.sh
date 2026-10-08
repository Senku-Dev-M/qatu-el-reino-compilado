#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/qatu-deb/qatu"
DIST_DIR="$ROOT_DIR/dist"
LINUX_DIR="$DIST_DIR/linux"

if [[ ! -f "$LINUX_DIR/QATU.x86_64" || ! -f "$LINUX_DIR/QATU.pck" ]]; then
  echo "Missing Linux export. Run the Godot Linux export command first." >&2
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p \
  "$BUILD_DIR/DEBIAN" \
  "$BUILD_DIR/opt/qatu" \
  "$BUILD_DIR/usr/games" \
  "$BUILD_DIR/usr/share/applications"

install -m 755 "$LINUX_DIR/QATU.x86_64" "$BUILD_DIR/opt/qatu/QATU.x86_64"
install -m 644 "$LINUX_DIR/QATU.pck" "$BUILD_DIR/opt/qatu/QATU.pck"

cat > "$BUILD_DIR/DEBIAN/control" <<'CONTROL'
Package: qatu
Version: 1.0.0
Section: games
Priority: optional
Architecture: amd64
Maintainer: Rodrigo Machaca Aruquipa
Description: Educational 2D metroidvania about software development
 QATU turns software-development topics into explorable zones,
 enemies, abilities, puzzles, and boss encounters.
CONTROL

cat > "$BUILD_DIR/usr/games/qatu" <<'LAUNCHER'
#!/bin/sh
exec /opt/qatu/QATU.x86_64 "$@"
LAUNCHER
chmod 755 "$BUILD_DIR/usr/games/qatu"

cat > "$BUILD_DIR/usr/share/applications/qatu.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=QATU: El Reino Compilado
Comment=Educational 2D metroidvania about software development
Exec=/usr/games/qatu
Terminal=false
Categories=Game;Education;
DESKTOP

mkdir -p "$DIST_DIR"
dpkg-deb --build --root-owner-group "$BUILD_DIR" "$DIST_DIR/qatu_1.0.0_amd64.deb"
echo "Created $DIST_DIR/qatu_1.0.0_amd64.deb"
