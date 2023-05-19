# Changelog

## [1.9.0] 19-05-2023

* Added `-useSelfClosingTags` parameter to the `Sync-XliffTranslations` command (GitHub issue [#38](https://github.com/rvanbekkum/ps-xliff-sync/issues/38))
* Added `-processAppFoldersSortedByDependencies` parameter to the `Test-BcAppXliffTranslations` command.

### Thank You (for 1.9.0)

* [Frédéric Vercaemst](https://github.com/fvet) for filing [Issue #38 Different Developer closing note when syncing xliffs via PS vs VS Code](https://github.com/rvanbekkum/ps-xliff-sync/issues/38)

## [1.8.0] 28-01-2023

* Added `-parseFromDeveloperNoteTrimCharacters` parameter to the `Sync-XliffTranslations` command (GitHub issue [#39](https://github.com/rvanbekkum/ps-xliff-sync/issues/39))

### Thank You (for 1.8.0)

* [Frédéric Vercaemst](https://github.com/fvet) for filing [Issue #39 "parseFromDeveloperNoteTrimCharacters" parameter missing in Sync-XliffTranslations / Test-BcAppXliffTranslations](https://github.com/rvanbekkum/ps-xliff-sync/issues/39)

## [1.7.0] 31-05-2022

* Fix for "attribute `target-language` cannot be found" bug by [Timotheus Pokorra](https://github.com/tpokorra) (GitHub issue [#30](https://github.com/rvanbekkum/ps-xliff-sync/issues/30))
* Fix for `SetXliffSyncNote` method which inserted the `source`-node another time when whitespace should _not_ be preserved.

### Thank You (for 1.7.0)

* [Timotheus Pokorra](https://github.com/tpokorra) for your [Pull Request #31 "Set attribute target-language even if it does not exist yet"](https://github.com/rvanbekkum/ps-xliff-sync/pull/31)

## [1.6.0] 09-02-2022

* Fixed missing `Write-Host "##[endgroup]"` in `Test-BcAppXliffTranslations`
* Support for multi-character `-parseFromDeveloperNoteSeparator` by [David FeldHoff](https://github.com/DavidFeldhoff)
* Changed default value for parameter `-FormatTranslationUnit` in `Test-BcAppXliffTranslations` to show both the Xliff Generator note and XLIFF Sync note for detected problems.

### Thank You (for 1.6.0)

* [David FeldHoff](https://github.com/DavidFeldhoff) for your [Pull Request #29 "Fix splitting if the separator consists of more than one character"](https://github.com/rvanbekkum/ps-xliff-sync/pull/29)

## [1.5.0] 07-12-2021

* Added `-FormatTranslationUnit` parameter to `Test-XliffTranslations` function. (GitHub issue [#21](https://github.com/rvanbekkum/ps-xliff-sync/issues/21))
* Added `-FormatTranslationUnit` parameter to `Sync-XliffTranslations` and `Test-BcAppXliffTranslations` functions. The latter has a default value that will print the AL object/field/action/control concerned. (GitHub issue [#21](https://github.com/rvanbekkum/ps-xliff-sync/issues/21))
* Write parameters when `-Verbose` switch is used with `Sync-XliffTranslations` or `Test-XliffTranslations` functions.
* Use `List[]` instead of array(s) in the `Test-XliffTranslations` function. (GitHub issue [#18](https://github.com/rvanbekkum/ps-xliff-sync/issues/18))
* Use `List[]` instead of array(s) in the `Sync-XliffTranslations` function. (GitHub issue [#18](https://github.com/rvanbekkum/ps-xliff-sync/issues/18))
* Added parameters `-syncAdditionalParameters` and `-testAdditionalParameters` to `Test-BcAppXliffTranslations` function. (GitHub issue [#22](https://github.com/rvanbekkum/ps-xliff-sync/issues/22))
* Fixed detected source text changes not being included in the detected issues.

### Thank You (for 1.5.0)

* [Jan Hoek](https://github.com/jhoek) for your [Pull Request #26 "Added -FormatTranslationUnit parameter"](https://github.com/rvanbekkum/ps-xliff-sync/pull/26) which adds the `-FormatTranslationUnit` parameter to `Test-XliffTranslations`.
* [Jan Hoek](https://github.com/jhoek) for your [Pull Request #27 "Use List[] instead of arrays"](https://github.com/rvanbekkum/ps-xliff-sync/pull/27) which changes `Test-XliffTranslations` to use lists instead of arrays.
* [Jan Hoek](https://github.com/jhoek) for your thoughts on aligning the parameters of `Test-BcAppXliffTranslations` (via DM).
* [Sergio Castelluccio](https://github.com/eclipses) for reporting `Test-BcAppXliffTranslations` not failing builds in Azure DevOps if errors are detected in a specific scenario (via DM).

## [1.4.0] 29-11-2021

* Changes in usage of `Resolve-Path` for scenarios where the `-targetLanguage` parameter of `Sync-XliffTranslations` is used.
* Added formatting settings (`.vscode/settings.json`) for PowerShell formatting (GitHub issue [#23](https://github.com/rvanbekkum/ps-xliff-sync/issues/23))

### Thank You (for 1.4.0)

* [David FeldHoff](https://github.com/DavidFeldhoff) for your [Pull Request #19 "Resolve-Path gets an error if the file does not exist yet."](https://github.com/rvanbekkum/ps-xliff-sync/pull/19)
* [Jan Hoek](https://github.com/jhoek) for your [Pull Request #24 "Chose formatting settings that matched current formatting as much as possible"](https://github.com/rvanbekkum/ps-xliff-sync/pull/19)

## [1.3.0] 29-09-2021

* Renamed functions to adhere to approved verbs and added aliases to still support the old function names (GitHub issue [#10](https://github.com/rvanbekkum/ps-xliff-sync/issues/10))
* New function `Test-BcAppXliffTranslations`, to be used for checking translations in a build pipeline for Microsoft Dynamics 365 Business Central apps. This function uses the `Sync-XliffTranslations` and `Test-XliffTranslations` functions to check for problems in all translation files of the BC app workspace folder.
* Add `Resolve-Path` for loading XLIFF files from or saving them to a filepath. (GitHub issue [#6](https://github.com/rvanbekkum/ps-xliff-sync/issues/6))
* Abort if file-load failed. (GitHub issue [#5](https://github.com/rvanbekkum/ps-xliff-sync/issues/5))
* Updated README with Installation instruction.

### Thank You (for 1.3.0)

* [Jan Hoek](https://github.com/jhoek) for filing [Issue #10 "Consider using standard verbs for your cmdlets"](https://github.com/rvanbekkum/ps-xliff-sync/issues/10)
* [Jan Hoek](https://github.com/jhoek) for filing [Issue #6 "Add support for relative paths"](https://github.com/rvanbekkum/ps-xliff-sync/issues/6)
* [Jan Hoek](https://github.com/jhoek) for filing [Issue #5 "In case of fatal exceptions, it might be better to stop the execution of the cmdlet"](https://github.com/rvanbekkum/ps-xliff-sync/issues/5)
* [Matthias König](https://github.com/aptMattKoe) for the suggestion of adding a small Installation section to the README.

## [1.2.0] 20-05-2021

* New function `Trans-XliffTranslations` by [Tomáš Žabčík](https://github.com/zabcik)
* Include units that already have needs-adaptation state in needs work count (GitHub issue [#8](https://github.com/rvanbekkum/ps-xliff-sync/issues/8))

### Thank You (for 1.2.0)

* [Tomáš Žabčík](https://github.com/zabcik) for your [Pull Request #9 "New Functions Trans-XliffTranslations"](https://github.com/rvanbekkum/ps-xliff-sync/pull/9)
* [Frédéric Vercaemst](https://github.com/fvet) for filing [Issue #8 "Translation(s) that need work - no output compared to Xliff-sync"](https://github.com/rvanbekkum/ps-xliff-sync/issues/8)

## [1.1.0] 06-03-2021

* Fix for `findByXliffGeneratorNoteAndSourceText` throwing error on variable not being found.
* Fix for incorrect assumption of `xml:space="preserve"` which would lead to errors in an attempt to insert whitespace/nodes.
* Fix/Improvement: Find by source (and developer note) would take the first unit with the same source text even if that unit did not have a translation, now it takes the first unit with the same source text with a translation to reuse translations.
* Command `Check-XliffTranslations` now returns the units that contain problems as an array. Useful if you want to do something with the outputs, e.g., extract/show more information or completely fail your build pipeline if any problems are found.

### Thank You (for 1.1.0)

* [Tomáš Žabčík](https://github.com/zabcik) for your [Pull Request #3 "fixing variable name"](https://github.com/rvanbekkum/ps-xliff-sync/pull/3)
* [Simone Colombo](https://github.com/simooo985) for filing [Issue #2 "Error syncing Angular translations"](https://github.com/rvanbekkum/ps-xliff-sync/issues/2)

## [1.0.0] 02-09-2020

* Initial version
