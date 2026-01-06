# 🎉 Windows Package Manager

Winget is a Microsoft-developed command-line package manager for Windows that enables discovery, installation, and management of Windows apps through command line. It uses Windows Package Manager manifest format and PowerShellGet module for app metadata and installation management.

![version](https://img.shields.io/badge/version-1.0-blue)
![rating](https://img.shields.io/badge/rating-★★★★★-yellow)
![uptime](https://img.shields.io/badge/uptime-100%25-brightgreen)

### 📝 Notes

```shell
winget list
winget search xxx
winget install xxx
winget upgrade --all
winget export -o package.json
winget import -i package.json
```

### 📦 Create Package

```shell
winget install wingetcreate
winget show --id Natthasath.hostctl --source winget
wingetcreate new https://github.com/natthasath/exam-timer/releases/download/v1.0.0/ExamTimer.exe

---
- Package identifier: Natthasath.ExamTimer
- Publisher: Natthasath Saksupanara
- Package name: Exam Timer
- License: MIT
---

```

### 🪅 Test Install Silent Mode

```shell
Start-Process -FilePath ".\Exam Timer Setup 1.0.0.exe" -ArgumentList "/S" -Wait
cmd /c "Exam Timer Setup 1.0.0.exe" /S
& ".\Exam Timer Setup 1.0.0.exe" /S
```