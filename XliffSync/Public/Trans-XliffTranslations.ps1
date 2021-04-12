<# 
 .Synopsis
  Synchronizes translation units and translations with a base XLIFF file to a target XLIFF file.
 .Description
  Iterates through the translation units of a base XLIFF file and synchronizes them with a target XLIFF file.
 .Parameter sourcePath
  Specifies the path to the base/source XLIFF file.
 .Parameter targetPath
  Specifies the path to the target XLIFF file.
 .Parameter unitMaps
  Specifies for which search purposes this command should create in-memory maps in preparation of syncing.
#>
function Trans-XliffTranslations {
    Param (
        [Parameter(Mandatory = $true)]
        [string] $sourcePath,        
        [Parameter(Mandatory = $true)]
        [string] $targetPath,                

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Id", "All")]
        [string] $unitMaps = "All"
    )

    Write-Host "Loading source document $sourcePath";
    [XlfDocument] $sourceDocument = [XlfDocument]::LoadFromPath($sourcePath);    

    Write-Host "Loading target document $targetPath";
    [XlfDocument] $targetDocument = [XlfDocument]::LoadFromPath($targetPath);

    $sourceTranslationsHashTable = @{};    
    if ($unitMaps -ne "None") {
        Write-Host "Creating Maps in memory for target document's units.";
        if ($unitMaps -eq "Id") {
            $sourceDocument.CreateUnitMaps($false, $false, $false, $false, $false);
            $targetDocument.CreateUnitMaps($false, $false, $false, $false, $false);
        }
        else {            
            [bool] $findBySource = $true;
            $sourceDocument.CreateUnitMaps($false, $false, $false, $false, $findBySource);
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
                [System.Xml.XmlNode] $targetDocTranslUnit = $sourceDocument.FindTranslationUnitBySourceText($targetSourceText);
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