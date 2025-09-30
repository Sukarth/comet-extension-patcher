Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enhanced logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Find-CometExecutable {
    Write-Log "Searching for Comet browser executable..."

    $searchPaths = @(
        "$env:LOCALAPPDATA\Perplexity\Comet\Application\comet.exe",
        "$env:PROGRAMFILES\Perplexity\Comet\Application\comet.exe",
        "$env:PROGRAMFILES(X86)\Perplexity\Comet\Application\comet.exe"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            Write-Log "Found Comet browser at: $path" "SUCCESS"
            return $path
        }
    }

    Write-Log "Comet browser not found at default locations" "WARN"
    Write-Log "Please select the comet.exe file manually" "INFO"

    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Filter           = "Comet Executable (comet.exe)|comet.exe|All Executables (*.exe)|*.exe"
        Title            = "Select Comet Browser Executable"
        InitialDirectory = $env:LOCALAPPDATA
    }

    if ($fileDialog.ShowDialog() -eq "OK") {
        Write-Log "Selected: $($fileDialog.FileName)" "SUCCESS"
        return $fileDialog.FileName
    }

    Write-Log "No file selected. Cannot continue." "ERROR"
    return $null
}

function Get-CometPaths($cometExecutablePath) {
    Write-Log "Resolving Comet installation paths..."

    $cometAppFolder = Split-Path -Path $cometExecutablePath -Parent
    $cometFolder = Split-Path -Path $cometAppFolder -Parent

    if (-not ($cometFolder -and (Test-Path $cometFolder))) {
        throw "Could not determine Comet folder path from: $cometExecutablePath"
    }
    Write-Log "Comet installation folder: $cometFolder" "INFO"

    $userDataPath = Join-Path -Path $cometFolder -ChildPath "User Data"
    if (-not (Test-Path $userDataPath)) {
        throw "User Data folder not found at: $userDataPath. The Comet browser may not be properly installed."
    }
    Write-Log "User Data folder located: $userDataPath" "SUCCESS"

    return [PSCustomObject]@{
        CometFolder = $cometFolder
        UserData    = $userDataPath
        AppFolder   = $cometAppFolder
    }
}

function Create-MCPEnhancedScript($userDataPath, $cometExecutablePath) {
    $scriptPath = Join-Path -Path $userDataPath -ChildPath "enable-mcp-extension-support.ps1"

    $scriptContent = @'
# MCP Extension Support Script for Comet Browser
$localStatePath = ".\Local State"

# Logging function for the nested script
function Write-ScriptLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Level) {
        "ERROR" { "[ERROR]" }
        "SUCCESS" { "[SUCCESS]" }
        "WARN" { "[WARN]" }
        default { "[INFO]" }
    }
    Write-Host "$timestamp $prefix $Message"
}

Write-ScriptLog "Starting MCP extension compatibility patch..."

if (-not (Test-Path $localStatePath)) {
    Write-ScriptLog "Local State file not found. Comet may not have been run yet." "ERROR"
    Write-ScriptLog "Please start Comet normally first, then try again." "INFO"
    Start-Sleep -Seconds 3
    exit 1
}

# Create backup with timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$timestampedBackup = ".\Local State.backup-$timestamp"
Copy-Item -Path $localStatePath -Destination $timestampedBackup -Force
Write-ScriptLog "Created backup: $timestampedBackup" "SUCCESS"

try {
    $content = Get-Content -Path $localStatePath -Raw

    # Multiple settings to enable MCP extension functionality
    $updates = @{
        '"Allow-external-extensions-scripting-on-NTP":false' = '"Allow-external-extensions-scripting-on-NTP":true'
        '"developer_mode_disabled":true' = '"developer_mode_disabled":false'
        '"extension_install_allowlist_enabled":true' = '"extension_install_allowlist_enabled":false'
    }

    $changesMade = $false
    foreach ($pattern in $updates.Keys) {
        if ($content -match [regex]::Escape($pattern)) {
            $content = $content -replace [regex]::Escape($pattern), $updates[$pattern]
            Write-ScriptLog "Updated: $pattern -> $($updates[$pattern])" "SUCCESS"
            $changesMade = $true
        }
    }

    if (-not $changesMade) {
        Write-ScriptLog "No restrictive settings found. Adding MCP-friendly defaults..." "INFO"
        # Add settings if they don't exist
        $content = $content -replace '("browser":\{)', ('$1' + '"Allow-external-extensions-scripting-on-NTP":true,"developer_mode_disabled":false,')
        $changesMade = $true
    }

    $content | Set-Content -Path $localStatePath -Force
    Write-ScriptLog "Extension compatibility settings updated successfully" "SUCCESS"
} 
catch {
    Write-ScriptLog "Error updating settings: $($_.Exception.Message)" "ERROR"
    if (Test-Path $timestampedBackup) {
        Copy-Item -Path $timestampedBackup -Destination $localStatePath -Force
        Write-ScriptLog "Restored from backup" "INFO"
    }
    Start-Sleep -Seconds 3
    exit 1
}

Write-ScriptLog "Starting Comet with MCP extension support..." "SUCCESS"
Start-Process "COMET_EXE_PATH_PLACEHOLDER"
'@

    $scriptContent = $scriptContent.Replace('COMET_EXE_PATH_PLACEHOLDER', $cometExecutablePath)
    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    Write-Log "Created MCP extension support script: $scriptPath" "SUCCESS"
    return $scriptPath
}

function Create-MCPDesktopShortcut($shortcutProperties) {
    Write-Log "Creating MCP-enabled Comet shortcut..."

    $WshShell = New-Object -ComObject WScript.Shell
    $DesktopPath = [System.Environment]::GetFolderPath('Desktop')
    $ShortcutPath = Join-Path -Path $DesktopPath -ChildPath "Comet Browser - MCP Enhanced.lnk"

    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $shortcutProperties.TargetPath
    $Shortcut.Arguments = $shortcutProperties.Arguments
    $Shortcut.WorkingDirectory = $shortcutProperties.WorkingDirectory
    $Shortcut.WindowStyle = 7  # Minimized
    $Shortcut.IconLocation = $shortcutProperties.IconLocation
    $Shortcut.Description = $shortcutProperties.Description
    $Shortcut.Save()

    Write-Log "Desktop shortcut created: $ShortcutPath" "SUCCESS"
}

function Show-MCPSuccessMessage {
    Clear-Host
    Write-Log "========================================" "SUCCESS"
    Write-Log "MCP Extension Setup Complete!" "SUCCESS"
    Write-Log "========================================" "SUCCESS"
    Write-Host ""
    Write-Log "NEXT STEPS:" "INFO"
    Write-Log "1. Start MCP Bridge: npx perplexity-web-mcp-bridge" "INFO"
    Write-Log "2. Install MCP Extension (developer mode in Comet)" "INFO"
    Write-Log "3. Use 'Comet Browser - MCP Enhanced' shortcut to launch" "INFO"
    Write-Host ""
    Write-Log "Extension download: https://github.com/Sukarth/perplexity-web-mcp-extension" "INFO"
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-MCPErrorMessage($errorMessage) {
    Write-Host ""
    Write-Log "Setup failed: $errorMessage" "ERROR"
    Write-Host ""
    Write-Log "Common solutions:" "INFO"
    Write-Log "- Make sure Comet browser is properly installed" "INFO"
    Write-Log "- Run this script as Administrator if permission issues occur" "INFO"
    Write-Log "- Close Comet browser before running this script" "INFO"
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main execution
try {
    Clear-Host
    Write-Log "========================================" "SUCCESS"
    Write-Log "MCP Extension Enabler for Comet Browser" "SUCCESS"  
    Write-Log "========================================" "SUCCESS"
    Write-Host ""

    # Find Comet executable
    $cometPath = Find-CometExecutable
    if (-not $cometPath) { 
        throw "Could not locate Comet browser executable"
    }

    # Get installation paths
    $paths = Get-CometPaths -cometExecutablePath $cometPath

    # Create the MCP enhancement script
    $mcpScriptPath = Create-MCPEnhancedScript -userDataPath $paths.UserData -cometExecutablePath $cometPath

    # Create desktop shortcut
    $shortcutProperties = @{
        TargetPath       = "powershell.exe"
        Arguments        = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$mcpScriptPath`""
        WorkingDirectory = $paths.UserData
        IconLocation     = "$cometPath,0"
        Description      = "Comet Browser with MCP Extension Support"
    }
    Create-MCPDesktopShortcut -shortcutProperties $shortcutProperties

    # Show success message
    Show-MCPSuccessMessage
}
catch {
    Show-MCPErrorMessage -errorMessage $_.Exception.Message
}