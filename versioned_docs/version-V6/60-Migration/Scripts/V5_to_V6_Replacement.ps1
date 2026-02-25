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

function Invoke-CrudAppServiceOverridesMigration {
  param(
    [Parameter(Mandatory)]
    [string] $RootPath
  )

  $methodNames = @('GetRangeAsync', 'GetAllAsync', 'GetCsvAsync', 'GetAsync', 'AddAsync', 'UpdateAsync', 'RemoveAsync', 'SaveSafeAsync', 'SaveAsync', 'UpdateFixedAsync')
  $classRegex = [regex]::new('(?s)class\s+(?<name>[A-Za-z_][A-Za-z0-9_]*)[^{]*:\s*[^{]*?\b(?<base>(?:[\w\.]+\.)?(?:CrudAppServiceBase|CrudAppServiceListAndItemBase))\s*<')
  $excludeFullPaths =
      $ExcludeDir | ForEach-Object {
          $p = if ([System.IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path -Path $RootPath -ChildPath $_ }
          [System.IO.Path]::GetFullPath($p)
      }

  Get-ChildItem -Path $RootPath -Recurse -File -Include '*.cs' |
  Where-Object {
      $full = [System.IO.Path]::GetFullPath($_.FullName)
      $isExcluded = $false
      foreach ($ex in $excludeFullPaths) {
          if ($full.StartsWith($ex.TrimEnd('\','/'), [System.StringComparison]::OrdinalIgnoreCase)) {
              $isExcluded = $true
              break
          }
      }
      -not $isExcluded
  } | ForEach-Object {
      $content = Get-Content -LiteralPath $_.FullName -Raw
      $updated = $content
      $pos = 0
      $fileChanged = $false

      while ($true) {
          $classMatch = $classRegex.Match($updated, $pos)
          if (-not $classMatch.Success) {
            break
          }

          $baseName = $classMatch.Groups['base'].Value
          $crudIndex = $updated.IndexOf($baseName, $classMatch.Index, [System.StringComparison]::Ordinal)
          if ($crudIndex -lt 0) {
            $pos = $classMatch.Index + $classMatch.Length
            continue
          }

          $genericStart = $updated.IndexOf('<', $crudIndex)
          if ($genericStart -lt 0) {
            $pos = $classMatch.Index + $classMatch.Length
            continue
          }

          $genericBlock = Get-GenericBlock -Text $updated -StartIndex $genericStart
          if ($null -eq $genericBlock) {
            $pos = $classMatch.Index + $classMatch.Length
            continue
          }

          $genericArgs = Split-GenericArguments -Text $genericBlock.Inner
          if ($genericArgs.Count -lt 4) {
            $pos = $classMatch.Index + $classMatch.Length
            continue
          }

          $dtoIndex = 0
          $filterIndex = 3
          if ($baseName -like '*CrudAppServiceListAndItemBase*') {
            $dtoIndex = 1
            $filterIndex = 4
          }

          if ($genericArgs.Count -le [Math]::Max($dtoIndex, $filterIndex)) {
            $pos = $classMatch.Index + $classMatch.Length
            continue
          }

          $dtoType = $genericArgs[$dtoIndex].Trim()
          $filterType = $genericArgs[$filterIndex].Trim()
          $mapperType = $genericArgs[$genericArgs.Count - 1].Trim()

          $openBraceIndex = $updated.IndexOf('{', $genericBlock.EndIndex)
          $span = Get-ClassBodySpan -Text $updated -OpenBraceIndex $openBraceIndex
          if ($null -eq $span) {
            $pos = $classMatch.Index + $classMatch.Length
            continue
          }

          $body = $updated.Substring($span.BodyStart, $span.BodyEnd - $span.BodyStart)
          $newBody = $body
          $bodyChanged = $false

          foreach ($methodName in $methodNames) {
              $methodRegex = [regex]::new("(?s)protected\s+override\s+[^{;]*?\b$([regex]::Escape($methodName))\b\s*<[^>]*>\s*\([^)]*\)[^{;]*\{")
              $searchPos = 0

              while ($true) {
                  $methodMatch = $methodRegex.Match($newBody, $searchPos)
                  if (-not $methodMatch.Success) {
                    break
                  }

                  $methodStart = $methodMatch.Index
                  $braceIndex = $newBody.IndexOf('{', $methodStart)
                  if ($braceIndex -lt 0) {
                    $searchPos = $methodMatch.Index + $methodMatch.Length
                    continue
                  }

                  $methodSpan = Get-BlockSpan -Text $newBody -OpenBraceIndex $braceIndex
                  if ($null -eq $methodSpan) {
                    $searchPos = $methodMatch.Index + $methodMatch.Length
                    continue
                  }

                  $methodText = $newBody.Substring($methodStart, $methodSpan.BodyEnd - $methodStart + 1)
                  $methodUpdated = $methodText
                  $methodUpdated = ([regex]::new('(?s)\bprotected\s+override\b')).Replace($methodUpdated, 'public override', 1)
                  $methodUpdated = [regex]::Replace($methodUpdated, "(\b$([regex]::Escape($methodName))\b)\s*<[^>]*>", '${1}')
                  $methodUpdated = [regex]::Replace($methodUpdated, '(?m)^\s*where\s+(?:TOtherDto|TOtherMapper|TOtherFilterDto)\s*:[^\r\n{;]+', '')
                  $methodUpdated = [regex]::Replace($methodUpdated, '\swhere\s+(?:TOtherDto|TOtherMapper|TOtherFilterDto)\s*:[^\r\n{;]+', '')
                  $methodUpdated = [regex]::Replace($methodUpdated, '\bTOtherDto\b', { param($m) $dtoType })
                  $methodUpdated = [regex]::Replace($methodUpdated, '\bTOtherMapper\b', { param($m) $mapperType })
                  $methodUpdated = [regex]::Replace($methodUpdated, '\bTOtherFilterDto\b', { param($m) $filterType })

                  if ($methodUpdated -cne $methodText) {
                      $newBody = $newBody.Substring(0, $methodStart) + $methodUpdated + $newBody.Substring($methodSpan.BodyEnd + 1)
                      $bodyChanged = $true
                      $searchPos = $methodStart + $methodUpdated.Length
                  }
                  else {
                      $searchPos = $methodMatch.Index + $methodMatch.Length
                  }
              }
          }

          if ($bodyChanged) {
              $updated = $updated.Substring(0, $span.BodyStart) + $newBody + $updated.Substring($span.BodyEnd)
              $fileChanged = $true
              Write-Host ("  => updated protected overrides of OperationalDomainServiceBase in class " + $classMatch.Groups['name'].Value) -ForegroundColor Yellow
          }

          $pos = $span.BodyStart + $newBody.Length + 1
      }

      if ($fileChanged) {
          Write-Host $_.FullName -ForegroundColor Green
          [System.IO.File]::WriteAllText($_.FullName, $updated, [System.Text.Encoding]::UTF8)
      }
  }
}

function ApplyChangesToLib {
  Write-Host "[Apply changes for @bia-team/bia-ng lib]"
  
  $replacementsTS = @(
    # Update enum imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDtoState\b)([\s\S]*?)[\s]*?\bDtoState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto-state\.enum';)"; Replacement = 'import { DtoState } from ''@bia-team/bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bEnvironmentType\b)([\s\S]*?)[\s]*?\bEnvironmentType\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { EnvironmentType } from ''@bia-team/bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bHttpStatusCodeCustom\b)([\s\S]*?)[\s]*?\bHttpStatusCodeCustom\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/http-status-code-custom\.enum';)"; Replacement = 'import { HttpStatusCodeCustom } from ''@bia-team/bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNumberMode\b)([\s\S]*?)[\s]*?\bNumberMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { NumberMode } from ''@bia-team/bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPrimeNGFiltering\b)([\s\S]*?)[\s]*?\bPrimeNGFiltering\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { PrimeNGFiltering } from ''@bia-team/bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPropType\b)([\s\S]*?)[\s]*?\bPropType\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { PropType } from ''@bia-team/bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRoleMode\b)([\s\S]*?)[\s]*?\bRoleMode\b[,]?([\s\S]*?} from '[\s\S]*?\/constants';)"; Replacement = 'import { RoleMode } from ''@bia-team/bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewType\b)([\s\S]*?)[\s]*?\bViewType\b[,]?([\s\S]*?} from '[\s\S]*?\/constants';)"; Replacement = 'import { ViewType } from ''@bia-team/bia-ng/models/enum''; import { $1$2'},
    
    # Update models imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bArchivableDto\b)([\s\S]*?)[\s]*?\bArchivableDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/archivable-dto';)"; Replacement = 'import { ArchivableDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBaseDto\b)([\s\S]*?)[\s]*?\bBaseDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/base-dto';)"; Replacement = 'import { BaseDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFixableDto\b)([\s\S]*?)[\s]*?\bFixableDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/fixable-dto';)"; Replacement = 'import { FixableDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamDto\b)([\s\S]*?)[\s]*?\bTeamDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/team-dto';)"; Replacement = 'import { TeamDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bteamFieldsConfigurationColumns\b)([\s\S]*?)[\s]*?\bteamFieldsConfigurationColumns\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/team-dto';)"; Replacement = 'import { teamFieldsConfigurationColumns } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bVersionedDto\b)([\s\S]*?)[\s]*?\bVersionedDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/versioned-dto';)"; Replacement = 'import { VersionedDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppConfig\b)([\s\S]*?)[\s]*?\bAppConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { AppConfig } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuMode\b)([\s\S]*?)[\s]*?\bMenuMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { MenuMode } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFooterMode\b)([\s\S]*?)[\s]*?\bFooterMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { FooterMode } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bColorScheme\b)([\s\S]*?)[\s]*?\bColorScheme\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { ColorScheme } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuProfilePosition\b)([\s\S]*?)[\s]*?\bMenuProfilePosition\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { MenuProfilePosition } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettings\b)([\s\S]*?)[\s]*?\bAppSettings\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { AppSettings } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bEnvironment\b)([\s\S]*?)[\s]*?\bEnvironment\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Environment } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCulture\b)([\s\S]*?)[\s]*?\bCulture\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Culture } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bKeycloak\b)([\s\S]*?)[\s]*?\bKeycloak\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Keycloak } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bConfiguration\b)([\s\S]*?)[\s]*?\bConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Configuration } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bApi\b)([\s\S]*?)[\s]*?\bApi\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Api } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTokenConf\b)([\s\S]*?)[\s]*?\bTokenConf\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { TokenConf } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bProfileConfiguration\b)([\s\S]*?)[\s]*?\bProfileConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { ProfileConfiguration } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeConfiguration\b)([\s\S]*?)[\s]*?\bIframeConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { IframeConfiguration } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAllowedHost\b)([\s\S]*?)[\s]*?\bAllowedHost\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { AllowedHost } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLoginParamDto\b)([\s\S]*?)[\s]*?\bLoginParamDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { LoginParamDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamConfigDto\b)([\s\S]*?)[\s]*?\bTeamConfigDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { TeamConfigDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserProfile\b)([\s\S]*?)[\s]*?\bUserProfile\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { UserProfile } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserData\b)([\s\S]*?)[\s]*?\bUserData\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { UserData } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCurrentTeamDto\b)([\s\S]*?)[\s]*?\bCurrentTeamDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { CurrentTeamDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAdditionalInfos\b)([\s\S]*?)[\s]*?\bAdditionalInfos\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { AdditionalInfos } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bToken\b)([\s\S]*?)[\s]*?\bToken\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { Token } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAuthInfo\b)([\s\S]*?)[\s]*?\bAuthInfo\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { AuthInfo } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldNumberFormat\b)([\s\S]*?)[\s]*?\bBiaFieldNumberFormat\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldNumberFormat } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldDateFormat\b)([\s\S]*?)[\s]*?\bBiaFieldDateFormat\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldDateFormat } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldConfig\b)([\s\S]*?)[\s]*?\bBiaFieldConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldConfig } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldsConfig\b)([\s\S]*?)[\s]*?\bBiaFieldsConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldsConfig } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfig\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfig } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigItem\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigItem } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigRow\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigRow\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigRow } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigColumn\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigColumn\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigColumn } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigGroup\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigGroup\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigGroup } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigField\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigField\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigField } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigTabGroup\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigTabGroup\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigTabGroup } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigTab\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigTab\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigTab } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigColumnSize\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigColumnSize\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigColumnSize } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaNavigation\b)([\s\S]*?)[\s]*?\bBiaNavigation\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-navigation';)"; Replacement = 'import { BiaNavigation } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableState\b)([\s\S]*?)[\s]*?\bBiaTableState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-table-state';)"; Replacement = 'import { BiaTableState } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bConfigDisplay\b)([\s\S]*?)[\s]*?\bConfigDisplay\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/config-display';)"; Replacement = 'import { ConfigDisplay } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDEFAULT_CRUD_STATE\b)([\s\S]*?)[\s]*?\bDEFAULT_CRUD_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/crud-state';)"; Replacement = 'import { DEFAULT_CRUD_STATE } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudState\b)([\s\S]*?)[\s]*?\bCrudState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/crud-state';)"; Replacement = 'import { CrudState } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDataResult\b)([\s\S]*?)[\s]*?\bDataResult\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/data-result';)"; Replacement = 'import { DataResult } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bExternalSiteConfig\b)([\s\S]*?)[\s]*?\bExternalSiteConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/external-site-config';)"; Replacement = 'import { ExternalSiteConfig } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bHttpOptions\b)([\s\S]*?)[\s]*?\bHttpOptions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-options';)"; Replacement = 'import { HttpOptions } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bGetParam\b)([\s\S]*?)[\s]*?\bGetParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { GetParam } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bGetListParam\b)([\s\S]*?)[\s]*?\bGetListParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { GetListParam } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bGetListByPostParam\b)([\s\S]*?)[\s]*?\bGetListByPostParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { GetListByPostParam } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bSaveParam\b)([\s\S]*?)[\s]*?\bSaveParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { SaveParam } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPutParam\b)([\s\S]*?)[\s]*?\bPutParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { PutParam } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPostParam\b)([\s\S]*?)[\s]*?\bPostParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { PostParam } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDeleteParam\b)([\s\S]*?)[\s]*?\bDeleteParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { DeleteParam } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDeletesParam\b)([\s\S]*?)[\s]*?\bDeletesParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { DeletesParam } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUpdateFixedStatusParam\b)([\s\S]*?)[\s]*?\bUpdateFixedStatusParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { UpdateFixedStatusParam } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bHttpRequestItem\b)([\s\S]*?)[\s]*?\bHttpRequestItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-request-item';)"; Replacement = 'import { HttpRequestItem } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeConfig\b)([\s\S]*?)[\s]*?\bIframeConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/iframe-config';)"; Replacement = 'import { IframeConfig } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeMessage\b)([\s\S]*?)[\s]*?\bIframeMessage\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/iframe-message';)"; Replacement = 'import { IframeMessage } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bKeyValuePair\b)([\s\S]*?)[\s]*?\bKeyValuePair\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/key-value-pair';)"; Replacement = 'import { KeyValuePair } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bOptionDto\b)([\s\S]*?)[\s]*?\bOptionDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/option-dto';)"; Replacement = 'import { OptionDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPagingFilterFormatDto\b)([\s\S]*?)[\s]*?\bPagingFilterFormatDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/paging-filter-format';)"; Replacement = 'import { PagingFilterFormatDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPrimeLocale\b)([\s\S]*?)[\s]*?\bPrimeLocale\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/prime-locale';)"; Replacement = 'import { PrimeLocale } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRoleDto\b)([\s\S]*?)[\s]*?\bRoleDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/role';)"; Replacement = 'import { RoleDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTargetedFeature\b)([\s\S]*?)[\s]*?\bTargetedFeature\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/signalR';)"; Replacement = 'import { TargetedFeature } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamAdvancedFilterDto\b)([\s\S]*?)[\s]*?\bTeamAdvancedFilterDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/team-advanced-filter-dto';)"; Replacement = 'import { TeamAdvancedFilterDto } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeam\b)([\s\S]*?)[\s]*?\bTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/model\/team';)"; Replacement = 'import { Team } from ''@bia-team/bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLdapDomain\b)([\s\S]*?)[\s]*?\bLdapDomain\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/model\/ldap-domain';)"; Replacement = 'import { LdapDomain } from ''@bia-team/bia-ng/models''; import { $1$2'},

    # Update bia-core imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettingsDas\b)([\s\S]*?)[\s]*?\bAppSettingsDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/services\/app-settings-das.service';)"; Replacement = 'import { AppSettingsDas } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettings\b)([\s\S]*?)[\s]*?\bAppSettings\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/services\/app-settings.service';)"; Replacement = 'import { AppSettings } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "\bDomainAppSettingsActions\b"; Replacement = 'CoreAppSettingsActions'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCoreAppSettingsActions\b)([\s\S]*?)[\s]*?\bCoreAppSettingsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings-actions';)"; Replacement = 'import { CoreAppSettingsActions } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettingsEffects\b)([\s\S]*?)[\s]*?\bAppSettingsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings-actions';)"; Replacement = 'import { AppSettingsEffects } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettingsState\b)([\s\S]*?)[\s]*?\bAppSettingsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings\.state';)"; Replacement = 'import { AppSettingsState } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAppSettingsState\b)([\s\S]*?)[\s]*?\bgetAppSettingsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings\.state';)"; Replacement = 'import { getAppSettingsState } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAppSettings\b)([\s\S]*?)[\s]*?\bgetAppSettings\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings\.state';)"; Replacement = 'import { getAppSettings } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettingsModule\b)([\s\S]*?)[\s]*?\bAppSettingsModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/app-settings\.module';)"; Replacement = 'import { AppSettingsModule } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPermissionGuard\b)([\s\S]*?)[\s]*?\bPermissionGuard\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/guards\/permission\.guard';)"; Replacement = 'import { PermissionGuard } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOnlineOfflineInterceptor\b)([\s\S]*?)[\s]*?\bBiaOnlineOfflineInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-online-offline\.interceptor';)"; Replacement = 'import { BiaOnlineOfflineInterceptor } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaOnlineOfflineInterceptor\b)([\s\S]*?)[\s]*?\bbiaOnlineOfflineInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-online-offline\.interceptor';)"; Replacement = 'import { biaOnlineOfflineInterceptor } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bXhrWithCredInterceptorService\b)([\s\S]*?)[\s]*?\bXhrWithCredInterceptorService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-xhr-with-cred-interceptor\.service';)"; Replacement = 'import { XhrWithCredInterceptorService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaXhrWithCredInterceptor\b)([\s\S]*?)[\s]*?\bbiaXhrWithCredInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-xhr-with-cred-interceptor\.service';)"; Replacement = 'import { biaXhrWithCredInterceptor } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bStandardEncodeHttpParamsInterceptor\b)([\s\S]*?)[\s]*?\bStandardEncodeHttpParamsInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/standard-encode-http-params-interceptor\.service';)"; Replacement = 'import { StandardEncodeHttpParamsInterceptor } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bStandardEncoder\b)([\s\S]*?)[\s]*?\bStandardEncoder\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/standard-encoder';)"; Replacement = 'import { StandardEncoder } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTokenInterceptor\b)([\s\S]*?)[\s]*?\bTokenInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/token\.interceptor';)"; Replacement = 'import { TokenInterceptor } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaTokenInterceptor\b)([\s\S]*?)[\s]*?\bbiaTokenInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/token\.interceptor';)"; Replacement = 'import { biaTokenInterceptor } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotification\b)([\s\S]*?)[\s]*?\bNotification\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/model\/notification';)"; Replacement = 'import { Notification } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTeam\b)([\s\S]*?)[\s]*?\bNotificationTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/model\/notification';)"; Replacement = 'import { NotificationTeam } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationType\b)([\s\S]*?)[\s]*?\bNotificationType\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/model\/notification';)"; Replacement = 'import { NotificationType } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationData\b)([\s\S]*?)[\s]*?\bNotificationData\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/model\/notification';)"; Replacement = 'import { NotificationData } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationDas\b)([\s\S]*?)[\s]*?\bNotificationDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/services\/notification-das\.service';)"; Replacement = 'import { NotificationDas } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationSignalRService\b)([\s\S]*?)[\s]*?\bNotificationSignalRService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/services\/notification-signalr\.service';)"; Replacement = 'import { NotificationSignalRService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bNotificationsState\b)[\s\S]*?\bNotificationsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bNotificationsState\b"; Replacement = '$1CoreNotificationsStore.NotificationsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\breducers\b"; Replacement = '$1CoreNotificationsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetNotificationsState\b)[\s\S]*?\bgetNotificationsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetNotificationsState\b"; Replacement = '$1CoreNotificationsStore.getNotificationsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetNotificationsEntitiesState\b)[\s\S]*?\bgetNotificationsEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetNotificationsEntitiesState\b"; Replacement = '$1CoreNotificationsStore.getNotificationsEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUserNotifications\b)[\s\S]*?\bgetUserNotifications\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetUserNotifications\b"; Replacement = '$1CoreNotificationsStore.getUserNotifications'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUnreadNotificationCount\b)[\s\S]*?\bgetUnreadNotificationCount\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetUnreadNotificationCount\b"; Replacement = '$1CoreNotificationsStore.getUnreadNotificationCount'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllNotifications\b)[\s\S]*?\bgetAllNotifications\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetAllNotifications\b"; Replacement = '$1CoreNotificationsStore.getAllNotifications'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetNotificationById\b)[\s\S]*?\bgetNotificationById\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetNotificationById\b"; Replacement = '$1CoreNotificationsStore.getNotificationById'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationsState\b)([\s\S]*?)[\s]*?\bNotificationsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationsState\b)([\s\S]*?)[\s]*?\bgetNotificationsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationsEntitiesState\b)([\s\S]*?)[\s]*?\bgetNotificationsEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUserNotifications\b)([\s\S]*?)[\s]*?\bgetUserNotifications\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUnreadNotificationCount\b)([\s\S]*?)[\s]*?\bgetUnreadNotificationCount\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllNotifications\b)([\s\S]*?)[\s]*?\bgetAllNotifications\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationById\b)([\s\S]*?)[\s]*?\bgetNotificationById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "\bDomainNotificationsActions\b"; Replacement = 'CoreNotificationsActions'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCoreNotificationsActions\b)([\s\S]*?)[\s]*?\bCoreNotificationsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notifications-actions';)"; Replacement = 'import { CoreNotificationsActions } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationsEffects\b)([\s\S]*?)[\s]*?\bNotificationsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notifications-effects';)"; Replacement = 'import { NotificationsEffects } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationModule\b)([\s\S]*?)[\s]*?\bNotificationModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/notification\.module';)"; Replacement = 'import { NotificationModule } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaMatomoService\b)([\s\S]*?)[\s]*?\bBiaMatomoService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/matomo\/bia-matomo\.service';)"; Replacement = 'import { BiaMatomoService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMatomoInjector\b)([\s\S]*?)[\s]*?\bMatomoInjector\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/matomo\/matomo-injector\.service';)"; Replacement = 'import { MatomoInjector } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMatomoTracker\b)([\s\S]*?)[\s]*?\bMatomoTracker\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/matomo\/matomo-tracker\.service';)"; Replacement = 'import { MatomoTracker } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAbstractDas\b)([\s\S]*?)[\s]*?\bAbstractDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/abstract-das\.service';)"; Replacement = 'import { AbstractDas } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAuthService\b)([\s\S]*?)[\s]*?\bAuthService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/auth\.service';)"; Replacement = 'import { AuthService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaAppInitService\b)([\s\S]*?)[\s]*?\bBiaAppInitService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-app-init\.service';)"; Replacement = 'import { BiaAppInitService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaBarcodeScannerService\b)([\s\S]*?)[\s]*?\bBiaBarcodeScannerService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-barcode-scanner\.service';)"; Replacement = 'import { BiaBarcodeScannerService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaDialogService\b)([\s\S]*?)[\s]*?\bBiaDialogService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-dialog\.service';)"; Replacement = 'import { BiaDialogService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaEnvironmentService\b)([\s\S]*?)\bBiaEnvironmentService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-environment\.service';)"; Replacement = 'import { BiaEnvironmentService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaInjectExternalService\b)([\s\S]*?)[\s]*?\bBiaInjectExternalService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-inject-external\.service';)"; Replacement = 'import { BiaInjectExternalService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaInjectorService\b)([\s\S]*?)[\s]*?\bBiaInjectorService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-injector\.service';)"; Replacement = 'import { BiaInjectorService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaMessageService\b)([\s\S]*?)[\s]*?\bBiaMessageService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-message\.service';)"; Replacement = 'import { BiaMessageService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaNgxLoggerServerService\b)([\s\S]*?)[\s]*?\bBiaNgxLoggerServerService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-ngx-logger-server\.service';)"; Replacement = 'import { BiaNgxLoggerServerService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOnlineOfflineService\b)([\s\S]*?)[\s]*?\bBiaOnlineOfflineService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-online-offline\.service';)"; Replacement = 'import { BiaOnlineOfflineService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOptionService\b)([\s\S]*?)[\s]*?\bBiaOptionService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-option\.service';)"; Replacement = 'import { BiaOptionService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaSignalRService\b)([\s\S]*?)\bBiaSignalRService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-signalr\.service';)"; Replacement = 'import { BiaSignalRService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaSwUpdateService\b)([\s\S]*?)\bBiaSwUpdateService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-sw-update\.service';)"; Replacement = 'import { BiaSwUpdateService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTranslateHttpLoader\b)([\s\S]*?)\bBiaTranslateHttpLoader\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translate-http-loader';)"; Replacement = 'import { BiaTranslateHttpLoader } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetCurrentCulture\b)([\s\S]*?)\bgetCurrentCulture\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { getCurrentCulture } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bSTORAGE_CULTURE_KEY\b)([\s\S]*?)\bSTORAGE_CULTURE_KEY\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { STORAGE_CULTURE_KEY } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDateFormat\b)([\s\S]*?)\bDateFormat\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { DateFormat } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTranslationService\b)([\s\S]*?)[\s]*?\bBiaTranslationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { BiaTranslationService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDateHelperService\b)([\s\S]*?)[\s]*?\bDateHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/date-helper\.service';)"; Replacement = 'import { DateHelperService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bGenericDas\b)([\s\S]*?)[\s]*?\bGenericDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/generic-das\.service';)"; Replacement = 'import { GenericDas } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNavigationService\b)([\s\S]*?)[\s]*?\bNavigationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/navigation\.service';)"; Replacement = 'import { NavigationService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRefreshTokenService\b)([\s\S]*?)[\s]*?\bRefreshTokenService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/refresh-token\.service';)"; Replacement = 'import { RefreshTokenService } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaSuccessWaitRefreshSignalR\b)([\s\S]*?)[\s]*?\bbiaSuccessWaitRefreshSignalR\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/shared\/bia-action';)"; Replacement = 'import { biaSuccessWaitRefreshSignalR } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaErrorHandler\b)([\s\S]*?)\bBiaErrorHandler\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/shared\/bia-error-handler';)"; Replacement = 'import { BiaErrorHandler } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamDas\b)([\s\S]*?)\bTeamDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/services\/team-das\.service';)"; Replacement = 'import { TeamDas } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bTeamsState\b)[\s\S]*?\bTeamsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bTeamsState\b"; Replacement = '$1CoreTeamsStore.TeamsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\breducers\b"; Replacement = '$1CoreTeamsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetTeamsState\b)[\s\S]*?\bgetTeamsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bgetTeamsState\b"; Replacement = '$1CoreTeamsStore.getTeamsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllTeams\b)[\s\S]*?\bgetAllTeams\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bgetAllTeams\b"; Replacement = '$1CoreTeamsStore.getAllTeams'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetTeamById\b)[\s\S]*?\bgetTeamById\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bgetTeamById\b"; Replacement = '$1CoreTeamsStore.getTeamById'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllTeamsOfType\b)[\s\S]*?\bgetAllTeamsOfType\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bgetAllTeamsOfType\b"; Replacement = '$1CoreTeamsStore.getAllTeamsOfType'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamsState\b)([\s\S]*?)[\s]*?\bTeamsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetTeamsState\b)([\s\S]*?)[\s]*?\bgetTeamsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllTeams\b)([\s\S]*?)[\s]*?\bgetAllTeams\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetTeamById\b)([\s\S]*?)[\s]*?\bgetTeamById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllTeamsOfType\b)([\s\S]*?)[\s]*?\bgetAllTeamsOfType\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "\bDomainTeamsActions\b"; Replacement = 'CoreTeamsActions'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCoreTeamsActions\b)([\s\S]*?)[\s]*?\bCoreTeamsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/teams-actions';)"; Replacement = 'import { CoreTeamsActions } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamsEffects\b)([\s\S]*?)[\s]*?\bTeamsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/teams-effects';)"; Replacement = 'import { TeamsEffects } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamModule\b)([\s\S]*?)[\s]*?\bTeamModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/team\.module';)"; Replacement = 'import { TeamModule } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\binitializeApp\b)([\s\S]*?)[\s]*?\binitializeApp\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/bia-core\.module';)"; Replacement = 'import { initializeApp } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaCoreModule\b)([\s\S]*?)[\s]*?\bBiaCoreModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/bia-core\.module';)"; Replacement = 'import { BiaCoreModule } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDataItem\b)([\s\S]*?)[\s]*?\bDataItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/db';)"; Replacement = 'import { DataItem } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppDB\b)([\s\S]*?)[\s]*?\bAppDB\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/db';)"; Replacement = 'import { AppDB } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bisEmpty\b)([\s\S]*?)[\s]*?\bisEmpty\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/utils';)"; Replacement = 'import { isEmpty } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bisObject\b)([\s\S]*?)[\s]*?\bisObject\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/utils';)"; Replacement = 'import { isObject } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bclone\b)([\s\S]*?)[\s]*?\bclone\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/utils';)"; Replacement = 'import { clone } from ''@bia-team/bia-ng/core''; import { $1$2'},
    # Update constants moved to bia-core imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bROUTE_DATA_BREADCRUMB\b)([\s\S]*?)[\s]*?\bROUTE_DATA_BREADCRUMB\b[,]?([\s\S]*?} from 'src\/app\/shared\/constants';)"; Replacement = 'import { ROUTE_DATA_BREADCRUMB } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bROUTE_DATA_CAN_NAVIGATE\b)([\s\S]*?)[\s]*?\bROUTE_DATA_CAN_NAVIGATE\b[,]?([\s\S]*?} from 'src\/app\/shared\/constants';)"; Replacement = 'import { ROUTE_DATA_CAN_NAVIGATE } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bROUTE_DATA_NO_MARGIN\b)([\s\S]*?)[\s]*?\bROUTE_DATA_NO_MARGIN\b[,]?([\s\S]*?} from 'src\/app\/shared\/constants';)"; Replacement = 'import { ROUTE_DATA_NO_MARGIN } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bROUTE_DATA_NO_PADDING\b)([\s\S]*?)[\s]*?\bROUTE_DATA_NO_PADDING\b[,]?([\s\S]*?} from 'src\/app\/shared\/constants';)"; Replacement = 'import { ROUTE_DATA_NO_PADDING } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTHEME_LIGHT\b)([\s\S]*?)[\s]*?\bTHEME_LIGHT\b[,]?([\s\S]*?} from 'src\/app\/shared\/constants';)"; Replacement = 'import { THEME_LIGHT } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTHEME_DARK\b)([\s\S]*?)[\s]*?\bTHEME_DARK\b[,]?([\s\S]*?} from 'src\/app\/shared\/constants';)"; Replacement = 'import { THEME_DARK } from ''@bia-team/bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTABLE_FILTER_GLOBAL\b)([\s\S]*?)[\s]*?\bTABLE_FILTER_GLOBAL\b[,]?([\s\S]*?} from 'src\/app\/shared\/constants';)"; Replacement = 'import { TABLE_FILTER_GLOBAL } from ''@bia-team/bia-ng/core''; import { $1$2'},
    
    # Update bia-shared imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaButtonGroupComponent\b)([\s\S]*?)[\s]*?\bBiaButtonGroupComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-button-group\/bia-button-group\.component';)"; Replacement = 'import { BiaButtonGroupComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaButtonGroupItem\b)([\s\S]*?)[\s]*?\bBiaButtonGroupItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-button-group\/bia-button-group\.component';)"; Replacement = 'import { BiaButtonGroupItem } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\binitExternalSiteConfig\b)([\s\S]*?)[\s]*?\binitExternalSiteConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-external-site\/bia-external-site\.component';)"; Replacement = 'import { initExternalSiteConfig } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaExternalSiteComponent\b)([\s\S]*?)[\s]*?\bBiaExternalSiteComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-external-site\/bia-external-site\.component';)"; Replacement = 'import { BiaExternalSiteComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOnlineOfflineIconComponent\b)([\s\S]*?)[\s]*?\bBiaOnlineOfflineIconComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-online-offline-icon\/bia-online-offline-icon\.component';)"; Replacement = 'import { BiaOnlineOfflineIconComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTeamSelectorComponent\b)([\s\S]*?)[\s]*?\bBiaTeamSelectorComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-team-selector\/bia-team-selector\.component';)"; Replacement = 'import { BiaTeamSelectorComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldBaseComponent\b)([\s\S]*?)[\s]*?\bBiaFieldBaseComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-field-base\/bia-field-base\.component';)"; Replacement = 'import { BiaFieldBaseComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldHelperService\b)([\s\S]*?)[\s]*?\bBiaFieldHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-field-base\/bia-field-helper\.service';)"; Replacement = 'import { BiaFieldHelperService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormComponent\b)([\s\S]*?)[\s]*?\bBiaFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-form\/bia-form\.component';)"; Replacement = 'import { BiaFormComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutComponent\b)([\s\S]*?)[\s]*?\bBiaFormLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-form-layout\/bia-form-layout\.component';)"; Replacement = 'import { BiaFormLayoutComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaInputComponent\b)([\s\S]*?)[\s]*?\bBiaInputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-input\/bia-input\.component';)"; Replacement = 'import { BiaInputComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOutputComponent\b)([\s\S]*?)[\s]*?\bBiaOutputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-output\/bia-output\.component';)"; Replacement = 'import { BiaOutputComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bHangfireContainerComponent\b)([\s\S]*?)[\s]*?\bHangfireContainerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/hangfire-container\/hangfire-container\.component';)"; Replacement = 'import { HangfireContainerComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuChangeEvent\b)([\s\S]*?)[\s]*?\bMenuChangeEvent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/api\/menuchangeevent';)"; Replacement = 'import { MenuChangeEvent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bClassicPageLayoutComponent\b)([\s\S]*?)[\s]*?\bClassicPageLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/classic-page-layout\/classic-page-layout\.component';)"; Replacement = 'import { ClassicPageLayoutComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLayoutMode\b)([\s\S]*?)[\s]*?\bLayoutMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/dynamic-layout\/dynamic-layout\.component';)"; Replacement = 'import { LayoutMode } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDynamicLayoutComponent\b)([\s\S]*?)[\s]*?\bDynamicLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/dynamic-layout\/dynamic-layout\.component';)"; Replacement = 'import { DynamicLayoutComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFullPageLayoutComponent\b)([\s\S]*?)[\s]*?\bFullPageLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/fullpage-layout\/fullpage-layout\.component';)"; Replacement = 'import { FullPageLayoutComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIeWarningComponent\b)([\s\S]*?)[\s]*?\bIeWarningComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ie-warning\/ie-warning\.component';)"; Replacement = 'import { IeWarningComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPopupLayoutComponent\b)([\s\S]*?)[\s]*?\bPopupLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/popup-layout\/popup-layout\.component';)"; Replacement = 'import { PopupLayoutComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaScrollingNotificationComponent\b)([\s\S]*?)[\s]*?\bBiaScrollingNotificationComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/scrolling-notification\/scrolling-notification\.component';)"; Replacement = 'import { BiaScrollingNotificationComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaThemeService\b)([\s\S]*?)[\s]*?\bBiaThemeService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-theme\.service';)"; Replacement = 'import { BiaThemeService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBIA_USER_CONFIG\b)([\s\S]*?)[\s]*?\bBIA_USER_CONFIG\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { BIA_USER_CONFIG } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBIA_LAYOUT_DATA\b)([\s\S]*?)[\s]*?\bBIA_LAYOUT_DATA\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { BIA_LAYOUT_DATA } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaLayoutService\b)([\s\S]*?)[\s]*?\bBiaLayoutService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { BiaLayoutService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuProfileConfig\b)([\s\S]*?)[\s]*?\bMenuProfileConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/menu-profile\.service';)"; Replacement = 'import { MenuProfileConfig } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaMenuProfileService\b)([\s\S]*?)[\s]*?\bBiaMenuProfileService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/menu-profile\.service';)"; Replacement = 'import { BiaMenuProfileService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuService\b)([\s\S]*?)[\s]*?\bMenuService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/menu\.service';)"; Replacement = 'import { MenuService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaConfigComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaConfigComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/config\/ultima-config\.component';)"; Replacement = 'import { BiaUltimaConfigComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaFooterComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaFooterComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/footer\/ultima-footer\.component';)"; Replacement = 'import { BiaUltimaFooterComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaLayoutComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/layout\/ultima-layout\.component';)"; Replacement = 'import { BiaUltimaLayoutComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaMenuComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaMenuComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/menu\/ultima-menu\.component';)"; Replacement = 'import { BiaUltimaMenuComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaMenuItemComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaMenuItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/menu-item\/ultima-menu-item\.component';)"; Replacement = 'import { BiaUltimaMenuItemComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaMenuProfileComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaMenuProfileComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/menu-profile\/ultima-menu-profile\.component';)"; Replacement = 'import { BiaUltimaMenuProfileComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaSidebarComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaSidebarComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/sidebar\/ultima-sidebar\.component';)"; Replacement = 'import { BiaUltimaSidebarComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaTopbarComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaTopbarComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/topbar\/ultima-topbar\.component';)"; Replacement = 'import { BiaUltimaTopbarComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaLayoutModule\b)([\s\S]*?)[\s]*?\bBiaUltimaLayoutModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/ultima-layout\.module';)"; Replacement = 'import { BiaUltimaLayoutModule } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLayoutComponent\b)([\s\S]*?)[\s]*?\bLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/layout\.component';)"; Replacement = 'import { LayoutComponent   } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPageLayoutComponent\b)([\s\S]*?)[\s]*?\bPageLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/page-layout\.component';)"; Replacement = 'import { PageLayoutComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIsNotCurrentTeamPipe\b)([\s\S]*?)[\s]*?\bIsNotCurrentTeamPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/notification-team-warning\/is-not-current-team\/is-not-current-team\.pipe';)"; Replacement = 'import { IsNotCurrentTeamPipe } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamListPipe\b)([\s\S]*?)[\s]*?\bTeamListPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/notification-team-warning\/team-list\/team-list\.pipe';)"; Replacement = 'import { TeamListPipe } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTeamWarningComponent\b)([\s\S]*?)[\s]*?\bNotificationTeamWarningComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/notification-team-warning\/notification-team-warning\.component';)"; Replacement = 'import { NotificationTeamWarningComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bSpinnerComponent\b)([\s\S]*?)[\s]*?\bSpinnerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/spinner\/spinner\.component';)"; Replacement = 'import { SpinnerComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaCalcTableComponent\b)([\s\S]*?)[\s]*?\bBiaCalcTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-calc-table\/bia-calc-table\.component';)"; Replacement = 'import { BiaCalcTableComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFrozenColumnDirective\b)([\s\S]*?)[\s]*?\bBiaFrozenColumnDirective\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-frozen-column\/bia-frozen-column\.directive';)"; Replacement = 'import { BiaFrozenColumnDirective } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableComponent\b)([\s\S]*?)[\s]*?\bBiaTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table\/bia-table\.component';)"; Replacement = 'import { BiaTableComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDictOptionDto\b)([\s\S]*?)[\s]*?\bDictOptionDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table\/dict-option-dto';)"; Replacement = 'import { DictOptionDto } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaBehaviorIcon\b)([\s\S]*?)[\s]*?\bBiaBehaviorIcon\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-behavior-controller\/bia-table-behavior-controller\.component';)"; Replacement = 'import { BiaBehaviorIcon } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableBehaviorControllerComponent\b)([\s\S]*?)[\s]*?\bBiaTableBehaviorControllerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-behavior-controller\/bia-table-behavior-controller\.component';)"; Replacement = 'import { BiaTableBehaviorControllerComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableControllerComponent\b)([\s\S]*?)[\s]*?\bBiaTableControllerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-controller\/bia-table-controller\.component';)"; Replacement = 'import { BiaTableControllerComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableFilterComponent\b)([\s\S]*?)[\s]*?\bBiaTableFilterComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-filter\/bia-table-filter\.component';)"; Replacement = 'import { BiaTableFilterComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableFooterControllerComponent\b)([\s\S]*?)[\s]*?\bBiaTableFooterControllerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-footer-controller\/bia-table-footer-controller\.component';)"; Replacement = 'import { BiaTableFooterControllerComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableHeaderComponent\b)([\s\S]*?)[\s]*?\bBiaTableHeaderComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-header\/bia-table-header\.component';)"; Replacement = 'import { BiaTableHeaderComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableInputComponent\b)([\s\S]*?)[\s]*?\bBiaTableInputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-input\/bia-table-input\.component';)"; Replacement = 'import { BiaTableInputComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableOutputComponent\b)([\s\S]*?)[\s]*?\bBiaTableOutputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-output\/bia-table-output\.component';)"; Replacement = 'import { BiaTableOutputComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamAdvancedFilterComponent\b)([\s\S]*?)[\s]*?\bTeamAdvancedFilterComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/team-advanced-filter\/team-advanced-filter\.component';)"; Replacement = 'import { TeamAdvancedFilterComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemFormComponent\b)([\s\S]*?)[\s]*?\bCrudItemFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/components\/crud-item-form\/crud-item-form\.component';)"; Replacement = 'import { CrudItemFormComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemImportFormComponent\b)([\s\S]*?)[\s]*?\bCrudItemImportFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/components\/crud-item-import-form\/crud-item-import-form\.component';)"; Replacement = 'import { CrudItemImportFormComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemTableComponent\b)([\s\S]*?)[\s]*?\bCrudItemTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/components\/crud-item-table\/crud-item-table\.component';)"; Replacement = 'import { CrudItemTableComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFormReadOnlyMode\b)([\s\S]*?)[\s]*?\bFormReadOnlyMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/model\/crud-config';)"; Replacement = 'import { FormReadOnlyMode } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bShowIconsConfig\b)([\s\S]*?)[\s]*?\bShowIconsConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/model\/crud-config';)"; Replacement = 'import { ShowIconsConfig } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudConfig\b)([\s\S]*?)[\s]*?\bCrudConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/model\/crud-config';)"; Replacement = 'import { CrudConfig } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bImportParam\b)([\s\S]*?)[\s]*?\bImportParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-import\.service';)"; Replacement = 'import { ImportParam } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bImportDataError\b)([\s\S]*?)[\s]*?\bImportDataError\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-import\.service';)"; Replacement = 'import { ImportDataError } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bImportData\b)([\s\S]*?)[\s]*?\bImportData\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-import\.service';)"; Replacement = 'import { ImportData } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemImportService\b)([\s\S]*?)[\s]*?\bCrudItemImportService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-import\.service';)"; Replacement = 'import { CrudItemImportService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemOptionsService\b)([\s\S]*?)[\s]*?\bCrudItemOptionsService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-options\.service';)"; Replacement = 'import { CrudItemOptionsService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemSignalRService\b)([\s\S]*?)[\s]*?\bCrudItemSignalRService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-signalr\.service';)"; Replacement = 'import { CrudItemSignalRService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemSingleService\b)([\s\S]*?)[\s]*?\bCrudItemSingleService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-single\.service';)"; Replacement = 'import { CrudItemSingleService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemService\b)([\s\S]*?)[\s]*?\bCrudItemService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item\.service';)"; Replacement = 'import { CrudItemService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemComponent\b)([\s\S]*?)[\s]*?\bCrudItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item\/crud-item\.component';)"; Replacement = 'import { CrudItemComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemEditComponent\b)([\s\S]*?)[\s]*?\bCrudItemEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-edit\/crud-item-edit\.component';)"; Replacement = 'import { CrudItemEditComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemImportComponent\b)([\s\S]*?)[\s]*?\bCrudItemImportComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-import\/crud-item-import\.component';)"; Replacement = 'import { CrudItemImportComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemItemComponent\b)([\s\S]*?)[\s]*?\bCrudItemItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-item\/crud-item-item\.component';)"; Replacement = 'import { CrudItemItemComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemNewComponent\b)([\s\S]*?)[\s]*?\bCrudItemNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-new\/crud-item-new\.component';)"; Replacement = 'import { CrudItemNewComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemReadComponent\b)([\s\S]*?)[\s]*?\bCrudItemReadComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-read\/crud-item-read\.component';)"; Replacement = 'import { CrudItemReadComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemsIndexComponent\b)([\s\S]*?)[\s]*?\bCrudItemsIndexComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-items-index\/crud-items-index\.component';)"; Replacement = 'import { CrudItemsIndexComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberFormComponent\b)([\s\S]*?)[\s]*?\bMemberFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-form\/member-form\.component';)"; Replacement = 'import { MemberFormComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberFormEditComponent\b)([\s\S]*?)[\s]*?\bMemberFormEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-form-edit\/member-form-edit\.component';)"; Replacement = 'import { MemberFormEditComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberFormNewComponent\b)([\s\S]*?)[\s]*?\bMemberFormNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-form-new\/member-form-new\.component';)"; Replacement = 'import { MemberFormNewComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberTableComponent\b)([\s\S]*?)[\s]*?\bMemberTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-table\/member-table\.component';)"; Replacement = 'import { MemberTableComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMember\b)([\s\S]*?)[\s]*?\bMember\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/model\/member';)"; Replacement = 'import { Member } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMembers\b)([\s\S]*?)[\s]*?\bMembers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/model\/member';)"; Replacement = 'import { Members } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bmemberFieldsConfiguration\b)([\s\S]*?)[\s]*?\bmemberFieldsConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/model\/member';)"; Replacement = 'import { memberFieldsConfiguration } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberDas\b)([\s\S]*?)[\s]*?\bMemberDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/services\/member-das\.service';)"; Replacement = 'import { MemberDas } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberOptionsService\b)([\s\S]*?)[\s]*?\bMemberOptionsService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/services\/member-options\.service';)"; Replacement = 'import { MemberOptionsService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberService\b)([\s\S]*?)[\s]*?\bMemberService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/services\/member\.service';)"; Replacement = 'import { MemberService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureMembersStore\b)([\s\S]*?)[\s]*?\bFeatureMembersStore\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/store\/member\.state';)"; Replacement = 'import { FeatureMembersStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureMembersActions\b)([\s\S]*?)[\s]*?\bFeatureMembersActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/store\/members-actions';)"; Replacement = 'import { FeatureMembersActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMembersEffects\b)([\s\S]*?)[\s]*?\bMembersEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/store\/members-effects';)"; Replacement = 'import { MembersEffects } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberState\b)([\s\S]*?)[\s]*?\bMemberState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/store\/members-reducer';)"; Replacement = 'import { MemberState } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberEditComponent\b)([\s\S]*?)[\s]*?\bMemberEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-edit\/member-edit\.component';)"; Replacement = 'import { MemberEditComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberImportComponent\b)([\s\S]*?)[\s]*?\bMemberImportComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-import\/member-import\.component';)"; Replacement = 'import { MemberImportComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberItemComponent\b)([\s\S]*?)[\s]*?\bMemberItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-item\/member-item\.component';)"; Replacement = 'import { MemberItemComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberNewComponent\b)([\s\S]*?)[\s]*?\bMemberNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-new\/member-new\.component';)"; Replacement = 'import { MemberNewComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMembersIndexComponent\b)([\s\S]*?)[\s]*?\bMembersIndexComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/members-index\/members-index\.component';)"; Replacement = 'import { MembersIndexComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bmemberCRUDConfiguration\b)([\s\S]*?)[\s]*?\bmemberCRUDConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/member\.constants';)"; Replacement = 'import { memberCRUDConfiguration } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberModule\b)([\s\S]*?)[\s]*?\bMemberModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/member\.module';)"; Replacement = 'import { MemberModule } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromLdapFormComponent\b)([\s\S]*?)[\s]*?\bUserFromLdapFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/components\/user-from-directory-form\/user-from-directory-form\.component';)"; Replacement = 'import { UserFromLdapFormComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFilter\b)([\s\S]*?)[\s]*?\bUserFilter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/model\/user-filter';)"; Replacement = 'import { UserFilter } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectory\b)([\s\S]*?)[\s]*?\bUserFromDirectory\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/model\/user-from-directory';)"; Replacement = 'import { UserFromDirectory } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectoryDas\b)([\s\S]*?)[\s]*?\bUserFromDirectoryDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/services\/user-from-directory-das\.service';)"; Replacement = 'import { UserFromDirectoryDas } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectoryDas\b)([\s\S]*?)[\s]*?\bUserFromDirectoryDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/services\/user-from-directory-das\.service';)"; Replacement = 'import { UserFromDirectoryDas } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';[\s\S]*)\breducers\b"; Replacement = '$1UsersFromDirectoryStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUsersState\b)[\s\S]*?\bgetUsersState\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';[\s\S]*)\bgetUsersState\b"; Replacement = '$1UsersFromDirectoryStore.getUsersState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUsersEntitiesState\b)[\s\S]*?\bgetUsersEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';[\s\S]*)\bgetUsersEntitiesState\b"; Replacement = '$1UsersFromDirectoryStore.getUsersEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllUsersFromDirectory\b)[\s\S]*?\bgetAllUsersFromDirectory\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';[\s\S]*)\bgetAllUsersFromDirectory\b"; Replacement = '$1UsersFromDirectoryStore.getAllUsersFromDirectory'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*)?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';)"; Replacement = 'import { UsersFromDirectoryStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUsersState\b)([\s\S]*)?\bgetUsersState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';)"; Replacement = 'import { UsersFromDirectoryStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUsersEntitiesState\b)([\s\S]*)?\bgetUsersEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';)"; Replacement = 'import { UsersFromDirectoryStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllUsersFromDirectory\b)([\s\S]*)?\bgetAllUsersFromDirectory\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';)"; Replacement = 'import { UsersFromDirectoryStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureUsersFromDirectoryActions\b)([\s\S]*?)[\s]*?\bFeatureUsersFromDirectoryActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-actions';)"; Replacement = 'import { FeatureUsersFromDirectoryActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUsersFromDirectoryEffects\b)([\s\S]*?)[\s]*?\bUsersFromDirectoryEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-effects';)"; Replacement = 'import { UsersFromDirectoryEffects } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\busersFromDirectoryAdapter\b)([\s\S]*?)[\s]*?\busersFromDirectoryAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-reducer';)"; Replacement = 'import { usersFromDirectoryAdapter } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectoryState\b)([\s\S]*?)[\s]*?\bUserFromDirectoryState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-reducer';)"; Replacement = 'import { UserFromDirectoryState } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bINIT_USERFROMDIRECTORY_STATE\b)([\s\S]*?)[\s]*?\bINIT_USERFROMDIRECTORY_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-reducer';)"; Replacement = 'import { INIT_USERFROMDIRECTORY_STATE } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\buserFromDirectoryReducers\b)([\s\S]*?)[\s]*?\buserFromDirectoryReducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-reducer';)"; Replacement = 'import { userFromDirectoryReducers } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserAddFromLdapComponent\b)([\s\S]*?)[\s]*?\bUserAddFromLdapComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/views\/user-add-from-directory-dialog\/user-add-from-directory-dialog\.component';)"; Replacement = 'import { UserAddFromLdapComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectoryModule\b)([\s\S]*?)[\s]*?\bUserFromDirectoryModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/user-from-directory\.module';)"; Replacement = 'import { UserFromDirectoryModule } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewFormComponent\b)([\s\S]*?)\bViewFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/components\/view-form\/view-form\.component';)"; Replacement = 'import { ViewFormComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewTeamTableComponent\b)([\s\S]*?)\bViewTeamTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/components\/view-team-table\/view-team-table\.component';)"; Replacement = 'import { ViewTeamTableComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewUserTableComponent\b)([\s\S]*?)\bViewUserTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/components\/view-user-table\/view-user-table\.component';)"; Replacement = 'import { ViewUserTableComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAssignViewToTeam\b)([\s\S]*?)\bAssignViewToTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/assign-view-to-team';)"; Replacement = 'import { AssignViewToTeam } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDefaultView\b)([\s\S]*?)\bDefaultView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/default-view';)"; Replacement = 'import { DefaultView } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamDefaultView\b)([\s\S]*?)\bTeamDefaultView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/team-default-view';)"; Replacement = 'import { TeamDefaultView } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamView\b)([\s\S]*?)\bTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/team-view';)"; Replacement = 'import { TeamView } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewTeam\b)([\s\S]*?)\bViewTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/view-team';)"; Replacement = 'import { ViewTeam } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bQUERY_STRING_VIEW\b)([\s\S]*?)\bQUERY_STRING_VIEW\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/view.constants';)"; Replacement = 'import { QUERY_STRING_VIEW } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bView\b)([\s\S]*?)\bView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/view';)"; Replacement = 'import { View } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamViewDas\b)([\s\S]*?)\bTeamViewDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/services\/team-view-das\.service';)"; Replacement = 'import { TeamViewDas } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserViewDas\b)([\s\S]*?)\bUserViewDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/services\/user-view-das\.service';)"; Replacement = 'import { UserViewDas } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewDas\b)([\s\S]*?)\bViewDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/services\/view-das\.service';)"; Replacement = 'import { ViewDas } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bViewsState\b)[\s\S]*?\bViewsState\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bViewsState\b"; Replacement = '$1ViewsStore.ViewsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\breducers\b"; Replacement = '$1ViewsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetViewsState\b)[\s\S]*?\bgetViewsState\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetViewsState\b"; Replacement = '$1ViewsStore.getViewsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetViewsEntitiesState\b)[\s\S]*?\bgetViewsEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetViewsEntitiesState\b"; Replacement = '$1ViewsStore.getViewsEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllViews\b)[\s\S]*?\bgetAllViews\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetAllViews\b"; Replacement = '$1ViewsStore.getAllViews'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetDisplayViewDialog\b)[\s\S]*?\bgetDisplayViewDialog\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetDisplayViewDialog\b"; Replacement = '$1ViewsStore.getDisplayViewDialog'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetLastViewChanged\b)[\s\S]*?\bgetLastViewChanged\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetLastViewChanged\b"; Replacement = '$1ViewsStore.getLastViewChanged'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetDataLoaded\b)[\s\S]*?\bgetDataLoaded\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetDataLoaded\b"; Replacement = '$1ViewsStore.getDataLoaded'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetViewById\b)[\s\S]*?\bgetViewById\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetViewById\b"; Replacement = '$1ViewsStore.getViewById'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewsState)([\s\S]*)?ViewsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers)([\s\S]*)?reducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetViewsState)([\s\S]*)?getViewsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetViewsEntitiesState)([\s\S]*)?getViewsEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllViews)([\s\S]*)?getAllViews\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetDisplayViewDialog)([\s\S]*)?getDisplayViewDialog\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetLastViewChanged)([\s\S]*)?getLastViewChanged\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetDataLoaded)([\s\S]*)?getDataLoaded\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetViewById)([\s\S]*)?getViewById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bloadAllView\b)[\s\S]*?\bloadAllView\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bloadAllView\b"; Replacement = '$1ViewsActions.loadAllView'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bloadAllSuccess\b)[\s\S]*?\bloadAllSuccess\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bloadAllSuccess\b"; Replacement = '$1ViewsActions.loadAllSuccess'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bassignViewToTeam\b)[\s\S]*?\bassignViewToTeam\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bassignViewToTeam\b"; Replacement = '$1ViewsActions.assignViewToTeam'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bremoveUserView\b)[\s\S]*?\bremoveUserView\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bremoveUserView\b"; Replacement = '$1ViewsActions.removeUserView'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bsetDefaultUserView\b)[\s\S]*?\bsetDefaultUserView\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bsetDefaultUserView\b"; Replacement = '$1ViewsActions.setDefaultUserView'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\baddUserView\b)[\s\S]*?\baddUserView\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\baddUserView\b"; Replacement = '$1ViewsActions.addUserView'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bupdateUserView\b)[\s\S]*?\bupdateUserView\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bupdateUserView\b"; Replacement = '$1ViewsActions.updateUserView'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bupdateTeamView\b)[\s\S]*?\bupdateTeamView\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bupdateTeamView\b"; Replacement = '$1ViewsActions.updateTeamView'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\baddUserViewSuccess\b)[\s\S]*?\baddUserViewSuccess\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\baddUserViewSuccess\b"; Replacement = '$1ViewsActions.addUserViewSuccess'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bremoveTeamView\b)[\s\S]*?\bremoveTeamView\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bremoveTeamView\b"; Replacement = '$1ViewsActions.removeTeamView'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bsetDefaultTeamView\b)[\s\S]*?\bsetDefaultTeamView\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bsetDefaultTeamView\b"; Replacement = '$1ViewsActions.setDefaultTeamView'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\baddTeamView\b)[\s\S]*?\baddTeamView\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\baddTeamView\b"; Replacement = '$1ViewsActions.addTeamView'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\baddTeamViewSuccess\b)[\s\S]*?\baddTeamViewSuccess\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\baddTeamViewSuccess\b"; Replacement = '$1ViewsActions.addTeamViewSuccess'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bfailure\b)[\s\S]*?\bfailure\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bfailure\b"; Replacement = '$1ViewsActions.failure'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bopenViewDialog\b)[\s\S]*?\bopenViewDialog\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bopenViewDialog\b"; Replacement = '$1ViewsActions.openViewDialog'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bcloseViewDialog\b)[\s\S]*?\bcloseViewDialog\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bcloseViewDialog\b"; Replacement = '$1ViewsActions.closeViewDialog'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bsetViewSuccess\b)[\s\S]*?\bsetViewSuccess\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';[\s\S]*)\bsetViewSuccess\b"; Replacement = '$1ViewsActions.setViewSuccess'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bloadAllView\b)([\s\S]*?)[\s]*?\bloadAllView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bloadAllSuccess\b)([\s\S]*?)[\s]*?\bloadAllSuccess\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bassignViewToTeam\b)([\s\S]*?)[\s]*?\bassignViewToTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bremoveUserView\b)([\s\S]*?)[\s]*?\bremoveUserView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bsetDefaultUserView\b)([\s\S]*?)[\s]*?\bsetDefaultUserView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\baddUserView\b)([\s\S]*?)[\s]*?\baddUserView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bupdateUserView\b)([\s\S]*?)[\s]*?\bupdateUserView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bupdateTeamView\b)([\s\S]*?)[\s]*?\bupdateTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\baddUserViewSuccess\b)([\s\S]*?)[\s]*?\baddUserViewSuccess\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bremoveTeamView\b)([\s\S]*?)[\s]*?\bremoveTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bsetDefaultTeamView\b)([\s\S]*?)[\s]*?\bsetDefaultTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\baddTeamView\b)([\s\S]*?)[\s]*?\baddTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\baddTeamViewSuccess\b)([\s\S]*?)[\s]*?\baddTeamViewSuccess\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bfailure\b)([\s\S]*?)[\s]*?\bfailure\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bopenViewDialog\b)([\s\S]*?)[\s]*?\bopenViewDialog\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bcloseViewDialog\b)([\s\S]*?)[\s]*?\bcloseViewDialog\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bsetViewSuccess\b)([\s\S]*?)[\s]*?\bsetViewSuccess\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewsEffects\b)([\s\S]*?)\bViewsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-effects';)"; Replacement = 'import { ViewsEffects } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewDialogComponent\b)([\s\S]*?)[\s]*?\bViewDialogComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/view\/views\/view-dialog\/view-dialog\.component';)"; Replacement = 'import { ViewDialogComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewListComponent\b)([\s\S]*?)[\s]*?\bViewListComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/view\/views\/view-list\/view-list\.component';)"; Replacement = 'import { ViewListComponent } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFormatValuePipe\b)([\s\S]*?)[\s]*?\bFormatValuePipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/format-value\.pipe';)"; Replacement = 'import { FormatValuePipe } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bJoinPipe\b)([\s\S]*?)[\s]*?\bJoinPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/join\.pipe';)"; Replacement = 'import { JoinPipe } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPluckPipe\b)([\s\S]*?)[\s]*?\bPluckPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/pluck\.pipe';)"; Replacement = 'import { PluckPipe } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bSafeUrlPipe\b)([\s\S]*?)[\s]*?\bSafeUrlPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/safe-url\.pipe';)"; Replacement = 'import { SafeUrlPipe } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTranslateFieldPipe\b)([\s\S]*?)[\s]*?\bTranslateFieldPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/translate-field\.pipe';)"; Replacement = 'import { TranslateFieldPipe } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeCommunicationService\b)([\s\S]*?)[\s]*?\bIframeCommunicationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/iframe\/iframe-communication\.service';)"; Replacement = 'import { IframeCommunicationService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeConfigMessageService\b)([\s\S]*?)[\s]*?\bIframeConfigMessageService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/iframe\/iframe-config-message\.service';)"; Replacement = 'import { IframeConfigMessageService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudHelperService\b)([\s\S]*?)[\s]*?\bCrudHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/crud-helper\.service';)"; Replacement = 'import { CrudHelperService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLayoutHelperService\b)([\s\S]*?)[\s]*?\bLayoutHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/layout-helper\.service';)"; Replacement = 'import { LayoutHelperService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTableHelperService\b)([\s\S]*?)[\s]*?\bTableHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/table-helper\.service';)"; Replacement = 'import { TableHelperService } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFieldValidator\b)([\s\S]*?)[\s]*?\bFieldValidator\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/validators\/field\.validator';)"; Replacement = 'import { FieldValidator } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bJsonValidator\b)([\s\S]*?)[\s]*?\bJsonValidator\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/validators\/json\.validator';)"; Replacement = 'import { JsonValidator } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFRAMEWORK_VERSION\b)([\s\S]*?)[\s]*?\bFRAMEWORK_VERSION\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/framework-version';)"; Replacement = 'import { FRAMEWORK_VERSION } from ''@bia-team/bia-ng/shared''; import { $1$2'},
    
    # Update bia-domains imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLanguageOptionDas\b)([\s\S]*?)[\s]*?\bLanguageOptionDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/services\/language-option-das\.service';)"; Replacement = 'import { LanguageOptionDas } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bLanguageOptionsState\b)[\s\S]*?\bLanguageOptionsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';[\s\S]*)\bLanguageOptionsState\b"; Replacement = '$1DomainLanguageOptionsStore.LanguageOptionsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';[\s\S]*)\breducers\b"; Replacement = '$1DomainLanguageOptionsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetLanguagesState\b)[\s\S]*?\bgetLanguagesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';[\s\S]*)\bgetLanguagesState\b"; Replacement = '$1DomainLanguageOptionsStore.getLanguagesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetLanguageOptionsEntitiesState\b)[\s\S]*?\bgetLanguageOptionsEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';[\s\S]*)\bgetLanguageOptionsEntitiesState\b"; Replacement = '$1DomainLanguageOptionsStore.getLanguageOptionsEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllLanguageOptions\b)[\s\S]*?\bgetAllLanguageOptions\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';[\s\S]*)\bgetAllLanguageOptions\b"; Replacement = '$1DomainLanguageOptionsStore.getAllLanguageOptions'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetLanguageOptionById\b)[\s\S]*?\bgetLanguageOptionById\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';[\s\S]*)\bgetLanguageOptionById\b"; Replacement = '$1DomainLanguageOptionsStore.getLanguageOptionById'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLanguageOptionsState\b)([\s\S]*?)[\s]*?\bLanguageOptionsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';)"; Replacement = 'import { DomainLanguageOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';)"; Replacement = 'import { DomainLanguageOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetLanguagesState\b)([\s\S]*?)[\s]*?\bgetLanguagesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';)"; Replacement = 'import { DomainLanguageOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetLanguageOptionsEntitiesState\b)([\s\S]*?)[\s]*?\bgetLanguageOptionsEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';)"; Replacement = 'import { DomainLanguageOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllLanguageOptions\b)([\s\S]*?)[\s]*?\bgetAllLanguageOptions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';)"; Replacement = 'import { DomainLanguageOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetLanguageOptionById\b)([\s\S]*?)[\s]*?\bgetLanguageOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-option\.state';)"; Replacement = 'import { DomainLanguageOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDomainLanguageOptionsActions\b)([\s\S]*?)[\s]*?\bDomainLanguageOptionsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-options-actions';)"; Replacement = 'import { DomainLanguageOptionsActions } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLanguageOptionsEffects\b)([\s\S]*?)[\s]*?\bLanguageOptionsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-options-effects';)"; Replacement = 'import { LanguageOptionsEffects } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\blanguageOptionsAdapter\b)([\s\S]*?)[\s]*?\blanguageOptionsAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-options-reducer';)"; Replacement = 'import { languageOptionsAdapter } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bState\b)[\s\S]*?\bState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-options-reducer';[\s\S]*)\bState\b"; Replacement = '$1LanguageOptionState'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bState\b)([\s\S]*?)[\s]*?\bState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-options-reducer';)"; Replacement = 'import { LanguageOptionState } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)[\s\S]*?\bINIT_STATE\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-options-reducer';[\s\S]*)\bINIT_STATE\b"; Replacement = '$1LanguageOptionState'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)([\s\S]*?)[\s]*?\bINIT_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-options-reducer';)"; Replacement = 'import { INIT_LANGUAGEOPTION_STATE } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\blanguageOptionReducers\b)([\s\S]*?)[\s]*?\blanguageOptionReducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-options-reducer';)"; Replacement = 'import { languageOptionReducers } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetLanguageOptionById\b)([\s\S]*?)[\s]*?\bgetLanguageOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/store\/language-options-reducer';)"; Replacement = 'import { getLanguageOptionById } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLanguageOptionModule\b)([\s\S]*?)[\s]*?\bLanguageOptionModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/language-option\/language-option\.module';)"; Replacement = 'import { LanguageOptionModule } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLdapDomainDas\b)([\s\S]*?)[\s]*?\bLdapDomainDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/services\/ldap-domain-das\.service';)"; Replacement = 'import { LdapDomainDas } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLdapDomainService\b)([\s\S]*?)[\s]*?\bLdapDomainService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/services\/ldap-domain\.service';)"; Replacement = 'import { LdapDomainService } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDomainLdapDomainsActions\b)([\s\S]*?)[\s]*?\bDomainLdapDomainsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain-actions';)"; Replacement = 'import { DomainLdapDomainsActions } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLdapDomainsEffects\b)([\s\S]*?)[\s]*?\bLdapDomainsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain-effects';)"; Replacement = 'import { LdapDomainsEffects } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bldapDomainsAdapter\b)([\s\S]*?)[\s]*?\bldapDomainsAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain-reducer';)"; Replacement = 'import { ldapDomainsAdapter } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bLdapDomainState\b)[\s\S]*?\bLdapDomainState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';[\s\S]*)\bLdapDomainState\b"; Replacement = '$1DomainLdapDomainsStore.LdapDomainState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';[\s\S]*)\breducers\b"; Replacement = '$1DomainLdapDomainsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUsersState\b)[\s\S]*?\bgetUsersState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';[\s\S]*)\bgetUsersState\b"; Replacement = '$1DomainLdapDomainsStore.getUsersState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUsersEntitiesState\b)[\s\S]*?\bgetUsersEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';[\s\S]*)\bgetUsersEntitiesState\b"; Replacement = '$1DomainLdapDomainsStore.getUsersEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllLdapDomain\b)[\s\S]*?\bgetAllLdapDomain\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';[\s\S]*)\bgetAllLdapDomain\b"; Replacement = '$1DomainLdapDomainsStore.getAllLdapDomain'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLdapDomainState\b)([\s\S]*?)[\s]*?\bLdapDomainState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';)"; Replacement = 'import { DomainLdapDomainsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';)"; Replacement = 'import { DomainLdapDomainsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUsersState\b)([\s\S]*?)[\s]*?\bgetUsersState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';)"; Replacement = 'import { DomainLdapDomainsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUsersEntitiesState\b)([\s\S]*?)[\s]*?\bgetUsersEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';)"; Replacement = 'import { DomainLdapDomainsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllLdapDomain\b)([\s\S]*?)[\s]*?\bgetAllLdapDomain\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/store\/ldap-domain\.state';)"; Replacement = 'import { DomainLdapDomainsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLdapDomainModule\b)([\s\S]*?)[\s]*?\bLdapDomainModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/ldap-domain\/ldap-domain\.module';)"; Replacement = 'import { LdapDomainModule } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTypeOptionDas\b)([\s\S]*?)[\s]*?\bNotificationTypeOptionDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/services\/notification-type-option-das\.service';)"; Replacement = 'import { NotificationTypeOptionDas } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bNotificationTypeOptionsState\b)[\s\S]*?\bNotificationTypeOptionsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';[\s\S]*)\bNotificationTypeOptionsState\b"; Replacement = '$1DomainNotificationTypesStore.NotificationTypeOptionsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';[\s\S]*)\breducers\b"; Replacement = '$1DomainNotificationTypesStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetNotificationTypesState\b)[\s\S]*?\bgetNotificationTypesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';[\s\S]*)\bgetNotificationTypesState\b"; Replacement = '$1DomainNotificationTypesStore.getNotificationTypesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetNotificationTypeOptionsEntitiesState\b)[\s\S]*?\bgetNotificationTypeOptionsEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';[\s\S]*)\bgetNotificationTypeOptionsEntitiesState\b"; Replacement = '$1DomainNotificationTypesStore.getNotificationTypeOptionsEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllNotificationTypeOptions\b)[\s\S]*?\bgetAllNotificationTypeOptions\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';[\s\S]*)\bgetAllNotificationTypeOptions\b"; Replacement = '$1DomainNotificationTypesStore.getAllNotificationTypeOptions'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetNotificationTypeOptionById\b)[\s\S]*?\bgetNotificationTypeOptionById\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';[\s\S]*)\bgetNotificationTypeOptionById\b"; Replacement = '$1DomainNotificationTypesStore.getNotificationTypeOptionById'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTypeOptionsState\b)([\s\S]*?)[\s]*?\bNotificationTypeOptionsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';)"; Replacement = 'import { DomainNotificationTypesStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';)"; Replacement = 'import { DomainNotificationTypesStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationTypesState\b)([\s\S]*?)[\s]*?\bgetNotificationTypesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';)"; Replacement = 'import { DomainNotificationTypesStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationTypeOptionsEntitiesState\b)([\s\S]*?)[\s]*?\bgetNotificationTypeOptionsEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';)"; Replacement = 'import { DomainNotificationTypesStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllNotificationTypeOptions\b)([\s\S]*?)[\s]*?\bgetAllNotificationTypeOptions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';)"; Replacement = 'import { DomainNotificationTypesStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationTypeOptionById\b)([\s\S]*?)[\s]*?\bgetNotificationTypeOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-option\.state';)"; Replacement = 'import { DomainNotificationTypesStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDomainNotificationTypeOptionsActions\b)([\s\S]*?)[\s]*?\bDomainNotificationTypeOptionsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-options-actions';)"; Replacement = 'import { DomainNotificationTypeOptionsActions } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTypeOptionsEffects\b)([\s\S]*?)[\s]*?\bNotificationTypeOptionsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-options-effects';)"; Replacement = 'import { NotificationTypeOptionsEffects } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bnotificationTypeOptionsAdapter\b)([\s\S]*?)[\s]*?\bnotificationTypeOptionsAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-options-reducer';)"; Replacement = 'import { notificationTypeOptionsAdapter } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bState\b)[\s\S]*?\bState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-options-reducer';[\s\S]*)\bState\b"; Replacement = '$1NotificationTypeState'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bState\b)([\s\S]*?)[\s]*?\bState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-options-reducer';)"; Replacement = 'import { NotificationTypeState } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)[\s\S]*?\bINIT_STATE\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-options-reducer';[\s\S]*)\bINIT_STATE\b"; Replacement = '$1INIT_NOTIFICATIONTYPE_STATE'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)([\s\S]*?)[\s]*?\bINIT_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-options-reducer';)"; Replacement = 'import { INIT_NOTIFICATIONTYPE_STATE } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bnotificationTypeOptionReducers\b)([\s\S]*?)[\s]*?\bnotificationTypeOptionReducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-options-reducer';)"; Replacement = 'import { notificationTypeOptionReducers } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationTypeOptionById\b)([\s\S]*?)[\s]*?\bgetNotificationTypeOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/store\/notification-type-options-reducer';)"; Replacement = 'import { getNotificationTypeOptionById } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTypeOptionModule\b)([\s\S]*?)[\s]*?\bNotificationTypeOptionModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification-type-option\/notification-type-option\.module';)"; Replacement = 'import { NotificationTypeOptionModule } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRoleOptionDas\b)([\s\S]*?)[\s]*?\bRoleOptionDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/services\/role-option-das\.service';)"; Replacement = 'import { RoleOptionDas } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bRoleOptionsState\b)[\s\S]*?\bRoleOptionsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';[\s\S]*)\bRoleOptionsState\b"; Replacement = '$1DomainRoleOptionsStore.RoleOptionsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';[\s\S]*)\breducers\b"; Replacement = '$1DomainRoleOptionsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetRolesState\b)[\s\S]*?\bgetRolesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';[\s\S]*)\bgetRolesState\b"; Replacement = '$1DomainRoleOptionsStore.getRolesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetRoleOptionsEntitiesState\b)[\s\S]*?\bgetRoleOptionsEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';[\s\S]*)\bgetRoleOptionsEntitiesState\b"; Replacement = '$1DomainRoleOptionsStore.getRoleOptionsEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllRoleOptions\b)[\s\S]*?\bgetAllRoleOptions\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';[\s\S]*)\bgetAllRoleOptions\b"; Replacement = '$1DomainRoleOptionsStore.getAllRoleOptions'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetRoleOptionById\b)[\s\S]*?\bgetRoleOptionById\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';[\s\S]*)\bgetRoleOptionById\b"; Replacement = '$1DomainRoleOptionsStore.getRoleOptionById'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRoleOptionsState\b)([\s\S]*?)[\s]*?\bRoleOptionsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';)"; Replacement = 'import { DomainRoleOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';)"; Replacement = 'import { DomainRoleOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetRolesState\b)([\s\S]*?)[\s]*?\bgetRolesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';)"; Replacement = 'import { DomainRoleOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetRoleOptionsEntitiesState\b)([\s\S]*?)[\s]*?\bgetRoleOptionsEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';)"; Replacement = 'import { DomainRoleOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllRoleOptions\b)([\s\S]*?)[\s]*?\bgetAllRoleOptions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';)"; Replacement = 'import { DomainRoleOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetRoleOptionById\b)([\s\S]*?)[\s]*?\bgetRoleOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-option\.state';)"; Replacement = 'import { DomainRoleOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDomainRoleOptionsActions\b)([\s\S]*?)[\s]*?\bDomainRoleOptionsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-options-actions';)"; Replacement = 'import { DomainRoleOptionsActions } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRoleOptionsEffects\b)([\s\S]*?)[\s]*?\bRoleOptionsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-options-effects';)"; Replacement = 'import { RoleOptionsEffects } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\broleOptionsAdapter\b)([\s\S]*?)[\s]*?\broleOptionsAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-options-reducer';)"; Replacement = 'import { roleOptionsAdapter } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bState\b)[\s\S]*?\bState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-options-reducer';[\s\S]*)\bState\b"; Replacement = '$1RoleOptionState'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bState\b)([\s\S]*?)[\s]*?\bState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-options-reducer';)"; Replacement = 'import { RoleOptionState } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)[\s\S]*?\bINIT_STATE\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-options-reducer';[\s\S]*)\bINIT_STATE\b"; Replacement = '$1INIT_ROLEOPTION_STATE'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)([\s\S]*?)[\s]*?\bINIT_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-options-reducer';)"; Replacement = 'import { INIT_ROLEOPTION_STATE } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\broleOptionReducers\b)([\s\S]*?)[\s]*?\broleOptionReducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-options-reducer';)"; Replacement = 'import { roleOptionReducers } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetRoleOptionById\b)([\s\S]*?)[\s]*?\bgetRoleOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/store\/role-options-reducer';)"; Replacement = 'import { getRoleOptionById } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRoleOptionModule\b)([\s\S]*?)[\s]*?\bRoleOptionModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/role-option\/role-option\.module';)"; Replacement = 'import { RoleOptionModule } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamOptionDas\b)([\s\S]*?)[\s]*?\bTeamOptionDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/services\/team-option-das\.service';)"; Replacement = 'import { TeamOptionDas } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bTeamOptionsState\b)[\s\S]*?\bTeamOptionsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';[\s\S]*)\bTeamOptionsState\b"; Replacement = '$1DomainTeamOptionsStore.RoleOptionsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';[\s\S]*)\breducers\b"; Replacement = '$1DomainTeamOptionsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetTeamsState\b)[\s\S]*?\bgetTeamsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';[\s\S]*)\bgetTeamsState\b"; Replacement = '$1DomainTeamOptionsStore.getTeamsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetTeamOptionsEntitiesState\b)[\s\S]*?\bgetTeamOptionsEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';[\s\S]*)\bgetTeamOptionsEntitiesState\b"; Replacement = '$1DomainTeamOptionsStore.getTeamOptionsEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllTeamOptions\b)[\s\S]*?\bgetAllTeamOptions\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';[\s\S]*)\bgetAllTeamOptions\b"; Replacement = '$1DomainTeamOptionsStore.getAllTeamOptions'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetTeamOptionById\b)[\s\S]*?\bgetTeamOptionById\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';[\s\S]*)\bgetTeamOptionById\b"; Replacement = '$1DomainTeamOptionsStore.getTeamOptionById'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamOptionsState\b)([\s\S]*?)[\s]*?\bTeamOptionsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';)"; Replacement = 'import { DomainTeamOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';)"; Replacement = 'import { DomainTeamOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetTeamsState\b)([\s\S]*?)[\s]*?\bgetTeamsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';)"; Replacement = 'import { DomainTeamOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetTeamOptionsEntitiesState\b)([\s\S]*?)[\s]*?\bgetTeamOptionsEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';)"; Replacement = 'import { DomainTeamOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllTeamOptions\b)([\s\S]*?)[\s]*?\bgetAllTeamOptions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';)"; Replacement = 'import { DomainTeamOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetTeamOptionById\b)([\s\S]*?)[\s]*?\bgetTeamOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-option\.state';)"; Replacement = 'import { DomainTeamOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDomainTeamOptionsActions\b)([\s\S]*?)[\s]*?\bDomainTeamOptionsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-options-actions';)"; Replacement = 'import { DomainTeamOptionsActions } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamOptionsEffects\b)([\s\S]*?)[\s]*?\bTeamOptionsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-options-effects';)"; Replacement = 'import { TeamOptionsEffects } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bteamOptionsAdapter\b)([\s\S]*?)[\s]*?\bteamOptionsAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-options-reducer';)"; Replacement = 'import { teamOptionsAdapter } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bState\b)[\s\S]*?\bState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-options-reducer';[\s\S]*)\bState\b"; Replacement = '$1TeamOptionState'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bState\b)([\s\S]*?)[\s]*?\bState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-options-reducer';)"; Replacement = 'import { TeamOptionState } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)[\s\S]*?\bINIT_STATE\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-options-reducer';[\s\S]*)\bINIT_STATE\b"; Replacement = '$1INIT_TEAMOPTION_STATE'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)([\s\S]*?)[\s]*?\bINIT_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-options-reducer';)"; Replacement = 'import { INIT_TEAMOPTION_STATE } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bteamOptionReducers\b)([\s\S]*?)[\s]*?\bteamOptionReducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-options-reducer';)"; Replacement = 'import { teamOptionReducers } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetTeamOptionById\b)([\s\S]*?)[\s]*?\bgetTeamOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/store\/team-options-reducer';)"; Replacement = 'import { getTeamOptionById } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamOptionModule\b)([\s\S]*?)[\s]*?\bTeamOptionModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team-option\/team-option\.module';)"; Replacement = 'import { TeamOptionModule } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserOptionDas\b)([\s\S]*?)[\s]*?\bUserOptionDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/services\/user-option-das\.service';)"; Replacement = 'import { UserOptionDas } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bUserOptionsState\b)[\s\S]*?\bUserOptionsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';[\s\S]*)\bUserOptionsState\b"; Replacement = '$1DomainUserOptionsStore.UserOptionsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';[\s\S]*)\breducers\b"; Replacement = '$1DomainUserOptionsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUsersState\b)[\s\S]*?\bgetUsersState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';[\s\S]*)\bgetUsersState\b"; Replacement = '$1DomainUserOptionsStore.getUsersState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUserOptionsEntitiesState\b)[\s\S]*?\bgetUserOptionsEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';[\s\S]*)\bgetUserOptionsEntitiesState\b"; Replacement = '$1DomainUserOptionsStore.getUserOptionsEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllUserOptions\b)[\s\S]*?\bgetAllUserOptions\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';[\s\S]*)\bgetAllUserOptions\b"; Replacement = '$1DomainUserOptionsStore.getAllUserOptions'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUserOptionById\b)[\s\S]*?\bgetUserOptionById\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';[\s\S]*)\bgetUserOptionById\b"; Replacement = '$1DomainUserOptionsStore.getUserOptionById'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetLastUsersAdded\b)[\s\S]*?\bgetLastUsersAdded\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';[\s\S]*)\bgetLastUsersAdded\b"; Replacement = '$1DomainUserOptionsStore.getLastUsersAdded'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserOptionsState\b)([\s\S]*?)[\s]*?\bUserOptionsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';)"; Replacement = 'import { DomainUserOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';)"; Replacement = 'import { DomainUserOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUsersState\b)([\s\S]*?)[\s]*?\bgetUsersState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';)"; Replacement = 'import { DomainUserOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUserOptionsEntitiesState\b)([\s\S]*?)[\s]*?\bgetUserOptionsEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';)"; Replacement = 'import { DomainUserOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllUserOptions\b)([\s\S]*?)[\s]*?\bgetAllUserOptions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';)"; Replacement = 'import { DomainUserOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUserOptionById\b)([\s\S]*?)[\s]*?\bgetUserOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';)"; Replacement = 'import { DomainUserOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetLastUsersAdded\b)([\s\S]*?)[\s]*?\bgetLastUsersAdded\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-option\.state';)"; Replacement = 'import { DomainUserOptionsStore } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDomainUserOptionsActions\b)([\s\S]*?)[\s]*?\bDomainUserOptionsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-options-actions';)"; Replacement = 'import { DomainUserOptionsActions } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserOptionsEffects\b)([\s\S]*?)[\s]*?\bUserOptionsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-options-effects';)"; Replacement = 'import { UserOptionsEffects } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\buserOptionsAdapter\b)([\s\S]*?)[\s]*?\buserOptionsAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-options-reducer';)"; Replacement = 'import { userOptionsAdapter } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bState\b)[\s\S]*?\bState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-options-reducer';[\s\S]*)\bState\b"; Replacement = '$1UserOptionState'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bState\b)([\s\S]*?)[\s]*?\bState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-options-reducer';)"; Replacement = 'import { UserOptionState } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)[\s\S]*?\bINIT_STATE\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-options-reducer';[\s\S]*)\bINIT_STATE\b"; Replacement = '$1INIT_USEROPTION_STATE'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)([\s\S]*?)[\s]*?\bINIT_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-options-reducer';)"; Replacement = 'import { INIT_USEROPTION_STATE } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\buserOptionReducers\b)([\s\S]*?)[\s]*?\buserOptionReducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-options-reducer';)"; Replacement = 'import { userOptionReducers } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUserOptionById\b)([\s\S]*?)[\s]*?\bgetUserOptionById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/store\/user-options-reducer';)"; Replacement = 'import { getUserOptionById } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserOptionModule\b)([\s\S]*?)[\s]*?\bUserOptionModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/user-option\/user-option\.module';)"; Replacement = 'import { UserOptionModule } from ''@bia-team/bia-ng/domains''; import { $1$2'},
    
    # Update bia-features imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBackgroundTaskAdminComponent\b)([\s\S]*?)[\s]*?\bBackgroundTaskAdminComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/background-task\/views\/background-task-admin\/background-task-admin\.component';)"; Replacement = 'import { BackgroundTaskAdminComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBackgroundTaskReadOnlyComponent\b)([\s\S]*?)[\s]*?\bBackgroundTaskReadOnlyComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/background-task\/views\/background-task-read-only\/background-task-read-only\.component';)"; Replacement = 'import { BackgroundTaskReadOnlyComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaBackgroundTaskModule\b)([\s\S]*?)[\s]*?\bBiaBackgroundTaskModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/background-task\/background-task\.module';)"; Replacement = 'import { BiaBackgroundTaskModule } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationFormComponent\b)([\s\S]*?)[\s]*?\bNotificationFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/components\/notification-form\/notification-form\.component';)"; Replacement = 'import { NotificationFormComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationListItem\b)([\s\S]*?)[\s]*?\bNotificationListItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/model\/notification-list-item';)"; Replacement = 'import { NotificationListItem } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bnotificationFieldsConfiguration\b)([\s\S]*?)[\s]*?\bnotificationFieldsConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/model\/notification-list-item';)"; Replacement = 'import { notificationFieldsConfiguration } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotification\b)([\s\S]*?)[\s]*?\bNotification\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/model\/notification';)"; Replacement = 'import { Notification } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTranslation\b)([\s\S]*?)[\s]*?\bNotificationTranslation\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/model\/notification';)"; Replacement = 'import { NotificationTranslation } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTeam\b)([\s\S]*?)[\s]*?\bNotificationTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/model\/notification';)"; Replacement = 'import { NotificationTeam } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationData\b)([\s\S]*?)[\s]*?\bNotificationData\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/model\/notification';)"; Replacement = 'import { NotificationData } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationDas\b)([\s\S]*?)[\s]*?\bNotificationDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/services\/notification-das\.service';)"; Replacement = 'import { NotificationDas } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationOptionsService\b)([\s\S]*?)[\s]*?\bNotificationOptionsService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/services\/notification-options\.service';)"; Replacement = 'import { NotificationOptionsService } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationsSignalRService\b)([\s\S]*?)[\s]*?\bNotificationsSignalRService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/services\/notification-signalr\.service';)"; Replacement = 'import { NotificationsSignalRService } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationService\b)([\s\S]*?)[\s]*?\bNotificationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/services\/notification\.service';)"; Replacement = 'import { NotificationService } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureNotificationsStore\b)([\s\S]*?)[\s]*?\bFeatureNotificationsStore\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notification\.state';)"; Replacement = 'import { FeatureNotificationsStore } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureNotificationsActions\b)([\s\S]*?)[\s]*?\bFeatureNotificationsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notifications-actions';)"; Replacement = 'import { FeatureNotificationsActions } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationsEffects\b)([\s\S]*?)[\s]*?\bNotificationsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notifications-effects';)"; Replacement = 'import { NotificationsEffects } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bnotificationsAdapter\b)([\s\S]*?)[\s]*?\bnotificationsAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notifications-reducer';)"; Replacement = 'import { notificationsAdapter } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bState\b)[\s\S]*?\bState\b[\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notifications-reducer';[\s\S]*)\bState\b"; Replacement = '$1NotificationState'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bState\b)([\s\S]*?)[\s]*?\bState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notifications-reducer';)"; Replacement = 'import { NotificationState } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)[\s\S]*?\bINIT_STATE\b[\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notifications-reducer';[\s\S]*)\bINIT_STATE\b"; Replacement = '$1INIT_NOTIFICATION_STATE'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)([\s\S]*?)[\s]*?\bINIT_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notifications-reducer';)"; Replacement = 'import { INIT_NOTIFICATION_STATE } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bnotificationReducers\b)([\s\S]*?)[\s]*?\bnotificationReducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notifications-reducer';)"; Replacement = 'import { notificationReducers } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationById\b)([\s\S]*?)[\s]*?\bgetNotificationById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/store\/notifications-reducer';)"; Replacement = 'import { getNotificationById } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bnotificationCRUDConfiguration\b)([\s\S]*?)[\s]*?\bnotificationCRUDConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/notification\.constants';)"; Replacement = 'import { notificationCRUDConfiguration } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaNotificationModule\b)([\s\S]*?)[\s]*?\bBiaNotificationModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/notifications\/notification\.module';)"; Replacement = 'import { BiaNotificationModule } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFormComponent\b)([\s\S]*?)[\s]*?\bUserFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/components\/user-form\/user-form\.component';)"; Replacement = 'import { UserFormComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserTableComponent\b)([\s\S]*?)[\s]*?\bUserTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/components\/user-table\/user-table\.component';)"; Replacement = 'import { UserTableComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserTeamsComponent\b)([\s\S]*?)[\s]*?\bUserTeamsComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/components\/user-teams\/user-teams\.component';)"; Replacement = 'import { UserFormComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserTeam\b)([\s\S]*?)[\s]*?\bUserTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/model\/user-team';)"; Replacement = 'import { UserTeam } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUser\b)([\s\S]*?)[\s]*?\bUser\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/model\/user';)"; Replacement = 'import { User } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\buserFieldsConfiguration\b)([\s\S]*?)[\s]*?\buserFieldsConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/model\/user';)"; Replacement = 'import { userFieldsConfiguration } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserDas\b)([\s\S]*?)[\s]*?\bUserDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/services\/user-das\.service';)"; Replacement = 'import { UserDas } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserOptionsService\b)([\s\S]*?)[\s]*?\bUserOptionsService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/services\/user-options\.service';)"; Replacement = 'import { UserOptionsService } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserService\b)([\s\S]*?)[\s]*?\bUserService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/services\/user\.service';)"; Replacement = 'import { UserService } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureUsersStore\b)([\s\S]*?)[\s]*?\bFeatureUsersStore\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/user\.state';)"; Replacement = 'import { FeatureUsersStore } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureUsersActions\b)([\s\S]*?)[\s]*?\bFeatureUsersActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/users-actions';)"; Replacement = 'import { FeatureUsersActions } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUsersEffects\b)([\s\S]*?)[\s]*?\bUsersEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/users-effects';)"; Replacement = 'import { UsersEffects } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\busersAdapter\b)([\s\S]*?)[\s]*?\busersAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/users-reducer';)"; Replacement = 'import { usersAdapter } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bState\b)[\s\S]*?\bState\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/users-reducer';[\s\S]*)\bState\b"; Replacement = '$1UserState'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bState\b)([\s\S]*?)[\s]*?\bState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/users-reducer';)"; Replacement = 'import { UserState } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)[\s\S]*?\bINIT_STATE\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/users-reducer';[\s\S]*)\bINIT_STATE\b"; Replacement = '$1INIT_USER_STATE'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bINIT_STATE\b)([\s\S]*?)[\s]*?\bINIT_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/users-reducer';)"; Replacement = 'import { INIT_USER_STATE } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\buserReducers\b)([\s\S]*?)[\s]*?\buserReducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/users-reducer';)"; Replacement = 'import { userReducers } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUserById\b)([\s\S]*?)[\s]*?\bgetUserById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/store\/users-reducer';)"; Replacement = 'import { getUserById } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserEditComponent\b)([\s\S]*?)[\s]*?\bUserEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/views\/user-edit\/user-edit\.component';)"; Replacement = 'import { UserEditComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserImportComponent\b)([\s\S]*?)[\s]*?\bUserImportComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/views\/user-import\/user-import\.component';)"; Replacement = 'import { UserImportComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserItemComponent\b)([\s\S]*?)[\s]*?\bUserItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/views\/user-item\/user-item\.component';)"; Replacement = 'import { UserItemComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserNewComponent\b)([\s\S]*?)[\s]*?\bUserNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/views\/user-new\/user-new\.component';)"; Replacement = 'import { UserNewComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUsersIndexComponent\b)([\s\S]*?)[\s]*?\bUsersIndexComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/views\/users-index\/users-index\.component';)"; Replacement = 'import { UsersIndexComponent } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\buserCRUDConfiguration\b)([\s\S]*?)[\s]*?\buserCRUDConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/user\.constants';)"; Replacement = 'import { userCRUDConfiguration } from ''@bia-team/bia-ng/features''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUserModule\b)([\s\S]*?)[\s]*?\bBiaUserModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users\/user\.module';)"; Replacement = 'import { BiaUserModule } from ''@bia-team/bia-ng/features''; import { $1$2'},
    
    # Some permissions moved to bia-permissions in bia-ng/core
    @{Pattern = "\bPermission\b\.\bBackground_Task_Admin\b"; Replacement = 'BiaPermission.Background_Task_Admin'},
    @{Pattern = "\bPermission\b\.\bBackground_Task_Read_Only\b"; Replacement = 'BiaPermission.Background_Task_Read_Only'},
    @{Pattern = "\bPermission\b\.\bNotification_Create\b"; Replacement = 'BiaPermission.Notification_Create'},
    @{Pattern = "\bPermission\b\.\bNotification_List_Access\b"; Replacement = 'BiaPermission.Notification_List_Access'},
    @{Pattern = "\bPermission\b\.\bNotification_Delete\b"; Replacement = 'BiaPermission.Notification_Delete'},
    @{Pattern = "\bPermission\b\.\bNotification_Read\b"; Replacement = 'BiaPermission.Notification_Read'},
    @{Pattern = "\bPermission\b\.\bNotification_Update\b"; Replacement = 'BiaPermission.Notification_Update'},
    @{Pattern = "\bPermission\b\.\bRoles_List\b"; Replacement = 'BiaPermission.Roles_List'},
    @{Pattern = "\bPermission\b\.\bUser_Add\b"; Replacement = 'BiaPermission.User_Add'},
    @{Pattern = "\bPermission\b\.\bUser_Delete\b"; Replacement = 'BiaPermission.User_Delete'},
    @{Pattern = "\bPermission\b\.\bUser_Save\b"; Replacement = 'BiaPermission.User_Save'},
    @{Pattern = "\bPermission\b\.\bUser_List\b"; Replacement = 'BiaPermission.User_List'},
    @{Pattern = "\bPermission\b\.\bUser_ListAD\b"; Replacement = 'BiaPermission.User_ListAD'},
    @{Pattern = "\bPermission\b\.\bUser_List_Access\b"; Replacement = 'BiaPermission.User_List_Access'},
    @{Pattern = "\bPermission\b\.\bUser_Sync\b"; Replacement = 'BiaPermission.User_Sync'},
    @{Pattern = "\bPermission\b\.\bUser_UpdateRoles\b"; Replacement = 'BiaPermission.User_UpdateRoles'},
    @{Pattern = "\bPermission\b\.\bLdapDomains_List\b"; Replacement = 'BiaPermission.LdapDomains_List'},
    @{Pattern = "\bPermission\b\.\bView_List\b"; Replacement = 'BiaPermission.View_List'},
    @{Pattern = "\bPermission\b\.\bView_AddUserView\b"; Replacement = 'BiaPermission.View_AddUserView'},
    @{Pattern = "\bPermission\b\.\bView_AddTeamViewSuffix\b"; Replacement = 'BiaPermission.View_AddTeamViewSuffix'},
    @{Pattern = "\bPermission\b\.\bView_UpdateUserView\b"; Replacement = 'BiaPermission.View_UpdateUserView'},
    @{Pattern = "\bPermission\b\.\bView_UpdateTeamViewSuffix\b"; Replacement = 'BiaPermission.View_UpdateTeamViewSuffix'},
    @{Pattern = "\bPermission\b\.\bView_DeleteUserView\b"; Replacement = 'BiaPermission.View_DeleteUserView'},
    @{Pattern = "\bPermission\b\.\bView_DeleteTeamView\b"; Replacement = 'BiaPermission.View_DeleteTeamView'},
    @{Pattern = "\bPermission\b\.\bView_SetDefaultUserView\b"; Replacement = 'BiaPermission.View_SetDefaultUserView'},
    @{Pattern = "\bPermission\b\.\bView_SetDefaultTeamViewSuffix\b"; Replacement = 'BiaPermission.View_SetDefaultTeamViewSuffix'},
    @{Pattern = "\bPermission\b\.\bView_AssignToTeamSuffix\b"; Replacement = 'BiaPermission.View_AssignToTeamSuffix'},
    @{Pattern = "\bPermission\b\.\bImpersonation_Connection_Rights\b"; Replacement = 'BiaPermission.Impersonation_Connection_Rights'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPermission\b)([\s\S]*?)[\s]*?\bPermission\b[,]?([\s\S]*?} from '[\s\S]*?\/permission';)"; Replacement = 'import { BiaPermission } from ''@bia-team/bia-ng/core''; import { $1Permission$2'; Requirement = '\bBiaPermission\b\.'}
    
    # Clean empty imports
    @{Pattern = "import {[\s]*?} from '[\S]*?';"; Replacement = ''},
    
    # update components templates and scss coming from bia
    @{Pattern = "((templateUrl:|styleUrls:\s*\[|styleUrl:)[\s]*'[\S]*\/)shared\/bia-shared\/([\S]*\.component\.(html|scss)')"; Replacement = '$1../../node_modules/@bia-team/bia-ng/templates/$3'}
    @{Pattern = "((templateUrl:|styleUrls:\s*\[|styleUrl:)[\s]*'[\S]*\/)bia-features\/([\S]*\.component\.(html|scss)')"; Replacement = '$1../../../node_modules/@bia-team/bia-ng/templates/features/$3'}
    )

  $extensions = "*.ts"
  Invoke-ReplacementsInFiles -RootPath $SourceFrontEnd -Replacements $replacementsTS -Extensions $extensions
}

function Get-FileText([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Fichier introuvable: $path" }
  return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Set-FileText([string]$path, [string]$text, [switch]$WhatIfOnly) {
  if ($WhatIfOnly) { Write-Host "WHATIF: Écriture ignorée -> $path" -ForegroundColor Yellow; return }
  [System.IO.File]::WriteAllText($path, $text, [System.Text.Encoding]::UTF8)
}

function Update-TeamConfigCs {
  param(
    [Parameter(Mandatory)][string] $CsText,
    [Parameter(Mandatory)][array]  $Teams
  )

  function Get-Eol([string]$text) { if ($text -match "`r`n") { "`r`n" } else { "`n" } }

  
  $mDecl = [regex]::Match($CsText, 'Config\s*=\s*new[\s\S]*?\{')
  if (-not $mDecl.Success) {
    Write-Host "Declaration 'Config = new … {' not found." -ForegroundColor Yellow
    return $CsText
  }
  $listOpen = $mDecl.Index + $mDecl.Length - 1

  $k = $listOpen; $brace = 0
  do {
    if ($CsText[$k] -eq '{') { $brace++ }
    elseif ($CsText[$k] -eq '}') { $brace-- }
    $k++
  } while ($k -lt $CsText.Length -and $brace -gt 0)
  $listClose = $k - 1

  $listStart = $listOpen + 1
  $listText  = $CsText.Substring($listStart, $listClose - $listStart)

  $updatedList = $listText
  foreach ($team in $Teams) {
    $teamId   = [regex]::Escape($team.TeamTypeId)
    $rxTeam   = [regex]"TeamTypeId\s*=\s*\(int\)\s*TeamTypeId\.$teamId\b"
    $searchFrom = 0

    while ($true) {
      $mTeam = $rxTeam.Match($updatedList, $searchFrom)
      if (-not $mTeam.Success) { break }

      $pos = $mTeam.Index
      $i = $pos; $depth = 0; $openIdx = -1
      while ($i -ge 0) {
        $ch = $updatedList[$i]
        if ($ch -eq '}') { $depth++ }
        elseif ($ch -eq '{') {
          if ($depth -eq 0) { $openIdx = $i; break }
          $depth--
        }
        $i--
      }
      if ($openIdx -lt 0) { $searchFrom = $mTeam.Index + $mTeam.Length; continue }

      $segStart = [Math]::Max(0, $openIdx - 400)
      $seg      = $updatedList.Substring($segStart, $openIdx - $segStart)
      $mNew     = [regex]::Matches($seg, 'new\s*([A-Za-z_][A-Za-z0-9_<>.]*)?\s*(?:\(\s*\))?\s*$', 'RightToLeft')
      if ($mNew.Count -eq 0) { $searchFrom = $mTeam.Index + $mTeam.Length; continue }
      $typeName = $mNew[0].Groups[1].Value
      if ($typeName -and ($typeName -notmatch '^BiaTeamConfig(\s*<[^>]+>\s*)?$')) { $searchFrom = $mTeam.Index + $mTeam.Length; continue }
      $backScan = $updatedList.Substring([Math]::Max(0,$openIdx-800), [Math]::Min(800,$openIdx))
      if ($backScan -match '(Children|Parents)\s*=\s*new[\s\S]*$') { $searchFrom = $mTeam.Index + $mTeam.Length; continue }

      $j = $openIdx; $b2 = 0
      do {
        if ($updatedList[$j] -eq '{') { $b2++ }
        elseif ($updatedList[$j] -eq '}') { $b2-- }
        $j++
      } while ($j -lt $updatedList.Length -and $b2 -gt 0)
      $closeIdx = $j - 1

      $bodyStart = $openIdx + 1
      $bodyLen   = $closeIdx - $bodyStart
      $body      = $updatedList.Substring($bodyStart, $bodyLen)

      $eol = Get-Eol $body
      $mAdmin = [regex]::Match($body, '(?m)^(?<indent>[ \t]*)AdminRoleIds\s*=\s*\[(?:[\s\S]*?)\],[ \t]*\r?\n')
      $insertIdx = -1
      $indent    = ''
      if ($mAdmin.Success) {
        $insertIdx = $mAdmin.Index + $mAdmin.Length 
        $indent    = $mAdmin.Groups['indent'].Value
      } else {
        $mTeamLine = [regex]::Match($body, '(?m)^(?<indent>[ \t]*)TeamTypeId\s*=.*?,[ \t]*\r?\n')
        if ($mTeamLine.Success) {
          $insertIdx = $mTeamLine.Index + $mTeamLine.Length
          $indent    = $mTeamLine.Groups['indent'].Value
        } else {
          $insertIdx = 0
          $indent    = '                '
        }
      }

      $map = [ordered]@{
        RoleMode                = 'RoleMode'
        DisplayInHeader         = 'DisplayInHeader'
        DisplayOne              = 'DisplayOne'
        DisplayAlways           = 'DisplayAlways'
        TeamSelectionCanBeEmpty = 'TeamSelectionCanBeEmpty'
        Label                   = 'Label'
      }

      $toInsert = New-Object System.Text.StringBuilder
      foreach ($k in $map.Keys) {
        $val = To-CsValue -propName $k -tsValue $team.$k
        if ($null -eq $val) { continue }
        if ([regex]::IsMatch($body, "(?m)^\s*$([regex]::Escape($map[$k]))\s*=")) { continue }
        [void]$toInsert.Append($indent + $map[$k] + " = " + $val + "," + $eol)
      }

      if ($toInsert.Length -gt 0) {
        $body = $body.Insert($insertIdx, $toInsert.ToString())
        $updatedList = $updatedList.Substring(0,$bodyStart) + $body + $updatedList.Substring($closeIdx)
        $searchFrom  = $bodyStart + $body.Length
      } else {
        $searchFrom = $mTeam.Index + $mTeam.Length
      }
    }
  }

  return $CsText.Substring(0,$listStart) + $updatedList + $CsText.Substring($listClose)
}

function Remove-TeamsFromTs {
  param(
    [Parameter(Mandatory)][string] $TsText
  )
  $removed = $TsText
  $patternWithCommaBefore = [regex]'(?s),\s*teams\s*:\s*\[[\s\S]*?\]'
  $patternStandalone      = [regex]'(?s)teams\s*:\s*\[[\s\S]*?\]\s*,?'

  if ($patternWithCommaBefore.IsMatch($removed)) {
    $removed = $patternWithCommaBefore.Replace($removed, '')
  } elseif ($patternStandalone.IsMatch($removed)) {
    $removed = $patternStandalone.Replace($removed, '')
  } else {
    Write-Host "No 'teams' section to delete" -ForegroundColor Yellow
  }

  $removed = [regex]::Replace($removed, '(?m),\s*,', ', ')

  return $removed
}

function To-CsValue {
  param(
    [string]$propName,
    [string]$tsValue
  )
  if ($null -eq $tsValue -or $tsValue -eq '') { return $null }

  switch ($propName) {
    'RoleMode' {
      # TS: RoleMode.AllRoles -> C#: <EnumNamespace>.RoleMode.AllRoles
      if ($tsValue -match '^\s*RoleMode\.(\w+)\s*$') {
        return "BIA.Net.Core.Common.Enum.RoleMode.$($Matches[1])"
      }
      return $tsValue
    }
    'DisplayInHeader' { return ($tsValue -replace '^\s*true\s*$', 'true'  -replace '^\s*false\s*$', 'false') }
    'DisplayOne'      { return ($tsValue -replace '^\s*true\s*$', 'true'  -replace '^\s*false\s*$', 'false') }
    'DisplayAlways'   { return ($tsValue -replace '^\s*true\s*$', 'true'  -replace '^\s*false\s*$', 'false') }
    'TeamSelectionCanBeEmpty' { return ($tsValue -replace '^\s*true\s*$', 'true'  -replace '^\s*false\s*$', 'false') }
    'Label' {
      # TS: 'myTeam.headerLabel' | "myTeam.headerLabel" -> C#: "myTeam.headerLabel"
      $unq = $tsValue.Trim()
      if ($unq.StartsWith("'") -or $unq.StartsWith('"')) {
        $unq = $unq.Trim("'`"")
      }
      return '"' + $unq + '"'
    }
    default { return $tsValue }
  }
}

function Parse-TeamsFromTs {
  param(
    [Parameter(Mandatory)][string] $TsText
  )
  # 1) Localiser le tableau teams [...]
  $teamsSectionRegex = [regex]'teams\s*:\s*\[(?<array>[\s\S]*?)\]'
  $m = $teamsSectionRegex.Match($TsText)
  if (-not $m.Success) {
    Write-Host "No 'teams' section found in all-environments.ts" -ForegroundColor Yellow
    return @()
  }
  $teamsArrayText = $m.Groups['array'].Value

  # 2) Extraire chaque objet { teamTypeId: TeamTypeId.Xxx, ... }
  $teamObjectRegex = [regex]'\{\s*teamTypeId\s*:\s*TeamTypeId\.(?<id>\w+)\s*,(?<body>[\s\S]*?)\}'
  $teams = New-Object System.Collections.Generic.List[object]

  foreach ($tm in $teamObjectRegex.Matches($teamsArrayText)) {
    $id = $tm.Groups['id'].Value
    $body = $tm.Groups['body'].Value

    # helpers pour extraire une propriété "clé: valeur,"
    function Get-TsProp {
      param([string]$source, [string]$propName)
      $r = [regex]::new("(?m)^\s*$([regex]::Escape($propName))\s*:\s*(?<val>[^,\r\n]+)\s*,?")
      $mm = $r.Match($source)
      if ($mm.Success) { return $mm.Groups['val'].Value.Trim() }
      return $null
    }

    $obj = [pscustomobject]@{
      TeamTypeId              = $id
      RoleMode                = (Get-TsProp -source $body -propName 'roleMode')               # e.g. RoleMode.AllRoles
      DisplayInHeader         = (Get-TsProp -source $body -propName 'inHeader')               # true/false
      DisplayOne              = (Get-TsProp -source $body -propName 'displayOne')
      DisplayAlways           = (Get-TsProp -source $body -propName 'displayAlways')
      TeamSelectionCanBeEmpty = (Get-TsProp -source $body -propName 'teamSelectionCanBeEmpty')
      Label                   = (Get-TsProp -source $body -propName 'label')                  # 'myTeam.headerLabel'
    }
    $teams.Add($obj) | Out-Null
  }

  return $teams
}

function Invoke-MigrationTeamConfig {
  try {
    Write-Host "Migration Team Config started" -ForegroundColor Cyan

    $TsFilePath = Get-ChildItem -Path $SourceFrontEnd -Recurse -ErrorAction SilentlyContinue -Filter 'all-environments.ts' -File | Select-Object -ExpandProperty FullName -First 1
    $CsFilePath = Get-ChildItem -Path $SourceBackEnd  -Recurse -ErrorAction SilentlyContinue -Filter 'TeamConfig.cs' -File | Select-Object -ExpandProperty FullName -First 1

    if (-not $TsFilePath) { Write-Host "File 'all-environments.ts' not found under $SourceFrontEnd" -ForegroundColor Red; return }
    if (-not $CsFilePath) { Write-Host "File 'TeamConfig.cs' not found under $SourceBackEnd" -ForegroundColor Red; return }
    if (-not (Test-Path -LiteralPath $TsFilePath)) { Write-Host "Path not found: $TsFilePath" -ForegroundColor Red; return }
    if (-not (Test-Path -LiteralPath $CsFilePath)) { Write-Host "Path not found: $CsFilePath" -ForegroundColor Red; return }

    Write-Host "TS file: $TsFilePath" -ForegroundColor DarkCyan
    Write-Host "CS file: $CsFilePath" -ForegroundColor DarkCyan

    $tsText = Get-FileText $TsFilePath
    $csText = Get-FileText $CsFilePath

    $teams = Parse-TeamsFromTs -TsText $tsText
    if ($teams.Count -eq 0) { Write-Host "No team to migrate." -ForegroundColor Yellow; return }
    Write-Host ("Teams found: " + (($teams | ForEach-Object { $_.TeamTypeId } | Sort-Object -Unique) -join ', '))

    $csUpdated = Update-TeamConfigCs -CsText $csText -Teams $teams
    $tsUpdated = Remove-TeamsFromTs -TsText $tsText

    if ($csUpdated -ne $csText) { Set-FileText -path $CsFilePath -text $csUpdated } else { Write-Host "TeamConfig.cs unchanged." -ForegroundColor Yellow }
    if ($tsUpdated -ne $tsText) { Set-FileText -path $TsFilePath -text $tsUpdated } else { Write-Host "all-environments.ts unchanged." -ForegroundColor Yellow }
  }
  catch {
    Write-Error $_
  }
  finally {
    Write-Host "Migration Team Config finished" -ForegroundColor Cyan
  }
}

function Invoke-DynamicLayoutTransform {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Files
    )

    # Save original dir
    $orig = Get-Location

    # Verify Node
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Error "Node.js not found on PATH. Install Node and re-run."
        exit 1
    }

    # Create temp dir (installed once)
    $temp = Join-Path $env:TEMP ("ng-route-transformer-" + [guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $temp | Out-Null
    Set-Location $temp

    # package.json (ES module)
@"
{
  "type": "module",
  "private": true
}
"@ | Out-File -FilePath (Join-Path $temp "package.json") -Encoding utf8

    Write-Host "Installing typescript (local, once)..."
    npm install typescript --no-audit --no-fund --silent --no-progress | Out-Null

    # Write transformer.mjs (same transformer logic as your last working version, but main() loops over args)
    $transformer = @'
// transformer.mjs
import fs from "fs";
import ts from "typescript";
import path from "path";

function extractFeatureFromConstantsFile(moduleFilename) {
  const dir = path.dirname(moduleFilename);

  let files;
  try {
    files = fs.readdirSync(dir).filter(f => f.endsWith(".constants.ts"));
  } catch {
    return null;
  }

  for (const file of files) {
    const fullPath = path.join(dir, file);
    let text;
    try {
      text = fs.readFileSync(fullPath, "utf8");
    } catch {
      continue;
    }

    const m = text.match(
      /export\s+const\s+([a-zA-Z0-9]+)CRUDConfiguration\b/
    );

    if (m) {
      const raw = m[1];
      return raw.charAt(0).toUpperCase() + raw.slice(1);
    }
  }

  return null;
}

function resolveFeature(route, sf, filename) {
  return (
    extractFeatureFromConstantsFile(filename)
  );
}

function isIdentifierNamed(node, name) {
  return node && ts.isIdentifier(node) && node.text === name;
}
function findProp(obj, name) {
  if (!obj || !ts.isObjectLiteralExpression(obj)) return undefined;
  for (const p of obj.properties) {
    if (ts.isPropertyAssignment(p) && ts.isIdentifier(p.name) && p.name.text === name) return p;
  }
  return undefined;
}
function looksLikeRoute(obj) {
  if (!obj || !ts.isObjectLiteralExpression(obj)) return false;
  for (const p of obj.properties) {
    if (ts.isPropertyAssignment(p) && ts.isIdentifier(p.name)) {
      const n = p.name.text;
      if (n === "component" || n === "children" || n === "path" || n === "loadChildren") return true;
    }
  }
  return false;
}

// Collapse duplicate edits and detect true conflicts
function dedupeEdits(edits) {
  // key => { start,end,text }
  const map = new Map();
  const conflicts = [];
  for (const e of edits) {
    const key = `${e.start}:${e.end}`;
    if (!map.has(key)) {
      map.set(key, e);
    } else {
      const existing = map.get(key);
      if (existing.text === e.text) {
        // identical duplicate — ignore
        continue;
      } else {
        // conflicting replacement for same span
        conflicts.push({ span: key, existing, conflict: e });
        // Deterministic resolution: prefer the existing (first inserted)
      }
    }
  }
  return { edits: Array.from(map.values()), conflicts };
}

function applyEdits(src, edits) {
  if (!edits || edits.length === 0) return src;
  // detect overlaps first (safer): if overlapping, we will throw
  edits.sort((a,b) => a.start - b.start);
  for (let i = 1; i < edits.length; ++i) {
    if (edits[i].start < edits[i-1].end) {
      throw new Error(`Overlapping edits detected (start ${edits[i].start} < prev end ${edits[i-1].end}). Aborting apply.`);
    }
  }
  // apply descending
  edits.sort((a,b) => b.start - a.start);
  let out = src;
  for (const e of edits) out = out.slice(0,e.start) + e.text + out.slice(e.end);
  return out;
}

function safeRemoveRangeWithComma(src, start, end) {
  let s = start, e = end;
  // absorb trailing whitespace then comma if present
  while (e < src.length && /\s/.test(src[e])) e++;
  if (src[e] === ",") { e = e+1; return { s,e }; }
  // else look for leading comma
  let ls = s - 1;
  while (ls >= 0 && /\s/.test(src[ls])) ls--;
  if (ls >= 0 && src[ls] === ",") {
    // include comma and any whitespace before it
    let ls2 = ls;
    while (ls2 - 1 >= 0 && /\s/.test(src[ls2 - 1])) ls2--;
    s = ls2;
  }
  return { s, e };
}

function buildLayoutConditionalText(condNode, trueIsPopup, sf) {
  const condText = condNode.getText(sf);
  const left = trueIsPopup ? "LayoutMode.popup" : "LayoutMode.fullPage";
  const right = trueIsPopup ? "LayoutMode.fullPage" : "LayoutMode.popup";
  return `(${condText} ? ${left} : ${right})`;
}

function toKebabCase(str) {
  return str
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")        // lowercase/number followed by uppercase
    .replace(/([A-Z]+)([A-Z][a-z])/g, "$1-$2")    // consecutive uppercase letters (acronyms)
    .replace(/_/g, "-")                            // underscores
    .toLowerCase();
}

function patchImportsText(text) {
  const needed = ["DynamicLayoutComponent", "LayoutMode"];
  const importRegex = /import\s*\{([\s\S]*?)\}\s*from\s*(['"][^'"]+['"])\s*;/g;
  let out = text;
  let m;
  const inserts = [];
  let sharedImportFound = false;
  let sharedImportPath = null;

  // ---- Patch layout imports ----
  while ((m = importRegex.exec(text)) !== null) {
    const full = m[0], inner = m[1], matchStart = m.index;
    const fromPath = m[2];
    const names = inner.split(",").map(s => s.trim()).filter(Boolean).map(s => {
      const a = s.indexOf(" as ");
      return a >= 0 ? s.slice(0,a).trim() : s;
    });
    const touchesLayout = names.includes("FullPageLayoutComponent") || names.includes("PopupLayoutComponent");
    if (!touchesLayout) continue;

    const toAdd = needed.filter(n => !names.includes(n));
    if (toAdd.length === 0) continue;

    // Check if this is from a shared library (not individual component paths)
    const fromPathStr = fromPath.slice(1, -1); // remove quotes
    const isSharedLibrary = !fromPathStr.includes("/fullpage-layout/") && 
                            !fromPathStr.includes("/popup-layout/") &&
                            !fromPathStr.includes("/dynamic-layout/");
    
    if (isSharedLibrary) {
      // Add to existing shared import
      sharedImportFound = true;
      sharedImportPath = fromPathStr;
      const braceCloseRel = full.lastIndexOf("}");
      const insertPos = matchStart + braceCloseRel;
      const insertionText = (inner.trim().length === 0 || inner.trim().endsWith(",")) ? " " + toAdd.join(", ") : ", " + toAdd.join(", ");
      inserts.push({ pos: insertPos, newText: insertionText });
    } else {
      // This is from individual component paths - we'll add a separate import for shared path
      // Mark that we need to add the shared library import
      sharedImportFound = null; // Mark as needing separate import
    }
  }

  inserts.sort((a,b) => b.pos - a.pos);
  for (const ins of inserts) out = out.slice(0, ins.pos) + ins.newText + out.slice(ins.pos);

  // If we found individual component imports, add a new shared import for DynamicLayoutComponent and LayoutMode
  if (text.includes("FullPageLayoutComponent") || text.includes("PopupLayoutComponent")) {
    if (!sharedImportFound || sharedImportPath === null) {
      // Need to add new import from shared library
      const dynamicImportLine = "import { DynamicLayoutComponent, LayoutMode } from 'src/app/shared/bia-shared/components/layout/dynamic-layout/dynamic-layout.component';";
      
      // Check if it already exists
      if (!out.includes("import { DynamicLayoutComponent") && !out.includes("import { LayoutMode")) {
        const lastImport = out.lastIndexOf("import ");
        const insertPos = out.indexOf("\n", lastImport) + 1;
        out = out.slice(0, insertPos) + dynamicImportLine + "\n" + out.slice(insertPos);
      }
    }
  }

  // ---- Insert missing CRUDConfiguration imports ----
  if (text.includes("DynamicLayoutComponent")) {
    const configRegex = /([a-zA-Z0-9]+)CRUDConfiguration\b/g;
    let m2;
    const neededCRUD = new Map();
    while ((m2 = configRegex.exec(out)) !== null) {
      const feature = m2[1];
      neededCRUD.set(feature, `${feature}CRUDConfiguration`);
    }

    for (const [feature, cfg] of neededCRUD) {
      // Use kebab-case for import path
      const kebabFeature = toKebabCase(feature);
      const importLine = `import { ${cfg} } from './${kebabFeature}.constants';`;

      if (!out.includes(importLine)) {
        const lastImport = out.lastIndexOf("import ");
        const insertPos = out.indexOf("\n", lastImport) + 1;
        out = out.slice(0, insertPos) + importLine + "\n" + out.slice(insertPos);
      }
    }
  }

  return out;
}

function transformOneFile(src, filename) {
  let dynamicLayoutRootConsumed = false;
  const sf = ts.createSourceFile(filename, src, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS);
  const edits = [];
  const removeInjectCandidates = [];

  function visitNode(node, depth = 0) {
    if (ts.isArrayLiteralExpression(node)) {
      node.elements.forEach(el => {
        if (ts.isObjectLiteralExpression(el) && looksLikeRoute(el)) visitRouteObject(el, depth, null);
        else if (ts.isArrayLiteralExpression(el)) visitNode(el, depth);
      });
      return;
    }
    ts.forEachChild(node, c => visitNode(c, depth));
  }

  function getInsertPosBeforeClosingBrace(objNode) {
    const lastTok = objNode.getLastToken && objNode.getLastToken();
    if (lastTok) return lastTok.getStart();
    // fallback: getEnd()-1
    return objNode.getEnd() - 1;
  }

  function prefixForInsertion(objNode, sf) {
    // If object literal text right before "}" has a comma, use a space
    const text = objNode.getFullText(sf);
    const lastProp = objNode.properties[objNode.properties.length - 1];
    if (!lastProp) return ""; // empty object → no prefix needed
    const afterLastProp = text.slice(lastProp.end - objNode.pos, objNode.end - objNode.pos);
    return /,\s*\}$/.test(afterLastProp) ? " " : ", ";
  }

  function getLoadChildrenImportPath(loadChildrenProp, sf) {
    if (!loadChildrenProp || !ts.isPropertyAssignment(loadChildrenProp)) return null;
    const text = loadChildrenProp.initializer.getText(sf);
    const m = text.match(/import\s*\(\s*['"](.+?)['"]\s*\)/);
    return m ? m[1] : null;
  }

  function isTrulyDynamicComponent(dynamicProp) {
    if (!dynamicProp || !ts.isPropertyAssignment(dynamicProp)) return false;

    let expr = dynamicProp.initializer;

    // unwrap arrow function: () => expr
    if (ts.isArrowFunction(expr)) {
      expr = expr.body;
    }

    // unwrap parentheses
    while (ts.isParenthesizedExpression(expr)) {
      expr = expr.expression;
    }

    // ONLY treat ternary as dynamic
    return ts.isConditionalExpression(expr);
  }

  // SINGLE-DECISION visitRouteObject (computes actions once per route)
  function visitRouteObject(routeObj, depth, inheritedFinalComponent) {
    const compProp = findProp(routeObj, "component");
    const dataProp = findProp(routeObj, "data");
    const childrenProp = findProp(routeObj, "children");

    // compute existing final component name if possible
    let currentFinalComponent = inheritedFinalComponent;
    if (compProp && ts.isPropertyAssignment(compProp) && ts.isIdentifier(compProp.initializer)) {
      currentFinalComponent = compProp.initializer.text;
    }

    // Decide exactly once what we will do for this route
    let desiredComponentText = null;     // if not null -> replace component initializer with this text
    let desiredLayoutModeText = null;    // if not null -> set/replace data.layoutMode to this text
    let shouldRemoveInject = false;      // whether to remove injectComponent later
    let keepInjectAlways = false;        // RULE 1: keep injectComponent when root FullPage -> Dynamic

    function getInjectInitializerText() {
      if (!dataProp || !ts.isPropertyAssignment(dataProp) || !ts.isObjectLiteralExpression(dataProp.initializer)) return null;
      const inj = findProp(dataProp.initializer, "injectComponent");
      if (inj && ts.isPropertyAssignment(inj)) return inj.initializer.getText(sf);
      return null;
    }

    if (compProp && ts.isPropertyAssignment(compProp)) {
      const compInit = compProp.initializer;

      // RULE 1: root-level FullPageLayoutComponent -> DynamicLayoutComponent (NO layoutMode)
      if (
        isIdentifierNamed(compInit, "FullPageLayoutComponent") &&
        !dynamicLayoutRootConsumed
      ) {
        desiredComponentText = "DynamicLayoutComponent";
        keepInjectAlways = true;
        dynamicLayoutRootConsumed = true;

        const feature = resolveFeature(routeObj, sf, filename);

        if (feature) {
          const featureLower =
            feature.charAt(0).toLowerCase() + feature.slice(1);

          routeObj.__crudFeature = {
            feature,
            configName: `${featureLower}CRUDConfiguration`
          };
        }
      } else {
        // RULE 2/3/4: PopupLayoutComponent or FullPageLayoutComponent (non-root)
        // Only apply non-root Popup/Full replacements once a root DynamicLayout has been consumed
        if (dynamicLayoutRootConsumed) {
          // RULE 2: PopupLayoutComponent or FullPageLayoutComponent (non-root)
          if (isIdentifierNamed(compInit, "PopupLayoutComponent") || isIdentifierNamed(compInit, "FullPageLayoutComponent")) {
            const isPopup = isIdentifierNamed(compInit, "PopupLayoutComponent");
            desiredLayoutModeText = `LayoutMode.${isPopup ? "popup" : "fullPage"}`;
            const injText = getInjectInitializerText();
            if (injText) desiredComponentText = injText;
            shouldRemoveInject = true;
          }
          // RULE 3: ternary cond ? Popup : Full or reversed
          else if (ts.isConditionalExpression(compInit)) {
            const cond = compInit;
            const whenT = cond.whenTrue;
            const whenF = cond.whenFalse;
            const trueIsPopup = isIdentifierNamed(whenT, "PopupLayoutComponent");
            const trueIsFull = isIdentifierNamed(whenT, "FullPageLayoutComponent");
            const falseIsPopup = isIdentifierNamed(whenF, "PopupLayoutComponent");
            const falseIsFull = isIdentifierNamed(whenF, "FullPageLayoutComponent");
            const validPair = (trueIsPopup && falseIsFull) || (trueIsFull && falseIsPopup);
            if (validPair) {
              // Only set desiredLayoutModeText if the condition doesn't contain the CrudConfiguration
              const feature = resolveFeature(routeObj, sf, filename);
              const configName = feature
                ? `${feature.charAt(0).toLowerCase() + feature.slice(1)}CRUDConfiguration`
                : null;
              const conditionText = cond.condition.getText(sf);
              const containsConfig = configName && conditionText.includes(configName);

              if (!containsConfig) {
                desiredLayoutModeText = buildLayoutConditionalText(cond.condition, trueIsPopup, sf);
              }

              const injText = getInjectInitializerText();
              if (injText) desiredComponentText = injText;
              shouldRemoveInject = true;
            }
          }
          // RULE 4: contains Popup/Full anywhere (not ternary)
          else {
            const txt = compInit.getText(sf);
            const containsPopup = /\bPopupLayoutComponent\b/.test(txt);
            const containsFull = /\bFullPageLayoutComponent\b/.test(txt);
            if ((containsPopup || containsFull) && !ts.isConditionalExpression(compInit)) {
              const mode = containsPopup ? "popup" : "fullPage";
              desiredLayoutModeText = `LayoutMode.${mode}`;
              const injText = getInjectInitializerText();
              if (injText) desiredComponentText = injText;
              shouldRemoveInject = true;
            }
          }
        }
      }
    }

    // ---- NEW RULE: all descendants of DynamicLayoutComponent ----
    if (
      (inheritedFinalComponent === "DynamicLayoutComponent") &&
      !desiredLayoutModeText // do not override explicit layout decisions
    ) {
      const loadChildrenProp = findProp(routeObj, "loadChildren");

      if (loadChildrenProp) {
        const hasLayoutMode =
          dataProp &&
          ts.isPropertyAssignment(dataProp) &&
          ts.isObjectLiteralExpression(dataProp.initializer) &&
          findProp(dataProp.initializer, "layoutMode");

        if (!hasLayoutMode) {
          const modeText = "LayoutMode.fullPage";

          if (
            dataProp &&
            ts.isPropertyAssignment(dataProp) &&
            ts.isObjectLiteralExpression(dataProp.initializer)
          ) {
            const dataInit = dataProp.initializer;
            const insertPos = getInsertPosBeforeClosingBrace(dataInit);
            const insertion =
              prefixForInsertion(dataInit, sf) +
              `layoutMode: ${modeText} `;
            edits.push({ start: insertPos, end: insertPos, text: insertion });
          } else {
            const insertPos = getInsertPosBeforeClosingBrace(routeObj);
            const insertion =
              prefixForInsertion(routeObj, sf) +
              `data: { layoutMode: ${modeText} } `;
            edits.push({ start: insertPos, end: insertPos, text: insertion });
          }
        }
      }
    }

    // Emit the decided edits (one per target)
    if (desiredComponentText !== null && compProp && ts.isPropertyAssignment(compProp)) {
      const compInit = compProp.initializer;
      edits.push({ start: compInit.getStart(sf), end: compInit.getEnd(), text: desiredComponentText });
      inheritedFinalComponent = desiredComponentText;
    }

    const dynamicProp =
      dataProp &&
      ts.isPropertyAssignment(dataProp) &&
      ts.isObjectLiteralExpression(dataProp.initializer) &&
      findProp(dataProp.initializer, "dynamicComponent");

    const hasDynamicComponent = isTrulyDynamicComponent(dynamicProp);

    if (desiredLayoutModeText !== null) {
      if (dataProp && ts.isPropertyAssignment(dataProp) && ts.isObjectLiteralExpression(dataProp.initializer)) {
        const dataInit = dataProp.initializer;
        const layoutProp = findProp(dataInit, "layoutMode");
        if (layoutProp) {
          edits.push({ start: layoutProp.initializer.getStart(sf), end: layoutProp.initializer.getEnd(), text: desiredLayoutModeText });
        } else {
          const insertPos = getInsertPosBeforeClosingBrace(dataInit);
          const insertion = prefixForInsertion(dataInit, sf) + `layoutMode: ${desiredLayoutModeText} `;
          edits.push({ start: insertPos, end: insertPos, text: insertion });
        }
      } else {
        const insertPos = getInsertPosBeforeClosingBrace(routeObj);
        // use prefixForInsertion for routeObj as well so we handle trailing comma cases
        const insertion = prefixForInsertion(routeObj, sf) + `data: { layoutMode: ${desiredLayoutModeText} } `;
        edits.push({ start: insertPos, end: insertPos, text: insertion });
      }
    }

    // ---- NEW: Add configuration when converting to DynamicLayoutComponent ----
    if (routeObj.__crudFeature && desiredComponentText === "DynamicLayoutComponent") {
      const { configName, feature } = routeObj.__crudFeature;

      // ---- RULE: Only add configuration: if the import file exists ----
      const kebabFeature = toKebabCase(feature);
      const basePath = path.dirname(filename);
      const configFileBase = path.join(basePath, `${kebabFeature}.constants`);
      const possibleExtensions = [".ts", ".js", ".mts", ".cts"];
      const importExists = possibleExtensions.some(ext => fs.existsSync(configFileBase + ext));

      if (!importExists) {
        // Skip adding configuration & do not mark imports
        // Still remove injectComponent normally later
        // -> Abort patch 2 safely
        return;
      }

      if (dataProp && ts.isPropertyAssignment(dataProp) && ts.isObjectLiteralExpression(dataProp.initializer)) {
        const dataInit = dataProp.initializer;

        // Only add if not already present
        const existing = findProp(dataInit, "configuration");
        if (!existing) {
          const insertPos = getInsertPosBeforeClosingBrace(dataInit);
          const insertion = prefixForInsertion(dataInit, sf) + `configuration: ${configName} `;
          edits.push({ start: insertPos, end: insertPos, text: insertion });
        }
      } else {
        // No data property → create it
        const insertPos = getInsertPosBeforeClosingBrace(routeObj);
        const insertion =
          prefixForInsertion(routeObj, sf) +
          `data: { configuration: ${configName} } `;
        edits.push({ start: insertPos, end: insertPos, text: insertion });
      }

      // Mark import
      routeObj.__needsCRUDImport = true;
    }

    if (shouldRemoveInject && !keepInjectAlways && dataProp && ts.isPropertyAssignment(dataProp) && ts.isObjectLiteralExpression(dataProp.initializer)) {
      removeInjectCandidates.push({ dataProp, routeObj });
    }

    // Recurse children after decisions emitted
    if (childrenProp && ts.isPropertyAssignment(childrenProp) && ts.isArrayLiteralExpression(childrenProp.initializer)) {
      const childArr = childrenProp.initializer;
      childArr.elements.forEach(el => {
        if (ts.isObjectLiteralExpression(el)) visitRouteObject(el, depth + 1, inheritedFinalComponent);
      });
    }
  }

  function walkForRoutes(node) {
    if (ts.isVariableStatement(node)) {
      for (const decl of node.declarationList.declarations) {
        if (decl.type && ts.isTypeReferenceNode(decl.type) && decl.type.typeName && decl.type.typeName.getText(sf) === "Routes" && decl.initializer && ts.isArrayLiteralExpression(decl.initializer)) {
          visitNode(decl.initializer, 0, null);
        }
      }
    }
    ts.forEachChild(node, walkForRoutes);
  }

  walkForRoutes(sf);

  // Final sweep: remove injectComponent unless final component is DynamicLayoutComponent
  for (const cand of removeInjectCandidates) {
    const { dataProp, routeObj } = cand;
    if (!dataProp || !ts.isPropertyAssignment(dataProp)) continue;
    const dataInit = dataProp.initializer;
    if (!dataInit || !ts.isObjectLiteralExpression(dataInit)) continue;

    let finalComponent = null;
    for (const p of routeObj.properties) {
      if (ts.isPropertyAssignment(p) && ts.isIdentifier(p.name) && p.name.text === "component" && ts.isIdentifier(p.initializer)) {
        finalComponent = p.initializer.text;
      }
    }

    if (finalComponent !== "DynamicLayoutComponent") {
      for (const dp of dataInit.properties) {
        if (
          ts.isPropertyAssignment(dp) &&
          ts.isIdentifier(dp.name) &&
          (dp.name.text === "injectComponent" || dp.name.text === "dynamicComponent")
        ) {
          const start = dp.getStart(sf);
          const end = dp.getEnd();
          let { s, e } = safeRemoveRangeWithComma(src, start, end);

          // consume trailing spaces/tabs
          while (e < src.length && /[ \t]/.test(src[e])) e++;

          // consume one newline (CRLF or LF)
          if (src[e] === "\r" && src[e+1] === "\n") e += 2;
          else if (src[e] === "\n" || src[e] === "\r") e += 1;

          edits.push({ start: s, end: e, text: "" });
        }
      }
    }
  }

  // Dedupe edits and apply
  const dedup = dedupeEdits(edits);
  if (dedup.conflicts && dedup.conflicts.length > 0) {
    const dbg = {
      message: "Conflicting edits for identical spans detected (dedupe).",
      file: filename,
      conflicts: dedup.conflicts
    };
    fs.writeFileSync(filename + ".dedupe-debug.json", JSON.stringify(dbg, null, 2), "utf8");
    throw new Error("Conflicting edits detected; see " + filename + ".dedupe-debug.json");
  }

  try {
    const result = applyEdits(src, dedup.edits);
    const final = patchImportsText(result);
    return final;
  } catch (err) {
    console.error("Aborting write due to overlapping edits:", err && err.message ? err.message : err);
    const dbg = {
      message: "Overlapping edits prevented to avoid corruption",
      file: filename,
      plannedEdits: dedup.edits.map(e => ({ start: e.start, end: e.end, snippetStart: src.slice(Math.max(0,e.start-40), e.start), snippetEnd: src.slice(e.end, Math.min(src.length, e.end+40)), newTextPreview: e.text.length>200? e.text.slice(0,200)+"...": e.text }))
    };
    fs.writeFileSync(filename + ".edit-debug.json", JSON.stringify(dbg, null, 2), "utf8");
    throw err;
  }
}

function main() {
  const args = process.argv.slice(2);
  if (!args || args.length === 0) {
    console.error("Usage: node transformer.mjs <file1> <file2> ...");
    process.exit(2);
  }

  for (const f of args) {
    const abs = path.resolve(process.cwd(), f);
    let src = fs.readFileSync(abs, "utf8");

    try {
      const out = transformOneFile(src, abs);
      fs.writeFileSync(abs, out, "utf8");
      console.log("Wrote:", f);
    } catch (e) {
      console.error("Transform failed for", f);
      console.error(e && e.stack ? e.stack : e);
    }
  }
}

main();
'@

    $transformerPath = Join-Path $temp "transformer.mjs"
    Set-Content -Path $transformerPath -Value $transformer -Encoding utf8

    # Run transformer for all files in single Node invocation
    try {
        Write-Host "Transforming $($Files.Count) files..."
        & node $transformerPath @Files
    }
    catch {
        Write-Error "Transformer failed: $_"
        Set-Location $orig
        exit 1
    }
    finally {
        # try cleanup
        try { Set-Location $orig } catch {}
        # We keep temp dir briefly in case you want to inspect; remove if you want
        # Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
    }

    Write-Host "Done. Output: $($Files.Count) files"
}

function Invoke-DynamicLayoutViewChildInsert {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Files
    )

    $orig = Get-Location

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Error "Node.js not found on PATH."
        exit 1
    }

    $temp = Join-Path $env:TEMP ("ng-view-child-transformer-" + [guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $temp | Out-Null
    Set-Location $temp

@"
{
  "type": "module",
  "private": true
}
"@ | Out-File (Join-Path $temp "package.json") -Encoding utf8

    npm install typescript --no-audit --no-fund --silent --no-progress | Out-Null

    $transformer = @'
import fs from "fs";
import ts from "typescript";
import path from "path";

/* ============================================================
   Utilities
   ============================================================ */
function serviceExists(filename, featureKebab) {
  const servicePath = path.join(
    path.dirname(filename),
    "services",
    `${featureKebab}.service.ts`
  );

  return fs.existsSync(servicePath);
}


function toKebabCase(str) {
  return str
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")
    .replace(/_/g, "-")
    .toLowerCase();
}

function findProp(obj, name) {
  return obj.properties.find(
    p => ts.isPropertyAssignment(p) &&
         ts.isIdentifier(p.name) &&
         p.name.text === name
  );
}

function getStringProp(obj, name) {
  const p = findProp(obj, name);
  return p && ts.isStringLiteral(p.initializer) ? p.initializer.text : null;
}

function insertBeforeBrace(obj) {
  const tok = obj.getLastToken();
  return tok ? tok.getStart() : obj.getEnd() - 1;
}

function dedupe(edits) {
  const map = new Map();
  for (const e of edits) {
    const k = `${e.start}:${e.end}`;
    if (!map.has(k)) map.set(k, e);
  }
  return [...map.values()];
}

function apply(src, edits) {
  edits.sort((a,b) => b.start - a.start);
  let out = src;
  for (const e of edits)
    out = out.slice(0, e.start) + e.text + out.slice(e.end);
  return out;
}

/* ============================================================
   Feature extraction
   ============================================================ */
function extractFeatureFromConfiguration(route, sf) {
  const data = findProp(route, "data");
  if (!data || !ts.isObjectLiteralExpression(data.initializer)) return null;

  const cfg = findProp(data.initializer, "configuration");
  if (!cfg || !ts.isIdentifier(cfg.initializer)) return null;

  // planeCRUDConfiguration → Plane
  const m = cfg.initializer.text.match(/^([a-z0-9]+)CRUDConfiguration$/i);
  if (!m) return null;

  const raw = m[1];
  return raw.charAt(0).toUpperCase() + raw.slice(1);
}

/* ============================================================
   Import patching
   ============================================================ */

function patchImports(src, filename, feature) {
  const featureLower = feature.charAt(0).toLowerCase() + feature.slice(1);
  const featureKebab = toKebabCase(feature);

  const serviceImport =
    `import { ${feature}Service } from './services/${featureKebab}.service';`;

  const crudImport =
    `import { ${featureLower}CRUDConfiguration } from './${featureKebab}.constants';`;

  // ✅ SKIP if imports already exist (like first script)
  if (src.includes(serviceImport) && src.includes(crudImport)) {
    return src;
  }

  let out = src;

  const importRegex = /^import .*;$/gm;
  let lastImportEnd = 0;
  let m;
  while ((m = importRegex.exec(out)) !== null) {
    lastImportEnd = m.index + m[0].length;
  }

  const inserts = [];
  if (!out.includes(serviceImport)) inserts.push(serviceImport);
  if (!out.includes(crudImport)) inserts.push(crudImport);

  if (inserts.length) {
    out =
      out.slice(0, lastImportEnd) +
      "\n" +
      inserts.join("\n") +
      out.slice(lastImportEnd);
  }

  return out;
}

/* ============================================================
   View path resolution
   ============================================================ */

function computeViewImportPath(filename) {
  const normalized = filename.replace(/\\/g, "/");

  const marker = "/src/app/";
  const idx = normalized.indexOf(marker);

  if (idx === -1) {
    throw new Error(
      `Cannot compute ViewModule path: file is not under src/app\n${filename}`
    );
  }

  const appRoot = normalized.slice(0, idx + marker.length);
  const viewModule = path.join(
    appRoot,
    "shared/bia-shared/view.module"
  );

  let rel = path.relative(path.dirname(filename), viewModule);

  if (!rel.startsWith(".")) rel = "./" + rel;

  return rel.replace(/\\/g, "/");
}

/* ============================================================
   Main transform
   ============================================================ */

function transform(src, filename) {
  const sf = ts.createSourceFile(filename, src, ts.ScriptTarget.Latest, true);
  const edits = [];
  let usedFeature = null;

  function hasIndexInjectComponent(route, sf) {
    const data = findProp(route, "data");
    if (!data || !ts.isObjectLiteralExpression(data.initializer)) return false;

    const inject = findProp(data.initializer, "injectComponent");
    if (!inject) return false;

    const init = inject.initializer;

    // Identifier: MyFeatureIndexComponent
    if (ts.isIdentifier(init)) {
      return init.text.endsWith("IndexComponent");
    }

    // Property access: SomeNamespace.MyFeatureIndexComponent
    if (ts.isPropertyAccessExpression(init)) {
      return init.name.text.endsWith("IndexComponent");
    }

    return false;
  }

  function visit(node) {
    if (ts.isObjectLiteralExpression(node)) {
      const comp = findProp(node, "component");

      if (
        comp &&
        comp.initializer.getText(sf) === "DynamicLayoutComponent" &&
        hasIndexInjectComponent(node, sf)
      ) {
        processRoute(node);
      }
    }
    ts.forEachChild(node, visit);
  }

  function processRoute(route) {
    const feature = extractFeatureFromConfiguration(route, sf);
    const viewPath = computeViewImportPath(filename);

    let viewChild = null;
    let featureForImports = null;

    if (feature) {
      // CRUD-based route
      const featureLower = feature.charAt(0).toLowerCase() + feature.slice(1);

      viewChild = `{
        path: 'view',
        data: {
          featureConfiguration: ${featureLower}CRUDConfiguration,
          featureServiceType: ${feature}Service,
          leftWidth: 60,
        },
        loadChildren: () =>
          import('${viewPath}').then(m => m.ViewModule),
      }`;

      usedFeature = feature;
      featureForImports = feature;
    } else {
      // No CRUD configuration → fallback behavior
      viewChild = `{
        path: 'view',
        data: {
          // TODO: manually set featureStateKey to match the tableStateKey used in the IndexComponent (example 'plane' → 'planesGrid')
          featureStateKey: 'myFeatureTableStateKey',
          leftWidth: 60,
        },
        loadChildren: () =>
          import('${viewPath}').then(m => m.ViewModule),
      }`;
    }

    let childrenProp = findProp(route, "children");

    if (!childrenProp) {
      const pos = insertBeforeBrace(route);
      edits.push({
        start: pos,
        end: pos,
        text: `children: [ ${viewChild} ] `
      });
      return;
    }

    const arr = childrenProp.initializer;
    if (!ts.isArrayLiteralExpression(arr)) return;

    // Avoid duplicates
    for (const el of arr.elements) {
      if (
        ts.isObjectLiteralExpression(el) &&
        getStringProp(el, "path") === "view"
      ) {
        return;
      }
    }

    let after = null;
    for (const el of arr.elements) {
      if (ts.isObjectLiteralExpression(el)) {
        const p = getStringProp(el, "path");
        if (p === "import") after = el;
      }
    }
    if (!after) {
      for (const el of arr.elements) {
        if (ts.isObjectLiteralExpression(el)) {
          const p = getStringProp(el, "path");
          if (p === "create") after = el;
        }
      }
    }

    if (after) {
      edits.push({
        start: after.getEnd(),
        end: after.getEnd(),
        text: `, ${viewChild}`
      });
    } else {
      edits.push({
        start: arr.elements.pos,
        end: arr.elements.pos,
        text: `${viewChild}, `
      });
    }
  }

  visit(sf);

  let out = apply(src, dedupe(edits));
  if (usedFeature) out = patchImports(out, filename, usedFeature);

  return out;
}

/* ============================================================
   CLI
   ============================================================ */

for (const f of process.argv.slice(2)) {
  const abs = path.resolve(f);
  const src = fs.readFileSync(abs, "utf8");
  const out = transform(src, abs);
  fs.writeFileSync(abs, out, "utf8");
  console.log("Updated:", f);
}
'@

    $path = Join-Path $temp "transformer.mjs"
    Set-Content $path $transformer -Encoding utf8

    & node $path @Files

    Set-Location $orig
}

function Invoke-DynamicLayoutTransformInFilesRec {
  param (
    [string]$Source,
    [string]$Include,
    [System.Collections.Generic.List[string]]$FileList
  )
  foreach ($childDirectory in Get-ChildItem -Force -Path $Source -Directory -Exclude $ExcludeDir) {
    Invoke-DynamicLayoutTransformInFilesRec -Source $childDirectory.FullName -Include $Include -FileList $FileList
  }

  $fileItems = Get-ChildItem -LiteralPath $Source -File -Filter $Include
  foreach ($file in $fileItems) {
    $FileList.Add($file.FullName)
  }
}

function Invoke-DynamicLayoutTransformInFiles {
  param (
    [string]$Source,
    [string]$Include
  )
  $fileList = New-Object System.Collections.Generic.List[string]
  Invoke-DynamicLayoutTransformInFilesRec -Source $Source -Include $Include -FileList $fileList

  if ($fileList.Count -gt 0) {
      Invoke-DynamicLayoutTransform -Files $fileList.ToArray()
  }
}

function Invoke-DynamicLayoutViewChildInsertInFilesRec {
  param (
    [string]$Source,
    [string]$Include,
    [System.Collections.Generic.List[string]]$FileList
  )
  foreach ($childDirectory in Get-ChildItem -Force -Path $Source -Directory -Exclude $ExcludeDir) {
    Invoke-DynamicLayoutViewChildInsertInFilesRec -Source $childDirectory.FullName -Include $Include -FileList $FileList
  }

  $fileItems = Get-ChildItem -LiteralPath $Source -File -Filter $Include
  foreach ($file in $fileItems) {
    $FileList.Add($file.FullName)
  }
}

function Invoke-DynamicLayoutViewChildInsertInFiles {
  param (
    [string]$Source,
    [string]$Include
  )
  $fileList = New-Object System.Collections.Generic.List[string]
  Invoke-DynamicLayoutViewChildInsertInFilesRec -Source $Source -Include $Include -FileList $fileList

  if ($fileList.Count -gt 0) {
      Invoke-DynamicLayoutViewChildInsert -Files $fileList.ToArray()
  }
}

function Invoke-IndexComponentFullCodeViews {
    [CmdletBinding()]
    param(
        [string]$Source
    )

    $colors = @{
        Reset  = "`e[0m"
        Red    = "`e[31m"
        Green  = "`e[32m"
        Yellow = "`e[33m"
        Blue   = "`e[34m"
        Cyan   = "`e[36m"
    }

    $IndexBaseClasses = @(
        'CrudItemsIndexComponent'
        'AnnouncementsIndexComponent'
        'NotificationsIndexComponent'
        'UsersIndexComponent'
        'MembersIndexComponent'
    )

    function Write-Colored {
        param([string]$Message, [string]$Color)
        Write-Host "$($colors[$Color])$Message$($colors.Reset)"
    }

    function Get-FileContent {
        param([string]$FilePath)
        try {
            return Get-Content -Path $FilePath -Raw -ErrorAction Stop
        }
        catch {
            Write-Colored "Error reading file $FilePath : $_" "Red"
            return $null
        }
    }

    function Has-Method {
        param([string]$Content, [string]$MethodName)
        return $Content -match "$MethodName\s*\([^)]*\)\s*[{:]"
    }

    function Has-Property {
        param([string]$Content, [string]$PropertyName)
        return $Content -match "$PropertyName\s*:\s*\w+(\s*\|)?\s*\w*\s*[;=]"
    }

    function Get-ClassName {
        param([string]$Content)
        $match = $Content -match 'export\s+class\s+(\w+)'
        if ($match) {
            return $Matches[1]
        }
        return $null
    }

    function Get-ParentClass {
        param([string]$Content)

        $text = $Content -replace '\r?\n', ' '

        while ($text -match '<[^<>]*>') {
            $text = [regex]::Replace($text, '<[^<>]*>', '')
        }

        if ($text -match 'export\s+(abstract\s+)?class\s+\w+\s+extends\s+(\w+)\b') {
            return $Matches[2]
        }

        return $null
    }

    function Get-Imports {
        param(
            [string]$Content,
            [string]$CurrentFilePath
        )

        $imports = @{}

        $Content -split "`n" | ForEach-Object {
            if ($_ -match "import\s+\{\s*([^}]+)\s*\}\s+from\s+['""]([^'""]+)['""]") {
                $classNames = $Matches[1] -split ',' | ForEach-Object { $_.Trim() }
                $importPath = $Matches[2]

                foreach ($class in $classNames) {
                    $resolvedPath = Resolve-ImportPath -ImportPath $importPath -CurrentFilePath $CurrentFilePath
                    if ($resolvedPath) {
                        $imports[$class] = $resolvedPath
                    }
                }
            }
        }

        return $imports
    }

    function Resolve-ImportPath {
        param(
            [string]$ImportPath,
            [string]$CurrentFilePath
        )

        if ($ImportPath.StartsWith('.')) {
            $base = Split-Path $CurrentFilePath
            $candidate = Join-Path $base $ImportPath

            foreach ($ext in @('.ts', '.component.ts', '.service.ts', '.class.ts')) {
                $full = "$candidate$ext"
                if (Test-Path $full) { return $full }
            }

            if (Test-Path "$candidate/index.ts") {
                return "$candidate/index.ts"
            }
        }

        return $null
    }

    function Has-TableController {
        param([string]$TemplateContent)
        return $TemplateContent -match 'table-controller'
    }

    function Get-RequiredDependenciesInCode {
        param([string]$MethodsCode)
    
        $dependencies = @()
        if ($MethodsCode -match 'this\.\brouter\b') { $dependencies += 'router' }
        if ($MethodsCode -match 'this\.\bactivatedRoute\b') { $dependencies += 'activatedRoute' }
        if ($MethodsCode -match 'this\.\blocation\b') { $dependencies += 'location' }
    
        return $dependencies | Select-Object -Unique
    }

    function Has-DependencyInjection {
        param([string]$Content, [string]$DependencyName)

        if ($Content -match "constructor\s*\([^)]*\b$DependencyName\b\s*:") {
            return $true
        }

        if ($Content -match "\bthis\.$DependencyName\b\s*=\s*this\.injector\.get") {
            return $true
        }

        return $false
    }

    function Has-CrudItemsIndexInheritance {
        param(
            [string]$FilePath,
            [hashtable]$Visited = @{}
        )

        if ($Visited[$FilePath]) { return $false }
        $Visited[$FilePath] = $true

        $content = Get-FileContent -FilePath $FilePath

        $parentClass = Get-ParentClass -Content $content
        if (-not $parentClass) { return $false }

        if ($IndexBaseClasses -contains $parentClass) {
            return $true
        }

        $imports = Get-Imports -Content $content -CurrentFilePath $FilePath

        if (-not $imports.ContainsKey($parentClass)) {
            return $false
        }

        return Has-CrudItemsIndexInheritance -FilePath $imports[$parentClass] -Visited $Visited
    }

    function Get-TemplateContentFromComponent {
        param(
            [string]$ComponentPath,
            [string]$ComponentContent
        )

        if ($ComponentContent -match "templateUrl\s*:\s*['""]([^'""]+)['""]") {
            $componentDir = Split-Path -Path $ComponentPath -Parent
            $templatePath = Join-Path $componentDir $Matches[1]
            if (Test-Path $templatePath) {
                return Get-FileContent -FilePath $templatePath
            }
            return $null
        }

        if ($ComponentContent -match "template\s*:\s*`"(.*?)`"" -or
            $ComponentContent -match "template\s*:\s*'(.*?)'") {
            return $Matches[1]
        }

        return $null
    }

    $onSelectedViewChangedMethod = @"

  onSelectedViewChanged(view: View | null) {
    this.currentView = view;
    this.updateViewQueryParam(view);
  }
"@

    $updateViewQueryParamMethod = @"

  updateViewQueryParam(view: View | null) {
    if (this.isViewRouteLoaded()) {
      this.changeView(view);
    } else {
      const tree = this.router.createUrlTree([], {
        relativeTo: this.activatedRoute,
        queryParams: view?.name ? { view: view.name } : { view: null },
        queryParamsHandling: 'merge',
      });

      this.location.replaceState(this.router.serializeUrl(tree));
    }
  }
"@

    $isViewRouteLoadedMethod = @"

  isViewRouteLoaded(): boolean {
    const currentUrl = this.router.url;
    const baseUrl = currentUrl.split('?')[0];
    return baseUrl.endsWith('/saveView');
  }
"@

    $changeViewMethod = @"

  changeView(view: View | null) {
    const segments = this.router.url.split('?')[0].split('/').filter(Boolean);

    if (segments.length >= 2) {
      segments[segments.length - 2] = view?.id.toString() ?? '0';

      this.router.navigate(['/', ...segments], {
        relativeTo: this.activatedRoute,
        queryParams: { view: view?.name ?? null },
        queryParamsHandling: 'merge',
        replaceUrl: true,
      });
    }
  }
"@

    $currentViewProperty = "  currentView: View | null;`n"


    Write-Colored "==============================================================" "Cyan"
    Write-Colored "TS IndexComponent Checker - Deep Inheritance Analysis" "Cyan"
    Write-Colored "==============================================================" "Cyan"
    Write-Host ""

    $indexComponentFiles = @(Get-ChildItem -Path $Source -Filter "*index.component.ts" -Recurse -ErrorAction SilentlyContinue)

    Write-Colored "Found $($indexComponentFiles.Count) IndexComponent files" "Blue"
    Write-Host ""

    $filesNeedingUpdate = @()
    $filesChecked = @()
    $fileCache = @{}

    foreach ($file in $indexComponentFiles) {
        $content = Get-FileContent -FilePath $file.FullName
        if ($null -eq $content) { continue }
    
        $fileCache[$file.FullName] = $content
    
        $className = Get-ClassName -Content $content
    
        $templateContent = Get-TemplateContentFromComponent `
            -ComponentPath $file.FullName `
            -ComponentContent $content

        if ($null -eq $templateContent -or -not (Has-TableController -TemplateContent $templateContent)) {
            Write-Colored "[SKIP] $($file.Name)" "Blue"
            Write-Host "    No bia-table-controller in template"
            $filesChecked += $file.FullName
            continue
        }

        $extendsCrudItems = Has-CrudItemsIndexInheritance `
            -FilePath $file.FullName `
            -FileCache $fileCache `
            -VisitedClasses @{}
        
        if ($extendsCrudItems) {
            Write-Colored "[OK] $($file.Name)" "Green"
            Write-Host "    Extends CrudItemsIndexComponent (directly or indirectly)"
        }
        else {
            # Check for required methods and properties
            $hasMethods = @{
                onSelectedViewChanged = Has-Method -Content $content -MethodName "onSelectedViewChanged"
                updateViewQueryParam  = Has-Method -Content $content -MethodName "updateViewQueryParam"
                isViewRouteLoaded     = Has-Method -Content $content -MethodName "isViewRouteLoaded"
                changeView            = Has-Method -Content $content -MethodName "changeView"
            }
        
            $hasProperties = @{
                currentView = Has-Property -Content $content -PropertyName "currentView"
            }
        
            $hasViewImport = $content -match "import.*View.*from"
        
            $missing = @()
            if (-not $hasMethods.onSelectedViewChanged) { $missing += 'onSelectedViewChanged()' }
            if (-not $hasMethods.updateViewQueryParam) { $missing += 'updateViewQueryParam()' }
            if (-not $hasMethods.isViewRouteLoaded) { $missing += 'isViewRouteLoaded()' }
            if (-not $hasMethods.changeView) { $missing += 'changeView()' }
            if (-not $hasProperties.currentView) { $missing += 'currentView property' }
            if (-not $hasViewImport) { $missing += 'View import' }
        
            # Check for missing dependencies in constructor (only if methods are missing)
            # If methods are missing, then dependencies will also be needed
            $missingDeps = @()
            if ($missing.Count -gt 0) {
                $requiredDeps = Get-RequiredDependenciesInCode -MethodsCode ($onSelectedViewChangedMethod + $updateViewQueryParamMethod + $isViewRouteLoadedMethod + $changeViewMethod)
            
                foreach ($dep in $requiredDeps) {
                    if (-not (Has-DependencyInjection -Content $content -DependencyName $dep)) {
                        $missingDeps += $dep
                    }
                }
            
                if ($missingDeps.Count -gt 0) {
                    foreach ($dep in $missingDeps) {
                        $missing += "Missing injection: $dep"
                    }
                }
            }
        
            if ($missing.Count -gt 0) {
                Write-Colored "[MISSING] $($file.Name)" "Red"
                Write-Host "    Class: $className"
                Write-Host "    Missing:"
                foreach ($item in $missing) {
                    Write-Colored "      - $item" "Yellow"
                }
            
                $filesNeedingUpdate += @{
                    Path        = $file.FullName
                    Content     = $content
                    ClassName   = $className
                    Missing     = $missing
                    MissingDeps = $missingDeps
                }
            }
            else {
                Write-Colored "[OK] $($file.Name)" "Green"
                Write-Host "    Has all required members and dependencies"
            }
        }
        $filesChecked += $file.FullName
    }

    Write-Host ""
    Write-Colored "==============================================================" "Cyan"
    Write-Colored "Summary" "Cyan"
    Write-Colored "==============================================================" "Cyan"
    Write-Host "Total files checked: $($filesChecked.Count)"
    Write-Colored "Files needing updates: $($filesNeedingUpdate.Count)" $(if ($filesNeedingUpdate.Count -eq 0) { "Green" } else { "Yellow" })
    Write-Host ""

    if ($filesNeedingUpdate.Count -gt 0) {
        Write-Colored "Files that need updating:" "Yellow"
        foreach ($file in $filesNeedingUpdate) {
            Write-Host "  - $($file.Path)"
        }
        Write-Host ""
        Write-Colored "Auto-fixing files (methods, properties, and injections)..." "Blue"
        Write-Host ""
    
        foreach ($file in $filesNeedingUpdate) {
            Write-Colored "Processing: $($file.Path)" "Cyan"
        
            $content = $file.Content
            $updatedContent = $content
        
            # Add Location import if missing
            if ($file.Missing -like '*Missing injection: location*') {
                if ($updatedContent -notmatch 'import.*Location.*from\s+@angular/common') {
                    $pattern = "import\s*\{\s*([^}]*)\s*\}\s*from\s+'@angular/common'\s*;"
                    if ($updatedContent -match $pattern) {
                        $old = $Matches[0]
                        $new = $old -replace '\}', ', Location }'
                        $updatedContent = $updatedContent -replace [regex]::Escape($old), $new
                        Write-Host "    [+] Added Location import"
                    }
                }
            }

            if ($file.Missing -like '*Missing injection: router*' -or
                $file.Missing -like '*Missing injection: activatedRoute*') {

                if ($updatedContent -notmatch 'from\s+''@angular/router''') {
                    $routerImport = "import { Router, ActivatedRoute } from '@angular/router';"
                    $updatedContent = $routerImport + "`n" + $updatedContent
                    Write-Host "    [+] Added Router & ActivatedRoute imports"
                }
            }
        
            # Add missing constructor injections
            if ($updatedContent -match 'constructor\s*\(([\s\S]*?)\)\s*\{') {
                $paramsBlock = $Matches[1].Trim()
                $oldConstructor = $Matches[0]

                $paramList = @()
                if ($paramsBlock.Length -gt 0) {
                    $paramList = $paramsBlock -split ",\s*`n?"
                }

                $joinedParams = $paramList -join "`n"

                if ($file.Missing -like '*Missing injection: router*' -and
                    $joinedParams -notmatch '\brouter\s*:') {
                    $paramList += 'private router: Router'
                    Write-Host "    [+] Added router parameter to constructor"
                }

                if ($file.Missing -like '*Missing injection: activatedRoute*' -and
                    $joinedParams -notmatch '\bactivatedRoute\s*:') {
                    $paramList += 'private activatedRoute: ActivatedRoute'
                    Write-Host "    [+] Added activatedRoute parameter to constructor"
                }

                if ($file.Missing -like '*Missing injection: location*' -and
                    $joinedParams -notmatch '\blocation\s*:') {
                    $paramList += 'private location: Location'
                    Write-Host "    [+] Added location parameter to constructor"
                }

                $newParams = ($paramList | ForEach-Object { "    $_" }) -join ",`n"

                $newConstructor = "constructor(`n$newParams`n) {"

                $updatedContent = $updatedContent -replace
                [regex]::Escape($oldConstructor),
                $newConstructor
            }
        
            # Add methods and properties
            $classClosingBraceIndex = $updatedContent.LastIndexOf('}')
            if ($classClosingBraceIndex -gt 0) {
                $insertionPoint = $classClosingBraceIndex
                $toAdd = ''
        
                if ($file.Missing -contains 'currentView property') {
                    $toAdd += "`n" + $currentViewProperty
                    Write-Host "    [+] Added currentView property"
                }
            
                if ($file.Missing -like '*onSelectedViewChanged*') {
                    $toAdd += $onSelectedViewChangedMethod + "`n"
                    Write-Host "    [+] Added onSelectedViewChanged() method"
                }
            
                if ($file.Missing -like '*updateViewQueryParam*') {
                    $toAdd += $updateViewQueryParamMethod + "`n"
                    Write-Host "    [+] Added updateViewQueryParam() method"
                }
            
                if ($file.Missing -like '*isViewRouteLoaded*') {
                    $toAdd += $isViewRouteLoadedMethod + "`n"
                    Write-Host "    [+] Added isViewRouteLoaded() method"
                }
            
                if ($file.Missing -like '*changeView*') {
                    $toAdd += $changeViewMethod + "`n"
                    Write-Host "    [+] Added changeView() method"
                }
            
                if ($toAdd.Length -gt 0) {
                    $updatedContent = $updatedContent.Substring(0, $insertionPoint) + "`n" + $toAdd + $updatedContent.Substring($insertionPoint)
                
                    # Add View import if it was in the missing list
                    if ($file.Missing -contains 'View import') {
                        if ($updatedContent -notmatch 'import.*View.*from.*packages/bia-ng/shared/public-api') {
                            # Try to add it after existing packages/bia-ng imports
                            $searchString = "from 'packages/bia-ng/shared/public-api';"
                            $lastPackageImport = $updatedContent.LastIndexOf($searchString)
                            if ($lastPackageImport -gt 0) {
                                $lineEnd = $updatedContent.IndexOf([char]10, $lastPackageImport)
                                if ($lineEnd -gt 0) {
                                    $newLine = "`nimport { View } from 'packages/bia-ng/shared/public-api';"
                                    $updatedContent = $updatedContent.Insert($lineEnd, $newLine)
                                    Write-Host "    [+] Added View import from packages/bia-ng/shared/public-api"
                                }
                            }
                        }
                    }
            
                    try {
                        Set-Content -Path $file.Path -Value $updatedContent -ErrorAction Stop
                        Write-Colored "    [SUCCESS] File updated successfully" "Green"
                    }
                    catch {
                        Write-Colored "    [ERROR] Error writing file: $_" "Red"
                    }
                }
            }
        }
        Write-Host ""
        Write-Colored "Auto-fix complete!" "Green"
    }

    if ($filesNeedingUpdate.Count -eq 0) {
        Write-Colored "All files are properly configured!" "Green"
    }

}

function Invoke-ManageCentralPackageVersions {
  param (
    [Parameter(Mandatory = $true)]
    [string]$SourcePath
  )

  $biaPropsPath = Join-Path $SourcePath 'Directory.Packages.Bia.props'
  $projectPropsPath = Join-Path $SourcePath 'Directory.Packages.Project.props'

  if (-not (Test-Path -LiteralPath $projectPropsPath)) {
    Write-Warning ("Directory.Packages.Project.props not found: {0}" -f $projectPropsPath)
    return
  }

  $biaPackages = @{}
  if (Test-Path -LiteralPath $biaPropsPath) {
    try {
      $biaDoc = New-Object System.Xml.XmlDocument
      $biaDoc.PreserveWhitespace = $false
      $biaDoc.Load($biaPropsPath)
      foreach ($node in $biaDoc.SelectNodes('//PackageVersion[@Include]')) {
        $includeAttr = $node.Attributes['Include']
        if ($includeAttr -and -not [string]::IsNullOrWhiteSpace($includeAttr.Value)) {
          $biaPackages[$includeAttr.Value] = $true
        }
      }
    }
    catch {
      Write-Warning ("Unable to read {0}: {1}" -f $biaPropsPath, $_.Exception.Message)
      $biaPackages = @{}
    }
  }

  $projectDoc = New-Object System.Xml.XmlDocument
  $projectDoc.PreserveWhitespace = $false
  try {
    $projectDoc.Load($projectPropsPath)
  }
  catch {
    Write-Error ("Unable to read {0}: {1}" -f $projectPropsPath, $_.Exception.Message)
    return
  }

  $projectItemGroup = $projectDoc.SelectSingleNode('/Project/ItemGroup')
  if (-not $projectItemGroup) {
    $projectItemGroup = $projectDoc.CreateElement('ItemGroup')
    [void]$projectDoc.DocumentElement.AppendChild($projectItemGroup)
  }

  $existingProjectPackages = @{}
  foreach ($node in $projectItemGroup.SelectNodes('PackageVersion')) {
    $includeAttr = $node.Attributes['Include']
    if ($includeAttr -and -not [string]::IsNullOrWhiteSpace($includeAttr.Value)) {
      $versionAttr = $node.Attributes['Version']
      if ($versionAttr) {
        $existingProjectPackages[$includeAttr.Value] = $versionAttr.Value
      }
      else {
        $existingProjectPackages[$includeAttr.Value] = $null
      }
    }
  }

  $packagesForProject = @{}
  $packageSources = @{}

  $excludeFullPaths = @()
  foreach ($ex in $ExcludeDir) {
    $fullPath = if ([System.IO.Path]::IsPathRooted($ex)) { $ex } else { Join-Path -Path $SourcePath -ChildPath $ex }
    $excludeFullPaths += [System.IO.Path]::GetFullPath($fullPath)
  }

  $csprojFiles = Get-ChildItem -LiteralPath $SourcePath -Recurse -File -Filter '*.csproj' |
  Where-Object {
    $full = [System.IO.Path]::GetFullPath($_.FullName)
    $isExcluded = $false
    foreach ($ex in $excludeFullPaths) {
      $normalizedEx = $ex.TrimEnd([char[]]@([char]0x5C, [char]0x2F))
      if ($full.StartsWith($normalizedEx, [System.StringComparison]::OrdinalIgnoreCase)) {
        $isExcluded = $true
        break
      }
    }
    -not $isExcluded
  }

  foreach ($proj in $csprojFiles) {
    $projDoc = New-Object System.Xml.XmlDocument
    $projDoc.PreserveWhitespace = $true
    try {
      $projDoc.Load($proj.FullName)
    }
    catch {
      Write-Warning ("Unable to read {0}: {1}" -f $proj.FullName, $_.Exception.Message)
      continue
    }

    $packageRefs = $projDoc.SelectNodes('//PackageReference[@Include]')
    foreach ($packageRef in $packageRefs) {
      $includeAttr = $packageRef.Attributes['Include']
      if (-not $includeAttr -or [string]::IsNullOrWhiteSpace($includeAttr.Value)) {
        continue
      }

      $packageId = $includeAttr.Value
      $versionAttr = $packageRef.Attributes['Version']
      $versionValue = $null
      if ($versionAttr) {
        $versionValue = $versionAttr.Value
      }

      if (-not $biaPackages.ContainsKey($packageId) -and -not [string]::IsNullOrWhiteSpace($versionValue)) {
        if ($packagesForProject.ContainsKey($packageId) -and $packagesForProject[$packageId] -ne $versionValue) {
          $previousSource = $packageSources[$packageId]
          Write-Warning ("Version conflict for {0}: keeping {1} (from {2}), ignoring {3} (from {4})" -f $packageId, $packagesForProject[$packageId], $previousSource, $versionValue, $proj.FullName)
        }
        elseif (-not $packagesForProject.ContainsKey($packageId)) {
          $packagesForProject[$packageId] = $versionValue
          $packageSources[$packageId] = $proj.FullName
        }
      }
    }
  }

  $projectPropsChanged = $false
  $finalPackages = @{}
  foreach ($key in $existingProjectPackages.Keys) {
    $finalPackages[$key] = $existingProjectPackages[$key]
  }

  foreach ($packageId in $packagesForProject.Keys) {
    $excludedPackages = @("System.Security.Principal.Windows")
    if (-not $excludedPackages.Contains($packageId)) {
      $versionValue = $packagesForProject[$packageId]
      if (-not $finalPackages.ContainsKey($packageId)) {
        Write-Host ("  -> adding {0} {1} to Directory.Packages.Project.props" -f $packageId, $versionValue)
        $finalPackages[$packageId] = $versionValue
        $projectPropsChanged = $true
      }
      elseif ($versionValue -and $finalPackages[$packageId] -ne $versionValue) {
        Write-Host ("  -> updating {0}: {1} -> {2} in Directory.Packages.Project.props" -f $packageId, $finalPackages[$packageId], $versionValue)
        $finalPackages[$packageId] = $versionValue
        $projectPropsChanged = $true
      }
    }
  }

  if ($projectPropsChanged) {
    foreach ($node in @($projectItemGroup.SelectNodes('PackageVersion'))) {
      [void]$projectItemGroup.RemoveChild($node)
    }

    $sortedPackages = $finalPackages.Keys | Sort-Object
    foreach ($packageId in $sortedPackages) {
      $versionValue = $finalPackages[$packageId]
      if ([string]::IsNullOrWhiteSpace($versionValue)) {
        continue
      }

      $packageNode = $projectDoc.CreateElement('PackageVersion')
      $includeAttribute = $projectDoc.CreateAttribute('Include')
      $includeAttribute.Value = $packageId
      [void]$packageNode.Attributes.Append($includeAttribute)

      $versionAttribute = $projectDoc.CreateAttribute('Version')
      $versionAttribute.Value = $versionValue
      [void]$packageNode.Attributes.Append($versionAttribute)

      [void]$projectItemGroup.AppendChild($packageNode)
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.IndentChars = '  '
    $settings.OmitXmlDeclaration = $true
    $settings.NewLineChars = [Environment]::NewLine
    $settings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
    $settings.Encoding = $utf8NoBom

    $writer = [System.Xml.XmlWriter]::Create($projectPropsPath, $settings)
    $projectDoc.Save($writer)
    $writer.Close()

    Write-Host ("  -> updated {0}" -f $projectPropsPath)
  }
  else {
    Write-Host "  -> Directory.Packages.Project.props already up to date"
  }
}

# FRONT END
# BEGIN - deactivate navigation in breadcrumb for crudItemId
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "(path:\s*':crudItemId',\s*data:\s*\{\s*breadcrumb:\s*'',\s*canNavigate:\s*)true(,\s*\})" -NewRegexp '$1false$2' -Include "*module.ts"
# END - deactivate navigation in breadcrumb for crudItemId

# BEGIN - switch to lib bia-ng
ApplyChangesToLib
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp '("includePaths":\s*\["src\/styles",\s*")src\/scss\/bia("\])' -NewRegexp '$1node_modules/bia-ng/scss$2' -Include "*angular.json"
# END - switch to lib bia-ng

# BEGIN - add (viewNameChange)="onViewNameChange($event)" to index component HTML
ReplaceInProject `
  -Source $SourceFrontEnd `
  -OldRegexp '(?m)^(?<indent>\s*)(?<line>\(viewChange\)="onViewChange\(\$event\)")\s*(?<nl>\r?\n)(?!\k<indent>\(selectedViewChanged\)="onSelectedViewChanged\(\$event\)")' `
  -NewRegexp '${indent}${line}${nl}${indent}(selectedViewChanged)="onSelectedViewChanged($event)"${nl}' `
  -Include '*-index.component.html'
#  # END - add (viewNameChange)="onViewNameChange($event)" to index component HTML

# BEGIN Team config move to back-end
Invoke-MigrationTeamConfig
# End Team config move to back-end

# BEGIN Remove [autoLayout] in <p-table> and [responsive]/responsive from <p-table> | <p-dialog>
$replacementsHtml = @(
  # <p-table ... [autoLayout]="..."   OU   <p-table ... autoLayout="...">   OU   <p-table ... [autoLayout]>
  @{
    Pattern     = '(?is)(<p-table\b[^>]*?)\s+(?:\[\s*autoLayout\s*\](?:\s*=\s*(?:"[^"]*"|''[^'']*''))?|autoLayout\s*=\s*(?:"[^"]*"|''[^'']*''))'
    Replacement = '$1'
  },

  # <p-(table|dialog) ... [responsive]="..."   OU   responsive="..."   OU   [responsive]>
  @{
    Pattern     = '(?is)(<(?:p-table|p-dialog)\b[^>]*?)\s+(?:\[\s*responsive\s*\](?:\s*=\s*(?:"[^"]*"|''[^'']*''))?|responsive\s*=\s*(?:"[^"]*"|''[^'']*''))'
    Replacement = '$1'
  }
)

Invoke-ReplacementsInFiles -RootPath $SourceFrontEnd -Replacements $replacementsHtml -Extensions @('*.html')
# END Remove [autoLayout] in <p-table> and [responsive]/responsive from <p-table> | <p-dialog>

# BEGIN Remove import Textarea and add Renderer2 injection for extended classes of BiaFormComponent
$replacementsTs = @(
  @{
    Pattern     = '(?m)^\s*import\s*\{\s*Textarea\s*\}\s*from\s*''primeng/inputtextarea''\s*;\s*\r?\n?'
    Replacement = ''
  },
  @{
    Pattern     = '(?is)(\bimports\s*:\s*\[[^\]]*?)\s*\bTextarea\b\s*,\s*'
    Replacement = '$1'
  },
  @{
    Pattern     = '(?is)(\bimports\s*:\s*\[[^\]]*?),\s*\bTextarea\b\s*'
    Replacement = '$1'
  },
  @{
    Pattern     = '(?is)(\bimports\s*:\s*\[)\s*\bTextarea\b\s*(\])'
    Replacement = '$1$2'
  },

  @{
    Requirement = 'extends\s+BiaFormComponent'
    Pattern     = '(?s)import\s*\{\s*(?![^}]*\bRenderer2\b)([^}]*)\}\s*from\s*''@angular/core''\s*;'
    Replacement = 'import { $1 Renderer2 } from ''@angular/core'';'
  },
  @{
    Requirement = 'extends\s+BiaFormComponent(?!.*constructor\s*\([^)]*\bRenderer2\b)'
    Pattern='(?s)(constructor\s*\(\s*(?!\s*\))([^)]*?))\)'
    Replacement='$1, protected renderer: Renderer2)'
  },
  @{
    Requirement = 'extends\s+BiaFormComponent'
    Pattern     = '(?s)constructor\s*\(\s*\)'
    Replacement = 'constructor(protected renderer: Renderer2)'
  },
  @{
    Requirement = 'extends\s+BiaFormComponent'
    Pattern     = '(?s)super\s*\(\s*(?![^)]*\brenderer\b)([^)]*?)\)'
    Replacement = 'super($1, renderer)'
  }
)

Invoke-ReplacementsInFiles -RootPath $SourceFrontEnd -Replacements $replacementsTs -Extensions @('*.ts')
# END Remove import Textarea and add Renderer2 injection for extended classes of BiaFormComponent

# BEGIN - bia-input -> bia-form-field
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "bia-input" -NewRegexp 'bia-form-field' -Include "*.html"
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "bia-input" -NewRegexp 'bia-form-field' -Include "*.ts"
# END - bia-input -> bia-form-field

# BEGIN - BiaInput -> BiaFormField
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "BiaInput" -NewRegexp 'BiaFormField' -Include "*.ts"
# END - BiaInput -> BiaFormField

# BEGIN - bia-output -> bia-form-field
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "bia-output" -NewRegexp 'bia-form-field' -Include "*.html"
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "bia-output" -NewRegexp 'bia-form-field' -Include "*.ts"
# END - bia-output -> bia-form-field

# BEGIN - BiaOutput -> BiaFormField
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "BiaOutput" -NewRegexp 'BiaFormField' -Include "*.ts"
# END - BiaOutput -> BiaFormField


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
  if ($content -match "import\s*\{[^}]*\}\s*from\s*'$escapedPackage'") {
    # Append to the existing import block from the same package
    $content = $content -replace "(import\s*\{[^}]*)(}\s*from\s*'$escapedPackage')", "`$1 $componentToAdd `$2"
    $modified = $true
  }
  else {
    # Insert a new import line after the last import statement
    $fromMatches = [regex]::Matches($content, "from\s+'[^']+';")
    if ($fromMatches.Count -gt 0) {
      $lastMatch = $fromMatches[$fromMatches.Count - 1]
      $lineEnd = $content.IndexOf([char]10, $lastMatch.Index + $lastMatch.Length)
      if ($lineEnd -lt 0) { $lineEnd = $content.Length - 1 }
      $content = $content.Insert($lineEnd + 1, "import { $componentToAdd } from '$importPackage';`n")
      $modified = $true
    }
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
# BEGIN - TeamSelectionMode -> TeamAutomaticSelectionMode
ReplaceInProject ` -Source $SourceBackEnd -OldRegexp "(?<=^|\s)TeamSelectionMode(?=$|\s)" -NewRegexp 'TeamAutomaticSelectionMode' -Include "TeamConfig.cs"
# END - TeamSelectionMode -> TeamAutomaticSelectionMode

# BEGIN - charset encoding file into controllers
ReplaceInProject ` -Source $SourceBackEnd -OldRegexp 'this\.File\(buffer, BiaConstants\.Csv\.ContentType \+ ";charset=utf-8"' -NewRegexp 'this.File(buffer, BiaConstants.Csv.ContentType + $";charset={BiaConstants.Csv.CharsetEncoding}"' -Include "*Controller.cs"
# END - charset encoding file into controllers

# BEGIN - LazyLoadDto, new() -> class, IPagingFilterFormatDto, new()
ReplaceInProject ` -Source $SourceBackEnd -OldRegexp "LazyLoadDto, new\(\)" -NewRegexp 'class, IPagingFilterFormatDto, new\(\)' -Include "*.cs"
# END - LazyLoadDto, new() -> class, IPagingFilterFormatDto, new()

# BEGIN - LazyLoadDto -> PagingFilterFormatDto
ReplaceInProject ` -Source $SourceBackEnd -OldRegexp "\bLazyLoadDto\b" -NewRegexp 'PagingFilterFormatDto' -Include "*.cs"
# END - LazyLoadDto -> PagingFilterFormatDto

# BEGIN - Replace protected generic overrides in CrudAppServiceBase classes
Invoke-CrudAppServiceOverridesMigration -RootPath $SourceBackEnd
# END - Replace protected generic overrides in CrudAppServiceBase classes

# BEGIN Replace old protected generic methods names from OperationDomainServiceBase
$replacementsTs = @(
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'GetRangeAsync<'
    Replacement = 'GetRangeGenericAsync<'
  },
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'GetAllAsync<'
    Replacement = 'GetAllGenericAsync<'
  },
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'GetCsvAsync<'
    Replacement = 'GetCsvGenericAsync<'
  },
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'GetAsync<'
    Replacement = 'GetGenericAsync<'
  },
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'AddAsync<'
    Replacement = 'AddGenericAsync<'
  },
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'UpdateAsync<'
    Replacement = 'UpdateGenericAsync<'
  },
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'RemoveAsync<'
    Replacement = 'RemoveGenericAsync<'
  },
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'SaveSafeAsync<'
    Replacement = 'SaveSafeGenericAsync<'
  },
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'SaveAsync<'
    Replacement = 'SaveGenericAsync<'
  },
  @{
    Requirement = 'class\s+\w*AppService\s*:\s*(?:(?!\bclass\b)[\s\S])*?\bI\w+AppService\b'
    Pattern     = 'UpdateFixedAsync<'
    Replacement = 'UpdateFixedGenericAsync<'
  }
)

Invoke-ReplacementsInFiles -RootPath $SourceBackEnd -Replacements $replacementsTs -Extensions @('*.cs')
# END Replace old protected generic methods names from OperationDomainServiceBase

# BEGIN - Replace FullPageLayout by DynamicLayout in routing
Invoke-DynamicLayoutTransformInFiles -Source $SourceFrontEnd -Include @('*module.ts')
# END - Replace FullPageLayout by DynamicLayout in routing

# BEGIN - Add view routing in feature routing
Invoke-DynamicLayoutViewChildInsertInFiles -Source $SourceFrontEnd -Include @('*module.ts')
# END - Add view routing in feature routing

# BEGIN - Add view routing in feature routing
Invoke-IndexComponentFullCodeViews -Source $SourceFrontEnd
# END - Add view routing in feature routing

# BEGIN - autoCommit
ReplaceInProject `
  -Source $SourceBackEnd `
  -OldRegexp 'public\s*override(?<async>\s+async)?\s*Task<([\S]*?)>\s*(AddAsync|UpdateAsync)\(([\s\S]*?),(\s*)string mapperMode = null\)' `
  -NewRegexp 'public override${async} Task<$1> $2($3,$4string mapperMode = null,$4bool autoCommit = true)' `
  -Include '*Service.cs'

ReplaceInProject `
  -Source $SourceBackEnd `
  -OldRegexp 'base.AddAsync\(([\s\S]*?)mapperMode\)' `
  -NewRegexp 'base.AddAsync($1mapperMode, autoCommit: autoCommit)' `
  -Include '*Service.cs'

ReplaceInProject `
  -Source $SourceBackEnd `
  -OldRegexp 'base.UpdateAsync\(([\s\S]*?)mapperMode\)' `
  -NewRegexp 'base.UpdateAsync($1mapperMode, autoCommit: autoCommit)' `
  -Include '*Service.cs'

ReplaceInProject `
  -Source $SourceBackEnd `
  -OldRegexp 'public\s*override(?<async>\s+async)?\s*Task<([\S]*?)>\s*RemoveAsync\(([\s\S]*?),(\s*)bool bypassFixed = false\)' `
  -NewRegexp 'public override${async} Task<$1> RemoveAsync($2,$3bool bypassFixed = false,$3bool autoCommit = true)' `
  -Include '*Service.cs'

ReplaceInProject `
  -Source $SourceBackEnd `
  -OldRegexp 'base.RemoveAsync\(([\s\S]*?)bypassFixed\)' `
  -NewRegexp 'base.RemoveAsync($1bypassFixed, autoCommit: autoCommit)' `
  -Include '*Service.cs'
# END - autoCommit

# BEGIN - Directory.Packages.props
Invoke-ManageCentralPackageVersions -SourcePath $SourceBackEnd
ReplaceInProject `
  -Source $SourceBackEnd `
  -OldRegexp '<PackageReference Include="([\s\S]*?)" Version="(.*)"' `
  -NewRegexp '<PackageReference Include="$1"' `
  -Include '*.csproj'
# END - Directory.Packages.props

# BEGIN - Transform RowVersion properties for versioning
ReplaceInProject `
 -Source $SourceBackEnd `
 -OldRegexp '(\s*)\[Timestamp\]\r?\n\s*\[Column\("RowVersion"\)\]\r?\n\s*public byte\[\] RowVersion([A-Za-z0-9_]+) \{ get; set; \}' `
 -NewRegexp '$1[BiaRowVersionProperty(DbProvider.SqlServer)]$1[AuditIgnore]$1public byte[] RowVersion$2 { get; set; }
$1/// <summary>$1/// Add row version for Postgre in table $2.$1/// </summary>$1[BiaRowVersionProperty(DbProvider.PostGreSql)]$1[AuditIgnore]$1public uint RowVersionXmin$2 { get; set; }' `
 -Include "*.cs"
# END - Transform RowVersion properties for versioning

# BEGIN - BiaClaimsPrincipal.RoleIds -> BiaConstants.Claims.RoleIds
ReplaceInProject ` -Source $SourceBackEnd -OldRegexp 'BiaClaimsPrincipal\.RoleIds' -NewRegexp 'BiaConstants.Claims.RoleIds' -Include "*.cs"
# END - BiaClaimsPrincipal.RoleIds -> BiaConstants.Claims.RoleIds

# FRONT END CLEAN
Set-Location $SourceFrontEnd
npm run clean

# BACK END RESTORE
Set-Location $SourceBackEnd
dotnet restore --no-cache

Write-Host "Finish"
pause
