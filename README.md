# 🎉 Windows Package Manager

Winget is a Microsoft-developed command-line package manager for Windows that enables discovery, installation, and management of Windows apps through the command line. This repository collects day-to-day winget notes, an exported package list, and the workflow for creating and testing a new winget package manifest.

![platform](https://img.shields.io/badge/platform-windows-lightgrey)
![license](https://img.shields.io/github/license/natthasath/windows-package-manager)

### 🏆 Usage

```shell
winget list
winget search xxx
winget install xxx
winget upgrade --all
winget export -o package.json
winget import -i package.json
```

[`package.json`](package.json) is the exported package list in this repo — restore it on a new machine with `winget import -i package.json`.

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

### 📜 License

This project is licensed under the [MIT License](LICENSE).
