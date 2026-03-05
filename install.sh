#!/bin/bash
DEST="/Applications/World of Warcraft/_retail_/Interface/AddOns/AutoSellPlus"
SRC="$(cd "$(dirname "$0")" && pwd)"

rm -rf "$DEST"
mkdir -p "$DEST"
cp "$SRC"/AutoSellPlus/* "$DEST"/

echo "Installed to $DEST"
