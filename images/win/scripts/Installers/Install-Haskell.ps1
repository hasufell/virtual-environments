################################################################################
##  File:  Install-Haskell.ps1
##  Desc:  Install Haskell for Windows
################################################################################

# Get 3 latest versions of GHC, use OData query for that since choco search has issues https://github.com/chocolatey/choco/issues/2271
$ODataQuery = '$filter=(Title eq ''ghc'') and (IsPrerelease eq false)&$orderby=Version desc'
$Url = "https://community.chocolatey.org/api/v2/Packages()?$ODataQuery"
$ChocoVersionsOutput = [Version[]](Invoke-RestMethod -Uri $Url).properties.Version
$LatestMajorMinor = $ChocoVersionsOutput | Group-Object { $_.ToString(2) } | Sort-Object { [Version]$_.Name } | Select-Object -last 3
$VersionsList = $LatestMajorMinor | ForEach-Object { $_.Group | Select-Object -First 1 } | Sort-Object

# The latest version will be installed as a default
ForEach ($version in $VersionsList)
{
    Write-Host "Installing ghc $version..."
    Choco-Install -PackageName ghc -ArgumentList '--version', $version, '-m'
}

# Add default version of GHC to path, because choco formula updates path on user level
$DefaultGhcVersion = $VersionsList | Select-Object -Last 1
$DefaultGhcShortVersion = ([version]$DefaultGhcVersion).ToString(3)
$DefaultGhcPath = Join-Path $env:ChocolateyInstall "lib\ghc.$DefaultGhcVersion\tools\ghc-$DefaultGhcShortVersion\bin"
# Starting from version 9 haskell installation directory is $env:ChocolateyToolsLocation instead of $env:ChocolateyInstall\lib
if ($DefaultGhcShortVersion -notmatch '^[0-8]\.\d+.*')
{
    $DefaultGhcPath = Join-Path $env:ChocolateyToolsLocation "ghc-$DefaultGhcShortVersion\bin"
}

Add-MachinePathItem -PathItem $DefaultGhcPath

Write-Host 'Installing cabal...'
Choco-Install -PackageName cabal

Invoke-PesterTests -TestFile 'Haskell'

# install minimal ghcup, utilizing pre-installed msys2 at C:\msys64
$msysPath = "C:\msys64"
$ghcupPrefix = "C:\"
$appdata = [Environment]::GetEnvironmentVariable('APPDATA', [System.EnvironmentVariableTarget]::Machine) 
$cabalDir = "$appdata\cabal"
Invoke-Command -ScriptBlock ([ScriptBlock]::Create($bootstrapHaskell)) -ArgumentList $false, $true, $true, $false, $false, $false, $false, $ghcupPrefix, "", $msysPath, $cabalDir
[Environment]::SetEnvironmentVariable("GHCUP_INSTALL_BASE_PREFIX", $ghcupPrefix, [System.EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("GHCUP_MSYS2", $msysPath, [System.EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("CABAL_DIR", $cabalDir, [System.EnvironmentVariableTarget]::Machine)
Add-MachinePathItem "$ghcupPrefix\ghcup\bin"
Add-MachinePathItem "$cabalDir\bin"
