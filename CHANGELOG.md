# Changelog

## [1.2.0] 20-05-2021

* New function `Trans-XliffTranslations` by [Tomáš Žabčík](https://github.com/zabcik)
* Include units that already have needs-adaptation state in needs work count (GitHub issue [#8](https://github.com/rvanbekkum/ps-xliff-sync/issues/8))

### Thank You

* [Tomáš Žabčík](https://github.com/zabcik) for your [Pull Request #9 "New Functions Trans-XliffTranslations"](https://github.com/rvanbekkum/ps-xliff-sync/pull/9)
* [Frédéric Vercaemst](https://github.com/fvet) for filing [Issue #8 "Translation(s) that need work - no output compared to Xliff-sync"](https://github.com/rvanbekkum/ps-xliff-sync/issues/8)

## [1.1.0] 06-03-2021

* Fix for `findByXliffGeneratorNoteAndSourceText` throwing error on variable not being found.
* Fix for incorrect assumption of `xml:space="preserve"` which would lead to errors in an attempt to insert whitespace/nodes.
* Fix/Improvement: Find by source (and developer note) would take the first unit with the same source text even if that unit did not have a translation, now it takes the first unit with the same source text with a translation to reuse translations.
* Command `Check-XliffTranslations` now returns the units that contain problems as an array. Useful if you want to do something with the outputs, e.g., extract/show more information or completely fail your build pipeline if any problems are found.

### Thank You

* [Tomáš Žabčík](https://github.com/zabcik) for your [Pull Request #3 "fixing variable name"](https://github.com/rvanbekkum/ps-xliff-sync/pull/3)
* [Simone Colombo](https://github.com/simooo985) for filing [Issue #2 "Error syncing Angular translations"](https://github.com/rvanbekkum/ps-xliff-sync/issues/2)

## [1.0.0] 02-09-2020

* Initial version
