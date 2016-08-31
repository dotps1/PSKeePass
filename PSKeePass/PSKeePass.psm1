#region ProviderPath

$paths = @(
    'Private'
)

foreach ($path in $paths) {
    "$(Split-Path -Path $MyInvocation.MyCommand.Path)\$path\*.ps1" | 
        Resolve-Path | 
            ForEach-Object { 
                . $_.ProviderPath 
            }
}

#endregion ProviderPath


#region Assemblies

[System.Reflection.Assembly]::LoadFile(
    "$PSScriptRoot\bin\KeePass.exe"
)

#endregion Assemblies
