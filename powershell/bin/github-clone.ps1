# written by https://twitter.com/dblockdotorg
# powershell port of bash/bin/github-clone

param(
    [Parameter(Position = 0)]
    [string]$Url,

    [Parameter(Position = 1)]
    [string]$Name
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrEmpty($Url)) {
    Write-Host "syntax: github-clone [url] ([your github username])"
    Write-Host "written by https://twitter.com/dblockdotorg"
    exit 1
}

# the github username
if ([string]::IsNullOrEmpty($Name)) {
    $Name = git config user.login
}
if ([string]::IsNullOrEmpty($Name)) {
    $Name = git config user.name
}
if ([string]::IsNullOrEmpty($Name)) {
    $Name = $env:USERNAME
}

# parse the GIT url (https:// or git@host:org/repo form)
if ($Url -match '^(?<proto>[a-zA-Z]+://)(?:(?<user>[^@/]+)@)?(?<host>[^/]+)/(?<org>[^/]+)/(?<repo>[^/.]+)(\.git)?/?$') {
    $org = $Matches['org']
    $repo = $Matches['repo']
    $upstream = "https://github.com/$org/$repo.git"
    $fork = "https://github.com/$Name/$repo.git"
}
elseif ($Url -match '^(?:[^@]+@)?(?<host>[^:]+):(?<org>[^/]+)/(?<repo>[^/.]+)(\.git)?$') {
    $org = $Matches['org']
    $repo = $Matches['repo']
    $upstream = "git@github.com:$org/$repo.git"
    $fork = "git@github.com:$Name/$repo.git"
}
else {
    Write-Error "github-clone error: could not parse url $Url"
    exit 1
}

Write-Host "github-clone: cloning $org/$repo into $repo/upstream-$repo and $repo/$Name-$repo"

# check whether directory already exists
if (Test-Path "$repo\$Name-$repo") {
    Write-Error "github-clone error: $repo\$Name-$repo already exists"
    exit 1
}
if (Test-Path "$repo\upstream-$repo") {
    Write-Error "github-clone error: $repo\upstream-$repo already exists"
    exit 1
}

New-Item -ItemType Directory -Force -Path $repo | Out-Null
Push-Location $repo

git clone $upstream "upstream-$repo"
git clone $fork "$Name-$repo"

Push-Location "$Name-$repo"
git remote add upstream $upstream
Pop-Location

Get-Location
Get-ChildItem

Pop-Location
