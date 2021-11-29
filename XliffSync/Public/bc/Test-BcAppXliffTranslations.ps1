<#
 .Synopsis
  Synchronizes and checks translations for a workspace folder with Microsoft Dynamics 365 Business Central apps.
 .Description
  Iterates through the translation units of a base XLIFF file and synchronizes them with a target XLIFF file.
 .Parameter buildProjectFolder
  Specifies the path to the workspace folder containing the projects.
 .Parameter appFolders
  Specifies the names of the app folders in the workspace folder. If empty, all subfolders will be processed.
 .Parameter translationRules
  Specifies which technical validation rules should be used.
 .Parameter translationRulesEnableAll
  Specifies whether to apply all technical validation rules.
 .Parameter restrictErrorsToLanguages
  Specifies languages to restrict errors to. For languages not in the list only warnings will be raised. If empty, then the setting of AzureDevOps applies to all languages.
  .Parameter AzureDevOps
  Specifies whether to generate Azure DevOps Pipeline compatible output. This setting determines the severity of errors.
 .Parameter reportProgress
  Specifies whether the command should report progress.
 .Parameter printProblems
  Specifies whether the command should print all detected problems.
 .Parameter printUnitsWithErrors
  Specifies whether the command should print the units with errors.
#>
function Test-BcAppXliffTranslations {
    Param(
        [Parameter(Mandatory = $false)]
        [string] $buildProjectFolder = $ENV:BUILD_REPOSITORY_LOCALPATH,
        [Parameter(Mandatory = $false)]
        [string[]] $appFolders = @(),
        [Parameter(Mandatory = $false)]
        [ValidateSet("ConsecutiveSpacesConsistent", "ConsecutiveSpacesExist", "OptionMemberCount", "OptionLeadingSpaces", "Placeholders", "PlaceholdersDevNote")]
        [string[]] $translationRules = @("ConsecutiveSpacesConsistent", "OptionMemberCount", "OptionLeadingSpaces", "Placeholders"),
        [switch] $translationRulesEnableAll,
        [Parameter(Mandatory = $false)]
        [string[]] $restrictErrorsToLanguages = @(),
        [Parameter(Mandatory = $false)]
        [ValidateSet('no', 'error', 'warning')]
        [string] $AzureDevOps = 'warning',
        [switch] $reportProgress,
        [switch] $printProblems,
        [switch] $printUnitsWithErrors
    )

    if ((-not $appFolders) -or ($appFolders.Length -eq 0)) {
        $appFolders = (Get-ChildItem $buildProjectFolder -Directory).Name
        Write-Host "-appFolders not explicitly set, using subfolders of $($buildProjectFolder): $appFolders"
    }

    Sort-AppFoldersByDependencies -appFolders $appFolders -baseFolder $buildProjectFolder -WarningAction SilentlyContinue | ForEach-Object {
        Write-Host "Checking translations for $_"
        $appProjectFolder = Join-Path $buildProjectFolder $_
        $appTranslationsFolder = Join-Path $appProjectFolder "Translations"
        Write-Host "Retrieving translation files from $appTranslationsFolder"
        $baseXliffFile = Get-ChildItem -Path $appTranslationsFolder -Filter '*.g.xlf'
        Write-Host "Base translation file $($baseXliffFile.FullName)"
        $targetXliffFiles = Get-ChildItem -Path $appTranslationsFolder -Filter '*.xlf' | Where-Object { -not $_.FullName.EndsWith('.g.xlf') }
        $allUnitsWithIssues = @()

        foreach ($targetXliffFile in $targetXliffFiles) {
            [string]$AzureDevOpsSeverityForFile = $AzureDevOps
            if (($AzureDevOps -eq 'error') -and ($restrictErrorsToLanguages.Length -gt 0)) {
                if ($null -eq ($restrictErrorsToLanguages | Where-Object { $targetXliffFile.Name -match $_ })) {
                    $AzureDevOpsSeverityForFile = 'warning'
                }
                Write-Host "Translation error severity is '$AzureDevOpsSeverityForFile' for file $($targetXliffFile.FullName)"
            }

            Write-Host "Syncing to file $($targetXliffFile.FullName)"
            Sync-XliffTranslations -sourcePath $baseXliffFile.FullName -targetPath $targetXliffFile.FullName -AzureDevOps $AzureDevOpsSeverityForFile -reportProgress:$reportProgress -printProblems:$printProblems
            Write-Host "Checking translations in file $($targetXliffFile.FullName)"
            $unitsWithIssues = Test-XliffTranslations -targetPath $targetXliffFile.FullName -checkForMissing -checkForProblems -translationRules $translationRules -translationRulesEnableAll:$translationRulesEnableAll -AzureDevOps $AzureDevOpsSeverityForFile -reportProgress:$reportProgress -printProblems:$printProblems

            if ($unitsWithIssues.Count -gt 0) {
                Write-Host "Issues detected in file $($targetXliffFile.FullName)."
                if ($printUnitsWithErrors) {
                    Write-Host "Units with issues:"
                    Write-Host $unitsWithIssues
                }

                if ($AzureDevOpsSeverityForFile -eq 'error') {
                    $allUnitsWithIssues += $unitsWithIssues
                }
            }
        }

        if ($targetXliffFiles.Count -eq 0) {
            Write-Host "##vso[task.logissue type=warning]There are no target translation files for $($baseXliffFile.Name)"
        }

        if (($AzureDevOps -eq 'error') -and ($allUnitsWithIssues.Count -gt 0)) {
            throw "Issues detected in translation files!"
        }
    }
}
Set-Alias -Name Check-BcAppXliffTranslations -Value Test-BcAppXliffTranslations
Export-ModuleMember -Function Test-BcAppXliffTranslations -Alias Check-BcAppXliffTranslations
