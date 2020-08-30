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
  Specifies whether or not syncing should use the attributes from the target files for the trans-unit nodes while syncing.
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
  .Parameter ignoreLineEndingTypeChanges
  Specifies whether changes in line ending type (CRLF vs. LF) should not be considered as changes to the source text of a trans-unit.
  .Parameter missingTranslation
  Specifies the target tag content for units where the translation is missing.
  .Parameter needsWorkTranslationSubstate
  Specifies the substate to use for translations that need work in xlf2 files.
  .Parameter AzureDevOps
  Specifies whether to #TODO:
#>
function Sync-XliffTranslations {
    Param (
        [Parameter(Mandatory=$true)]
        [string] $sourcePath,
        [Parameter(Mandatory=$false)]
        [string] $targetPath,
        [Parameter(Mandatory=$false)]
        [string] $targetLanguage, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [string] $developerNoteDesignation="Developer",
        [Parameter(Mandatory=$false)]
        [string] $xliffGeneratorNoteDesignation="Xliff Generator",
        [Parameter(Mandatory=$false)]
        [switch] $preserveTargetAttributes, #TODO: Not tested yet
        [Parameter(Mandatory=$false)]
        [switch] $preserveTargetAttributesOrder, #TODO: Not tested yet
        [Parameter(Mandatory=$false)]
        [switch] $findByXliffGeneratorNoteAndSource,
        [Parameter(Mandatory=$false)]
        [switch] $findByXliffGeneratorAndDeveloperNote,
        [Parameter(Mandatory=$false)]
        [switch] $findByXliffGeneratorNote,
        [Parameter(Mandatory=$false)]
        [switch] $findBySourceAndDeveloperNote,
        [Parameter(Mandatory=$false)]
        [switch] $findBySource,
        [Parameter(Mandatory=$false)]
        [switch] $parseFromDeveloperNote, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [switch] $parseFromDeveloperNoteOverwrite, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [string] $parseFromDeveloperNoteSeparator="|", #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [switch] $copyFromSource, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [switch] $copyFromSourceOverwrite, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [boolean] $detectSourceTextChanges=$true, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [switch] $ignoreLineEndingTypeChanges, #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [string] $missingTranslation="", #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [string] $needsWorkTranslationSubstate="xliffSync:needsWork", #TODO: Not implemented yet
        [Parameter(Mandatory=$false)]
        [switch] $AzureDevOps #TODO: Not implemented yet
    )

    # Abort if both $targetPath and $targetLanguage are missing.
    if (-not $targetPath -and -not $targetLanguage) {
        throw "Missing -targetPath or -targetLanguage parameter";
    }

    # TEMPORARY: Abort if a parameter for an unimplemented feature is used.
    if ($targetLanguage -or $parseFromDeveloperNote -or $copyFromSource -or $ignoreLineEndingTypeChanges -or $missingTranslation) {
        throw "The parameters you entered are for one or more features that have not been implemented yet.";
    }

    [XlfDocument] $mergedDocument = [XlfDocument]::LoadFromPath($sourcePath);
    $mergedDocument.developerNoteDesignation = $developerNoteDesignation;
    $mergedDocument.xliffGeneratorNoteDesignation = $xliffGeneratorNoteDesignation;
    $mergedDocument.missingTranslation = $missingTranslation;
    $mergedDocument.needsWorkTranslationSubstate = $needsWorkTranslationSubstate;
    $mergedDocument.parseFromDeveloperNoteSeparator = $parseFromDeveloperNoteSeparator;
    $mergedDocument.preserveTargetAttributes = $preserveTargetAttributes;
    $mergedDocument.preserveTargetAttributesOrder = $preserveTargetAttributesOrder;

    [XlfDocument] $targetDocument = $null;
    if ($targetPath) {
        $targetDocument = [XlfDocument]::LoadFromPath($targetPath);
    }
    else {
        #TODO: Create a new document for the $targetLanguage
    }
    [string] $language = $targetDocument.GetTargetLanguage();
    if ($language) {
        $mergedDocument.SetTargetLanguage($language);
    }

    $sourceTranslationsHashTable = @{};
    $findByNotes = $findByXliffGeneratorNoteAndSource -or $findByXliffGeneratorAndDeveloperNote -or $findByXliffGeneratorNote;
    $findByIsEnabled = $findByNotes -or $findBySourceAndDeveloperNote -or $findBySource -or $copyFromSource -or $parseFromDeveloperNote;

    $mergedDocument.TranslationUnitNodes() | ForEach-Object {
        [System.Xml.XmlNode] $unit = $_;
        
        # Find by ID.
        [System.Xml.XmlNode] $targetUnit = $targetDocument.FindTranslationUnit($unit.id);
        [string] $translation = $null;
        
        if ((-not $targetUnit) -and $findByIsEnabled) {
            [string] $developerNote = $mergedDocument.GetUnitDeveloperNote($unit);
            [string] $sourceText = $mergedDocument.GetUnitSourceText($unit);

            if ($findByNotes) {
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
                    Write-Host "Searching by SourceDevNote!"
                    [System.Xml.XmlNode] $targetDocTranslUnit = $targetDocument.FindTranslationUnitBySourceTextAndDeveloperNote($sourceText, $developerNote);
                    if ($targetDocTranslUnit) {
                        Write-Host "Found by SourceDevNote!"
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
                    }
                    else {
                        $translation = $sourceTranslationsHashTable[$sourceText];
                    }
                }
            }

            #TODO: Later -- copyFromSource + parseFromDeveloperNote
        }

        $mergedDocument.MergeUnit($unit, $targetUnit, $translation);

        #TODO: Later -- detectSourceTextChanges
    }

    $mergedDocument.SaveToFilePath($targetPath);
}
