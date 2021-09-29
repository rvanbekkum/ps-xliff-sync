<#
 .Synopsis
  Translates translation units in target(s) with a translation base from source file(s).
 .Description
  Iterates through the translation units of target file(s) and translates them with a translation base from source file(s).
 .Parameter sourcePath
  Specifies the path to the base/source XLIFF file / folder.
 .Parameter targetPath
  Specifies the path to the target XLIFF file.
 .Parameter unitMaps
  Specifies for which search purposes this command should create in-memory maps in preparation of syncing.
#>
function Set-XliffTranslations {
    Param (
        [Parameter(Mandatory = $true)]
        [string] $sourcePath,
        [Parameter(Mandatory = $true)]
        [string] $targetPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Id", "All")]
        [string] $unitMaps = "All"
    )

    Write-Host "Loading target document $targetPath";
    [XlfDocument] $targetDocument = [XlfDocument]::LoadFromPath($targetPath);

    $targetLanguage = $targetDocument.GetTargetLanguage();

    Write-Host "Loading source document $sourcePath";
    [XlfDocument] $sourceDocument = [XlfDocument]::new();
    $filter = "*.$targetLanguage.xlf";
    Get-ChildItem -Path $sourcePath -Filter $filter -Recurse | foreach-object -process {
        if ($_) {
            $targetPath2 = $_.FullName;
            Write-Host "Loading target document $targetPath2";
            $sourceDocument.AddFromPath($targetPath2);
        }
    }

    if ($unitMaps -ne "None") {
        Write-Host "Creating Maps in memory for source document's units.";
        if ($unitMaps -eq "Id") {
            $sourceDocument.CreateUnitMaps($false, $false, $false, $false, $false);
        }
        else {
            [bool] $findBySource = $true;
            $sourceDocument.CreateUnitMaps($false, $false, $false, $false, $findBySource);
        }
    }

    if ($unitMaps -ne "None") {
        Write-Host "Creating Maps in memory for target document's units.";
        if ($unitMaps -eq "Id") {
            $targetDocument.CreateUnitMaps($false, $false, $false, $false, $false);
        }
        else {
            [bool] $findBySource = $true;
            $targetDocument.CreateUnitMaps($false, $false, $false, $false, $findBySource);
        }
    }

    Write-Host "Retrieving translation units from source document";
    [int] $unitCount = $sourceDocument.TranslationUnitNodes().Count;
    [int] $i = 0;
    [int] $onePercentCount = $unitCount / 100;
    if ($onePercentCount -eq 0) {
        $onePercentCount = 1;
    }

    Write-Host "Processing unit nodes... (Please be patient)";
    [string] $progressMessage = "Syncing translation units."
    if ($reportProgress) {
        Write-Progress -Activity $progressMessage -PercentComplete 0;
    }

    $sourceTranslationsHashTable = @{};
    $sourceDocument.TranslationUnitNodes() | ForEach-Object {
        [System.Xml.XmlNode] $sourceUnit = $_;

        [string] $sourceText = $sourceDocument.GetUnitSourceText($sourceUnit);
        if (-not $sourceTranslationsHashTable.ContainsKey($sourceText)) {
            [System.Xml.XmlNode] $sourceDocTranslUnit = $sourceDocument.FindTranslationUnitBySourceText($sourceText);
            if ($sourceDocTranslUnit) {
                [string] $translation = $null;
                $translation = $sourceDocument.GetUnitTranslation($sourceDocTranslUnit);
                if ($translation) {
                    $sourceTranslationsHashTable[$sourceText] = $translation;
                }
            }
        }
    }

    $targetDocument.TranslationUnitNodes() | ForEach-Object {
        [System.Xml.XmlNode] $targetUnit = $_;

        if ($reportProgress) {
            $i++;
            if ($i % $onePercentCount -eq 0) {
                $percentage = ($i / $unitCount) * 100;
                Write-Progress -Activity $progressMessage -PercentComplete $percentage;
            }
        }

        # Read target "sourceText"
        [string] $targetSourceText = $targetDocument.GetUnitSourceText($targetUnit);
        # Write-Host "Source: $targetSourceText";

        # Read target "targetText"
        [string] $targetTargetText = $targetDocument.GetUnitTranslation($targetUnit);
        # Write-Host "Target: $targetTargetText";

        # Needs-Translation
        if ($targetSourceText -and (-not $targetTargetText)) {

            [string] $translation = $null;

            # Find by ID.
            [System.Xml.XmlNode] $sourceUnit = $sourceDocument.FindTranslationUnit($targetUnit.id);
            if ($sourceUnit) {
                $translation = $sourceDocument.GetUnitTranslation($sourceUnit);
            }

            # Find by Source.
            if (-not $translation) {

                if ($sourceTranslationsHashTable.ContainsKey($targetSourceText)) {
                    $translation = $sourceTranslationsHashTable[$targetSourceText];
                }
            }

            if ($translation) {
                $targetDocument.MergeUnit($targetUnit, $targetUnit, $translation);
                # Write-Host "Translation: $translation";
            }

        }
    }

    Write-Host "Saving document to $targetPath"
    $targetDocument.SaveToFilePath($targetPath);
}
Set-Alias -Name Trans-XliffTranslations -Value Set-XliffTranslations
Export-ModuleMember -Function Set-XliffTranslations -Alias Trans-XliffTranslations
