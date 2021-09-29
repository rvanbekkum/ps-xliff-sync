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
 .Parameter developerNoteDesignation
  Specifies the name that is used to designate a developer note.
 .Parameter xliffGeneratorNoteDesignation
  Specifies the name that is used to designate an XLIFF generator note.
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
        [switch] $checkForProblems,
        [Parameter(Mandatory=$false)]
        [string] $developerNoteDesignation="Developer",
        [Parameter(Mandatory=$false)]
        [string] $xliffGeneratorNoteDesignation="Xliff Generator",
        [Parameter(Mandatory=$false)]
        [string] $missingTranslation = "",
        [Parameter(Mandatory=$false)]
        [ValidateSet("ConsecutiveSpacesConsistent", "ConsecutiveSpacesExist", "OptionMemberCount", "OptionLeadingSpaces", "Placeholders", "PlaceholdersDevNote")]
        [string[]] $translationRules,
        [Parameter(Mandatory=$false)]
        [switch] $translationRulesEnableAll,
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

    if ($translationRulesEnableAll) {
        $translationRules = (Get-Variable "translationRules").Attributes.ValidValues;
    }

    Write-Host "Loading target document $targetPath";
    [XlfDocument] $targetDocument = [XlfDocument]::LoadFromPath($targetPath);
    $targetDocument.developerNoteDesignation = $developerNoteDesignation;
    $targetDocument.xliffGeneratorNoteDesignation = $xliffGeneratorNoteDesignation;

    Write-Host "Retrieving translation units from target document";
    [int] $unitCount = $targetDocument.TranslationUnitNodes().Count;
    [int] $i = 0;
    [int] $onePercentCount = $unitCount / 100;
    if ($onePercentCount -eq 0) {
        $onePercentCount = 1;
    }

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
                $targetDocument.SetState($unit, [XlfTranslationState]::MissingTranslation);
                $missingTranslationUnits += $unit;
            }

        }

        if ($checkForProblems -and $translationRules) {
            if (HasProblem -targetDocument $targetDocument -unit $unit -enabledRules $translationRules) {
                $targetDocument.SetState($unit, [XlfTranslationState]::NeedsWorkTranslation);
                $needWorkTranslationUnits += $unit;
            }

            # Check for resolved problem (to delete XLIFF Sync note)
            if ($targetDocument.GetState($unit) -ne [XlfTranslationState]::NeedsWorkTranslation) {
                if ($targetDocument.TryDeleteXLIFFSyncNote($unit)) {
                    $problemResolvedInFile = $true;
                }
            }
        }
    }

    [int] $missingCount = $missingTranslationUnits.Count;
    if ($checkForMissing) {
        Write-Host -ForegroundColor Yellow "Detected: $missingCount missing translation(s).";

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

    [int] $needWorkCount = $needWorkTranslationUnits.Count;
    if ($checkForProblems) {
        Write-Host -ForegroundColor Yellow "Detected: $needWorkCount translation(s) that need work.";

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
        Write-Host "Saving document to $targetPath";
        $targetDocument.SaveToFilePath($targetPath);
    }

    return $missingTranslationUnits + $needWorkTranslationUnits;
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

function HasProblem {
    Param (
        [XlfDocument] $targetDocument,
        [System.Xml.XmlNode] $unit,
        [string[]] $enabledRules
    )

    [string] $sourceText = $targetDocument.GetUnitSourceText($unit);
    [string] $translText = $targetDocument.GetUnitTranslation($unit);
    [string] $devNoteText = $targetDocument.GetUnitDeveloperNote($unit);
    if ((-not $sourceText) -or (-not $translText)) {
        return $false;
    }

    if ($enabledRules.Contains('Placeholders') -and (IsPlaceholdersMismatch -sourceText $sourceText -translationText $translText)) {
        $targetDocument.SetXliffSyncNote($unit, 'Problem detected: The number of placeholders in the source and translation text do not match.');
        return $true;
    }

    if ($enabledRules.Contains('PlaceholdersDevNote') -and (IsPlaceholdersMismatch -sourceText $sourceText -translationText $devNoteText)) {
        $targetDocument.SetXliffSyncNote($unit, 'Problem detected: One or more placeholders are missing an explanation in the Developer note.');
        return $true;
    }

    if (IsOptionCaptionUnit -targetDocument $targetDocument -unit $unit) {
        [string[]] $sourceMembers = $sourceText -split ",";
        [string[]] $translMembers = $translText -split ",";

        if ($enabledRules.Contains('OptionMemberCount') -and (IsOptionMemberCountMismatch -sourceMembers $sourceMembers -translMembers $translMembers)) {
            $targetDocument.SetXliffSyncNote($unit, 'Problem detected: The number of option members in the source and translation text do not match.');
            return $true;
        }
        if ($enabledRules.Contains('OptionLeadingSpaces') -and (IsOptionMemberLeadingSpacesMismatch -sourceMembers $sourceMembers -translMembers $translMembers)) {
            $targetDocument.SetXliffSyncNote($unit, 'Problem detected: The leading spaces in the option values of the source and translation text do not match.');
            return $true;
        }
    }

    if ($enabledRules.Contains('ConsecutiveSpacesExist')) {
        if (GetConsecutiveSpacesInText -textToCheck $sourceText) {
            $targetDocument.SetXliffSyncNote($unit, 'Problem detected: Consecutive spaces exist in the source text.');
            return $true;
        }
        if (GetConsecutiveSpacesInText -textToCheck $translText) {
            $targetDocument.SetXliffSyncNote($unit, 'Problem detected: Consecutive spaces exist in the translation text.');
            return $true;
        }
    }

    if ($enabledRules.Contains('ConsecutiveSpacesConsistent') -and (IsConsecutiveSpacesMismatch -sourceText $sourceText -translText $translText)) {
        $targetDocument.SetXliffSyncNote($unit, 'Problem detected: The "consecutive space"-occurrences in source and translation text do not match.');
        return $true;
    }

    if ($targetDocument.GetState($unit) -eq [XlfTranslationState]::NeedsWorkTranslation) {
        return $true;
    }

    return $false;
}

function IsPlaceholdersMismatch {
    Param (
        [string] $sourceText,
        [string] $translationText
    )

    return (HasMissingPlaceholders -textWithPlaceholders $sourceText -textToCheck $translationText) -or 
           (HasMissingPlaceholders -textWithPlaceholders $translationText -textToCheck $sourceText);
}

function HasMissingPlaceholders {
    Param (
        [string] $textWithPlaceholders,
        [string] $textToCheck
    )

    $placeHolderMatches = ([regex]'%[0-9]+|\{[0-9]+\}').Matches($textWithPlaceholders);
    if ($placeHolderMatches) {
        $missingPlaceHolder = $placeHolderMatches | Where-Object {
            $textToCheck.IndexOf($_.Value) -lt 0
        } | Select-Object -First 1;

        if ($missingPlaceHolder) {
            return $true;
        }
    }
    return $false;
}

function IsOptionCaptionUnit {
    Param (
        [XlfDocument] $targetDocument,
        [System.Xml.XmlNode] $unit
    )

    [string] $xliffGenNote = $targetDocument.GetUnitXliffGeneratorNote($unit);
    if (-not $xliffGenNote) {
        return $false;
    }

    [string[]] $optionKeywords = @('Property OptionCaption', 'Property PromotedActionCategories');
    [string] $keyWordFound = $optionKeywords | Where-Object { $xliffGenNote.IndexOf($_) -ge 0 } | Select-Object -First 1;
    if ($keyWordFound) {
        return $true;
    }

    return $false;
}

function IsOptionMemberCountMismatch {
    Param (
        [string[]] $sourceMembers,
        [string[]] $translMembers
    )

    return $sourceMembers.Count -ne $translMembers.Count;
}

function IsOptionMemberLeadingSpacesMismatch {
    Param (
        [string[]] $sourceMembers,
        [string[]] $translMembers
    )

    for ($i = 0; $i -lt $sourceMembers.Length; $i++) {
        [string] $sourceMember = $sourceMembers[$i];
        [string] $translMember = $translMembers[$i];
        [int] $sourceLeadingSpaces = ($sourceMember.Length - ($sourceMember.TrimStart().Length));
        [int] $translLeadingSpaces = ($translMember.Length - ($translMember.TrimStart().Length));
        if ($sourceLeadingSpaces -ne $translLeadingSpaces) {
            return $true;
        }
    }

    return $false;
}

function GetConsecutiveSpacesInText {
    Param (
        [string] $textToCheck
    )

    return ([regex]'\s\s+').Matches($textToCheck);
}

function IsConsecutiveSpacesMismatch {
    Param (
        [string] $sourceText,
        [string] $translText
    )

    $sourceTextConsecutiveSpaces = GetConsecutiveSpacesInText -textToCheck $sourceText;
    $translTextConsecutiveSpaces = GetConsecutiveSpacesInText -textToCheck $translText;
    if ($sourceTextConsecutiveSpaces.Count -ne $translTextConsecutiveSpaces.Count) {
        return $true;
    }

    for ($i = 0; $i -lt $sourceTextConsecutiveSpaces.Length; $i++) {
        if (($sourceTextConsecutiveSpaces[$i].Value.Length) -ne ($translTextConsecutiveSpaces[$i].Value.Length)) {
            return $true;
        }
    }

    return $false;
}
