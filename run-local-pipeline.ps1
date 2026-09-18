param(
    [string] $Pipeline = 'ci',
    [ValidateSet('file', 'server')]
    [string] $Profile
)

Get-Content "$PSScriptRoot\.env" | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
        [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process')
    }
}

if (-not $Profile) { $Profile = if ($env:ServerMode1C -eq 'true') { 'server' } else { 'file' } }

$v8CiArguments = @(
    '--config', "$PSScriptRoot\v8ci.yaml"
    '--policy', "$PSScriptRoot\v8-ci-policy.yaml"
    'run', $Pipeline
)
if ($Profile) { $v8CiArguments += '--profile', $Profile }

$v8CiCleanArguments = @(
    '--config', "$PSScriptRoot\v8ci.yaml"
    '--policy', "$PSScriptRoot\v8-ci-policy.yaml"
    'clean', '--older-than', '24h'
)

Write-Host "v8-ci $($v8CiCleanArguments -join ' ')"
& v8-ci @v8CiCleanArguments
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "v8-ci $($v8CiArguments -join ' ')"
& v8-ci @v8CiArguments
exit $LASTEXITCODE
