<# 
 .Synopsis
  Compares XLIFF translation files and creates a new XLIFF translation files with the differences.
 .Description
  Compares an original version to a new version of an XLIFF file and adds the units that have been added or changed (in source text) to a new XLIFF translation file.
 .Parameter originalPath
  Specifies the path to the original version of the XLIFF file.
 .Parameter newPath
  Specifies the path to the new version of the XLIFF file.
 .Parameter diffPath
  Specifies the path where the XLIFF file with the differences will be saved.
 .Parameter newOnly
  Specifies whether the command should only include the new units.
 .Parameter reportProgress
  Specifies whether the command should report progress.
#>
function Extract-XliffTranslationsDiff {
    Param (
        [Parameter(Mandatory=$true)]
        [string] $originalPath,
        [Parameter(Mandatory=$true)]
        [string] $newPath,
        [Parameter(Mandatory=$true)]
        [string] $diffPath,
        [switch] $newOnly,
        [switch] $reportProgress
    )

    Write-Host "Loading original document $originalPath";
    [XlfDocument] $originalDocument = [XlfDocument]::LoadFromPath($originalPath);
    Write-Host "Loading new document $newPath";
    [XlfDocument] $newDocument = [XlfDocument]::LoadFromPath($newPath);
    Write-Host "Creating new empty diff document";
    [XlfDocument] $diffDocument = [XlfDocument]::CreateEmptyDocFrom($originalDocument, $newDocument.GetTargetLanguage());

    Write-Host "Create Hash Map for original document's unit ids"
    $idMap = @{}
    $originalDocument.TranslationUnitNodes() | ForEach-Object {
        $unit = $_
        $idMap.Add($unit.'id', $originalDocument.GetUnitSourceText($unit));
    }

    Write-Host "Retrieve translation units from new document"
    [int] $unitCount = $newDocument.TranslationUnitNodes().Count;
    [int] $i = 0;
    [int] $onePercentCount = $unitCount / 100;

    Write-Host "Processing unit nodes... (Please be patient)"
    if ($reportProgress) {
        Write-Progress -Activity "Extracting new or changed units" -PercentComplete 0;
    }

    $newDocument.TranslationUnitNodes() | ForEach-Object {
        [System.Xml.XmlNode] $unit = $_;

        if ($reportProgress) {
            $i++;
            if ($i % $onePercentCount -eq 0) {
                $percentage = ($i / $unitCount) * 100;
                Write-Progress -Activity "Extracting new or changed units" -PercentComplete $percentage;
            }
        }

        [bool] $foundInOriginal = $idMap.ContainsKey($unit.id);
        if (-not $foundInOriginal) {
            $diffDocument.ImportUnit($unit);
        }
        elseif (-not $newOnly) {
            $originalSourceText = $idMap[$unit.id];
            $newSourceText = $newDocument.GetUnitSourceText($unit);
            if ($newSourceText -ne $originalSourceText) {
                $diffDocument.ImportUnit($unit);
            }
        }
    }

    Write-Host "Saving document to $diffPath"
    $diffDocument.SaveToFilePath($diffPath);
}