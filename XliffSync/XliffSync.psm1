[cmdletbinding()]
param()

# Load Model (e.g., classes)
$modelList = @(
    'XlfDocument'
)
foreach($model in $modelList)
{
    . "$PSScriptRoot\Model\$model.ps1"
}

# Load Functions
foreach($folder in @('Public'))
{
    $rootPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    if(Test-Path -Path $rootPath)
    {
        $files = Get-ChildItem -Path $rootPath -Filter *.ps1 -Recurse

        # dot source each file
        $files | Where-Object{ $_.name -NotLike '*.Tests.ps1'} | 
            ForEach-Object{Write-Verbose $_.BaseName; . $_.FullName}
    }
}

# Export Public Functions
Export-ModuleMember -Function (Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1").BaseName
