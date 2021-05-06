Import-Module -Name (Resolve-Path -Path "XliffSync\XliffSync.psm1") -Force -DisableNameChecking;

Trans-XliffTranslations `
    -source (Resolve-Path -Path "XliffSync\Tests\TestTransSource.cs-CZ.xlf") `
    -target (Resolve-Path -Path "XliffSync\Tests\TestTransTarget.cs-CZ.xlf")