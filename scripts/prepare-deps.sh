#!/usr/bin/env bash
# Package Core (+ ProviderUtils) into the shared .alpackages cache so you can
# work on a single provider app without compiling the whole stack.
#
# Windows (most BC developers):  .\scripts\prepare-deps.ps1
# Linux / macOS:                 ./scripts/prepare-deps.sh
# Optional:                      set ALC to your alc / alc.exe path
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="$ROOT/.alpackages"
OUT="$CACHE"

find_alc() {
  if [[ -n "${ALC:-}" && -x "$ALC" ]]; then
    printf '%s\n' "$ALC"
    return
  fi

  local path newest=""
  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo unknown)"
  local alc_rel="bin/linux/alc"
  case "$uname_s" in
    Darwin*) alc_rel="bin/darwin/alc" ;;
    MINGW*|MSYS*|CYGWIN*) alc_rel="bin/win32/alc.exe" ;;
  esac

  shopt -s nullglob
  for path in \
    "$HOME/.cursor/extensions"/ms-dynamics-smb.al-*/$alc_rel \
    "$HOME/.cursor-server/extensions"/ms-dynamics-smb.al-*/$alc_rel \
    "$HOME/.vscode/extensions"/ms-dynamics-smb.al-*/$alc_rel \
    "$HOME/.vscode-server/extensions"/ms-dynamics-smb.al-*/$alc_rel
  do
    [[ -x "$path" || -f "$path" ]] || continue
    if [[ -z "$newest" || "$path" > "$newest" ]]; then
      newest="$path"
    fi
  done
  shopt -u nullglob

  if [[ -z "$newest" ]]; then
    echo "alc not found. On Windows prefer: .\\scripts\\prepare-deps.ps1" >&2
    echo "Or set ALC=/path/to/alc and re-run." >&2
    exit 1
  fi
  printf '%s\n' "$newest"
}

package_app() {
  local project="$1"
  local name
  name="$(basename "$project")"
  echo "==> Packaging $name"
  "$ALC" \
    /project:"$project" \
    /packagecachepath:"$CACHE" \
    /outfolder:"$OUT" \
    /errorsonlyinconsole
}

mkdir -p "$CACHE"
ALC="$(find_alc)"
echo "Using alc: $ALC"
echo "Package cache: $CACHE"

shopt -s nullglob
ms_apps=( "$CACHE"/Microsoft_Application_*.app )
shopt -u nullglob
if [[ ${#ms_apps[@]} -eq 0 ]]; then
  echo "No Microsoft Application symbols in $CACHE." >&2
  echo "Open apps/AIOpenSDK.Core, run AL: Download Symbols, then re-run this script." >&2
  exit 1
fi

package_app "$ROOT/apps/AIOpenSDK.Core"
package_app "$ROOT/apps/AIOpenSDK.ProviderUtils"

echo
echo "Done. Core + ProviderUtils are in $CACHE."
echo "You can open a single provider under apps/ and Package/Publish it."
echo "Docs: docs/DEVELOPMENT.md"
