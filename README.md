# XLIFF Sync

A module to keep XLIFF translation files in sync with a specified, automatically generated base-XLIFF file.

This PowerShell module is based off the [XLIFF Sync](https://github.com/rvanbekkum/vsc-xliff-sync) VSCode extension.

## Project Status

Under development.
This module will implement the same features as those available in the XLIFF Sync VSCode extension.

## Prerequisites

You need to have Powershell 5.0 or newer. This module uses classes.

## Usage

### Synchronize XLIFF Translations

The `Sync-XliffTranslations` commandlet will synchronize translation units and translations for a specified base/source file and target file.
To use the commandlet you will need to specify the path to the base/source file (`-sourcePath`) and a path to the target file (`-targetPath`) _or_ a target language (`-targetLanguage`).

An example usage:

```powershell
Sync-XliffTranslations -sourcePath "C:\MyProject\My Project.g.xlf" -targetPath "C:\MyProject\My Project.nl-NL.xlf" -findByXliffGeneratorNoteAndSource -findByXliffGeneratorAndDeveloperNote -findByXliffGeneratorNote
```

The extension will try to find corresponding trans-units and translations within a target file as follows:

1. Finding trans-units:
> 1. By Id
> 2. By XLIFF Generator Note & Source (controlled by parameter `findByXliffGeneratorNoteAndSource`)
> 3. By XLIFF Generator Note & Developer Note (controlled by parameter `findByXliffGeneratorAndDeveloperNote`)
> 4. By XLIFF Generator Note (controlled by parameter `findByXliffGeneratorNote`)

2. Finding translations:
> 5. By Source & Developer Note (controlled by parameter `findBySourceAndDeveloperNote`)
> 6. By Source (controlled by parameter `findBySource`)

3. Initial translation:
> 7. Parse from Developer Note (controlled by parameter `parseFromDeveloperNote`)
> 8. Copy from Source if source-language = target-language (controlled by parameter `copyFromSourceForSameLanguage`)

If no trans-unit or translation is found, the unit is added and its target node is tagged with `state="needs-translation"`.

Please check the documentation of the commandlet for more information and the available parameters.

### Check XLIFF Translations

The `Check-XliffTranslations` commandlet will check for missing translations and/or for problems in translations in a specified XLIFF file.
To use the commandlet you will need to specify the target file (`-targetPath`) and whether you want to check for missing translations (`-checkForMissing`) and/or problems in translations (`-checkForProblems`).
If you let the command check for problems, then you can use the `translationRules` parameter to specify which technical validation rules should be applied.

An example usage:

```powershell
Check-XliffTranslations -targetPath "C:\MyProject\My Project.nl-NL.xlf" -checkForMissing -Verbose
```

When finished the command will report the number of missing translations and number of detected problems.
Translation units without translations will be marked with `state="needs-translation"` and translation units with a problem in the translation will be marked with a 'needs-work' state and an "XLIFF Sync"-note that explains the detected problem.

Please check the documentation of the commandlet for more information and the available parameters.
