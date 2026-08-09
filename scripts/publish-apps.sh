#!/usr/bin/env bash
# Package and publish AI Open SDK apps to Business Central (dev endpoint).
# Same deployment path VS Code uses for F5 / AL: Publish.
#
# Windows (typical):  .\scripts\publish-apps.ps1
# Linux / macOS:      ./scripts/publish-apps.sh
#
# Usage:
#   ./scripts/publish-apps.sh
#   ./scripts/publish-apps.sh --set all
#   ./scripts/publish-apps.sh --apps AIOpenSDK.Core,AIOpenSDK.Provider.OpenAI
#   ./scripts/publish-apps.sh --package-only
#
# Target (first match wins per field):
#   flags → BC_* env vars → apps/AIOpenSDK.Core/.vscode/launch.json
#
# Credentials (UserPassword): BC_USERNAME + BC_PASSWORD
# Bearer token (optional):     BC_ACCESS_TOKEN
# Optional:                    ALC=/path/to/alc
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="$ROOT/.alpackages"
SET="runtime"
APPS_CSV=""
LAUNCH_JSON="${LAUNCH_JSON:-$ROOT/apps/AIOpenSDK.Core/.vscode/launch.json}"
SCHEMA_UPDATE_MODE="Synchronize"
DEPENDENCY_PUBLISHING_OPTION="Default"
PACKAGE_ONLY=0
SKIP_PACKAGE=0

SERVER="${BC_SERVER:-}"
SERVER_INSTANCE="${BC_SERVER_INSTANCE:-}"
PORT="${BC_PORT:-}"
AUTHENTICATION="${BC_AUTHENTICATION:-}"
ENVIRONMENT_TYPE="${BC_ENVIRONMENT_TYPE:-}"
ENVIRONMENT_NAME="${BC_ENVIRONMENT_NAME:-}"
TENANT="${BC_TENANT:-}"

ALL_APPS=(
  AIOpenSDK.Core
  AIOpenSDK.ProviderUtils
  AIOpenSDK.Provider.OpenAI
  AIOpenSDK.Provider.Anthropic
  AIOpenSDK.Provider.OpenAICompatible
  AIOpenSDK.Provider.OpenCodeZen
  AIOpenSDK.Examples
  AIOpenSDK.Test
)

RUNTIME_APPS=(
  AIOpenSDK.Core
  AIOpenSDK.ProviderUtils
  AIOpenSDK.Provider.OpenAI
  AIOpenSDK.Provider.Anthropic
  AIOpenSDK.Provider.OpenAICompatible
  AIOpenSDK.Provider.OpenCodeZen
)

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --set) SET="$2"; shift 2 ;;
    --apps) APPS_CSV="$2"; shift 2 ;;
    --launch-json) LAUNCH_JSON="$2"; shift 2 ;;
    --schema-update-mode) SCHEMA_UPDATE_MODE="$2"; shift 2 ;;
    --dependency-publishing-option) DEPENDENCY_PUBLISHING_OPTION="$2"; shift 2 ;;
    --server) SERVER="$2"; shift 2 ;;
    --server-instance) SERVER_INSTANCE="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --authentication) AUTHENTICATION="$2"; shift 2 ;;
    --environment-type) ENVIRONMENT_TYPE="$2"; shift 2 ;;
    --environment-name) ENVIRONMENT_NAME="$2"; shift 2 ;;
    --tenant) TENANT="$2"; shift 2 ;;
    --package-only) PACKAGE_ONLY=1; shift ;;
    --skip-package) SKIP_PACKAGE=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown argument: $1" >&2; usage 1 ;;
  esac
done

resolve_app_list() {
  if [[ -n "$APPS_CSV" ]]; then
    IFS=',' read -r -a APP_LIST <<< "$APPS_CSV"
    return
  fi
  case "$SET" in
    all) APP_LIST=("${ALL_APPS[@]}") ;;
    core) APP_LIST=(AIOpenSDK.Core) ;;
    providers)
      APP_LIST=(
        AIOpenSDK.Provider.OpenAI
        AIOpenSDK.Provider.Anthropic
        AIOpenSDK.Provider.OpenAICompatible
        AIOpenSDK.Provider.OpenCodeZen
      )
      ;;
    runtime) APP_LIST=("${RUNTIME_APPS[@]}") ;;
    *) echo "Invalid --set: $SET (runtime|all|core|providers)" >&2; exit 1 ;;
  esac
}

find_alc() {
  if [[ -n "${ALC:-}" && -x "$ALC" ]]; then
    printf '%s\n' "$ALC"
    return
  fi

  local path newest=""
  local uname_s alc_rel
  uname_s="$(uname -s 2>/dev/null || echo unknown)"
  alc_rel="bin/linux/alc"
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
    echo "alc not found. On Windows prefer: .\\scripts\\publish-apps.ps1" >&2
    echo "Or set ALC=/path/to/alc and re-run." >&2
    exit 1
  fi
  printf '%s\n' "$newest"
}

json_field() {
  # json_field <file> <key> — minimal extractor for flat app.json / launch values
  local file="$1" key="$2"
  python3 - "$file" "$key" <<'PY'
import json, sys, re
path, key = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
text = re.sub(r"(?m)^\s*//.*$", "", text)
data = json.loads(text)
if key.startswith("cfg."):
    cfgs = data.get("configurations") or []
    onprem = next((c for c in cfgs if c.get("environmentType") == "OnPrem"), None)
    cfg = onprem or (cfgs[0] if cfgs else {})
    val = cfg.get(key[4:], "")
else:
    val = data.get(key, "")
if val is None:
    val = ""
print(val)
PY
}

app_out_path() {
  local project="$1"
  local publisher name version
  publisher="$(json_field "$project/app.json" publisher)"
  name="$(json_field "$project/app.json" name)"
  version="$(json_field "$project/app.json" version)"
  printf '%s/%s_%s_%s.app\n' "$CACHE" "$publisher" "$name" "$version"
}

package_app() {
  # stdout: package path only (captured by callers). Status + alc → stderr.
  local project="$1"
  local name out
  name="$(basename "$project")"
  out="$(app_out_path "$project")"
  echo "==> Packaging $name" >&2
  "$ALC" \
    /project:"$project" \
    /packagecachepath:"$CACHE" \
    /out:"$out" \
    /errorsonlyinconsole >&2
  [[ -f "$out" ]] || { echo "Expected package not found: $out" >&2; exit 1; }
  printf '%s\n' "$out"
}

load_launch_defaults() {
  [[ -f "$LAUNCH_JSON" ]] || return 0
  if [[ -z "$SERVER" && -z "$ENVIRONMENT_NAME" ]]; then
    echo "Using launch config: $LAUNCH_JSON"
  fi
  [[ -n "$ENVIRONMENT_TYPE" ]] || ENVIRONMENT_TYPE="$(json_field "$LAUNCH_JSON" cfg.environmentType)"
  [[ -n "$ENVIRONMENT_NAME" ]] || ENVIRONMENT_NAME="$(json_field "$LAUNCH_JSON" cfg.environmentName)"
  [[ -n "$SERVER" ]] || SERVER="$(json_field "$LAUNCH_JSON" cfg.server)"
  [[ -n "$SERVER_INSTANCE" ]] || SERVER_INSTANCE="$(json_field "$LAUNCH_JSON" cfg.serverInstance)"
  [[ -n "$PORT" ]] || PORT="$(json_field "$LAUNCH_JSON" cfg.port)"
  [[ -n "$AUTHENTICATION" ]] || AUTHENTICATION="$(json_field "$LAUNCH_JSON" cfg.authentication)"
  [[ -n "$TENANT" ]] || TENANT="$(json_field "$LAUNCH_JSON" cfg.tenant)"
}

dev_apps_url() {
  local query base tenant mode dep
  # BC expects lowercase SchemaUpdateMode values (synchronize|recreate|forcesync)
  mode="$(printf '%s' "$SCHEMA_UPDATE_MODE" | tr '[:upper:]' '[:lower:]')"
  dep="$(printf '%s' "$DEPENDENCY_PUBLISHING_OPTION" | tr '[:upper:]' '[:lower:]')"
  query="SchemaUpdateMode=${mode}&DependencyPublishingOption=${dep}"
  [[ -n "$TENANT" ]] && query+="&tenant=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$TENANT")"

  ENVIRONMENT_TYPE="${ENVIRONMENT_TYPE:-OnPrem}"
  PORT="${PORT:-7049}"
  AUTHENTICATION="${AUTHENTICATION:-UserPassword}"
  TENANT="${TENANT:-default}"

  if [[ "$ENVIRONMENT_TYPE" == "Sandbox" || "$ENVIRONMENT_TYPE" == "Production" ]]; then
    [[ -n "$ENVIRONMENT_NAME" ]] || {
      echo "Cloud publish requires EnvironmentName (--environment-name or BC_ENVIRONMENT_NAME)." >&2
      exit 1
    }
    tenant="${TENANT:-common}"
    printf 'https://api.businesscentral.dynamics.com/v2.0/%s/%s/dev/apps?%s\n' "$tenant" "$ENVIRONMENT_NAME" "$query"
    return
  fi

  [[ -n "$SERVER" && -n "$SERVER_INSTANCE" ]] || {
    echo "OnPrem publish requires Server and ServerInstance (launch.json or --server / BC_SERVER)." >&2
    exit 1
  }

  base="${SERVER%/}"
  if [[ ! "$base" =~ ^https?:// ]]; then
    base="http://$base"
  fi
  printf '%s:%s/%s/dev/apps?%s\n' "$base" "$PORT" "$SERVER_INSTANCE" "$query"
}

publish_app() {
  # Dev endpoint expects multipart/form-data (same as VS Code / BcContainerHelper), not raw octet-stream.
  local app_path="$1" url="$2"
  local name body_file http_code curl_args
  [[ -f "$app_path" ]] || {
    echo "Package file not found: $app_path" >&2
    exit 1
  }
  name="$(basename "$app_path")"
  echo "==> Publishing $name"
  echo "    $url"

  body_file="$(mktemp)"
  curl_args=(
    -sS
    -X POST
    -F "${name}=@${app_path};filename=${name};type=application/octet-stream"
    --max-time 600
    -w '%{http_code}'
    -o "$body_file"
  )

  if [[ -n "${BC_ACCESS_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer ${BC_ACCESS_TOKEN}")
  elif [[ "$AUTHENTICATION" == "Windows" ]]; then
    curl_args+=(--negotiate -u :)
  else
    [[ -n "${BC_USERNAME:-}" && -n "${BC_PASSWORD:-}" ]] || {
      echo "Set BC_USERNAME and BC_PASSWORD (UserPassword), or BC_ACCESS_TOKEN." >&2
      rm -f "$body_file"
      exit 1
    }
    curl_args+=(-u "${BC_USERNAME}:${BC_PASSWORD}")
  fi

  http_code="$(curl "${curl_args[@]}" "$url" || true)"
  if [[ "$http_code" != 2* ]]; then
    echo "Publish failed for $name (HTTP ${http_code:-000})" >&2
    if [[ -s "$body_file" ]]; then
      echo "---- response ----" >&2
      cat "$body_file" >&2
      echo >&2
      echo "------------------" >&2
    fi
    rm -f "$body_file"
    exit 1
  fi
  rm -f "$body_file"
  echo "    OK ($http_code)"
}

resolve_app_list
for a in "${APP_LIST[@]}"; do
  [[ -f "$ROOT/apps/$a/app.json" ]] || {
    echo "Unknown app folder: $a" >&2
    exit 1
  }
done

mkdir -p "$CACHE"
PACKAGED=()

if [[ "$SKIP_PACKAGE" -eq 0 ]]; then
  shopt -s nullglob
  ms_apps=( "$CACHE"/Microsoft_Application_*.app )
  shopt -u nullglob
  if [[ ${#ms_apps[@]} -eq 0 ]]; then
    echo "No Microsoft Application symbols in $CACHE." >&2
    echo "Open apps/AIOpenSDK.Core, run AL: Download Symbols, then re-run this script." >&2
    exit 1
  fi

  ALC="$(find_alc)"
  echo "Using alc: $ALC"
  echo "Package cache: $CACHE"
  echo "Apps: ${APP_LIST[*]}"
  echo

  for a in "${APP_LIST[@]}"; do
    PACKAGED+=( "$(package_app "$ROOT/apps/$a")" )
  done
else
  echo "SkipPackage: using existing .app files in $CACHE"
  for a in "${APP_LIST[@]}"; do
    out="$(app_out_path "$ROOT/apps/$a")"
    [[ -f "$out" ]] || {
      echo "Missing package for $a. Run without --skip-package first. Expected: $out" >&2
      exit 1
    }
    PACKAGED+=( "$out" )
  done
fi

if [[ "$PACKAGE_ONLY" -eq 1 ]]; then
  echo
  echo "PackageOnly: done. Apps are in $CACHE"
  printf '  %s\n' "${PACKAGED[@]}"
  exit 0
fi

load_launch_defaults
URL="$(dev_apps_url)"

echo
echo "Publish target: ${ENVIRONMENT_TYPE:-OnPrem}  auth=${AUTHENTICATION:-UserPassword}"
echo

for app_path in "${PACKAGED[@]}"; do
  publish_app "$app_path" "$URL"
done

echo
echo "Done. Published ${#PACKAGED[@]} app(s)."
echo "Docs: docs/DEVELOPMENT.md"
