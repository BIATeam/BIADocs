$Source = "C:\sources\Project";
$SourceBackEnd = $Source + "\DotNet"
$SourceFrontEnd = $Source + "\Angular\src"

$ExcludeDir = ('dist', 'node_modules', 'docs', 'scss', '.git', '.vscode', '.angular', '.dart_tool', 'bia-shared', 'bia-features', 'bia-domains', 'bia-core')

function ReplaceInProject {
  param (
    [string]$Source,
    [string]$OldRegexp,
    [string]$NewRegexp,
    [string]$Include

  )
  Write-Host "ReplaceInProject $OldRegexp by $NewRegexp";
  #Write-Host $Source;
  #Write-Host $OldRegexp;
  #Write-Host $NewRegexp;
  #Write-Host $Filter;
  ReplaceInProjectRec -Source $Source -OldRegexp $OldRegexp -NewRegexp $NewRegexp -Include $Include
}

function ReplaceInProjectRec {
  param (
    [string]$Source,
    [string]$OldRegexp,
    [string]$NewRegexp,
    [string]$Include
  )
  foreach ($childDirectory in Get-ChildItem -Force -Path $Source -Directory -Exclude $ExcludeDir) {
    ReplaceInProjectRec -Source $childDirectory.FullName -OldRegexp $OldRegexp -NewRegexp $NewRegexp -Include $Include
  }
	
  Get-ChildItem -LiteralPath $Source -File -Filter $Include | ForEach-Object {
    $oldContent = [System.IO.File]::ReadAllText($_.FullName);
    $found = $oldContent | select-string -Pattern $OldRegexp
    if ($found.Matches) {
      $newContent = $oldContent -Replace $OldRegexp, $NewRegexp 
      $match = $newContent -match '#capitalize#([a-z])'
      if ($match) {
        [string]$lower = $Matches[1]
        [string]$upper = $lower.ToUpper()
        [string]$newContent = $newContent -Replace "#capitalize#([a-z])", $upper 
      }
      if ($oldContent -cne $newContent) {
        Write-Host "     => " $_.FullName
        [System.IO.File]::WriteAllText($_.FullName, $newContent)
      }
    }
  }
}

function GetPresentationApiFolder {
  param (
    [string]$SourceFolder
  )
  $folderPath = Get-ChildItem -Path $SourceFolder -Recurse | Where-Object { $_.PSIsContainer -and $_.FullName.EndsWith("Presentation.Api") -and -not $_.FullName.StartsWith("BIA.") }
  if ($null -ne $folderPath -and $folderPath.Count -gt 0) {
    $folderPath = $folderPath[0].FullName.ToString()
    return $folderPath
  }
  else {
    return $null
  }
}

function InsertFunctionInClass() {
  param (
    [string]$Source,
    [string]$MatchBegin,
    [string]$FunctionBody,
    [string]$ReplaceByExpr,
    [string]$NoMatchCondition,
    [string]$MatchCondition,
    [string[]]$ReplaceSeqences,
    [string[]]$ReplaceByMatch1
  )
  foreach ($childDirectory in Get-ChildItem -Force -Path $Source -Directory -Exclude $ExcludeDir) {
    InsertFunctionInClassRec -Source $childDirectory.FullName -MatchBegin $MatchBegin -NoMatchCondition $NoMatchCondition -FunctionBody $FunctionBody -ReplaceByExpr $ReplaceByExpr -MatchCondition $MatchCondition -ReplaceSeqences $ReplaceSeqences -ReplaceByMatch1 $ReplaceByMatch1
  }
}

function InsertFunctionInClassRec() {
  param (
    [string]$Source,
    [string]$MatchBegin,
    [string]$FunctionBody,
    [string]$ReplaceByExpr,
    [string]$NoMatchCondition,
    [string]$MatchCondition,
    [string[]]$ReplaceSeqences,
    [string[]]$ReplaceByMatch1
  )
  foreach ($childDirectory in Get-ChildItem -Force -Path $Source -Directory -Exclude $ExcludeDir) {
    InsertFunctionInClassRec -Source $childDirectory.FullName -MatchBegin $MatchBegin -NoMatchCondition $NoMatchCondition -FunctionBody $FunctionBody -ReplaceByExpr $ReplaceByExpr -MatchCondition $MatchCondition -ReplaceSeqences $ReplaceSeqences -ReplaceByMatch1 $ReplaceByMatch1
  }

  $fichiersTypeScript = Get-ChildItem -Path $Source -Filter "*.ts"
  foreach ($fichier in $fichiersTypeScript) {
    $contenuFichier = Get-Content -Path $fichier.FullName -Raw

    # Vérifiez si la classe hérite de CrudItemService
    if ($contenuFichier -match $MatchBegin) {
      $nomClasse = $matches[1]
      if ($MatchCondition -eq "" -or $contenuFichier -match $MatchCondition) {
        # Vérifiez si les fonctions ne sont pas déjà présentes
        if ($contenuFichier -notmatch $NoMatchCondition) {
          # Utilisez une fonction pour trouver la position de la fermeture de la classe
          $positionFermetureClasse = TrouverPositionFermetureClasse $contenuFichier $MatchBegin

          $FunctionBodyRep = $FunctionBody;
          For ($i = 0; $i -lt $ReplaceSeqences.Length; $i++) {
            $ReplaceByMatch = $ReplaceByMatch1[$i]
            if ($contenuFichier -match $ReplaceByMatch) {
              $Match = $matches[1]
              Write-Host "Replacement found : $ReplaceByMatch  : $Match" 
              $FunctionBodyRep = $FunctionBodyRep.Replace($ReplaceSeqences[$i], $Match)
            }
            else {
              Write-Host "Replacement not found : $ReplaceByMatch" 
            }
          }
          # Insérez les fonctions avant la fermeture de la classe
          $contenuFichier = $contenuFichier.Insert($positionFermetureClasse, $FunctionBodyRep + " ")

          # Écrivez les modifications dans le fichier
          $contenuFichier | Set-Content -Path $fichier.FullName -NoNewline
          Write-Host "Fonctions ajoutées à la classe ou namespace $nomClasse dans le fichier $($fichier.FullName)"
        }
      }
    }
  }
}

# Fonction pour trouver la position de la fermeture de la classe
function TrouverPositionFermetureClasse ($contenuFichier, $MatchBegin) {
  $nombreAccoladesOuvrantes = 0
  $nombreAccoladesFermantes = 0
  $index = 0
  $trouveClasse = $false
  $positionFermeture = 0

  # Parcourez le contenu du fichier ligne par ligne
  $contenuFichier -split " " | ForEach-Object {

    # Vérifiez si la ligne contient la déclaration de la classe
    if ($trouveClasse -eq $false -and $_ -match $MatchBegin) {
      $trouveClasse = $true
    }

    # Si la classe a été trouvée, mettez à jour les compteurs d'accolades
    if ($trouveClasse) {
      $nombreAccoladesOuvrantes += ($_ -split "{").Count - 1
      $nombreAccoladesFermantes += ($_ -split "}").Count - 1
    }

    # Si le nombre d'accolades fermantes est égal au nombre d'accolades ouvrantes
    # pour la classe en cours, retournez l'index actuel
    if ($trouveClasse -and $nombreAccoladesFermantes -gt 0 -and $nombreAccoladesFermantes -eq $nombreAccoladesOuvrantes -and $positionFermeture -eq 0) {
      $positionFermeture = $index
    }
    $index += $_.Length + 1
  }

  # Retournez la dernière position si la classe n'a pas de fermeture explicite
  return $positionFermeture
}

function Invoke-MigrateBiaFieldConfig {
    param(
        [string]$SourceFrontEndPath
    )

    $PKG_PATH = "@bia-team/bia-ng/models/enum"

    function Add-EnumImport {
        param([string]$content, [string]$enumName)

        $importSection = [regex]::Match($content, '(?s)^(import\s[\s\S]*?;[\s\n]*)+')
        if ($importSection.Success -and $importSection.Value.Contains($enumName)) {
            return $content
        }

        $escapedPkg = [regex]::Escape($PKG_PATH)
        $rx = [regex]::new("(?s)(import\s*\{)([^}]*?)(\}\s*from\s*['""]" + $escapedPkg + "['""][\s]*;)")
        $m = $rx.Match($content)

        if ($m.Success) {
            $open    = $m.Groups[1].Value
            $names   = $m.Groups[2].Value
            $close   = $m.Groups[3].Value
            $trimmed = $names.TrimEnd()
            if ($trimmed -notmatch ',\s*$') { $trimmed = $trimmed + ',' }
            $replacement = $open + $trimmed + "`n  " + $enumName + "`n" + $close
            return $content.Substring(0, $m.Index) + $replacement + $content.Substring($m.Index + $m.Length)
        }

        $allImports = [regex]::Matches($content, '(?m)^import\s[\s\S]*?;')
        if ($allImports.Count -gt 0) {
            $last     = $allImports[$allImports.Count - 1]
            $insertAt = $last.Index + $last.Length
            $newLine  = "`nimport { " + $enumName + " } from '" + $PKG_PATH + "';"
            return $content.Substring(0, $insertAt) + $newLine + $content.Substring($insertAt)
        }

        return "import { " + $enumName + " } from '" + $PKG_PATH + "';`n" + $content
    }

    $RULES = @(
        # ── TableColumnVisibility ────────────────────────────────────────────
        @{ P = '(?<!\w)isVisibleInTable\s*:\s*false(?!\w)'
           R = 'tableColumnVisibility: TableColumnVisibility.Hidden'
           I = @('TableColumnVisibility') },

        @{ P = '(?<!\w)isVisibleInTable\s*:\s*true\s*,?[ \t]*\r?\n?'
           R = ''
           I = @() },

        @{ P = '(?<!\w)isHideByDefault\s*:\s*true(?!\w)'
           R = 'tableColumnVisibility: TableColumnVisibility.AvailableButHidden'
           I = @('TableColumnVisibility') },

        @{ P = '(?<!\w)isHideByDefault\s*:\s*false\s*,?[ \t]*\r?\n?'
           R = ''
           I = @() },

        # ── FieldEditMode ────────────────────────────────────────────────────
        @{ P = '(?<!\w)isEditable\s*:\s*false\s*,[ \t]*\r?\n?[ \t]*isOnlyInitializable\s*:\s*true(?!\w)'
           R = 'fieldEditMode: FieldEditMode.InitializableOnly'
           I = @('FieldEditMode') },

        @{ P = '(?<!\w)isOnlyInitializable\s*:\s*true\s*,[ \t]*\r?\n?[ \t]*isEditable\s*:\s*false(?!\w)'
           R = 'fieldEditMode: FieldEditMode.InitializableOnly'
           I = @('FieldEditMode') },

        @{ P = '(?<!\w)isEditable\s*:\s*false\s*,[ \t]*\r?\n?[ \t]*isOnlyUpdatable\s*:\s*true(?!\w)'
           R = 'fieldEditMode: FieldEditMode.UpdatableOnly'
           I = @('FieldEditMode') },

        @{ P = '(?<!\w)isOnlyUpdatable\s*:\s*true\s*,[ \t]*\r?\n?[ \t]*isEditable\s*:\s*false(?!\w)'
           R = 'fieldEditMode: FieldEditMode.UpdatableOnly'
           I = @('FieldEditMode') },

        @{ P = '(?<!\w)isOnlyInitializable\s*:\s*true(?!\w)'
           R = 'fieldEditMode: FieldEditMode.InitializableOnly'
           I = @('FieldEditMode') },

        @{ P = '(?<!\w)isOnlyUpdatable\s*:\s*true(?!\w)'
           R = 'fieldEditMode: FieldEditMode.UpdatableOnly'
           I = @('FieldEditMode') },

        @{ P = '(?<!\w)isEditable\s*:\s*false(?!\w)'
           R = 'fieldEditMode: FieldEditMode.ReadOnly'
           I = @('FieldEditMode') },

        @{ P = '(?<!\w)isEditable\s*:\s*true\s*,?[ \t]*\r?\n?'
           R = ''
           I = @() },

        @{ P = '(?<!\w)isOnlyInitializable\s*:\s*false\s*,?[ \t]*\r?\n?'
           R = ''
           I = @() },

        @{ P = '(?<!\w)isOnlyUpdatable\s*:\s*false\s*,?[ \t]*\r?\n?'
           R = ''
           I = @() }
    )

    function Apply-FieldRules {
        param([string]$block, [ref]$needed)
        foreach ($rule in $RULES) {
            if ([regex]::IsMatch($block, $rule.P)) {
                $block = [regex]::Replace($block, $rule.P, $rule.R)
                foreach ($imp in $rule.I) { [void]$needed.Value.Add($imp) }
            }
        }
        return $block
    }

    function Apply-RulesInsideBiaFieldConfigBlocks {
        param([string]$content)

        $needed = [System.Collections.Generic.HashSet[string]]::new()

        $blockStartRx = [regex]::new(
            '(?s)Object\.assign\(\s*new\s+BiaFieldConfig\s*(<[^>]*>)?\s*\([^)]*\)\s*,\s*\{',
            [System.Text.RegularExpressions.RegexOptions]::None
        )

        $result    = [System.Text.StringBuilder]::new($content.Length)
        $searchPos = 0
        $matches   = $blockStartRx.Matches($content)

        foreach ($m in $matches) {
            [void]$result.Append($content.Substring($searchPos, $m.Index - $searchPos))
            [void]$result.Append($m.Value)

            $pos   = $m.Index + $m.Length
            $depth = 1

            while ($pos -lt $content.Length -and $depth -gt 0) {
                $ch = $content[$pos]
                if ($ch -eq '{') { $depth++ }
                elseif ($ch -eq '}') { $depth-- }
                $pos++
            }

            $innerStart = $m.Index + $m.Length
            $innerEnd   = $pos - 1
            $inner      = $content.Substring($innerStart, $innerEnd - $innerStart)
            $inner      = Apply-FieldRules -block $inner -needed ([ref]$needed)

            [void]$result.Append($inner)
            [void]$result.Append('}')
            $searchPos = $pos
        }

        [void]$result.Append($content.Substring($searchPos))

        return [PSCustomObject]@{
            Content = $result.ToString()
            Needed  = $needed
        }
    }

    $oldFields   = @('isVisibleInTable', 'isHideByDefault', 'isEditable', 'isOnlyInitializable', 'isOnlyUpdatable')
    $filesScanned  = 0
    $filesModified = 0

    $tsFiles = Get-ChildItem -Path $SourceFrontEndPath -Recurse -Filter '*.ts' |
        Where-Object { $_.FullName -notmatch '[\\/]node_modules[\\/]' }

    foreach ($file in $tsFiles) {
        $filesScanned++
        $original = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        $hasOldField = $false
        foreach ($f in $oldFields) {
            if ($original.Contains($f)) { $hasOldField = $true; break }
        }
        if (-not $hasOldField -or -not $original.Contains('BiaFieldConfig')) { continue }

        $result  = Apply-RulesInsideBiaFieldConfigBlocks -content $original
        $content = $result.Content
        $needed  = $result.Needed

        foreach ($imp in $needed) {
            $content = Add-EnumImport -content $content -enumName $imp
        }

        if ($content -ne $original) {
            [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
            $filesModified++
            Write-Host "     => $($file.FullName)"
        }
    }

    Write-Host "Invoke-MigrateBiaFieldConfig done. Scanned: $filesScanned, Modified: $filesModified"
}

function Invoke-ReplacementsInFiles {
  param(
      [Parameter(Mandatory)]
      [string] $RootPath,
      [Parameter(Mandatory)]
      [hashtable[]] $Replacements,   # @{ Pattern = '<regex>'; Replacement = '<string>'; Requirement = '<string>' }
      [Parameter(Mandatory)]
      [string[]] $Extensions
  )
  $excludeFullPaths =
      $ExcludeDir | ForEach-Object {
          $p = if ([System.IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path -Path $RootPath -ChildPath $_ }
          [System.IO.Path]::GetFullPath($p)
      }

  $i = 0
  $allFiles = Get-ChildItem -Path $RootPath -Recurse -File -Include $Extensions 
  
  $allTotal = $allFiles.Count

  $files = $allFiles |
  Where-Object {
      $i++
      Write-Progress -Activity "Filtering files to process..." -Status "Item $i of $allTotal" -PercentComplete (($i / $allTotal) * 100)
      $full = [System.IO.Path]::GetFullPath($_.FullName)
      $isExcluded = $false
      foreach ($ex in $excludeFullPaths) {
          if ($full.StartsWith($ex.TrimEnd('\','/'), [System.StringComparison]::OrdinalIgnoreCase)) {
              $isExcluded = $true
              break
          }
      }
      -not $isExcluded
  } 
  
  $total = $files.Count

  $j = 0
  $files | ForEach-Object {
      $j++
      Write-Progress -Activity "Processing files..." -Status "Item $j of $total" -PercentComplete (($j / $total) * 100)
      $content         = Get-Content -LiteralPath $_.FullName -Raw
      $fileModified    = $false
      $fileReplacements = @()
      $contentCurrent  = $content

      foreach ($rule in $Replacements) {
        if($rule.Requirement -and -not ($contentCurrent -cmatch $rule.Requirement)) {
          continue;
        }

        $newContent = $contentCurrent -creplace $rule.Pattern, $rule.Replacement
        if ($newContent -cne $contentCurrent) {
            $contentCurrent  = $newContent
            $fileModified    = $true
            $fileReplacements += "  => replaced `"$($rule.Pattern)`" by `"$($rule.Replacement)`" ($occ)"
        }
    }

      if ($fileModified) {
          Write-Host $_.FullName -ForegroundColor Green
          $fileReplacements | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
          [System.IO.File]::WriteAllText($_.FullName, $contentCurrent, [System.Text.Encoding]::UTF8)
      }
  }
}

function Invoke-RenameBiaFieldConfigIsVisible {
    param(
        [string]$SourceFrontEndPath
    )

    function Find-MatchingBrace {
        param([string]$content, [int]$startPos)
        $depth = 1
        $pos   = $startPos
        while ($pos -lt $content.Length -and $depth -gt 0) {
            $ch = $content[$pos]
            if ($ch -eq '{') { $depth++ }
            elseif ($ch -eq '}') { $depth-- }
            $pos++
        }
        return $pos
    }

    function Process-BiaFieldConfigFile {
        param([string]$content, [string]$extension)

        $modified = $false

        if ($extension -eq '.html') {
            $newContent = [regex]::Replace($content, '(?<!\w)isVisible(?!\w)', 'isVisibleInForm')
            if ($newContent -ne $content) {
                return [PSCustomObject]@{ Content = $newContent; Modified = $true }
            }
            return [PSCustomObject]@{ Content = $content; Modified = $false }
        }

        $blockStartRx = [regex]::new(
            '(?s)Object\.assign\(\s*new\s+BiaFieldConfig\s*(<[^>]*>)?\s*\([^)]*\)\s*,\s*\{'
        )

        $result    = [System.Text.StringBuilder]::new($content.Length)
        $searchPos = 0
        $matches   = $blockStartRx.Matches($content)

        foreach ($m in $matches) {
            [void]$result.Append($content.Substring($searchPos, $m.Index - $searchPos))
            [void]$result.Append($m.Value)

            $innerStart = $m.Index + $m.Length
            $afterClose = Find-MatchingBrace -content $content -startPos $innerStart
            $innerEnd   = $afterClose - 1

            $inner    = $content.Substring($innerStart, $innerEnd - $innerStart)
            $newInner = [regex]::Replace($inner, '(?<!\w)isVisible\s*:', 'isVisibleInForm:')

            if ($newInner -ne $inner) { $modified = $true }

            [void]$result.Append($newInner)
            [void]$result.Append('}')
            $searchPos = $afterClose
        }

        [void]$result.Append($content.Substring($searchPos))

        return [PSCustomObject]@{ Content = $result.ToString(); Modified = $modified }
    }

    $filesScanned  = 0
    $filesModified = 0

    $files = Get-ChildItem -Path $SourceFrontEndPath -Recurse -Include '*.ts', '*.html' |
        Where-Object { $_.FullName -notmatch '[\\/]node_modules[\\/]' }

    foreach ($file in $files) {
        $filesScanned++
        $original = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        if (-not $original.Contains('isVisible')) { continue }

        $result = Process-BiaFieldConfigFile -content $original -extension $file.Extension

        if ($result.Modified) {
            [System.IO.File]::WriteAllText($file.FullName, $result.Content, [System.Text.Encoding]::UTF8)
            $filesModified++
            Write-Host "     => $($file.FullName)"
        }
    }

    Write-Host "Invoke-RenameBiaFieldConfigIsVisible done. Scanned: $filesScanned, Modified: $filesModified"
}

function Invoke-AddContextMenuImport {
    param(
        [string]$SourceFrontEndPath
    )

    $templatePatterns = @('bia-table\.component\.html', 'bia-calc-table\.component\.html')

    $importStatement = "import { ContextMenu } from 'primeng/contextmenu';"

    $files = Get-ChildItem -Path $SourceFrontEndPath -Recurse -Filter '*.component.ts' |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' }

    $patched = 0

    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8

        # Check if this file uses one of the target templates
        $usesTemplate = $false
        foreach ($pattern in $templatePatterns) {
            if ($content -match $pattern) {
                $usesTemplate = $true
                break
            }
        }
        if (-not $usesTemplate) { continue }

        Write-Host "Processing: $($file.Name)"
        $changed = $false

        # --- 1. Add the import statement if not already present ---
        if ($content -notmatch "from 'primeng/contextmenu'") {
            $lines = $content -split "`n"
            $lastPrimengIdx = -1
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "^import .* from 'primeng/") {
                    $lastPrimengIdx = $i
                }
            }

            if ($lastPrimengIdx -ge 0) {
                $before = $lines[0..$lastPrimengIdx]
                $after = $lines[($lastPrimengIdx + 1)..($lines.Count - 1)]
                $newLines = $before + $importStatement + $after
                $content = $newLines -join "`n"
                $changed = $true
                Write-Host "  [+] Added import statement"
            }
            else {
                Write-Warning "  Could not find a primeng import line in: $($file.Name)"
            }
        }
        else {
            Write-Host "  [=] Import already present"
        }

        # --- 2. Add ContextMenu to the imports: [...] array if not already present ---
        # Extract only the imports array content to check (avoids matching the import statement)
        $arrayContent = ''
        $inArr = $false
        foreach ($ln in ($content -split "`n")) {
            if ($ln -match '^\s+imports:\s*\[') { $inArr = $true }
            if ($inArr) { $arrayContent += $ln + "`n" }
            if ($inArr -and $ln -match '^\s+\],') { $inArr = $false; break }
        }
        if ($arrayContent -notmatch '\bContextMenu\b') {
            # Find the @Component imports array and append ContextMenu before the closing ]
            # The array ends with a line that is just "  ]," (2-space indent)
            $lines = $content -split "`n"
            $inImportsArray = $false
            $insertIdx = -1

            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^\s+imports:\s*\[') {
                    $inImportsArray = $true
                }
                if ($inImportsArray -and $lines[$i] -match '^\s+\],') {
                    $insertIdx = $i
                    $inImportsArray = $false
                    break
                }
            }

            if ($insertIdx -ge 0) {
                # Determine indentation from surrounding entries
                $indent = '    '
                if ($insertIdx -gt 0 -and $lines[$insertIdx - 1] -match '^(\s+)\S') {
                    $indent = $Matches[1]
                }
                $newEntry = "${indent}ContextMenu,"
                $before = $lines[0..($insertIdx - 1)]
                $after = $lines[$insertIdx..($lines.Count - 1)]
                $newLines = $before + $newEntry + $after
                $content = $newLines -join "`n"
                $changed = $true
                Write-Host "  [+] Added ContextMenu to imports array"
            }
            else {
                Write-Warning "  Could not find imports array closing ] in: $($file.Name)"
            }
        }
        else {
            Write-Host "  [=] ContextMenu already in imports array"
        }

        if ($changed) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
            Write-Host "  => PATCHED"
            $patched++
        }
        else {
            Write-Host "  => No changes needed"
        }
    }

    Write-Host ""
    Write-Host "Invoke-AddContextMenuImport done. $patched file(s) patched."
}

# FRONT END

# BEGIN - Migrate BiaFieldConfig to TableColumnVisibility and FieldEditMode enums
Invoke-MigrateBiaFieldConfig -SourceFrontEndPath $SourceFrontEnd
# END - Migrate BiaFieldConfig to TableColumnVisibility and FieldEditMode enums

# BEGIN - Rename isVisible to isVisibleInForm in BiaFieldConfig
Invoke-RenameBiaFieldConfigIsVisible -SourceFrontEndPath $SourceFrontEnd
# END - Rename isVisible to isVisibleInForm in BiaFieldConfig

# BEGIN - Rename isHideByDefault to isHiddenByDefault
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "\bisHideByDefault\b" -NewRegexp 'isHiddenByDefault' -Include "*.ts"
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "\bisHideByDefault\b" -NewRegexp 'isHiddenByDefault' -Include "*.html"
# END - Rename isHideByDefault to isHiddenByDefault

# BEGIN - Add ContextMenu import to components using bia-table or bia-calc-table
Invoke-AddContextMenuImport -SourceFrontEndPath $SourceFrontEnd
# END - Add ContextMenu import to components using bia-table or bia-calc-table

# BACK END

# BEGIN - Use TeamCrudAppServiceBase instead of CrudAppServiceBase for teams
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "\bCrudAppServiceBase(<[^>]*PagingFilterFormatDto\s*<\s*TeamAdvancedFilterDto\s*>[^>]*>)" -NewRegexp 'TeamCrudAppServiceBase$1' -Include "*.cs"
# END - Use TeamCrudAppServiceBase instead of CrudAppServiceBase for teams

# FRONT END CLEAN
Set-Location $SourceFrontEnd
npm run clean

# BACK END RESTORE
Set-Location $SourceBackEnd
dotnet restore --no-cache

Write-Host "Finish"
pause
