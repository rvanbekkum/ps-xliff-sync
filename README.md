# XLIFF Sync

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![XliffSync](https://img.shields.io/powershellgallery/v/XliffSync.svg?style=flat-square&label=XliffSync)](https://www.powershellgallery.com/packages/XliffSync/)
[![Downloads](https://img.shields.io/powershellgallery/dt/XliffSync.svg?style=flat-square&color=blue)](https://www.powershellgallery.com/packages/XliffSync/)

A module to keep XLIFF translation files in sync with a specified, automatically generated base-XLIFF file.

This PowerShell module is based off the [XLIFF Sync](https://github.com/rvanbekkum/vsc-xliff-sync) VSCode extension.

## Project Status

Initial version with support for XLIFF 1.2 (support for XLIFF 2.0 follows later).

## Prerequisites

You need to have Powershell 5.0 or newer. This module uses classes.

## Installation

You can install the module from [PowerShell Gallery](https://www.powershellgallery.com/packages/XliffSync/) by running:

```powershell
Install-Module -Name XliffSync
```

## Usage

### Synchronize XLIFF Translations

The `Sync-XliffTranslations` function will synchronize translation units and translations for a specified base/source file and target file.
To use the function you will need to specify the path to the base/source file (`-sourcePath`) and a path to the target file (`-targetPath`) _or_ a target language (`-targetLanguage`).

An example usage:

```powershell
Sync-XliffTranslations -sourcePath "C:\MyProject\My Project.g.xlf" -targetPath "C:\MyProject\My Project.nl-NL.xlf" -findByXliffGeneratorNoteAndSource -findByXliffGeneratorAndDeveloperNote -findByXliffGeneratorNote -reportProgress
```

The function will try to find matching trans-units and translations within a target file as follows:

1. Finding trans-units:
> 1. By Id
> 2. By XLIFF Generator Note & Source (controlled by switch `findByXliffGeneratorNoteAndSource`)
> 3. By XLIFF Generator Note & Developer Note (controlled by switch `findByXliffGeneratorAndDeveloperNote`)
> 4. By XLIFF Generator Note (controlled by switch `findByXliffGeneratorNote`)

2. Finding translations:
> 5. By Source & Developer Note (controlled by switch `findBySourceAndDeveloperNote`)
> 6. By Source (controlled by switch `findBySource`)

3. Initial translation:
> 7. Parse from Developer Note (controlled by switch `parseFromDeveloperNote`)
> 8. Copy from Source if source-language = target-language (controlled by switch `copyFromSource`)

If no trans-unit or translation is found, the unit is added and its target node is tagged with `state="needs-translation"`.

Please check the documentation of the function for more information and the available parameters.

### Check XLIFF Translations

The `Test-XliffTranslations` function (alias: `Check-XliffTranslations`) will check for missing translations and/or for problems in translations in a specified XLIFF file.
To use the function you will need to specify the target file (`-targetPath`) and whether you want to check for missing translations (`-checkForMissing`) and/or problems in translations (`-checkForProblems`).
If you let the function check for problems, then you can use the `translationRules` parameter to specify which technical validation rules should be applied.

An example usage:

```powershell
$unitsWithProblems = Test-XliffTranslations -targetPath "C:\MyProject\My Project.nl-NL.xlf" -checkForMissing -reportProgress
```

When finished the function will report the number of missing translations and number of detected problems.
Translation units without translations will be marked with `state="needs-translation"` and translation units with a problem in the translation will be marked with a 'needs-work' state and an "XLIFF Sync"-note that explains the detected problem.
The function will return the translation units with problems, which you can assign to a variable (e.g., `$unitsWithProblems`) or omit, to have the output printed.

If you use the `-printProblems` parameter, then you can use the `-FormatTranslationUnit` to specify which part of the trans-units should be printed.
The default value for this parameter is set to show the ID of the trans-unit, i.e.:

```powershell
-FormatTranslationUnit { param($TranslationUnit) $TranslationUnit.id }
```

For Business Central app translation use cases, you could change this to show the XLIFF Generator note, which is also the default for [`Test-BcAppXliffTranslations`](#check-translations-of-your-microsoft-dynamics-365-business-central-apps), i.e.:

```powershell
-FormatTranslationUnit { param($TranslationUnit) $TranslationUnit.note | Where-Object from -EQ 'Xliff Generator' | Select-Object -ExpandProperty '#text' },
```

Please check the documentation of the function for more information and the available parameters.

### Get XLIFF Translation Files Diff

The `Get-XliffTranslationsDiff` function will compare an original and new version of an XLIFF file and produce a new XLIFF Diff file that contains all the translation units that were added or whose source text was changed.

An example usage:

```powershell
Get-XliffTranslationsDiff -originalPath "C:\MyProject\OriginalVersion.xlf" -newPath "C:\MyProject\NewVersion.xlf" -diffPath "C:\MyProject\Diff.xlf" -reportProgress
```

Please check the documentation of the function for more information and the available parameters.

### Apply Translations to XLIFF Translation Files

The `Set-XliffTranslations` function (alias: `Trans-XliffTranslations`) will apply translations to the translation units in a target file with a translation base from a source file.

An example usage:

```powershell
Set-XliffTranslations -sourcePath "C:\MyProject\translationSource.xlf" -targetPath "C:\MyProject\translationTarget.xlf"
```

Please check the documentation of the function for more information and the available parameters.

### Check Translations of your Microsoft Dynamics 365 Business Central apps

The `Test-BcAppXliffTranslations` function (alias: `Check-BcAppXliffTranslations`) checks for problems in translations in the XLIFF translation files used for Microsoft Dynamics 365 Business Central apps.
It first synchronizes the translation files with the `.g.xlf` base file, and then checks for problems afterwards.
You can use this function in the build pipelines of your Business Central apps after the compile step, to detect problems in the translations of your Business Central apps.

An example usage:

```powershell
Test-BcAppXliffTranslations -translationRulesEnableAll -AzureDevOps 'error' -printProblems
```

This function invokes the `Sync-XliffTranslations` and `Test-XliffTranslations` functions for each XLIFF translation file in the app folder(s).
Note that you can use the `-syncAdditionalParameters` and `-testAdditionalParameters` parameters to pass arguments specific to each of these functions respectively, e.g.:

```powershell
-syncAdditionalParameters @{ "parseFromDeveloperNote" = $true }
```

Please check the documentation of the function for more information and the available parameters.
