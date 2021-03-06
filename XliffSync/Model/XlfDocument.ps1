class XlfDocument {

    hidden [System.Xml.XmlNode] $root;
    hidden [System.Xml.XmlNode] $cachedImportParentNode;
    hidden [System.Xml.XmlNode[]] $cachedTranslationUnitNodes;

    hidden $idUnitMap;
    hidden $xliffGeneratorNoteSourceUnitMap;
    hidden $xliffGeneratorNoteDeveloperNoteUnitMap;
    hidden $xliffGeneratorNoteUnitMap;
    hidden $xliffGeneratorNote;
    hidden $sourceDeveloperNoteUnitMap;
    hidden $sourceUnitMap;
    
    [string] $developerNoteDesignation;
    [string] $xliffGeneratorNoteDesignation;
    [boolean] $preserveTargetAttributes;
    [boolean] $preserveTargetAttributesOrder;
    [string] $parseFromDeveloperNoteSeparator;
    [string] $missingTranslation;

    [boolean] Valid() {
        $hasRoot = $null -ne $this.root;
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

    [void] CreateUnitMaps([bool] $findByXliffGeneratorNoteAndSource, [bool] $findByXliffGeneratorAndDeveloperNote, [bool] $findByXliffGeneratorNote, [bool] $findBySourceAndDeveloperNote, [bool] $findBySource) {
        [bool] $findByXliffGenNotesIsEnabled = $findByXliffGeneratorNoteAndSource -or $findByXliffGeneratorAndDeveloperNote -or $findByXliffGeneratorNote;
        [bool] $findByIsEnabled = $findByXliffGenNotesIsEnabled -or $findBySourceAndDeveloperNote -or $findBySource;
        
        $this.idUnitMap = @{}
        $this.xliffGeneratorNoteSourceUnitMap = @{};
        $this.xliffGeneratorNoteDeveloperNoteUnitMap = @{};
        $this.xliffGeneratorNoteUnitMap = @{};
        $this.sourceDeveloperNoteUnitMap = @{};
        $this.sourceUnitMap = @{};

        $this.TranslationUnitNodes() | ForEach-Object {
            $unit = $_;
            if (-not $this.idUnitMap.Contains($unit.id)) {
                $this.idUnitMap.Add($unit.id, $unit);
            }

            if ($findByIsEnabled) {
                [string] $developerNote = $this.GetUnitDeveloperNote($unit);
                [string] $sourceText = $this.GetUnitSourceText($unit);

                if ($findByXliffGenNotesIsEnabled) {
                    [string] $xliffGeneratorNote = $this.GetUnitXliffGeneratorNote($unit);

                    if ($findByXliffGeneratorNoteAndSource) {
                        $key = @($xliffGeneratorNote, $sourceText);
                        if (-not $this.xliffGeneratorNoteSourceUnitMap.ContainsKey($key)) {
                            $this.xliffGeneratorNoteSourceUnitMap.Add($key, $unit);
                        }
                    }
                    if ($findByXliffGeneratorAndDeveloperNote) {
                        $key = @($xliffGeneratorNote, $developerNote);
                        if (-not $this.xliffGeneratorNoteDeveloperNoteUnitMap.ContainsKey($key)) {
                            $this.xliffGeneratorNoteDeveloperNoteUnitMap.Add($key, $unit);
                        }
                    }
                    if ($findByXliffGeneratorNote) {
                        $key = $xliffGeneratorNote;
                        if (-not $this.xliffGeneratorNoteUnitMap.ContainsKey($key)) {
                            $this.xliffGeneratorNoteUnitMap.Add($key, $unit);
                        }
                    }
                }

                if ($findBySourceAndDeveloperNote) {
                    $key = @($sourceText, $developerNote);
                    if (-not ($this.sourceDeveloperNoteUnitMap.ContainsKey($key))) {
                        $translation = $this.GetUnitTranslation($unit);
                        if ($translation) {
                            $this.sourceDeveloperNoteUnitMap.Add($key, $unit);
                        }
                    }
                }

                if ($findBySource -and (-not ($this.sourceUnitMap.ContainsKey($sourceText)))) {
                    $translation = $this.GetUnitTranslation($unit);
                    if ($translation) {
                        $this.sourceUnitMap.Add($sourceText, $unit);
                    }
                }
            }
        }
    }

    [System.Xml.XmlNode] FindTranslationUnit([string] $transUnitId) {
        if ($this.idUnitMap) {
            if ($this.idUnitMap.ContainsKey($transUnitId)) {
                return $this.idUnitMap[$transUnitId];
            }
            return $null;
        }
        else {
            return $this.TranslationUnitNodes() | Where-Object { $_.'id' -eq $transUnitId } | Select-Object -First 1;
        }
    }

    [System.Xml.XmlNode] FindTranslationUnitByXliffGeneratorNoteAndSourceText([string] $xliffGenNote, [string] $sourceText) {
        if ($this.xliffGeneratorNoteSourceUnitMap) {
            $key = @($xliffGenNote, $sourceText);
            if ($this.xliffGeneratorNoteSourceUnitMap.ContainsKey($key)) {
                return $this.xliffGeneratorNoteSourceUnitMap[$key];
            }
            return $null;
        }
        else {
            return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitXliffGeneratorNote($_) -eq $xliffGenNote) -and ($this.GetUnitSourceText($_) -eq $sourceText) } | Select-Object -First 1;
        }
    }

    [System.Xml.XmlNode] FindTranslationUnitByXliffGeneratorNoteAndDeveloperNote([string] $xliffGenNote, [string] $devNote) {
        if ($this.xliffGeneratorNoteDeveloperNoteUnitMap) {
            $key = @($xliffGenNote, $devNote);
            if ($this.xliffGeneratorNoteDeveloperNoteUnitMap.ContainsKey($key)) {
                return $this.xliffGeneratorNoteDeveloperNoteUnitMap[$key];
            }
            return $null;
        }
        else {
            return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitXliffGeneratorNote($_) -eq $xliffGenNote) -and ($this.GetUnitDeveloperNote($_) -eq $devNote) } | Select-Object -First 1;
        }
    }

    [System.Xml.XmlNode] FindTranslationUnitByXliffGeneratorNote([string] $xliffGenNote) {
        if ($this.xliffGeneratorNoteUnitMap) {
            $key = $xliffGenNote;
            if ($this.xliffGeneratorNoteUnitMap.ContainsKey($key)) {
                return $this.xliffGeneratorNoteUnitMap[$key];
            }
            return $null;
        }
        else {
            return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitXliffGeneratorNote($_) -eq $xliffGenNote) } | Select-Object -First 1;
        }
    }

    [System.Xml.XmlNode] FindTranslationUnitBySourceTextAndDeveloperNote([string] $sourceText, [string] $devNote) {
        if ($this.sourceDeveloperNoteUnitMap) {
            $key = @($sourceText, $devNote);
            if ($this.sourceDeveloperNoteUnitMap.ContainsKey($key)) {
                return $this.sourceDeveloperNoteUnitMap[$key];
            }
            return $null;
        }
        else {
            return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitDeveloperNote($_) -eq $devNote) -and ($this.GetUnitSourceText($_) -eq $sourceText) } | Select-Object -First 1;
        }
    }

    [System.Xml.XmlNode] FindTranslationUnitBySourceText([string] $sourceText) {
        if ($this.sourceUnitMap) {
            $key = $sourceText;
            if ($this.sourceUnitMap.ContainsKey($key)) {
                return $this.sourceUnitMap[$key];
            }
            return $null;
        }
        else {
            return $this.TranslationUnitNodes() | Where-Object { ($this.GetUnitSourceText($_) -eq $sourceText) } | Select-Object -First 1;
        }
    }

    [void] ImportUnit([System.Xml.XmlNode] $unit) {
        $newUnit = $this.root.OwnerDocument.ImportNode($unit, $true);

        [System.Xml.XmlNode] $parentNode = $this.cachedImportParentNode;
        if (-not $this.cachedImportParentNode) {
            switch ($this.Version()) {
                "1.2" { 
                    # Parent will be the first 'group' or 'body' node.
                    $parentNode = [XlfDocument]::GetNode('group', $this.root);
                    if (-not $parentNode) {
                        $parentNode = [XlfDocument]::GetNode('body', $this.root);
                    }
                    break;
                }
            }

            if (-not $parentNode) {
                return;
            }

            $this.cachedImportParentNode = $parentNode;
        }

        $parentNode.AppendChild($newUnit);
    }

    [void] MergeUnit([System.Xml.XmlNode] $sourceUnit, [System.Xml.XmlNode] $targetUnit, [string] $translation) {
        [System.Xml.XmlNode] $targetNode = $null;

        [System.Xml.XmlElement] $sourceUnitAsElement = $sourceUnit;
        if ($targetUnit) {
            if ($this.preserveTargetAttributes) {
                # Use the target's attribute values
                if ($this.preserveTargetAttributesOrder) {
                    $sourceAttributes = @{};
                    foreach ($attr in $sourceUnit.Attributes) {
                        $sourceAttributes[$attr.Name] = $attr.Value;
                    }

                    # First take the target's attributes
                    $sourceUnitAsElement.Attributes.RemoveAll();
                    foreach ($attr in $targetUnit.Attributes) {
                        $newAttr = $this.root.OwnerDocument.ImportNode($attr, $true);
                        $sourceUnitAsElement.SetAttributeNode($newAttr);
                    }

                    # Use the id from the sourceUnit
                    if ($sourceAttributes.ContainsKey('id')) {
                        $newAttr = $this.root.OwnerDocument.CreateAttribute('id');
                        $newAttr.Value = $sourceAttributes['id'];
                        $sourceUnitAsElement.SetAttributeNode($newAttr);
                    }

                    # Add the extra attributes from the sourceUnit
                    foreach ($attr in $sourceAttributes.GetEnumerator()) {
                        if (-not $sourceUnitAsElement.Attributes[$attr.Name]) {
                            $sourceUnitAsElement.SetAttribute($attr.Name, $attr.Value);
                        }
                    }
                }
                else {
                    foreach ($attr in $targetUnit.Attributes) {
                        if ($attr.Name -ne 'id') {
                            $newAttr = $this.root.OwnerDocument.ImportNode($attr, $true);
                            $sourceUnitAsElement.SetAttributeNode($newAttr);
                        }
                    }
                }
            }
            else {
                # Use the source's attribute values for the attributes in common, and extend these with any extra attributes from the target.
                foreach ($attr in $targetUnit.Attributes) {
                    if (-not $sourceUnitAsElement.Attributes[$attr.Name]) {
                        $newAttr = $this.root.OwnerDocument.ImportNode($attr, $true);
                        $sourceUnitAsElement.SetAttributeNode($newAttr);
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
            [XlfTranslationState] $newTranslationState = [XlfTranslationState]::Translated;
            if (-not $translation) {
                $translation = $this.missingTranslation;
                $newTranslationState = [XlfTranslationState]::MissingTranslation;
            }
            $targetNode = $this.CreateTargetNode($sourceUnit, $translation, $newTranslationState);
        }
        elseif ((-not $needsTranslation) -and $targetNode) {
            $this.DeleteTargetNode($sourceUnit);
        }

        if ($needsTranslation -and $targetNode) {
            if ($translation) {
                $targetNode.InnerText = $translation;
                if ($this.Version() -eq "1.2") {
                    $this.UpdateStateAttributes($targetNode, [XlfTranslationState]::Translated);
                }
            }

            $this.AppendTargetNode($sourceUnit, $targetNode);
        }
    }

    [void] UpdateStateAttributes([System.Xml.XmlElement] $stateNode, [XlfTranslationState] $translationState) {
        switch ($this.Version()) {
            "1.2" {
                switch ($translationState) {
                    ([XlfTranslationState]::MissingTranslation) {
                        $stateNode.SetAttribute('state', 'needs-translation');
                        break;
                    }
                    ([XlfTranslationState]::NeedsWorkTranslation) {
                        $stateNode.SetAttribute('state', 'needs-adaptation');
                        break;
                    }
                    ([XlfTranslationState]::Translated) {
                        $stateNode.SetAttribute('state', 'translated');
                        break;
                    }
                }
                break;
            }
        }
    }

    [XlfTranslationState] GetState([System.Xml.XmlNode] $unit) {
        [System.Xml.XmlNode] $stateNode = $this.TryGetStateNode($unit);
        if ($stateNode -and $stateNode.HasAttributes) {
            switch ($this.Version()) {
                "1.2" {
                    [string] $stateValue = $stateNode.GetAttribute('state');
                    if ($stateValue) {
                        switch ($stateValue) {
                            'needs-translation' {
                                return [XlfTranslationState]::MissingTranslation;
                            }
                            'needs-adaptation' {
                                return [XlfTranslationState]::NeedsWorkTranslation;
                            }
                            'translated' {
                                return [XlfTranslationState]::Translated;
                            }
                        }
                    }
                    break;
                }
            }
        }
        return [XlfTranslationState]::MissingTranslation;
    }

    [void] SetState([System.Xml.XmlNode] $unit, [XlfTranslationState] $newTranslationState) {
        [System.Xml.XmlNode] $stateNode = $this.TryGetStateNode($unit);
        if ((-not $stateNode) -and ($this.Version() -eq "1.2")) {
            [System.Xml.XmlNode] $newTargetNode = $this.CreateTargetNode($unit, "", $newTranslationState);
            $this.AppendTargetNode($unit, $newTargetNode);
        }
        elseif ($stateNode) {
            $this.UpdateStateAttributes($stateNode, $newTranslationState);
        }
    }

    hidden [System.Xml.XmlNode] TryGetStateNode([System.Xml.XmlNode] $unit) {
        [string] $stateNodeTag = 'target';
        switch ($this.Version()) {
            "1.2" {
                $stateNodeTag = 'target';
                break;
            }
        }

        return [XlfDocument]::GetNode($stateNodeTag, $unit);
    }

    [void] SetXliffSyncNote([System.Xml.XmlNode] $unit, [string] $noteText) {
        [xml] $xmlDoc = $this.root.OwnerDocument;
        [System.Xml.XmlElement] $noteNode = $xmlDoc.CreateNode([System.Xml.XmlNodeType]::Element, 'note', $this.root.NamespaceURI);
        [string] $fromAttributeValue = "XLIFF Sync";

        [System.Xml.XmlNode] $notesParent = $unit;
        switch ($this.Version()) {
            "1.2" {
                $noteNode.SetAttribute('from', $fromAttributeValue);
                break;
            }
            Default {
                return;
            }
        }

        $noteNode.SetAttribute('annotates', 'general');
        $noteNode.SetAttribute('priority', '1');
        $noteNode.InnerText = $noteText;

        [System.Xml.XmlNode] $existingNote = $this.GetExistingXliffSyncNote($notesParent);
        [System.Xml.XmlNode] $targetChildNode = $unit.ChildNodes | Where-Object { $_.Name -eq "target" } | Select-Object -First 1;

        if ($existingNote) {
            $notesParent.ReplaceChild($noteNode, $existingNote);
        }
        elseif ($targetChildNode -and ($this.Version() -eq "1.2")) {
            $unit.InsertAfter($noteNode, $targetChildNode.NextSibling);
            
            # Add the same whitespace after the note.
            $newWhiteSpaceNode = $this.root.OwnerDocument.ImportNode($targetChildNode.PreviousSibling, $true);
            $unit.InsertAfter($newWhiteSpaceNode, $noteNode);
        }
        else {
            $notesParent.AppendChild($noteNode);
        }
    }

    [bool] TryDeleteXLIFFSyncNote([System.Xml.XmlNode] $unit) {
        [System.Xml.XmlNode] $notesParent = $unit;
        if (-not $notesParent) {
            return $false;
        }

        [System.Xml.XmlNode] $existingNote = $this.GetExistingXliffSyncNote($notesParent);
        if (-not $existingNote) {
            return $false;
        }

        [System.Xml.XmlNode] $whiteSpaceNode = $existingNote.PreviousSibling;
        $notesParent.RemoveChild($existingNote);
        $notesParent.RemoveChild($whiteSpaceNode);

        return $true;
    }

    hidden [System.Xml.XmlNode] GetExistingXliffSyncNote([System.Xml.XmlNode] $notesParent) {
        if (-not $notesParent) {
            return $null;
        }

        [string] $categoryAttributeName = 'from';
        switch ($this.Version()) {
            "1.2" {
                $categoryAttributeName = 'from';
                break;
            }
        }
        [string] $categoryAttributeValue = "XLIFF Sync";
        return $notesParent.ChildNodes | Where-Object { ($_.name -eq 'note') -and ($_.Attributes) -and ($_.GetAttribute($categoryAttributeName) -eq $categoryAttributeValue)} | Select-Object -First 1;
    }

    [System.Xml.XmlNode] CreateTargetNode([System.Xml.XmlNode] $parentUnit, [string] $translation, [XlfTranslationState] $newTranslationState) {
        [xml] $xmlDoc = $this.root.OwnerDocument;
        [System.Xml.XmlNode] $targetNode = $xmlDoc.CreateNode([System.Xml.XmlNodeType]::Element, "target", $this.root.NamespaceURI);
        $xmlDoc.ImportNode($targetNode, $true);

        if ($this.Version() -eq "1.2") {
            $this.UpdateStateAttributes($targetNode, $newTranslationState);
        }

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
                    $unit.ReplaceChild($targetNode, $targetChildNode);
                }
                elseif ($sourceChildNode) {
                    $unit.InsertAfter($targetNode, $sourceChildNode.NextSibling);

                    # Add the same whitespace after the target node.
                    $newWhiteSpaceNode = $this.root.OwnerDocument.ImportNode($sourceChildNode.PreviousSibling, $true);
                    $unit.InsertAfter($newWhiteSpaceNode, $targetNode);
                }
                else {
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

        if ((-not $noteNode) -or (-not $noteNode.InnerText)) {
            return $null;
        }

        return $noteNode.InnerText;
    }

    [string] GetUnitTranslationFromDeveloperNote([System.Xml.XmlNode] $unitNode) {
        [string] $developerNoteText = $this.GetUnitDeveloperNote($unitNode);
        if (-not $developerNoteText) {
            return $null;
        }

        [string[]] $translationEntries = $developerNoteText.Split($this.parseFromDeveloperNoteSeparator);
        [string] $translationText = $null;

        for ($i = 0; $i -lt $translationEntries.Length; $i++) {
            [string] $translationEntry = $translationEntries[$i];
            [int] $trlSepIdx = $translationEntry.IndexOf('=');
            if ($trlSepIdx -lt 0) {
                continue;
            }

            [string] $language = $translationEntry.Substring(0, $trlSepIdx);
            if ($language -eq $this.GetTargetLanguage()) {
                $translationText = $translationEntry.Substring($trlSepIdx + 1);
                break;
            }
        }

        return $translationText;
    }

    [System.Xml.XmlNode[]] TranslationUnitNodes() {
        if ($this.cachedTranslationUnitNodes) {
            return $this.cachedTranslationUnitNodes;
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
                break;
            }
        }

        $this.cachedTranslationUnitNodes = $transUnits;

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

    static [XlfDocument] CreateCopyFrom([XlfDocument] $baseXlfDoc, [string] $language) {
        [xml] $baseXmlDoc = $baseXlfDoc.root.OwnerDocument;
        [System.Xml.XmlNode] $xmlDecl = $baseXmlDoc.ChildNodes.Item(0);
        [System.Xml.XmlNode] $rootNode = $baseXmlDoc.ChildNodes.Item(1);

        [XlfDocument] $newXfDoc = [XlfDocument]::new();
        [xml] $newXmlDoc = [System.Xml.XmlDocument]::new();
        $newXmlDecl = $newXmlDoc.ImportNode($xmlDecl, $false);
        $newXmlDoc.AppendChild($newXmlDecl);

        $newRootNode = $newXmlDoc.ImportNode($rootNode, $true);
        $newXmlDoc.AppendChild($newRootNode);
        $newXfDoc.root = $newRootNode;

        switch ($baseXlfDoc.Version()) {
            "1.2" {
                $newFileNode = $newRootNode.ChildNodes.Item(0);
                $newFileNode.'target-language' = $language;
                break;
            }
            "2.0" {
                $newRootNode.'trgLang' = $language;
                break;
            }
        }

        return $newXfDoc;
    }

    static [XlfDocument] CreateEmptyDocFrom([XlfDocument] $baseXlfDoc, [string] $language) {
        [xml] $baseXmlDoc = $baseXlfDoc.root.OwnerDocument;
        [System.Xml.XmlNode] $xmlDecl = $baseXmlDoc.ChildNodes.Item(0);
        [System.Xml.XmlNode] $rootNode = $baseXmlDoc.ChildNodes.Item(1);

        [XlfDocument] $newXfDoc = [XlfDocument]::new();
        [xml] $newXmlDoc = [System.Xml.XmlDocument]::new();
        $newXmlDecl = $newXmlDoc.ImportNode($xmlDecl, $false);
        $newXmlDoc.AppendChild($newXmlDecl);

        $newRootNode = $newXmlDoc.ImportNode($rootNode, $false);
        $newXmlDoc.AppendChild($newRootNode);

        switch ($baseXlfDoc.Version()) {
            "1.2" { 
                $baseFileNode = $rootNode.ChildNodes.Item(0);
                $newFileNode = $newXmlDoc.ImportNode($baseFileNode, $false);
                $newFileNode.'target-language' = $language;
                $newRootNode.AppendChild($newFileNode);

                [System.Xml.XmlNode] $newBodyNode = $newXmlDoc.CreateNode([System.Xml.XmlNodeType]::Element, "body", $newRootNode.NamespaceURI);
                $newFileNode.AppendChild($newBodyNode);

                [System.Xml.XmlNode] $newGroupNode = $newXmlDoc.CreateNode([System.Xml.XmlNodeType]::Element, "group", $newRootNode.NamespaceURI);
                ([System.Xml.XmlElement] $newGroupNode).SetAttribute('id', 'body');
                $newBodyNode.AppendChild($newGroupNode);
                break;
            }
        }

        $newXfDoc.root = $newRootNode;
        return $newXfDoc;
    }

    hidden static [XlfDocument] LoadFromRootNode([System.Xml.XmlNode] $rootNode) {
        [XlfDocument] $doc = [XlfDocument]::new();
        $doc.root = $rootNode;
        
        if ($doc.Version() -ne "1.2") {
            throw "Currently this module only supports XLIFF 1.2 Files. Support for XLIFF 2.0 will be added later.";
        }

        return $doc;
    }

    static [XlfDocument] LoadFromXmlDocument([xml] $xmlDoc) {
        [System.Xml.XmlNode] $xmlDecl = $xmlDoc.ChildNodes.Item(0);
        $xmlDecl.'encoding' = $xmlDecl.'encoding'.ToUpper();

        [System.Xml.XmlNode] $rootNode = $xmlDoc.ChildNodes.Item(1);

        return [XlfDocument]::LoadFromRootNode($rootNode);
    }

    static [XlfDocument] LoadFromPath([string] $filePath) {
        [xml] $fileContentXml = (New-Object System.Xml.XmlDocument);
        $fileContentXml.Load($filePath);
        return [XlfDocument]::LoadFromXmlDocument($fileContentXml);
    }
}

enum XlfTranslationState {
    MissingTranslation = 0
    NeedsWorkTranslation = 1
    Translated = 10
}
