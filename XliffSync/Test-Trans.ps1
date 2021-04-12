cls

Import-Module -Name "C:\Users\zabcikt.CDL\GitHub\ps-xliff-sync\XliffSync\XliffSync.psm1" -Force -DisableNameChecking;

Trans-XliffTranslations `
    -source "C:\Users\zabcikt.CDL\GitHub\ps-xliff-sync\XliffSync\Tests\TestTransSource.cs-CZ.xlf" `
    -target "C:\Users\zabcikt.CDL\GitHub\ps-xliff-sync\XliffSync\Tests\TestTransTarget.cs-CZ.xlf"
# -source "C:\tmp\" `
# -unitMaps 'None'