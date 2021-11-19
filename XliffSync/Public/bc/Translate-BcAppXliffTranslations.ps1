<#
  .Synopsis
   Synchronizes and generates missing translations for a workspace folder with Microsoft Dynamics 365 Business Central apps using Azure Cognitive Services.
  .Description
   Iterates through the translation units of a base XLIFF file, synchronizes them with a target XLIFF file and populate the translations needed.
  .Parameter buildProjectFolder
   Specifies the path to the workspace folder containing the projects.
  .Parameter appFolders
   Specifies the names of the app folders in the workspace folder. If empty, all subfolders will be processed.
  .Parameter ApiKey
   Specifies one fo the two API Keys
  .Parameter Region
   Specifies the Region where the Cognitive Service is hosted
  .Parameter CategoryId
   Specify the Category (domain) of the translation. This parameter is used to get translations from a customized system built with Custom Translator. 
   Add the Category ID from your Custom Translator project details to this parameter to use your deployed customized system. Default value is: general. 
#>
function Translate-BcAppXliffTranslations {
    param(
        [Parameter(Mandatory=$false)]
        [string] $buildProjectFolder = $ENV:BUILD_REPOSITORY_LOCALPATH,
        [Parameter(Mandatory=$false)]
        [string[]] $appFolders = @(),        
        [string]$ApiKey,
        [Parameter(Mandatory=$true)]
        [string]$Region,
        [Parameter(Mandatory=$false)]
        [string]$CategoryId = "general"
    )

    if ((-not $appFolders) -or ($appFolders.Length -eq 0)) {
        $appFolders = (Get-ChildItem $buildProjectFolder -Directory).Name
        Write-Host "-appFolders not explicitly set, using subfolders of $($buildProjectFolder): $appFolders"
    }

    Sort-AppFoldersByDependencies -appFolders $appFolders.Split(',') -baseFolder $ProjectRoot -WarningAction SilentlyContinue | ForEach-Object {

        Write-Host "Checking translations for $_"
        $appProjectFolder = Join-Path $ProjectRoot $_
        $appTranslationsFolder = Join-Path $appProjectFolder "Translations"
        Write-Host "Retrieving translation files from $appTranslationsFolder"
        $baseXliffFile = Get-ChildItem -Path $appTranslationsFolder -Filter '*.g.xlf'
        Write-Host "Base translation file $($baseXliffFile.FullName)"
        $targetXliffFiles = Get-ChildItem -Path $appTranslationsFolder -Filter '*.xlf' | Where-Object { -not $_.FullName.EndsWith('.g.xlf') }

        foreach ($targetXliffFile in $targetXliffFiles) {
            Write-Host "Syncing to file $($targetXliffFile.FullName)"
            Sync-XliffTranslations -sourcePath $baseXliffFile.FullName -targetPath $targetXliffFile.FullName
            Write-Host "Checking translations in file $($targetXliffFile.FullName)" 
            $unitsWithIssues = Test-XliffTranslations -targetPath $targetXliffFile.FullName -checkForMissing

            if ($unitsWithIssues.Count -ne 0) {
                Write-Host "Generating missing translations in file $($targetXliffFile.FullName)"
                Translate-XliffTranslations -XlfInputFile $targetXliffFile.FullName -ApiKey $ApiKey -Region $Region -CategoryId $CategoryId        
            }
        }
    }
}
Export-ModuleMember -Function Translate-BcAppXliffTranslations
