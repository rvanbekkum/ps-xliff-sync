<# 
 .Synopsis
  Checks for missing translations and translations that need work/review in an XLIFF file.
 .Description
  Iterates through the translation units of an XLIFF file and checks for missing translations and/or translations that need work/review.
 .Parameter targetPath
  Specifies the path to the target XLIFF file.
 .Parameter checkForMissing
  Specifies whether to check for missing translations.
 .Parameter checkForProblems
  Specifies whether to check for problems in the translations.
 .Parameter translationRules
  Specifies which technical validation rules should be used.
 .Parameter translationRulesEnableAll
  Specifies whether to apply all technical validation rules.
  .Parameter AzureDevOps
  Specifies whether to generate Azure DevOps Pipeline compatible output. This setting determines the severity of errors.
 .Parameter reportProgress
  Specifies whether the command should report progress.
 .Parameter printProblems
  Specifies whether the command should print all detected problems.
#>
function Check-XliffTranslations {
    Param (
        [Parameter(Mandatory=$true)]
        [string] $targetPath,
        [Parameter(Mandatory=$false)]
        [switch] $checkForMissing,
        [Parameter(Mandatory=$false)]
        [switch] $checkForProblems, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [string] $missingTranslation = "",
        [Parameter(Mandatory=$false)]
        [ValidateSet("ConsecutiveSpacesConsistent", "ConsecutiveSpacesExist", "OptionMemberCount", "OptionLeadingSpaces", "Placeholders", "PlaceholdersDevNote", "SourceEqualsTarget")]
        [string[]] $translationRules, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [switch] $translationRulesEnableAll, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [ValidateSet('no','error','warning')]
        [string] $AzureDevOps = 'no',
        [switch] $reportProgress,
        [switch] $printProblems
    )

    # Abort if both $checkForMissing and $checkForProblems are missing.
    if (-not $checkForMissing -and -not $checkForProblems) {
        throw "You need to use at least one of the following parameters: -checkForMissing, -checkForProblems";
    }

    # TEMPORARY: Abort if a parameter for an unimplemented feature is used.
    if ($checkForProblems -or $translationRules -or $translationRulesEnableAll) {
        throw "The parameters you entered are for one or more features that have not been implemented yet.";
    }

    Write-Host "Loading target document $targetPath";
    [XlfDocument] $targetDocument = [XlfDocument]::LoadFromPath($targetPath);

    Write-Host "Retrieving translation units from target document";
    [int] $unitCount = $targetDocument.TranslationUnitNodes().Count;
    [int] $i = 0;
    [int] $onePercentCount = $unitCount / 100;

    [System.Xml.XmlNode[]] $missingTranslationUnits = @();
    [System.Xml.XmlNode[]] $needWorkTranslationUnits = @();
    [bool] $problemResolvedInFile = $false;

    Write-Host "Processing unit nodes... (Please be patient)";
    [string] $progressMessage = "Checking translation units."
    if ($reportProgress) {
        if ($AzureDevOps -ne 'no') {
            Write-Host "##vso[task.setprogress value=0;]$progressMessage";
        }
        else {
            Write-Progress -Activity $progressMessage -PercentComplete 0;
        }
    }

    $targetDocument.TranslationUnitNodes() | ForEach-Object {
        [System.Xml.XmlNode] $unit = $_;

        if ($reportProgress) {
            $i++;
            if ($i % $onePercentCount -eq 0) {
                $percentage = ($i / $unitCount) * 100;
                if ($AzureDevOps -ne 'no') {
                    Write-Host "##vso[task.setprogress value=$percentage;]$progressMessage";
                }
                else {
                    Write-Progress -Activity $progressMessage -PercentComplete $percentage;
                }
            }
        }

        if ($checkForMissing) {
            if (HasMissingTranslation -targetDocument $targetDocument -unit $unit -missingTranslationText $missingTranslation) {
                #TODO: SetState attribute
                $missingTranslationUnits += $unit;
            }
            #TODO: Check for Need Work translation / Problem
            #TODO: Check for Resolved Problem
        }
    }

    if ($checkForMissing) {
        Write-Host "Detected: $($missingTranslationUnits.Count) missing translation(s).";

        if ($printProblems -and $missingTranslationUnits) {
            [string] $detectedMessage = "Missing translation in unit '{0}'.";
            if ($AzureDevOps -ne 'no') {
                $detectedMessage = "##vso[task.logissue type=$AzureDevOps]$detectedMessage";
            }
    
            $missingTranslationUnits | ForEach-Object {
                Write-Host ($detectedMessage -f $_.id);
            }
        }
    }

    if ($checkForProblems) {
        Write-Host "Detected: $($needWorkTranslationUnits.Count) translation(s) that need work.";

        if ($printProblems -and $needWorkTranslationUnits) {
            [string] $detectedMessage = "Translation issue in unit '{0}'.";
            if ($AzureDevOps -ne 'no') {
                $detectedMessage = "##vso[task.logissue type=$AzureDevOps]$detectedMessage";
            }
    
            $needWorkTranslationUnits | ForEach-Object {
                Write-Host ($detectedMessage -f $_.id);
            }
        }
    }

    [bool] $issueDetectedInFile = ($missingCount -gt 0) -or ($needWorkCount -gt 0);
    if ($issueDetectedInFile -or $problemResolvedInFile) {
        $targetDocument.SaveToFilePath($targetPath);
    }
}

function HasMissingTranslation {
    Param (
        [XlfDocument] $targetDocument,
        [System.Xml.XmlNode] $unit,
        [string] $missingTranslationText
    )
    
    [bool] $needsTranslation = $targetDocument.GetUnitNeedsTranslation($unit);
    if ($needsTranslation) {
        [string] $translation = $targetDocument.GetUnitTranslation($unit);
        if ((-not $translation) -or ($translation -eq $missingTranslationText)) {
            return $true;
        }
    }

    return $false;
}