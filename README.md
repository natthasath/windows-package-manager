# 🎉 Windows Package Manager

Winget is a Microsoft-developed command-line package manager for Windows that enables discovery, installation, and management of Windows apps through the command line. This repository collects day-to-day winget notes, an exported package list, and the workflow for creating and testing a new winget package manifest.

![platform](https://img.shields.io/badge/platform-windows-lightgrey)
![license](https://img.shields.io/github/license/natthasath/windows-package-manager)

### ✅ Requirements

Windows blocks running local PowerShell scripts by default (`Restricted` execution policy). This breaks the profile setup below and any local `.ps1` helper script with a `cannot be loaded because running scripts is disabled on this system` error.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

> [!IMPORTANT]
> Run this once per user before setting up the PowerShell profile or installing packages — otherwise local scripts (including `$PROFILE`) silently fail to load.

### ⚙️ Configuration

Install PowerShell 7 and set it as the default shell (replacing Windows PowerShell 5.1), then enable predictive IntelliSense:

```shell
winget install --id Microsoft.PowerShell --source winget
```

Set PowerShell 7 (`pwsh`) as the default profile in Windows Terminal (Settings → Startup → Default profile → **PowerShell**), then add the following to the PowerShell 7 profile (`$PROFILE`) to show inline suggestions from command history:

```powershell
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle InlineView
```

### 🏆 Usage

```shell
winget list
winget search xxx
winget install xxx
winget upgrade --all
winget export -o package.json
winget import -i package.json --accept-package-agreements --accept-source-agreements --ignore-unavailable
```

[`package.json`](package.json) is the exported package list in this repo — restore it on a new machine with the import command above. It mixes the `winget` and `msstore` sources, so the extra flags avoid a partial import failure; see Troubleshooting below if you'd rather export per source instead.

### 🧩 Create Package

```shell
winget install wingetcreate
winget show --id Natthasath.hostctl --source winget
wingetcreate new https://github.com/natthasath/exam-timer/releases/download/v1.0.0/ExamTimer.exe
```

| Field | Value |
| --- | --- |
| Package identifier | `Natthasath.ExamTimer` |
| Publisher | Natthasath Saksupanara |
| Package name | Exam Timer |
| License | MIT |

### 🧪 Testing

```shell
Start-Process -FilePath ".\Exam Timer Setup 1.0.0.exe" -ArgumentList "/S" -Wait
cmd /c "Exam Timer Setup 1.0.0.exe" /S
& ".\Exam Timer Setup 1.0.0.exe" /S
```

### ⚠️ Troubleshooting

**Mixed sources in `winget export`** — `winget export -o package.json` without `--source` bundles packages from every enabled source into one file. In this repo that means `winget` and `msstore` entries mixed together, which causes problems when importing on another machine:

- `msstore` entries are Microsoft Store Product IDs (e.g. `9NBLGGH6BZL3`) tied to a signed-in Microsoft account and region — they fail to install on a machine/account without access to that app.
- Each source needs its own agreement acceptance; running `winget import` non-interactively without the right flags hangs or errors out.
- If a source isn't registered on the target machine, every package from it fails to import unless ignored explicitly.

> [!IMPORTANT]
> Run `winget import -i package.json --accept-package-agreements --accept-source-agreements --ignore-unavailable` to avoid partial import failures.

A cleaner fix is exporting per source instead of mixing them:

```shell
winget export -o package-winget-only.json --source winget
winget export -o package-msstore-only.json --source msstore
```

[`package-winget-only.json`](package-winget-only.json) and [`package-msstore-only.json`](package-msstore-only.json) in this repo are kept separate for exactly this reason — restore them independently with `winget import -i <file>` to avoid Microsoft Store account/region issues entirely.

### 📜 License

This project is licensed under the [MIT License](LICENSE).
