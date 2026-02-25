<#
.SYNOPSIS
    Installs Copilot agent skills from this repository.

.DESCRIPTION
    Copies skill directories from the repository's skills/ folder to either
    a personal (~/.copilot/skills/) or project (.github/skills/) location.

.PARAMETER Target
    Where to install: 'personal' (~/.copilot/skills/) or 'project' (.github/skills/ in cwd).

.PARAMETER Force
    Overwrite existing skills without prompting.

.PARAMETER Skills
    Comma-separated list of specific skill names to install. If omitted, all skills are installed.

.EXAMPLE
    .\install.ps1 -Target personal
    .\install.ps1 -Target project -Force -Skills "skill1,skill2"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("personal", "project")]
    [string]$Target,

    [switch]$Force,

    [string]$Skills,

    [switch]$Help
)

function Show-Usage {
    Write-Host "Usage: .\install.ps1 -Target <personal|project> [-Force] [-Skills ""skill1,skill2""]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Target personal   Install to ~/.copilot/skills/"
    Write-Host "  -Target project    Install to .github/skills/ in the current directory"
    Write-Host "  -Force             Overwrite existing skills without prompting"
    Write-Host "  -Skills            Comma-separated list of specific skills to install"
    Write-Host "  -Help              Show this help message"
}

if ($Help -or -not $Target) {
    Show-Usage
    exit 0
}

# Resolve the script's own directory to locate skills/
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SourceDir = Join-Path $ScriptDir "skills"

if (-not (Test-Path $SourceDir)) {
    Write-Error "Skills directory not found at: $SourceDir"
    exit 1
}

# Determine destination
if ($Target -eq "personal") {
    $DestDir = Join-Path $HOME ".copilot" "skills"
} else {
    $DestDir = Join-Path (Get-Location) ".github" "skills"
}

# Gather available skills (subdirectories of skills/)
$AllSkills = Get-ChildItem -Path $SourceDir -Directory
if ($AllSkills.Count -eq 0) {
    Write-Warning "No skills found in: $SourceDir"
    exit 0
}

# Filter to requested skills if specified
if ($Skills) {
    $RequestedNames = $Skills -split "," | ForEach-Object { $_.Trim() }
    $SkillsToInstall = $AllSkills | Where-Object { $RequestedNames -contains $_.Name }

    $Found = $SkillsToInstall | ForEach-Object { $_.Name }
    $Missing = $RequestedNames | Where-Object { $Found -notcontains $_ }
    if ($Missing) {
        Write-Warning "Skills not found: $($Missing -join ', ')"
    }
} else {
    $SkillsToInstall = $AllSkills
}

if (-not $SkillsToInstall -or $SkillsToInstall.Count -eq 0) {
    Write-Warning "No matching skills to install."
    exit 0
}

# Ensure destination directory exists
if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    Write-Host "Created destination directory: $DestDir"
}

$InstalledCount = 0

foreach ($Skill in $SkillsToInstall) {
    $SkillDest = Join-Path $DestDir $Skill.Name

    if (Test-Path $SkillDest) {
        if ($Force) {
            Write-Host "  Overwriting: $($Skill.Name)"
            Remove-Item -Path $SkillDest -Recurse -Force
        } else {
            $Response = Read-Host "  Skill '$($Skill.Name)' already exists at $SkillDest. Overwrite? [y/N/a(ll)]"
            if ($Response -eq "a" -or $Response -eq "all") {
                $Force = $true
                Write-Host "  Overwriting: $($Skill.Name)"
                Remove-Item -Path $SkillDest -Recurse -Force
            } elseif ($Response -eq "y" -or $Response -eq "yes") {
                Write-Host "  Overwriting: $($Skill.Name)"
                Remove-Item -Path $SkillDest -Recurse -Force
            } else {
                Write-Host "  Skipping: $($Skill.Name)"
                continue
            }
        }
    } else {
        Write-Host "  Installing: $($Skill.Name)"
    }

    try {
        Copy-Item -Path $Skill.FullName -Destination $SkillDest -Recurse -Force -ErrorAction Stop
        $InstalledCount++
    } catch {
        Write-Error "  Failed to install '$($Skill.Name)': $_"
    }
}

Write-Host ""
Write-Host "Installed $InstalledCount skills to $DestDir"
