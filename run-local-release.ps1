param(
    [ValidateSet('file', 'server')]
    [string] $Profile
)

$arguments = @{ Pipeline = 'release' }
if ($Profile) { $arguments.Profile = $Profile }

& "$PSScriptRoot\run-local-pipeline.ps1" @arguments
exit $LASTEXITCODE
