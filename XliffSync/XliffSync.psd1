@{
    RootModule        = 'XliffSync.psm1'
    ModuleVersion     = '1.2.0.0'
    GUID              = 'a7614fd7-ce84-44db-9475-bc1f5fa4f0e5'
    Author            = 'Rob van Bekkum'
    CompanyName       = 'WSB Solutions B.V.'
    Copyright         = '(c) 2020 Rob van Bekkum. All rights reserved.'
    Description       = 'Keep XLIFF translation files easily in sync with a generated base-XLIFF file.'
    PowerShellVersion = '5.0'
    FunctionsToExport = @('Check-XliffTranslations', 'Get-XliffTranslationsDiff', 'Sync-XliffTranslations', 'Trans-XliffTranslations')
    PrivateData       = @{
        PSData = @{
            Tags       = @('xliff', 'localization', 'translation', 'dynamics-365', 'synchronization')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/rvanbekkum/ps-xliff-sync'    
        }
    }
}