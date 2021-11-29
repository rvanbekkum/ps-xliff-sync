# Changelog

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
