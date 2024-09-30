# Set execution policy to allow script execution
Set-ExecutionPolicy Bypass -Scope Process -Force;

# Install Chocolatey
Write-Host "Installing Chocolatey..."
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install some tools
choco install git -y
