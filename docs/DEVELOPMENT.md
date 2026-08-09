# Development guide

How to work with this multi-app repo day to day. Each folder under `apps/` is its own AL extension; they share one Microsoft symbol cache at the **repo root** `.alpackages/`.

Most Business Central developers use **Windows**. Commands below show PowerShell first; Linux/macOS alternatives are noted where they differ.

## Mental model

```
Microsoft symbols  ──►  .alpackages/   (Download Symbols once)
Core.app           ──►  .alpackages/   (package Core)
ProviderUtils.app  ──►  .alpackages/   (package Utils)
your provider      ──►  compiles against those packages
```

“Download Symbols” only fills **Microsoft** apps (and anything already published on your BC server). Sibling apps in this repo are **not** downloaded automatically — you package them into `.alpackages` (script or VS Code / Visual Studio Code AL: Package).

All apps use `al.packageCachePath` → `../../.alpackages` (or the workspace setting). One download applies to every app. That is intentional.

---

## Path A — Use the SDK in your own extension

1. Publish/install the apps you need on the environment (Core + provider(s); Utils comes with Completions providers).
2. In **your** app’s `app.json`, add dependencies on those app ids/names/versions (see each `apps/*/app.json`).
3. Download Symbols in your project.

You do not need this monorepo open unless you are changing the SDK.

---

## Path B — Work on Core (or the whole stack)

1. Open [`AL-AI-Toolkit.code-workspace`](../AL-AI-Toolkit.code-workspace) (or `apps/AIOpenSDK.Core`).
2. Configure `apps/AIOpenSDK.Core/.vscode/launch.json` for your BC (copy from [`.vscode/launch.json.example`](../.vscode/launch.json.example) if needed).
3. **AL: Download Symbols** once (from Core is enough).
4. Package/publish in order when something depends on a change:
   - Core → ProviderUtils → providers → Examples → Test

Or from the repo root, publish the runtime stack (Core + Utils + providers) via the BC **dev endpoint** (same path as VS Code Publish):

```powershell
# Windows — reads apps\AIOpenSDK.Core\.vscode\launch.json by default
$env:BC_USERNAME = 'YOUR_USER'
$env:BC_PASSWORD = 'YOUR_PASSWORD'
.\scripts\publish-apps.ps1              # runtime apps
.\scripts\publish-apps.ps1 -Set all     # + Examples + Test
.\scripts\publish-apps.ps1 -PackageOnly # alc package only, no publish
```

```bash
# Linux / macOS
export BC_USERNAME='YOUR_USER'
export BC_PASSWORD='YOUR_PASSWORD'
./scripts/publish-apps.sh
./scripts/publish-apps.sh --set all
./scripts/publish-apps.sh --package-only
```

Override target with `-Server` / `BC_SERVER` (etc.), or `--apps AIOpenSDK.Core,AIOpenSDK.Provider.OpenAI`. SaaS/AAD needs `BC_ACCESS_TOKEN` (interactive AAD login stays in VS Code).

---

## Path C — Work only on a provider (or add a new one)

You only need Microsoft symbols + **Core** (+ **ProviderUtils** for Chat Completions). You do not need to compile every other provider.

### First time in the clone

From the **repo root**:

```powershell
# Windows (PowerShell)
.\scripts\prepare-deps.ps1
```

```bash
# Linux / macOS
./scripts/prepare-deps.sh
```

That packages Core + ProviderUtils into `.alpackages`. If Microsoft symbols are missing, open Core once, run **Download Symbols**, then re-run the script.

If PowerShell blocks the script:  
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`  
(or run: `powershell -ExecutionPolicy Bypass -File .\scripts\prepare-deps.ps1`).

### Then work in the provider folder

1. Open `apps/AIOpenSDK.Provider.<YourProvider>/` (or the workspace and focus that folder).
2. Edit code; Package / Publish that app only.
3. After you pull Core/Utils changes from `main`, re-run `prepare-deps` so `.alpackages` has fresh dependency apps.

### New provider checklist

1. Copy an existing sibling (e.g. Anthropic for a custom HTTP API, or OpenAICompatible for Chat Completions).
2. New folder: `apps/AIOpenSDK.Provider.<Name>/` with its own `app.json`, `src/`, `.vscode/` (settings already use `../../.alpackages`).
3. Dependencies:
   - Always: **AI Open SDK** (Core)
   - Chat Completions wire format: also **AI Open SDK Provider Utils**
   - Never: another vendor provider app
4. Pick free object IDs in the provider band (see [OBJECT_IDS.md](OBJECT_IDS.md)); update that doc.
5. Implement `"AIOS Language Model"` (and Format/Options if needed). Prefer Utils’ `"AIOS Chat Completions Client"` when the API is Chat Completions.
6. Add a mock-oriented test in `apps/AIOpenSDK.Test` if Core contracts are involved; format-only coverage can live next to the provider later.
7. Run `prepare-deps`, then package your provider.

---

## Path D — Examples / Test

- **Examples**: needs Core + the providers the demo uses (see its `app.json`). Run `prepare-deps`, then package those providers into `.alpackages` (AL: Package on each).
- **Test**: mock tests need Core (Mock is in Core). Some tests also need ProviderUtils, Anthropic Format, and Examples (sample tools). Prefer packaging via the workspace after deps are prepared.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Provider can’t find `"AIOS Client"` / Core | Run `.\scripts\prepare-deps.ps1` (or `.sh`) / Package Core into `.alpackages` |
| Completions provider can’t find Format/Client | Package ProviderUtils after Core |
| Download Symbols “works for all apps” | Expected — shared `.alpackages` |
| Weird folder `apps/.../${workspaceFolder:repo}/.alpackages` | Delete it; open the **workspace** or use per-app `../../.alpackages` only |
| Only changed Core but provider still sees old API | Re-run `prepare-deps` (stale Core.app in cache) |
| `alc.exe` / `alc` not found | Install AL Language extension, or set `$env:ALC` / `ALC` to the compiler path |
| Publish auth failed (401/403) | Set `BC_USERNAME`/`BC_PASSWORD`, or `BC_ACCESS_TOKEN` for bearer; check launch.json server/instance/port |
| Publish 422 / dependency errors | Publish in order (`publish-apps` default), or use `-Set runtime` before Examples/Test |

---

## Public API

See [PUBLIC_API.md](PUBLIC_API.md). Prefer documented Public objects; `* Model` codeunits are Internal.
