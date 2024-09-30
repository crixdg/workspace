# PowerShell Profile for PowerShell 7

# Set the execution policy (optional)
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Load commonly used modules
# Import-Module Az          # Azure PowerShell
# Import-Module PSScriptAnalyzer  # Script analysis tools

# Custom prompt function
function prompt {
    $gitBranch = ''
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitBranch = & git rev-parse --abbrev-ref HEAD 2>$null
        if ($gitBranch) {
            $gitBranch = " ($gitBranch)"
        }
    }
    "$PWD$gitBranch> "
}

# Custom functions
function Clear-Console {
    Clear-Host
}

function Show-Date {
    Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

# Set default formatting for output
$FormatEnumerationLimit = -1  # Show all items in output

# Aliases for convenience
Set-Alias cls Clear-Console
Set-Alias date Show-Date

# Error handling
$ErrorActionPreference = "Continue"

# Load custom scripts
if (Test-Path "$HOME\config.txt") {
    $customScriptsPath = "$HOME\pwshrc.ps1"
    Get-ChildItem $customScriptsPath | ForEach-Object { . $_.FullName }
}
# else {
    # Write-Host "No config file found. Skipping loading scripts." -ForegroundColor Yellow
# }

# Profile settings
# Write-Host "PowerShell profile loaded successfully." -ForegroundColor Green
