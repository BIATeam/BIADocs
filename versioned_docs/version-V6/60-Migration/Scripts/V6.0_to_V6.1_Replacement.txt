$Source = "C:\Sources\Projects\MyProject";
$SourceBackEnd = $Source + "\DotNet"
$SourceFrontEnd = $Source + "\Angular\src"
$currentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

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

function RemoveWebApiRepositoryFunctionsThirdParameter ($contenuFichier, $MatchBegin) {
  # Define the name of the base class
  $baseClassName = "WebApiRepository"

  # Define the regular expression patterns to match the function invocations
  $getAsyncPattern = 'this.GetAsync<([^,]+)>\s*\(([^,]+),\s*([^,]+),\s*([^)]+)(,\s*[^)]+)*\)'
  $deleteAsyncPattern = 'this.DeleteAsync<([^,]+)>\s*\(([^,]+),\s*([^,]+),\s*([^)]+)(,\s*[^)]+)*\)'
  $putAsyncPattern = 'this.PutAsync<([^,]+)>\s*\(([^,]+),\s*([^,]+),\s*([^)]+)(,\s*[^)]+)*\)'
  $putAsyncWithBodyPattern = 'this.PutAsync<([^,]+),([^,]+)>\s*\(([^,]+),\s*([^,]+),\s*([^)]+)(,\s*[^)]+)*\)'
  $postAsyncPattern = 'this.PostAsync<([^,]+)>\s*\(([^,]+),\s*([^,]+),\s*([^)]+)(,\s*[^)]+)*\)'
  $postAsyncWithBodyPattern = 'this.PostAsync<([^,]+),([^,]+)>\s*\(([^,]+),\s*([^,]+),\s*([^)]+)(,\s*[^)]+)*\)'
  $constructorPattern = 'public\s+(\w+)\s*\(([^)]*)\)\s*:\s*base\s*\(([^)]*)\)'
  $modifiedConstructorPattern = 'public\s+(\w+)\s*\(([^)]*)\)\s*:\s*base\s*\(([^)]*), new AuthenticationConfiguration\(\) { Mode = AuthenticationMode\.Token }\)'

  # Get all .cs files in the source directory
  $files = Get-ChildItem -Path $sourceDirectory -Recurse -Include *.cs

  foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw

    # Check if the file contains the base class
    if ($content -match "class\s+\w+\s*:\s*$baseClassName") {
      # Replace the PostAsync<TResult> function invocation
      $content = [regex]::Replace($content, $getAsyncPattern, 'this.GetAsync<$1>($2, $3$5)')

      # Replace the PostAsync<TResult> function invocation
      $content = [regex]::Replace($content, $deleteAsyncPattern, 'this.DeleteAsync<$1>($2, $3$5)')

      # Replace the PostAsync<TResult> function invocation
      $content = [regex]::Replace($content, $putAsyncPattern, 'this.PutAsync<$1>($2, $3$5)')

      # Replace the PostAsync<TResult, TBody> function invocation
      $content = [regex]::Replace($content, $putAsyncWithBodyPattern, 'this.PutAsync<$1,$2>($3, $4$6)')

      # Replace the PostAsync<TResult> function invocation
      $content = [regex]::Replace($content, $postAsyncPattern, 'this.PostAsync<$1>($2, $3$5)')

      # Replace the PostAsync<TResult, TBody> function invocation
      $content = [regex]::Replace($content, $postAsyncWithBodyPattern, 'this.PostAsync<$1,$2>($3, $4$6)')

      # Check if the class overrides the GetBearerTokenAsync method
      if ($content -match "override\s+async\s+Task<string>\s+GetBearerTokenAsync\s*\(" -and $content -notmatch $modifiedConstructorPattern) {
        # Replace the constructor to add the new parameter to the base() call
        $content = [regex]::Replace($content, $constructorPattern, 'public $1($2) : base($3, new AuthenticationConfiguration() { Mode = AuthenticationMode.Token })')
      }

      # Write the modified content back to the file
      Set-Content -Path $file.FullName -Value $content
      Write-Host "Modified file: $($file.FullName)"
    }
  }
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

function Get-GenericBlock {
  param(
    [string]$Text,
    [int]$StartIndex
  )

  $depth = 0
  $start = -1
  for ($i = $StartIndex; $i -lt $Text.Length; $i++) {
    $char = $Text[$i]
    if ($char -eq '<') {
      if ($depth -eq 0) {
        $start = $i + 1
      }
      $depth++
    }
    elseif ($char -eq '>') {
      $depth--
      if ($depth -eq 0 -and $start -ge 0) {
        return @{ Inner = $Text.Substring($start, $i - $start); EndIndex = $i }
      }
    }
  }

  return $null
}

function Split-GenericArguments {
  param(
    [string]$Text
  )

  $items = @()
  $depth = 0
  $segmentStart = 0
  for ($i = 0; $i -lt $Text.Length; $i++) {
    $char = $Text[$i]
    if ($char -eq '<') {
      $depth++
    }
    elseif ($char -eq '>') {
      $depth--
    }
    elseif ($char -eq ',' -and $depth -eq 0) {
      $items += $Text.Substring($segmentStart, $i - $segmentStart).Trim()
      $segmentStart = $i + 1
    }
  }

  $items += $Text.Substring($segmentStart).Trim()
  return $items
}

function Get-ClassBodySpan {
  param(
    [string]$Text,
    [int]$OpenBraceIndex
  )

  if ($OpenBraceIndex -lt 0 -or $OpenBraceIndex -ge $Text.Length) {
    return $null
  }

  $depth = 0
  for ($i = $OpenBraceIndex; $i -lt $Text.Length; $i++) {
    $char = $Text[$i]
    if ($char -eq '{') {
      $depth++
    }
    elseif ($char -eq '}') {
      $depth--
    }

    if ($depth -eq 0) {
      return @{ BodyStart = $OpenBraceIndex + 1; BodyEnd = $i }
    }
  }

  return $null
}

function Get-BlockSpan {
  param(
    [string]$Text,
    [int]$OpenBraceIndex
  )

  if ($OpenBraceIndex -lt 0 -or $OpenBraceIndex -ge $Text.Length) {
    return $null
  }

  $depth = 0
  for ($i = $OpenBraceIndex; $i -lt $Text.Length; $i++) {
    $char = $Text[$i]
    if ($char -eq '{') {
      $depth++
    }
    elseif ($char -eq '}') {
      $depth--
    }

    if ($depth -eq 0) {
      return @{ BodyStart = $OpenBraceIndex + 1; BodyEnd = $i }
    }
  }

  return $null
}

function Get-FileText([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Fichier introuvable: $path" }
  return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Set-FileText([string]$path, [string]$text, [switch]$WhatIfOnly) {
  if ($WhatIfOnly) { Write-Host "WHATIF: Écriture ignorée -> $path" -ForegroundColor Yellow; return }
  [System.IO.File]::WriteAllText($path, $text, [System.Text.Encoding]::UTF8)
}

# FRONT END
# BEGIN - Add row to onFocusout table function
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp '\(focusout\)="onFocusout\(\)"' -NewRegexp '#currentRow (focusout)="onFocusout(currentRow)"' -Include "*.html"
# END - Add row to onFocusout table function

# BEGIN - Add BiaCalcTableCellComponent to standalone imports of components using bia-calc-table template
Write-Host "Adding BiaCalcTableCellComponent to components using bia-calc-table template..."

$componentToAdd = 'BiaCalcTableCellComponent'
$importPackage = '@bia-team/bia-ng/shared'
$escapedPackage = [regex]::Escape($importPackage)

$allTsFiles = Get-ChildItem -Path $SourceFrontEnd -Recurse -Filter "*.ts" | Where-Object {
  $fullPath = [System.IO.Path]::GetFullPath($_.FullName)
  -not ($ExcludeDir | Where-Object { $fullPath -match "[\\/]$([regex]::Escape($_))([\\/]|`$)" })
}

foreach ($file in $allTsFiles) {
  $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

  # Process only files whose templateUrl ends with bia-calc-table/bia-calc-table.component.html
  if ($content -notmatch "bia-calc-table/bia-calc-table\.component\.html") { continue }

  # Skip if BiaCalcTableCellComponent is already present
  if ($content -match [regex]::Escape($componentToAdd)) { continue }

  $modified = $false

  # 1. Add import statement at the top of the file
  $importLine = "import { $componentToAdd } from '$importPackage';`n"

  $importMatches = [regex]::Matches($content, "import\s+.*?;")

  if ($importMatches.Count -gt 0) {
    $lastImport = $importMatches[$importMatches.Count - 1]
    $insertPos  = $lastImport.Index + $lastImport.Length
    $content    = $content.Insert($insertPos, "`r`n$importLine")
    $modified   = $true
  }

  # 2. Add BiaCalcTableCellComponent to the standalone imports array in @Component
  if ($content -match 'imports\s*:\s*\[') {
    $content = $content -replace '(imports\s*:\s*\[)', "`$1$componentToAdd, "
    $modified = $true
  }

  if ($modified) {
    Write-Host "     => $($file.FullName)"
    [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
  }
}
# END - Add BiaCalcTableCellComponent to standalone imports of components using bia-calc-table template

# BACK END
# BEGIN - BiaClaimsPrincipal.RoleIds -> BiaConstants.Claims.RoleIds
ReplaceInProject ` -Source $SourceBackEnd -OldRegexp 'BiaClaimsPrincipal\.RoleIds' -NewRegexp 'BiaConstants.Claims.RoleIds' -Include "*.cs"
# END - BiaClaimsPrincipal.RoleIds -> BiaConstants.Claims.RoleIds

# FRONT END CLEAN
Set-Location $SourceFrontEnd
npm run clean

# # BACK END RESTORE
Set-Location $SourceBackEnd
dotnet restore --no-cache

Write-Host "Finish"
pause
