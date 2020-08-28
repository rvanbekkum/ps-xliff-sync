class XlfDocument {

    hidden [System.Xml.XmlNode] $root;
    hidden [System.Xml.XmlNode[]] $allTranslationUnitNodes;
    
    [string] $developerNoteDesignation;
    [string] $xliffGeneratorNoteDesignation;
    [boolean] $preserveTargetAttributes;
    [boolean] $preserveTargetAttributesOrder;
    [string] $parseFromDeveloperNoteSeparator;
    [string] $missingTranslation;
    [string] $needsWorkTranslationSubstate;

    [boolean] Valid() {
        $hasRoot = $null -ne $this.root;
        Write-Output $this.root
        $hasVersion = $null -ne $this.Version();
        $hasSourceLanguage = $null -ne $this.GetSourceLanguage();
        return $hasRoot -and $hasVersion -and $hasSourceLanguage;
    }

    [string] Version() {
        return $this.root.'version';
    }

    [string] GetSourceLanguage() {
        switch ($this.Version()) {
            "1.2" { 
                [System.Xml.XmlNode] $fileNode = [XlfDocument]::GetNode('file', $this.root);
                if ($fileNode) {
                    return $fileNode.'source-language';
                }
            }
        }
        return $null;
    }

    [void] SetSourceLanguage([string] $lng) {
        if (-not $lng) {
            return;
        }

        switch ($this.Version()) {
            "1.2" { 
                [System.Xml.XmlNode] $fileNode = [XlfDocument]::GetNode('file', $this.root);
                if ($fileNode) {
                    $fileNode.'source-language' = $lng
                }
                break;
            }
        }
    }

    [string] GetTargetLanguage() {
        switch ($this.Version()) {
            "1.2" { 
                [System.Xml.XmlNode] $fileNode = [XlfDocument]::GetNode('file', $this.root);
                if ($fileNode) {
                    return $fileNode.'target-language';
                }
            }
        }
        return $null;
    }

    [void] SetTargetLanguage([string] $lng) {
        if (-not $lng) {
            return;
        }

        switch ($this.Version()) {
            "1.2" { 
                [System.Xml.XmlNode] $fileNode = [XlfDocument]::GetNode('file', $this.root);
                if ($fileNode) {
                    $fileNode.'target-language' = $lng;
                }
            }
        }
    }

    [System.Xml.XmlNode] FindTranslationUnit([string] $transUnitId) {
        return $this.TranslationUnitNodes() | Where-Object { $_.'id' -eq $transUnitId } | Select-Object -First 1;
    }

    [System.Xml.XmlNode] FindTranslationUnitByXliffGeneratorNoteAndSourceText([string] $xliffGenNote, [string] $sourceText) {
        return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitXliffGeneratorNote($_) -eq $xliffGenNote) -and ($this.GetUnitSourceText($_) -eq $sourceText) } | Select-Object -First 1;
    }

    [System.Xml.XmlNode] FindTranslationUnitByXliffGeneratorNoteAndDeveloperNote([string] $xliffGenNote, [string] $devNote) {
        return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitXliffGeneratorNote($_) -eq $xliffGenNote) -and ($this.GetUnitDeveloperNote($_) -eq $devNote) } | Select-Object -First 1;
    }

    [System.Xml.XmlNode] FindTranslationUnitByXliffGeneratorNote([string] $xliffGenNote) {
        return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitXliffGeneratorNote($_) -eq $xliffGenNote) } | Select-Object -First 1;
    }

    [System.Xml.XmlNode] FindTranslationUnitBySourceTextAndDeveloperNote([string] $sourceText, [string] $devNote) {
        return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitDeveloperNote($_) -eq $devNote) -and ($this.GetUnitSourceText($_) -eq $sourceText) } | Select-Object -First 1;
    }

    [System.Xml.XmlNode] FindTranslationUnitBySourceText([string] $sourceText) {
        return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitSourceText($_) -eq $sourceText) } | Select-Object -First 1;
    }

    [void] MergeUnit([System.Xml.XmlNode] $sourceUnit, [System.Xml.XmlNode] $targetUnit,[string] $translation) {
        [System.Xml.XmlNode] $targetNode = $null;

        [System.Xml.XmlElement] $sourceUnitAsElement = $sourceUnit;
        if ($targetUnit) {
            #TODO: Test preserveTargetAttributes + preserveTargetAttributesOrder
            if ($this.preserveTargetAttributes) {
                if ($this.preserveTargetAttributesOrder) {
                    [System.Xml.XmlAttributeCollection]$sourceAttributes = $sourceUnitAsElement.Attributes;
                    $sourceUnitAsElement.Attributes = $targetUnit.Attributes;
                    $sourceUnitAsElement.'id' = $sourceAttributes['id'];
                    foreach ($attr in $sourceAttributes) {
                        if (-not $sourceUnitAsElement.Attributes[$attr.Name]) {
                            $sourceUnitAsElement.SetAttributeNode($attr);
                        }
                    }
                }
                else {
                    foreach ($attr in $targetUnit.Attributes) {
                        if ($attr.Name -ne 'id') {
                            $sourceUnitAsElement.SetAttributeNode($attr);
                        }
                    }
                }
            }
            else {
                foreach ($attr in $targetUnit.Attributes) {
                    if (-not $sourceUnitAsElement.Attributes[$attr.Name]) {
                        $sourceUnitAsElement.SetAttributeNode($attr);
                    }
                }
            }

            $targetUnitTargetNode = [XlfDocument]::GetNode('target', $targetUnit);
            if ($targetUnitTargetNode) {
                $targetNode = $this.root.OwnerDocument.ImportNode($targetUnitTargetNode, $true);
            }
        }

        [boolean] $needsTranslation = $this.GetUnitNeedsTranslation($sourceUnit);
        if ($needsTranslation -and (-not $targetNode)) {
            #TODO: State attributes
            if (-not $translation) {
                $translation = $this.missingTranslation;
            }

            $targetNode = $this.CreateTargetNode($sourceUnit, $translation);
        }
        elseif ((-not $needsTranslation) -and $targetNode) {
            $this.DeleteTargetNode($sourceUnit);
        }

        if ($needsTranslation -and $targetNode) {
            if ($translation) {
                Write-Host "2 Add Translation $translation";
                $targetNode.InnerText = $translation;
                #TODO: State attributes
            }

            $this.AppendTargetNode($sourceUnit, $targetNode);
        }
    }

    [System.Xml.XmlNode] CreateTargetNode([System.Xml.XmlNode] $parentUnit, [string] $translation) {
        [xml] $xmlDoc = $this.root.OwnerDocument;
        [System.Xml.XmlNode] $targetNode = $xmlDoc.CreateNode([System.Xml.XmlNodeType]::Element, "target", $this.root.NamespaceURI);
        $xmlDoc.ImportNode($targetNode, $true);

        if ($translation) {
            $targetNode.InnerText = $translation;
        }
        return $targetNode;
    }

    [void] AppendTargetNode([System.Xml.XmlNode] $unit, [System.Xml.XmlNode] $targetNode) {
        if (-not $unit) {
            return;
        }

        switch ($this.Version()) {
            "1.2" { 
                [System.Xml.XmlNode] $sourceChildNode = $unit.ChildNodes | Where-Object { $_.Name -eq "source" } | Select-Object -First 1;
                [System.Xml.XmlNode] $targetChildNode = $unit.ChildNodes | Where-Object { $_.Name -eq "target" } | Select-Object -First 1;
                
                if ($targetChildNode) {
                    Write-Host "Replace Child $targetChildNode with $targetNode"
                    $unit.ReplaceChild($targetNode, $targetChildNode);
                }
                elseif ($sourceChildNode) {
                    $unit.InsertAfter($targetNode, $sourceChildNode.NextSibling);
                    $unit.InsertAfter($sourceChildNode.PreviousSibling, $targetNode);
                }
                else {
                    Write-Host "AddLast $targetNode"
                    $unit.AppendChild($targetNode);
                }
                break;
            }
        }
    }

    [void] DeleteTargetNode([System.Xml.XmlElement] $unitNode) {
        if ($unitNode) {
            [System.Xml.XmlNode] $targetNode = $unitNode.ChildNodes | Where-Object { $_.Name -eq 'target'} | Select-Object -First 1;
            if ($targetNode) {
                $unitNode.RemoveChild($targetNode);
            }
        }
    }

    [boolean] GetUnitNeedsTranslation([System.Xml.XmlNode] $unitNode) {
        [string] $translateAttribute = $unitNode.'translate';
        if ($translateAttribute) {
            return $translateAttribute -eq 'yes';
        }
        return $true;
    }

    [string] GetUnitSourceText([System.Xml.XmlNode] $unitNode) {
        [System.Xml.XmlNode] $sourceNode = [XlfDocument]::GetNode('source', $unitNode);
        if ((-not $sourceNode) -and (-not $sourceNode.HasChildNodes)) {
            return $null;
        }
        return $sourceNode.ChildNodes[0].Value;
    }

    [string] GetUnitTranslation([System.Xml.XmlNode] $unitNode) {
        [System.Xml.XmlNode] $translationNode = [XlfDocument]::GetNode('target', $unitNode);
        if ((-not $translationNode) -and (-not $translationNode.HasChildNodes)) {
            return $null;
        }
        return $translationNode.ChildNodes[0].Value;
    }

    [string] GetUnitDeveloperNote([System.Xml.XmlNode] $unitNode) {
        return $this.GetUnitNoteText($unitNode, $this.developerNoteDesignation);
    }

    [string] GetUnitXliffGeneratorNote([System.Xml.XmlNode] $unitNode) {
        return $this.GetUnitNoteText($unitNode, $this.xliffGeneratorNoteDesignation);
    }

    [string] GetUnitNoteText([System.Xml.XmlNode] $unitNode, [string] $noteDesignation) {
        [System.Xml.XmlNode] $noteNode = $null;

        switch ($this.Version()) {
            "1.2" { 
                $noteNode = $unitNode.ChildNodes | Where-Object { ($_.Name -eq "note") -and ($_.'from' -eq $noteDesignation) } | Select-Object -First 1;
                break;
            }
        }

        if ((-not $noteNode) -or (-not $noteNode.HasChildNodes)) {
            return $null;
        }

        return $noteNode.ChildNodes[0].Value;
    }

    [System.Xml.XmlNode[]] TranslationUnitNodes() {
        if ($this.allTranslationUnitNodes) {
            return $this.allTranslationUnitNodes;
        }

        [System.Xml.XmlNode[]] $transUnits = @();
        if (-not $this.root) {
            return $transUnits;
        }

        switch ($this.Version()) {
            "1.2" { 
                [System.Xml.XmlNode] $bodyNode = [XlfDocument]::GetNode('body', $this.root);
                if ($bodyNode) {
                    $unitsInBody = $this.GetTranslationUnitsFromRoot($bodyNode);
                    if ($unitsInBody -and ($unitsInBody.Count -gt 0)) {
                        $transUnits += $unitsInBody;
                    }

                    $unitsInGroups = $this.GetGroupTranslationUnitNodes($bodyNode);
                    if ($unitsInGroups -and ($unitsInGroups.Count -gt 0)) {
                        $transUnits += $unitsInGroups;
                    }
                }
            }
        }

        $this.allTranslationUnitNodes = $transUnits;

        return $transUnits;
    }

    [void] SaveToFilePath([string] $filePath) {
        $this.root.OwnerDocument.Save($filePath);
    }

    hidden [System.Xml.XmlNode[]] GetGroupTranslationUnitNodes([System.Xml.XmlNode] $rootNode) {
        [System.Xml.XmlNode[]] $transUnits = @();
        [System.Xml.XmlNode[]] $groupNodes = $rootNode.ChildNodes | Where-Object {
            $_.Name -eq 'group'
        };
        if (-not $groupNodes) {
            return $transUnits
        }

        $groupNodes | ForEach-Object {
            $unitsInGroup = $this.GetTranslationUnitsFromRoot($_);
            if ($unitsInGroup -and ($unitsInGroup.Count -gt 0)) {
                $transUnits += $unitsInGroup;
            }
        }
        $groupNodes | ForEach-Object {
            $unitsInSubGroups = $this.GetGroupTranslationUnitNodes($_);
            if ($unitsInSubGroups -and ($unitsInSubGroups.Count -gt 0)) {
                $transUnits += $unitsInSubGroups;
            }
        }
        return $transUnits;
    }

    hidden [System.Xml.XmlNode[]] GetTranslationUnitsFromRoot([System.Xml.XmlNode] $rootNode) {
        return $rootNode.ChildNodes | Where-Object {
            $_.Name -eq 'trans-unit'
        };
    }

    hidden static [System.Xml.XmlNode] GetNode([string] $tag, [System.Xml.XmlNode] $node) {
        if (-not $node) {
            return $null;
        }

        if ($node.Name -eq $tag) {
            return $node;
        }
        else {
            foreach ($member in $node.ChildNodes) {
                [System.Xml.XmlNode] $child = $member;
                $reqNode = [XlfDocument]::GetNode($tag, $child);
                if ($null -ne $reqNode) {
                    return $reqNode;
                }
            }
        }

        return $null;
    }

    hidden static [XlfDocument] LoadFromRootNode([System.Xml.XmlNode] $rootNode) {
        $doc = [XlfDocument]::new();
        $doc.root = $rootNode;
        return $doc;
    }

    static [XlfDocument] LoadFromXmlDocument([xml] $document) {
        return [XlfDocument]::LoadFromRootNode($document.ChildNodes.Item(1));
    }

    static [XlfDocument] LoadFromPath([string] $filePath) {
        [xml] $fileContentXml = Get-Content $filePath;
        return [XlfDocument]::LoadFromXmlDocument($fileContentXml);
    }
}
