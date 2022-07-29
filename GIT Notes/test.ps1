[CmdletBinding()]
param(
    [parameter(Mandatory = $true)]
    [string]
    $DirName
)

New-Item -Path "c:\" -Name $DirName -ItemType "directory"
