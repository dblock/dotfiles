winget install --id GnuPG.Gpg4win -e --accept-source-agreements --accept-package-agreements

$gpg = "C:\Program Files\GnuPG\bin\gpg.exe"
$keys = "$env:USERPROFILE\OneDrive - Microsoft\Keys"

& $gpg --import "$keys\7C94E183.gpg"
& $gpg --import-ownertrust "$keys\7C94E183.trustlevel.txt"

git config --global user.signingkey 75BF031B7C94E183
git config --global commit.gpgsign true
git config --global gpg.program $gpg

# cache the passphrase for a day so gpg doesn't keep prompting
$gnupgHome = "$env:APPDATA\gnupg"
New-Item -ItemType Directory -Force -Path $gnupgHome | Out-Null
Set-Content -Path "$gnupgHome\gpg-agent.conf" -Value "default-cache-ttl 86400`nmax-cache-ttl 86400`n"

& "C:\Program Files\GnuPG\bin\gpgconf.exe" --kill gpg-agent
