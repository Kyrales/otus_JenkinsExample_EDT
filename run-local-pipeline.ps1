[CmdletBinding()]
param(
    [string] $EnvFile = (Join-Path $PSScriptRoot '.env'),
    [string] $PolicyFile,
    [ValidateSet('file', 'server')]
    [string] $Profile,
    [string] $Pipeline = 'ci'
)

$ErrorActionPreference = 'Stop'

function Import-DotEnv {
    param([Parameter(Mandatory)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Environment file not found: $Path" }
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
            $value = $Matches[2]
            if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            [Environment]::SetEnvironmentVariable($Matches[1], $value, 'Process')
        }
    }
}

function Get-RequiredEnvironmentValue {
    param([Parameter(Mandatory)][string] $Name)

    $value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if ([string]::IsNullOrWhiteSpace($value)) { throw "Required environment variable is missing: $Name" }
    return $value
}

Import-DotEnv -Path $EnvFile
$v8Ci = [Environment]::GetEnvironmentVariable('V8_CI_BIN', 'Process')
if ([string]::IsNullOrWhiteSpace($v8Ci)) {
    $v8Ci = 'F:\1C\Projects\v8-ci\build\release\windows\v8-ci.exe'
}
if (-not (Test-Path -LiteralPath $v8Ci -PathType Leaf)) { throw "Local v8-ci binary not found: $v8Ci" }
$policy = if ($PolicyFile) {
    $PolicyFile
}
elseif ($env:V8_CI_POLICY) {
    $env:V8_CI_POLICY
}
else {
    Join-Path $PSScriptRoot 'v8-ci-policy.yaml'
}
if (-not (Test-Path -LiteralPath $policy -PathType Leaf)) { throw "Local v8-ci policy not found: $policy" }
[void](Get-RequiredEnvironmentValue -Name 'CI_IMAGE')

$branch = [string]::Join('', @((& git -C $PSScriptRoot branch --show-current))).Trim()
if (-not $branch) { $branch = 'local' }
$sha = [string]::Join('', @((& git -C $PSScriptRoot rev-parse HEAD))).Trim()
if ($sha -notmatch '^[0-9a-fA-F]{7,64}$') { throw 'Cannot determine the current Git commit SHA' }
if (-not $Profile) { $Profile = if ($env:ServerMode1C -eq 'true') { 'server' } else { 'file' } }
$env:CI = 'true'
$env:CI_COMMIT_REF_NAME = $branch
$env:CI_COMMIT_SHA = $sha
$env:CI_PIPELINE_ID = "local-$([DateTime]::Now.ToString('yyyyMMdd-HHmmss'))"

& $v8Ci --config (Join-Path $PSScriptRoot 'v8ci.yaml') --policy $policy run $Pipeline --profile $Profile
exit $LASTEXITCODE
