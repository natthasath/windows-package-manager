<#
.SYNOPSIS
    Sets up PowerShell tab completion for Claude Code CLI (claude), Codex CLI (codex),
    Agy CLI (agy), and OpenCode CLI (opencode) on Windows 11.

.DESCRIPTION
    - codex ships a native completion generator (`codex completion powershell`); this
      script captures its output and uses it as-is.
    - claude and agy have no completion subcommand as of this writing, so this script
      writes hand-authored completers covering their documented top-level subcommands
      and flags (derived from `claude --help` / `agy --help`).
    - opencode has a `--completions <bash|zsh|fish|sh>` flag but no powershell target, so
      it also gets a hand-authored completer (derived from `opencode --help`).

    Generated completers are written as standalone .ps1 files under -CompletionsDir
    (default: a "Completions" folder next to your PowerShell profile). The script then
    adds a small, idempotent, marker-delimited block to your profile that dot-sources
    whichever of those files exist AND whose matching command is currently on PATH, so
    nothing breaks on a machine that only has some of the four tools installed.

    Re-run this script any time after upgrading one of these CLIs (codex in particular)
    to refresh the generated completions.

.PARAMETER ProfilePath
    Path to the PowerShell profile to update. Defaults to $PROFILE.

.PARAMETER CompletionsDir
    Directory the per-tool completion scripts are written to. Defaults to a
    "Completions" folder next to $ProfilePath.

.EXAMPLE
    .\Install-TabCompletion.ps1
    Generates completers for whichever of claude/codex/agy/opencode are installed and
    wires them into the current user's PowerShell profile.
#>

[CmdletBinding()]
param(
    [string]$ProfilePath = $PROFILE,
    [string]$CompletionsDir = (Join-Path (Split-Path -Parent $PROFILE) 'Completions')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-CommandAvailable {
    param([Parameter(Mandatory)][string]$Name)
    [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

New-Item -ItemType Directory -Path $CompletionsDir -Force | Out-Null

$installed = [System.Collections.Generic.List[string]]::new()
$skipped   = [System.Collections.Generic.List[string]]::new()

# ---------------------------------------------------------------------------
# codex — native generator (clap_complete), used verbatim
# ---------------------------------------------------------------------------
$codexFile = Join-Path $CompletionsDir 'codex.ps1'
if (Test-CommandAvailable 'codex') {
    codex completion powershell | Set-Content -Path $codexFile -Encoding utf8
    $installed.Add('codex (native: codex completion powershell)')
}
else {
    Remove-Item -Path $codexFile -ErrorAction SilentlyContinue
    $skipped.Add('codex (not found on PATH)')
}

# ---------------------------------------------------------------------------
# claude — hand-authored (no completion subcommand as of this writing)
# ---------------------------------------------------------------------------
$claudeFile = Join-Path $CompletionsDir 'claude.ps1'
@'
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -Native -CommandName 'claude' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $subCommands = @(
        @{ Name = 'agents';      Desc = 'Manage background agents' }
        @{ Name = 'attach';      Desc = 'Open a background session in this terminal' }
        @{ Name = 'auth';        Desc = 'Manage authentication' }
        @{ Name = 'auto-mode';   Desc = 'Inspect or reset auto mode classifier configuration' }
        @{ Name = 'doctor';      Desc = 'Check the health of your Claude Code installation' }
        @{ Name = 'gateway';     Desc = 'Run the enterprise auth/telemetry gateway' }
        @{ Name = 'import';      Desc = 'Import config from another AI coding agent' }
        @{ Name = 'install';     Desc = 'Install Claude Code native build' }
        @{ Name = 'logs';        Desc = "Print a background session's recent terminal output" }
        @{ Name = 'mcp';         Desc = 'Configure and manage MCP servers' }
        @{ Name = 'plugin';      Desc = 'Manage Claude Code plugins' }
        @{ Name = 'plugins';     Desc = 'Manage Claude Code plugins' }
        @{ Name = 'purge';       Desc = 'Delete all Claude Code state for a project' }
        @{ Name = 'respawn';     Desc = 'Restart a background session' }
        @{ Name = 'rm';          Desc = 'Delete a background session' }
        @{ Name = 'setup-token'; Desc = 'Set up a long-lived authentication token' }
        @{ Name = 'stop';        Desc = 'Stop a background session' }
        @{ Name = 'kill';        Desc = 'Stop a background session' }
        @{ Name = 'ultrareview'; Desc = 'Run a cloud-hosted multi-agent code review' }
        @{ Name = 'update';      Desc = 'Check for updates and install if available' }
        @{ Name = 'upgrade';     Desc = 'Check for updates and install if available' }
    )

    $options = @(
        '--add-dir', '--agent', '--agents', '--allow-dangerously-skip-permissions', '--allowedTools',
        '--append-system-prompt', '--autocompact', '--ax-screen-reader', '--bare', '--betas', '--bg',
        '--brief', '-c', '--continue', '--chrome', '--cloud', '-d', '--debug', '--dangerously-skip-permissions',
        '--debug-file', '--desktop', '--disable-slash-commands', '--disallowedTools', '--effort',
        '--environment', '--exclude-dynamic-system-prompt-sections', '--fallback-model', '--file',
        '--fork-session', '--forward-subagent-text', '--from-pr', '-h', '--help', '--ide',
        '--include-hook-events', '--include-partial-messages', '--input-format', '--json-schema',
        '--max-budget-usd', '--mcp-config', '--model', '-n', '--name', '--no-chrome',
        '--no-session-persistence', '--output-format', '-p', '--print', '--permission-mode',
        '--permission-prompts', '--permission-prompt-tool', '--plugin-dir', '--plugin-url',
        '--prompt-suggestions', '-r', '--resume', '--remote-control', '--remote-control-session-name-prefix',
        '--replay-user-messages', '--restricted', '--safe-mode', '--session-id', '--settings',
        '--setting-sources', '--strict-mcp-config', '--system-prompt', '--system-prompt-snapshot',
        '--teleport', '--tmux', '--tools', '-v', '--version', '--verbose', '-w', '--worktree'
    )

    if ($wordToComplete -like '-*') {
        $options | Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object { [CompletionResult]::new($_, $_, [CompletionResultType]::ParameterName, $_) }
        return
    }

    $hasSubCommand = $false
    for ($i = 1; $i -lt $commandAst.CommandElements.Count - 1; $i++) {
        $el = $commandAst.CommandElements[$i]
        if ($el -is [StringConstantExpressionAst] -and $el.Value -notlike '-*') { $hasSubCommand = $true; break }
    }
    if (-not $hasSubCommand) {
        $subCommands | Where-Object { $_.Name -like "$wordToComplete*" } |
            ForEach-Object { [CompletionResult]::new($_.Name, $_.Name, [CompletionResultType]::ParameterValue, $_.Desc) }
    }
}
'@ | Set-Content -Path $claudeFile -Encoding utf8
if (Test-CommandAvailable 'claude') { $installed.Add('claude (hand-authored)') } else { $skipped.Add('claude (not found on PATH; completer written anyway)') }

# ---------------------------------------------------------------------------
# agy — hand-authored (no completion subcommand as of this writing)
# ---------------------------------------------------------------------------
$agyFile = Join-Path $CompletionsDir 'agy.ps1'
@'
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -Native -CommandName 'agy' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $subCommands = @(
        @{ Name = 'agent';          Desc = 'List available agents' }
        @{ Name = 'agents';         Desc = 'List available agents' }
        @{ Name = 'changelog';      Desc = 'Show changelog and release notes' }
        @{ Name = 'help';           Desc = 'Show help for subcommands' }
        @{ Name = 'install';        Desc = 'Configure environment paths and shell settings' }
        @{ Name = 'mcp';            Desc = 'Manage MCP servers (add, remove, list, enable, disable)' }
        @{ Name = 'mic-serve';      Desc = "Serve this machine's microphone to a CLI on another host" }
        @{ Name = 'models';         Desc = 'List available models' }
        @{ Name = 'plugin';         Desc = 'Manage plugins (install, uninstall, list, enable, disable)' }
        @{ Name = 'plugins';        Desc = 'Alias for plugin' }
        @{ Name = 'remote-control'; Desc = 'Manage the remote-control background daemon' }
        @{ Name = 'update';         Desc = 'Update CLI' }
    )

    $options = @(
        '--add-dir', '--agent', '-c', '--continue', '--conversation', '--dangerously-skip-permissions',
        '--disable-slash-commands', '--effort', '-i', '--input-format', '--json-schema', '--log-file',
        '--mode', '--model', '--new-project', '--output-format', '-p', '--print', '--print-timeout',
        '--project', '--prompt', '--prompt-interactive', '--remote-control', '--sandbox', '-h', '--help'
    )

    if ($wordToComplete -like '-*') {
        $options | Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object { [CompletionResult]::new($_, $_, [CompletionResultType]::ParameterName, $_) }
        return
    }

    $hasSubCommand = $false
    for ($i = 1; $i -lt $commandAst.CommandElements.Count - 1; $i++) {
        $el = $commandAst.CommandElements[$i]
        if ($el -is [StringConstantExpressionAst] -and $el.Value -notlike '-*') { $hasSubCommand = $true; break }
    }
    if (-not $hasSubCommand) {
        $subCommands | Where-Object { $_.Name -like "$wordToComplete*" } |
            ForEach-Object { [CompletionResult]::new($_.Name, $_.Name, [CompletionResultType]::ParameterValue, $_.Desc) }
    }
}
'@ | Set-Content -Path $agyFile -Encoding utf8
if (Test-CommandAvailable 'agy') { $installed.Add('agy (hand-authored)') } else { $skipped.Add('agy (not found on PATH; completer written anyway)') }

# ---------------------------------------------------------------------------
# opencode — hand-authored. `opencode --completions` only generates bash/zsh/fish/sh,
# no powershell, so its subcommands/flags below are transcribed from `opencode --help`.
# ---------------------------------------------------------------------------
$opencodeFile = Join-Path $CompletionsDir 'opencode.ps1'
@'
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -Native -CommandName 'opencode' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $subCommands = @(
        @{ Name = 'upgrade';   Desc = 'Upgrade OpenCode to the latest or a specific version' }
        @{ Name = 'update';    Desc = 'Upgrade OpenCode to the latest or a specific version' }
        @{ Name = 'uninstall'; Desc = 'Uninstall OpenCode, keeping session data, configuration, and state' }
        @{ Name = 'acp';       Desc = 'Start an Agent Client Protocol server' }
        @{ Name = 'api';       Desc = 'Make a request to the running server' }
        @{ Name = 'debug';     Desc = 'Debugging and troubleshooting tools' }
        @{ Name = 'auth';      Desc = 'Manage integrations and credentials' }
        @{ Name = 'mcp';       Desc = 'Manage MCP (Model Context Protocol) servers' }
        @{ Name = 'plugin';    Desc = 'Manage plugins' }
        @{ Name = 'models';    Desc = 'List all available models' }
        @{ Name = 'stats';     Desc = 'Show shareable usage statistics' }
        @{ Name = 'mini';      Desc = 'Start the minimal interactive interface' }
        @{ Name = 'run';       Desc = 'Run OpenCode with a message' }
        @{ Name = 'session';   Desc = 'Manage sessions' }
        @{ Name = 'service';   Desc = 'Manage the background server' }
        @{ Name = 'reload';    Desc = 'Reload configuration' }
        @{ Name = 'pair';      Desc = 'Print one-time links to connect a browser or app' }
        @{ Name = 'serve';     Desc = 'Start the v2 API and web server' }
    )

    $options = @(
        '--standalone', '--server', '--auto', '--continue', '-c', '--session', '-s', '--prompt',
        '--help', '-h', '--version', '-v', '--wizard', '--completions', '--log-level', '--print-logs'
    )

    if ($wordToComplete -like '-*') {
        $options | Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object { [CompletionResult]::new($_, $_, [CompletionResultType]::ParameterName, $_) }
        return
    }

    $hasSubCommand = $false
    for ($i = 1; $i -lt $commandAst.CommandElements.Count - 1; $i++) {
        $el = $commandAst.CommandElements[$i]
        if ($el -is [StringConstantExpressionAst] -and $el.Value -notlike '-*') { $hasSubCommand = $true; break }
    }
    if (-not $hasSubCommand) {
        $subCommands | Where-Object { $_.Name -like "$wordToComplete*" } |
            ForEach-Object { [CompletionResult]::new($_.Name, $_.Name, [CompletionResultType]::ParameterValue, $_.Desc) }
    }
}
'@ | Set-Content -Path $opencodeFile -Encoding utf8
if (Test-CommandAvailable 'opencode') { $installed.Add('opencode (hand-authored)') } else { $skipped.Add('opencode (not found on PATH; completer written anyway)') }

# ---------------------------------------------------------------------------
# Wire the generated files into the profile (idempotent, marker-delimited)
# ---------------------------------------------------------------------------
$beginMarker = '# >>> tab-completion: claude/codex/agy/opencode >>>'
$endMarker   = '# <<< tab-completion: claude/codex/agy/opencode <<<'

$blockLines = @(
    $beginMarker
    '# Managed by scripts/Install-TabCompletion.ps1 (natthasath/windows-package-manager).'
    '# Re-run that script after upgrading codex/claude/agy/opencode to refresh completions.'
    "`$__tabCompletionDir = '$CompletionsDir'"
    "foreach (`$__tabCompletionTool in 'codex', 'claude', 'agy', 'opencode') {"
    "    `$__tabCompletionFile = Join-Path `$__tabCompletionDir ""`$__tabCompletionTool.ps1"""
    "    if ((Test-Path -LiteralPath `$__tabCompletionFile) -and (Get-Command -Name `$__tabCompletionTool -ErrorAction SilentlyContinue)) {"
    "        . `$__tabCompletionFile"
    '    }'
    '}'
    'Remove-Variable -Name __tabCompletionDir, __tabCompletionTool, __tabCompletionFile -ErrorAction SilentlyContinue'
    $endMarker
) -join [Environment]::NewLine

if (-not (Test-Path -LiteralPath $ProfilePath)) {
    New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
}

$existing = Get-Content -LiteralPath $ProfilePath -Raw -ErrorAction SilentlyContinue
if (-not $existing) { $existing = '' }

$pattern = [regex]::Escape($beginMarker) + '.*?' + [regex]::Escape($endMarker)
$existing = [regex]::Replace($existing, $pattern, '', [System.Text.RegularExpressions.RegexOptions]::Singleline).TrimEnd()

$newContent = if ($existing) { $existing + [Environment]::NewLine + [Environment]::NewLine + $blockLines } else { $blockLines }
Set-Content -LiteralPath $ProfilePath -Value $newContent -Encoding utf8

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Tab completion installed:' -ForegroundColor Green
$installed | ForEach-Object { Write-Host "  [x] $_" -ForegroundColor Green }
if ($skipped.Count -gt 0) {
    Write-Host 'Skipped:' -ForegroundColor Yellow
    $skipped | ForEach-Object { Write-Host "  [ ] $_" -ForegroundColor Yellow }
}
Write-Host ''
Write-Host "Completion scripts: $CompletionsDir"
Write-Host "Profile updated:    $ProfilePath"
Write-Host "Run '. `$PROFILE' or open a new PowerShell window to start using completions."
