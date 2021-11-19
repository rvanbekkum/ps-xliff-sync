<#
  .Synopsis
   Generates missing translations using Azure Cognitive Services.
  .Description
   Processes a Xliff file through the Microsoft Translator API v3.0 (https://docs.microsoft.com/en-us/azure/cognitive-services/translator/reference/v3-0-translate) to generate missing translations.
   Supports a custom translator trained Neural Machine Translation model through the setting of the CategoryId parameter.
  .Parameter XlfInputFile
   Specifies the path to the input XLIFF file.
  .Parameter XlfOutputFile
   Specifies the path to the output XLIFF file. If empty, it uses the same XlfInputFile path.
  .Parameter ApiKey
   Specifies one fo the two API Keys
  .Parameter Region
   Specifies the Region where the Cognitive Service is hosted
  .Parameter CategoryId
   Specify the Category (domain) of the translation. This parameter is used to get translations from a customized system built with Custom Translator. Add the Category ID from your Custom Translator project details to this parameter to use your deployed customized system. Default value is: general. 
  .Example
   Translate-XliffTranslations -XlfInputFile "C:\GIT\HelloWorld\base\Translations\Hello World.it-IT.xlf" -ApiKey "XXXXXXXXXXXXXX" -Region "westeurope"
#>
function Translate-XliffTranslations {
param(
    [ValidateScript({Test-Path -Path $_ -PathType leaf})]
    [Parameter(ValueFromPipeline=$true, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$XlfInputFile,
    [Parameter(Mandatory=$false)]
    [string]$XlfOutputFile,
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    [Parameter(Mandatory=$true)]
    [string]$Region,
    [Parameter(Mandatory=$false)]
    [string]$CategoryId = "general"
)

    function Translate-String {
        param (
            [Parameter(Mandatory=$true)]
            [string]$apiKey,
            [Parameter(Mandatory=$true)]
            [string]$region,
            [Parameter(Mandatory=$true)]
            [string]$sourceLanguage,
            [Parameter(Mandatory=$true)]
            [string]$targetLanguage,
            [Parameter(Mandatory=$true)]
            [string]$textToConvert
        )
        # Translation API
        $translateBaseURI = "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&category=$CategoryId"
        # API Auth Headers
        $headers = @{}
        $headers.Add("Ocp-Apim-Subscription-Key",$apiKey)
        $headers.Add("Ocp-Apim-Subscription-Region", $region);
        $headers.Add("Content-Type","application/json")
        # Conversion URI
        $convertURI = "$($translateBaseURI)&from=$($sourceLanguage)&to=$($targetLanguage)"
        # Build Conversion Body
        $text = @{'Text' = $($textToConvert)}
        $text = $text | ConvertTo-Json
        # Convert
        $conversionResult = Invoke-RestMethod -Method POST -Uri $convertURI -Headers $headers -Body "[$($text)]"
        return [string]$conversionResult.translations[0].text
    }

    $ErrorActionPreference = "Stop"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sourceByteSum = 0
    $targetByteSum = 0

    if (-not $XlfOutputFile) {
        $XlfOutputFile = $XlfInputFile
    }

    Write-Output "Opening $($XlfInputFile)"
    [System.Xml.XmlDocument]$xml = new-object System.Xml.XmlDocument
    $xml.load($XlfInputFile)

    $sourceLanguage = $xml.xliff.file.'source-language'
    $targetLanguage = $xml.xliff.file.'target-language'
    $targetLanguage  = $targetLanguage.Substring(0,5)

    Write-Host -ForegroundColor Yellow "Translating $($XlfInputFile) from $($sourceLanguage) to $($targetLanguage)."

    $count = 0
    foreach ($node in $xml.xliff.file.body.group.'trans-unit') {
        if ($node.target.state -ne "needs-translation") {
            continue
        }
        $sourceElementContainingText = $node.source
        if ($sourceElementContainingText -is [String]) {
            $sourceText = $sourceElementContainingText
        }

        # Translate the test of a single node.
        $translatedText = Translate-String -ApiKey $ApiKey -sourceLanguage $sourceLanguage -targetLanguage $targetLanguage -textToConvert $sourceText -region $Region

        $sourceByteSum += [System.Text.Encoding]::UTF8.GetByteCount([string]$sourceText)
        $targetByteSum += [System.Text.Encoding]::UTF8.GetByteCount([string]$translatedText)

        Write-Output "Translated '$($sourceText)' to '$($translatedText)'."

        # Set the same attributes on the 'trans-unit.target' element that the Multilingual App Toolkit would.
        $node.target.SetAttribute("state", "translated")
        $node.target.SetAttribute("state-qualifier", "tm-suggestion")

        # Put the translation into the target.
        $targetElementContainingText = $node.target
        if ($targetElementContainingText -is [System.Xml.XmlText] -or $targetElementContainingText -is [System.Xml.XmlLinkedNode]) {
            $targetElementContainingText.InnerText = $translatedText
        }

        $count = $count + 1
    }

    $xml.Save($XlfOutputFile)

    Write-Host -ForegroundColor Yellow "Done. File written to $($XlfOutputFile)"
    Write-Output "Translated $($count) strings."
    Write-Output "Total bytes of source text: $("{0:N}" -f $sourceByteSum)"
    Write-Output "Total bytes of target text: $("{0:N}" -f $targetByteSum)"

    $sw.Stop()
    Write-Host -ForegroundColor Green "Time taken: $($sw.Elapsed)"
}
Export-ModuleMember -Function Translate-XliffTranslations
