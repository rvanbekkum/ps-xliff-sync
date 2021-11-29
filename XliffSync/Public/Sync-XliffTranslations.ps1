<#
 .Synopsis
  Synchronizes translation units and translations with a base XLIFF file to a target XLIFF file.
 .Description
  Iterates through the translation units of a base XLIFF file and synchronizes them with a target XLIFF file.
 .Parameter sourcePath
  Specifies the path to the base/source XLIFF file.
 .Parameter targetPath
  Specifies the path to the target XLIFF file.
 .Parameter targetLanguage
  Specifies the target language to synchronize translation units for (alternative to specifying the target path).
 .Parameter developerNoteDesignation
  Specifies the name that is used to designate a developer note.
 .Parameter xliffGeneratorNoteDesignation
  Specifies the name that is used to designate an XLIFF generator note.
 .Parameter preserveTargetAttributes
  Specifies whether or not syncing should use the attribute values from the target files for the trans-unit nodes while syncing.
 .Parameter preserveTargetAttributesOrder
  Specifies whether the attributes of trans-unit nodes should use the order found in the target files while syncing.
 .Parameter findByXliffGeneratorNoteAndSource
  Specifies whether translation units should be matched on combination of XLIFF generator note and Source.
 .Parameter findByXliffGeneratorAndDeveloperNote
  Specifies whether translation units should be matched on combination of XLIFF generator note and developer note.
 .Parameter findByXliffGeneratorNote
  Specifies whether translation units should be matched on XLIFF generator note.
 .Parameter findBySourceAndDeveloperNote
  Specifies whether translations should be added from a translation unit with matching combination of source text and developer note.
 .Parameter findBySource
  Specifies whether translations should be added from a translation unit with matching source text.
 .Parameter parseFromDeveloperNote
  Specifies whether (initial) translations should be parsed from the translation unit's developer note (note: only when there is not already an existing translation in the target).
 .Parameter parseFromDeveloperNoteOverwrite
  Specifies whether translations parsed from the developer note should always overwrite existing translations.
  .Parameter copyFromSource
  Specifies whether (initial) translations should be copied from the source text (note: only when there is not already an existing translation in the target).
  .Parameter copyFromSourceOverwrite
  Specifies whether translations copied from the source text should overwrite existing translations.
  .Parameter detectSourceTextChanges
  Specifies whether changes in the source text of a trans-unit should be detected. If a change is detected, the target state is changed to needs-adaptation and a note is added to indicate the translation should be reviewed.
  .Parameter missingTranslation
  Specifies the target tag content for units where the translation is missing.
  .Parameter unitMaps
  Specifies for which search purposes this command should create in-memory maps in preparation of syncing.
  .Parameter AzureDevOps
  Specifies whether to generate Azure DevOps Pipeline compatible output. This setting determines the severity of errors.
 .Parameter reportProgress
  Specifies whether the command should report progress.
 .Parameter printProblems
  Specifies whether the command should print all detected problems.
#>
function Sync-XliffTranslations {
    Param (
        [Parameter(Mandatory = $true)]
        [string] $sourcePath,
        [Parameter(Mandatory = $false)]
        [string] $targetPath,
        [Parameter(Mandatory = $false)]
        [string] $targetLanguage,
        [Parameter(Mandatory = $false)]
        [string] $developerNoteDesignation = "Developer",
        [Parameter(Mandatory = $false)]
        [string] $xliffGeneratorNoteDesignation = "Xliff Generator",
        [switch] $preserveTargetAttributes,
        [switch] $preserveTargetAttributesOrder,
        [switch] $findByXliffGeneratorNoteAndSource,
        [switch] $findByXliffGeneratorAndDeveloperNote,
        [switch] $findByXliffGeneratorNote,
        [switch] $findBySourceAndDeveloperNote,
        [switch] $findBySource,
        [switch] $parseFromDeveloperNote,
        [switch] $parseFromDeveloperNoteOverwrite,
        [string] $parseFromDeveloperNoteSeparator = "|",
        [switch] $copyFromSource,
        [switch] $copyFromSourceOverwrite,
        [Parameter(Mandatory = $false)]
        [boolean] $detectSourceTextChanges = $true,
        [Parameter(Mandatory = $false)]
        [string] $missingTranslation = "",
        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Id", "All")]
        [string] $unitMaps = "All",
        [Parameter(Mandatory = $false)]
        [ValidateSet('no', 'error', 'warning')]
        [string] $AzureDevOps = 'no',
        [switch] $reportProgress,
        [switch] $printProblems
    )

    # Abort if both $targetPath and $targetLanguage are missing.
    if (-not $targetPath -and -not $targetLanguage) {
        throw "Missing -targetPath or -targetLanguage parameter.";
    }
    if ($targetPath -and (-not (Test-Path $targetPath))) {
        throw "File $targetPath could not be found."
    }

    Write-Host "Loading source document $sourcePath";
    [XlfDocument] $mergedDocument = [XlfDocument]::LoadFromPath($sourcePath);
    $mergedDocument.developerNoteDesignation = $developerNoteDesignation;
    $mergedDocument.xliffGeneratorNoteDesignation = $xliffGeneratorNoteDesignation;
    $mergedDocument.missingTranslation = $missingTranslation;
    $mergedDocument.parseFromDeveloperNoteSeparator = $parseFromDeveloperNoteSeparator;
    $mergedDocument.preserveTargetAttributes = $preserveTargetAttributes;
    $mergedDocument.preserveTargetAttributesOrder = $preserveTargetAttributesOrder;

    [XlfDocument] $targetDocument = $null;
    if (-not $targetPath) {
        $targetPath = (Resolve-Path $sourcePath) -replace '(\.g)?\.xlf', ".$targetLanguage.xlf"
    }

    if (Test-Path $targetPath) {
        Write-Host "Loading target document $targetPath";
        $targetDocument = [XlfDocument]::LoadFromPath($targetPath); ;
    } else {
        Write-Host "Creating new document for language '$targetLanguage'";
        $targetDocument = [XlfDocument]::CreateCopyFrom($mergedDocument, $targetLanguage);
    }

    [string] $language = $targetDocument.GetTargetLanguage();
    if ($language) {
        Write-Host "Setting target language for merge document to '$language'";
        $mergedDocument.SetTargetLanguage($language);
    }

    $sourceTranslationsHashTable = @{};
    [bool] $findByXliffGenNotesIsEnabled = $findByXliffGeneratorNoteAndSource -or $findByXliffGeneratorAndDeveloperNote -or $findByXliffGeneratorNote;
    [bool] $findByIsEnabled = $findByXliffGenNotesIsEnabled -or $findBySourceAndDeveloperNote -or $findBySource -or $copyFromSource -or $parseFromDeveloperNote;
    if ($unitMaps -ne "None") {
        Write-Host "Creating Maps in memory for target document's units.";
        if ($unitMaps -eq "Id") {
            $targetDocument.CreateUnitMaps($false, $false, $false, $false, $false);
        } else {
            $targetDocument.CreateUnitMaps($findByXliffGeneratorNoteAndSource, $findByXliffGeneratorAndDeveloperNote, $findByXliffGeneratorNote, $findBySourceAndDeveloperNote, $findBySource);
        }
    }

    Write-Host "Retrieving translation units from source document";
    [int] $unitCount = $mergedDocument.TranslationUnitNodes().Count;
    [int] $i = 0;
    [int] $onePercentCount = $unitCount / 100;
    if ($onePercentCount -eq 0) {
        $onePercentCount = 1;
    }
    [System.Xml.XmlNode[]] $detectedSourceTextChanges = @();

    Write-Host "Processing unit nodes... (Please be patient)";
    [string] $progressMessage = "Syncing translation units."
    if ($reportProgress) {
        if ($AzureDevOps -ne 'no') {
            Write-Host "##vso[task.setprogress value=0;]$progressMessage";
        } else {
            Write-Progress -Activity $progressMessage -PercentComplete 0;
        }
    }

    $mergedDocument.TranslationUnitNodes() | ForEach-Object {
        [System.Xml.XmlNode] $unit = $_;

        if ($reportProgress) {
            $i++;
            if ($i % $onePercentCount -eq 0) {
                $percentage = ($i / $unitCount) * 100;
                if ($AzureDevOps -ne 'no') {
                    Write-Host "##vso[task.setprogress value=$percentage;]$progressMessage";
                } else {
                    Write-Progress -Activity $progressMessage -PercentComplete $percentage;
                }
            }
        }

        # Find by ID.
        [System.Xml.XmlNode] $targetUnit = $targetDocument.FindTranslationUnit($unit.id);
        [string] $translation = $null;

        if ((-not $targetUnit) -and $findByIsEnabled) {
            [string] $developerNote = $mergedDocument.GetUnitDeveloperNote($unit);
            [string] $sourceText = $mergedDocument.GetUnitSourceText($unit);

            if ($findByXliffGenNotesIsEnabled) {
                [string] $xliffGeneratorNote = $mergedDocument.GetUnitXliffGeneratorNote($unit);
                if ($xliffGeneratorNote) {
                    # Find by Xliff Generator Note + Source Text combination.
                    if ($findByXliffGeneratorNoteAndSource -and $sourceText) {
                        $targetUnit = $targetDocument.FindTranslationUnitByXliffGeneratorNoteAndSourceText($xliffGeneratorNote, $sourceText);
                    }

                    # Find by Xliff Generator Note + Dev. Note combination.
                    if ((-not $targetUnit) -and $findByXliffGeneratorAndDeveloperNote -and $developerNote) {
                        $targetUnit = $targetDocument.FindTranslationUnitByXliffGeneratorNoteAndDeveloperNote($xliffGeneratorNote, $developerNote);
                    }

                    # Find by Xliff Generator Note.
                    if ((-not $targetUnit) -and $findByXliffGeneratorNote) {
                        $targetUnit = $targetDocument.FindTranslationUnitByXliffGeneratorNote($xliffGeneratorNote);
                    }
                }
            }

            if ((-not $targetUnit) -and $sourceText) {
                # Find by Source + Developer Note combination (also matching on empty/undefined developer note).
                if ($findBySourceAndDeveloperNote) {
                    [System.Xml.XmlNode] $targetDocTranslUnit = $targetDocument.FindTranslationUnitBySourceTextAndDeveloperNote($sourceText, $developerNote);
                    if ($targetDocTranslUnit) {
                        $translation = $targetDocument.GetUnitTranslation($targetDocTranslUnit);
                    }
                }

                # Find by Source.
                if ((-not $translation) -and $findBySource) {
                    if (-not $sourceTranslationsHashTable.ContainsKey($sourceText)) {
                        [System.Xml.XmlNode] $targetDocTranslUnit = $targetDocument.FindTranslationUnitBySourceText($sourceText);
                        if ($targetDocTranslUnit) {
                            $translation = $targetDocument.GetUnitTranslation($targetDocTranslUnit);
                            if ($translation) {
                                $sourceTranslationsHashTable[$sourceText] = $translation;
                            }
                        }
                    } else {
                        $translation = $sourceTranslationsHashTable[$sourceText];
                    }
                }
            }
        }

        if ((-not $translation) -and ($copyFromSource -or $parseFromDeveloperNote)) {
            [bool] $hasNoTranslation = $false;
            if ($targetUnit) {
                [string] $targetTranslation = $targetDocument.GetUnitTranslation($targetUnit);
                $hasNoTranslation = (-not $targetTranslation) -or ($targetTranslation -eq $missingTranslation);
            } else {
                $hasNoTranslation = $true;
            }

            [bool] $shouldParseFromDevNote = $parseFromDeveloperNote -and ($hasNoTranslation -or $parseFromDeveloperNoteOverwrite);
            [bool] $shouldCopyFromSource = $copyFromSource -and ($hasNoTranslation -or $copyFromSourceOverwrite);

            if ((-not $translation) -and $shouldParseFromDevNote) {
                $translation = $mergedDocument.GetUnitTranslationFromDeveloperNote($unit);
            }
            if ((-not $translation) -and $shouldCopyFromSource) {
                $translation = $mergedDocument.GetUnitSourceText($unit);
            }
        }

        $mergedDocument.MergeUnit($unit, $targetUnit, $translation);

        if ($detectSourceTextChanges -and $targetUnit) {
            [string] $mergedSourceText = $mergedDocument.GetUnitSourceText($unit);
            [string] $mergedTranslText = $mergedDocument.GetUnitTranslation($unit);
            [string] $origSourceText = $targetDocument.GetUnitSourceText($targetUnit);

            if ($mergedSourceText -and $origSourceText -and $mergedTranslText) {
                if ($mergedSourceText -ne $origSourceText) {
                    $mergedDocument.SetXliffSyncNote($unit, 'Source text has changed. Please review the translation.');
                    $mergedDocument.SetState($unit, [XlfTranslationState]::NeedsWorkTranslation);
                    $detectedSourceTextChanges += $unit;
                }
            }
        }
    }

    if ($detectSourceTextChanges) {
        Write-Host -ForegroundColor Yellow "Detected $($detectedSourceTextChanges.Count) source text change(s).";

        if ($printProblems -and $detectedSourceTextChanges) {
            [string] $detectedMessage = "Detected source text change in unit '{0}'.";
            if ($AzureDevOps -ne 'no') {
                $detectedMessage = "##vso[task.logissue type=$AzureDevOps]$detectedMessage";
            }

            $detectedSourceTextChanges | ForEach-Object {
                Write-Host ($detectedMessage -f $_.id);
            }
        }
    }

    Write-Host "Saving document to $targetPath"
    $mergedDocument.SaveToFilePath($targetPath);
}
Export-ModuleMember -Function Sync-XliffTranslations
