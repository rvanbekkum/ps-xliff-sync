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
  Specifies whether to #TODO:
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
        [switch] $AzureDevOps #TODO: Not implemented yet
    )

    # Abort if both $checkForMissing and $checkForProblems are missing.
    if (-not $checkForMissing -and -not $checkForProblems) {
        throw "You need to use at least one of the following parameters: -checkForMissing, -checkForProblems";
    }

    # TEMPORARY: Abort if a parameter for an unimplemented feature is used.
    if ($checkForProblems -or $translationRules -or $translationRulesEnableAll) {
        throw "The parameters you entered are for one or more features that have not been implemented yet.";
    }

    [XlfDocument] $targetDocument = [XlfDocument]::LoadFromPath($targetPath);

    [int] $missingCount = 0;
    [int] $needWorkCount = 0;
    [bool] $problemResolvedInFile = $false;

    $targetDocument.TranslationUnitNodes() | ForEach-Object {
        [System.Xml.XmlNode] $unit = $_;

        if ($checkForMissing) {
            if (HasMissingTranslation -targetDocument $targetDocument -unit $unit -missingTranslationText $missingTranslation) {
                Write-Verbose "Missing translation for unit '$($unit.'id')' with source text '$($targetDocument.GetUnitSourceText($unit))'.";
                #TODO: SetState attribute
                $missingCount += 1;
            }
            #TODO: Check for Need Work translation / Problem
            #TODO: Check for Resolved Problem
        }
    }

    if ($checkForMissing) {
        Write-Host "Detected: $missingCount missing translation(s).";
    }
    if ($checkForProblems) {
        Write-Host "Detected: $needWorkCount translation(s) that need work.";
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