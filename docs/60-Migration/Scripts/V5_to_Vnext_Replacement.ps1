$Source = "C:\sources\github\BIADemo";
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
  [CmdletBinding()]
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

  Get-ChildItem -Path $RootPath -Recurse -File -Include $Extensions |
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
      $content         = Get-Content -LiteralPath $_.FullName -Raw
      $fileModified    = $false
      $fileReplacements = @()
      $contentCurrent  = $content

      foreach ($rule in $Replacements) {
        if($rule.Requirement -and -not ($content -cmatch $rule.Requirement)) {
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

function ApplyChangesToLib {
  Write-Host "[Apply changes for bia-ng lib]"
  
  $replacementsTS = @(
    # Update enum imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDtoState\b)([\s\S]*?)[\s]*?\bDtoState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto-state\.enum';)"; Replacement = 'import { DtoState } from ''bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bEnvironmentType\b)([\s\S]*?)[\s]*?\bEnvironmentType\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { EnvironmentType } from ''bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bHttpStatusCodeCustom\b)([\s\S]*?)[\s]*?\bHttpStatusCodeCustom\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/http-status-code-custom\.enum';)"; Replacement = 'import { HttpStatusCodeCustom } from ''bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNumberMode\b)([\s\S]*?)[\s]*?\bNumberMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { NumberMode } from ''bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPrimeNGFiltering\b)([\s\S]*?)[\s]*?\bPrimeNGFiltering\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { PrimeNGFiltering } from ''bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPropType\b)([\s\S]*?)[\s]*?\bPropType\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { PropType } from ''bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRoleMode\b)([\s\S]*?)[\s]*?\bRoleMode\b[,]?([\s\S]*?} from '[\s\S]*?\/constants';)"; Replacement = 'import { RoleMode } from ''bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamTypeId\b)([\s\S]*?)[\s]*?\bTeamTypeId\b[,]?([\s\S]*?} from '[\s\S]*?\/constants';)"; Replacement = 'import { TeamTypeId } from ''bia-ng/models/enum''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewType\b)([\s\S]*?)[\s]*?\bViewType\b[,]?([\s\S]*?} from '[\s\S]*?\/constants';)"; Replacement = 'import { ViewType } from ''bia-ng/models/enum''; import { $1$2'},
    
    # Update models imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bArchivableDto\b)([\s\S]*?)[\s]*?\bArchivableDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/archivable-dto';)"; Replacement = 'import { ArchivableDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBaseDto\b)([\s\S]*?)[\s]*?\bBaseDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/base-dto';)"; Replacement = 'import { BaseDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFixableDto\b)([\s\S]*?)[\s]*?\bFixableDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/fixable-dto';)"; Replacement = 'import { FixableDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamDto\b)([\s\S]*?)[\s]*?\bTeamDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/team-dto';)"; Replacement = 'import { TeamDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bteamFieldsConfigurationColumns\b)([\s\S]*?)[\s]*?\bteamFieldsConfigurationColumns\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/team-dto';)"; Replacement = 'import { teamFieldsConfigurationColumns } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bVersionedDto\b)([\s\S]*?)[\s]*?\bVersionedDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/versioned-dto';)"; Replacement = 'import { VersionedDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppConfig\b)([\s\S]*?)[\s]*?\bAppConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { AppConfig } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuMode\b)([\s\S]*?)[\s]*?\bMenuMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { MenuMode } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFooterMode\b)([\s\S]*?)[\s]*?\bFooterMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { FooterMode } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bColorScheme\b)([\s\S]*?)[\s]*?\bColorScheme\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { ColorScheme } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuProfilePosition\b)([\s\S]*?)[\s]*?\bMenuProfilePosition\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { MenuProfilePosition } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettings\b)([\s\S]*?)[\s]*?\bAppSettings\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { AppSettings } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bEnvironment\b)([\s\S]*?)[\s]*?\bEnvironment\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Environment } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCulture\b)([\s\S]*?)[\s]*?\bCulture\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Culture } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bKeycloak\b)([\s\S]*?)[\s]*?\bKeycloak\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Keycloak } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bConfiguration\b)([\s\S]*?)[\s]*?\bConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Configuration } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bApi\b)([\s\S]*?)[\s]*?\bApi\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { Api } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTokenConf\b)([\s\S]*?)[\s]*?\bTokenConf\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { TokenConf } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bProfileConfiguration\b)([\s\S]*?)[\s]*?\bProfileConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { ProfileConfiguration } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeConfiguration\b)([\s\S]*?)[\s]*?\bIframeConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { IframeConfiguration } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAllowedHost\b)([\s\S]*?)[\s]*?\bAllowedHost\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/model\/app-settings';)"; Replacement = 'import { AllowedHost } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLoginParamDto\b)([\s\S]*?)[\s]*?\bLoginParamDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { LoginParamDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamConfigDto\b)([\s\S]*?)[\s]*?\bTeamConfigDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { TeamConfigDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserProfile\b)([\s\S]*?)[\s]*?\bUserProfile\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { UserProfile } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserData\b)([\s\S]*?)[\s]*?\bUserData\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { UserData } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCurrentTeamDto\b)([\s\S]*?)[\s]*?\bCurrentTeamDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { CurrentTeamDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAdditionalInfos\b)([\s\S]*?)[\s]*?\bAdditionalInfos\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { AdditionalInfos } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bToken\b)([\s\S]*?)[\s]*?\bToken\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { Token } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAuthInfo\b)([\s\S]*?)[\s]*?\bAuthInfo\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/auth-info';)"; Replacement = 'import { AuthInfo } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldNumberFormat\b)([\s\S]*?)[\s]*?\bBiaFieldNumberFormat\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldNumberFormat } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldDateFormat\b)([\s\S]*?)[\s]*?\bBiaFieldDateFormat\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldDateFormat } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldConfig\b)([\s\S]*?)[\s]*?\bBiaFieldConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldConfig } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldsConfig\b)([\s\S]*?)[\s]*?\bBiaFieldsConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldsConfig } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfig\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfig } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigItem\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigItem } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigRow\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigRow\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigRow } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigColumn\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigColumn\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigColumn } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigGroup\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigGroup\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigGroup } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigField\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigField\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigField } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigTabGroup\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigTabGroup\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigTabGroup } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigTab\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigTab\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigTab } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigColumnSize\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigColumnSize\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigColumnSize } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaNavigation\b)([\s\S]*?)[\s]*?\bBiaNavigation\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-navigation';)"; Replacement = 'import { BiaNavigation } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableState\b)([\s\S]*?)[\s]*?\bBiaTableState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-table-state';)"; Replacement = 'import { BiaTableState } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bConfigDisplay\b)([\s\S]*?)[\s]*?\bConfigDisplay\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/config-display';)"; Replacement = 'import { ConfigDisplay } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDEFAULT_CRUD_STATE\b)([\s\S]*?)[\s]*?\bDEFAULT_CRUD_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/crud-state';)"; Replacement = 'import { DEFAULT_CRUD_STATE } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudState\b)([\s\S]*?)[\s]*?\bCrudState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/crud-state';)"; Replacement = 'import { CrudState } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDataResult\b)([\s\S]*?)[\s]*?\bDataResult\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/data-result';)"; Replacement = 'import { DataResult } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bExternalSiteConfig\b)([\s\S]*?)[\s]*?\bExternalSiteConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/external-site-config';)"; Replacement = 'import { ExternalSiteConfig } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bHttpOptions\b)([\s\S]*?)[\s]*?\bHttpOptions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-options';)"; Replacement = 'import { HttpOptions } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bGetParam\b)([\s\S]*?)[\s]*?\bGetParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { GetParam } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bGetListParam\b)([\s\S]*?)[\s]*?\bGetListParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { GetListParam } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bGetListByPostParam\b)([\s\S]*?)[\s]*?\bGetListByPostParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { GetListByPostParam } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bSaveParam\b)([\s\S]*?)[\s]*?\bSaveParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { SaveParam } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPutParam\b)([\s\S]*?)[\s]*?\bPutParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { PutParam } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPostParam\b)([\s\S]*?)[\s]*?\bPostParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { PostParam } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDeleteParam\b)([\s\S]*?)[\s]*?\bDeleteParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { DeleteParam } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDeletesParam\b)([\s\S]*?)[\s]*?\bDeletesParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { DeletesParam } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUpdateFixedStatusParam\b)([\s\S]*?)[\s]*?\bUpdateFixedStatusParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-params';)"; Replacement = 'import { UpdateFixedStatusParam } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bHttpRequestItem\b)([\s\S]*?)[\s]*?\bHttpRequestItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/models\/http-request-item';)"; Replacement = 'import { HttpRequestItem } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeConfig\b)([\s\S]*?)[\s]*?\bIframeConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/iframe-config';)"; Replacement = 'import { IframeConfig } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeMessage\b)([\s\S]*?)[\s]*?\bIframeMessage\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/iframe-message';)"; Replacement = 'import { IframeMessage } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bKeyValuePair\b)([\s\S]*?)[\s]*?\bKeyValuePair\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/key-value-pair';)"; Replacement = 'import { KeyValuePair } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bOptionDto\b)([\s\S]*?)[\s]*?\bOptionDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/option-dto';)"; Replacement = 'import { OptionDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPagingFilterFormatDto\b)([\s\S]*?)[\s]*?\bPagingFilterFormatDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/paging-filter-format';)"; Replacement = 'import { PagingFilterFormatDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPrimeLocale\b)([\s\S]*?)[\s]*?\bPrimeLocale\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/prime-locale';)"; Replacement = 'import { PrimeLocale } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRoleDto\b)([\s\S]*?)[\s]*?\bRoleDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/role';)"; Replacement = 'import { RoleDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTargetedFeature\b)([\s\S]*?)[\s]*?\bTargetedFeature\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/signalR';)"; Replacement = 'import { TargetedFeature } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamAdvancedFilterDto\b)([\s\S]*?)[\s]*?\bTeamAdvancedFilterDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/team-advanced-filter-dto';)"; Replacement = 'import { TeamAdvancedFilterDto } from ''bia-ng/models''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeam\b)([\s\S]*?)[\s]*?\bTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/model\/team';)"; Replacement = 'import { Team } from ''bia-ng/models''; import { $1$2'},

    # Update bia-core imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettingsDas\b)([\s\S]*?)[\s]*?\bAppSettingsDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/services\/app-settings-das.service';)"; Replacement = 'import { AppSettingsDas } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettings\b)([\s\S]*?)[\s]*?\bAppSettings\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/services\/app-settings.service';)"; Replacement = 'import { AppSettings } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "\bDomainAppSettingsActions\b"; Replacement = 'CoreAppSettingsActions'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCoreAppSettingsActions\b)([\s\S]*?)[\s]*?\bCoreAppSettingsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings-actions';)"; Replacement = 'import { CoreAppSettingsActions } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettingsEffects\b)([\s\S]*?)[\s]*?\bAppSettingsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings-actions';)"; Replacement = 'import { AppSettingsEffects } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettingsState\b)([\s\S]*?)[\s]*?\bAppSettingsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings\.state';)"; Replacement = 'import { AppSettingsState } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAppSettingsState\b)([\s\S]*?)[\s]*?\bgetAppSettingsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings\.state';)"; Replacement = 'import { getAppSettingsState } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAppSettings\b)([\s\S]*?)[\s]*?\bgetAppSettings\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/store\/app-settings\.state';)"; Replacement = 'import { getAppSettings } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppSettingsModule\b)([\s\S]*?)[\s]*?\bAppSettingsModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/app-settings\/app-settings\.module';)"; Replacement = 'import { AppSettingsModule } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPermissionGuard\b)([\s\S]*?)[\s]*?\bPermissionGuard\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/guards\/permission\.guard';)"; Replacement = 'import { PermissionGuard } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOnlineOfflineInterceptor\b)([\s\S]*?)[\s]*?\bBiaOnlineOfflineInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-online-offline\.interceptor';)"; Replacement = 'import { BiaOnlineOfflineInterceptor } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaOnlineOfflineInterceptor\b)([\s\S]*?)[\s]*?\bbiaOnlineOfflineInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-online-offline\.interceptor';)"; Replacement = 'import { biaOnlineOfflineInterceptor } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bXhrWithCredInterceptorService\b)([\s\S]*?)[\s]*?\bXhrWithCredInterceptorService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-xhr-with-cred-interceptor\.service';)"; Replacement = 'import { XhrWithCredInterceptorService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaXhrWithCredInterceptor\b)([\s\S]*?)[\s]*?\bbiaXhrWithCredInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-xhr-with-cred-interceptor\.service';)"; Replacement = 'import { biaXhrWithCredInterceptor } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bStandardEncodeHttpParamsInterceptor\b)([\s\S]*?)[\s]*?\bStandardEncodeHttpParamsInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/standard-encode-http-params-interceptor\.service';)"; Replacement = 'import { StandardEncodeHttpParamsInterceptor } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bStandardEncoder\b)([\s\S]*?)[\s]*?\bStandardEncoder\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/standard-encoder';)"; Replacement = 'import { StandardEncoder } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTokenInterceptor\b)([\s\S]*?)[\s]*?\bTokenInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/token\.interceptor';)"; Replacement = 'import { TokenInterceptor } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaTokenInterceptor\b)([\s\S]*?)[\s]*?\bbiaTokenInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/token\.interceptor';)"; Replacement = 'import { biaTokenInterceptor } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotification\b)([\s\S]*?)[\s]*?\bNotification\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/model\/notification';)"; Replacement = 'import { Notification } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTeam\b)([\s\S]*?)[\s]*?\bNotificationTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/model\/notification';)"; Replacement = 'import { NotificationTeam } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationType\b)([\s\S]*?)[\s]*?\bNotificationType\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/model\/notification';)"; Replacement = 'import { NotificationType } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationData\b)([\s\S]*?)[\s]*?\bNotificationData\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/model\/notification';)"; Replacement = 'import { NotificationData } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationDas\b)([\s\S]*?)[\s]*?\bNotificationDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/services\/notification-das\.service';)"; Replacement = 'import { NotificationDas } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationSignalRService\b)([\s\S]*?)[\s]*?\bNotificationSignalRService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/services\/notification-signalr\.service';)"; Replacement = 'import { NotificationSignalRService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bNotificationsState\b)[\s\S]*?\bNotificationsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bNotificationsState\b"; Replacement = '$1CoreNotificationsStore.NotificationsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\breducers\b"; Replacement = '$1CoreNotificationsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetNotificationsState\b)[\s\S]*?\bgetNotificationsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetNotificationsState\b"; Replacement = '$1CoreNotificationsStore.getNotificationsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetNotificationsEntitiesState\b)[\s\S]*?\bgetNotificationsEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetNotificationsEntitiesState\b"; Replacement = '$1CoreNotificationsStore.getNotificationsEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUserNotifications\b)[\s\S]*?\bgetUserNotifications\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetUserNotifications\b"; Replacement = '$1CoreNotificationsStore.getUserNotifications'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUnreadNotificationCount\b)[\s\S]*?\bgetUnreadNotificationCount\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetUnreadNotificationCount\b"; Replacement = '$1CoreNotificationsStore.getUnreadNotificationCount'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllNotifications\b)[\s\S]*?\bgetAllNotifications\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetAllNotifications\b"; Replacement = '$1CoreNotificationsStore.getAllNotifications'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetNotificationById\b)[\s\S]*?\bgetNotificationById\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';[\s\S]*)\bgetNotificationById\b"; Replacement = '$1CoreNotificationsStore.getNotificationById'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationsState\b)([\s\S]*?)[\s]*?\bNotificationsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationsState\b)([\s\S]*?)[\s]*?\bgetNotificationsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationsEntitiesState\b)([\s\S]*?)[\s]*?\bgetNotificationsEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUserNotifications\b)([\s\S]*?)[\s]*?\bgetUserNotifications\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUnreadNotificationCount\b)([\s\S]*?)[\s]*?\bgetUnreadNotificationCount\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllNotifications\b)([\s\S]*?)[\s]*?\bgetAllNotifications\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetNotificationById\b)([\s\S]*?)[\s]*?\bgetNotificationById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notification\.state';)"; Replacement = 'import { CoreNotificationsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "\bDomainNotificationsActions\b"; Replacement = 'CoreNotificationsActions'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCoreNotificationsActions\b)([\s\S]*?)[\s]*?\bCoreNotificationsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notifications-actions';)"; Replacement = 'import { CoreNotificationsActions } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationsEffects\b)([\s\S]*?)[\s]*?\bNotificationsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/store\/notifications-effects';)"; Replacement = 'import { NotificationsEffects } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationModule\b)([\s\S]*?)[\s]*?\bNotificationModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/notification\/notification\.module';)"; Replacement = 'import { NotificationModule } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaMatomoService\b)([\s\S]*?)[\s]*?\bBiaMatomoService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/matomo\/bia-matomo\.service';)"; Replacement = 'import { BiaMatomoService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMatomoInjector\b)([\s\S]*?)[\s]*?\bMatomoInjector\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/matomo\/matomo-injector\.service';)"; Replacement = 'import { MatomoInjector } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMatomoTracker\b)([\s\S]*?)[\s]*?\bMatomoTracker\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/matomo\/matomo-tracker\.service';)"; Replacement = 'import { MatomoTracker } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAbstractDas\b)([\s\S]*?)[\s]*?\bAbstractDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/abstract-das\.service';)"; Replacement = 'import { AbstractDas } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAuthService\b)([\s\S]*?)[\s]*?\bAuthService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/auth\.service';)"; Replacement = 'import { AuthService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaAppInitService\b)([\s\S]*?)[\s]*?\bBiaAppInitService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-app-init\.service';)"; Replacement = 'import { BiaAppInitService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaBarcodeScannerService\b)([\s\S]*?)[\s]*?\bBiaBarcodeScannerService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-barcode-scanner\.service';)"; Replacement = 'import { BiaBarcodeScannerService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaDialogService\b)([\s\S]*?)[\s]*?\bBiaDialogService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-dialog\.service';)"; Replacement = 'import { BiaDialogService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaEnvironmentService\b)([\s\S]*?)\bBiaEnvironmentService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-environment\.service';)"; Replacement = 'import { BiaEnvironmentService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaInjectExternalService\b)([\s\S]*?)[\s]*?\bBiaInjectExternalService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-inject-external\.service';)"; Replacement = 'import { BiaInjectExternalService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaInjectorService\b)([\s\S]*?)[\s]*?\bBiaInjectorService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-injector\.service';)"; Replacement = 'import { BiaInjectorService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaMessageService\b)([\s\S]*?)[\s]*?\bBiaMessageService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-message\.service';)"; Replacement = 'import { BiaMessageService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaNgxLoggerServerService\b)([\s\S]*?)[\s]*?\bBiaNgxLoggerServerService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-ngx-logger-server\.service';)"; Replacement = 'import { BiaNgxLoggerServerService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOnlineOfflineService\b)([\s\S]*?)[\s]*?\bBiaOnlineOfflineService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-online-offline\.service';)"; Replacement = 'import { BiaOnlineOfflineService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOptionService\b)([\s\S]*?)[\s]*?\bBiaOptionService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-option\.service';)"; Replacement = 'import { BiaOptionService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaSignalRService\b)([\s\S]*?)\bBiaSignalRService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-signalr\.service';)"; Replacement = 'import { BiaSignalRService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaSwUpdateService\b)([\s\S]*?)\bBiaSwUpdateService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-sw-update\.service';)"; Replacement = 'import { BiaSwUpdateService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTranslateHttpLoader\b)([\s\S]*?)\bBiaTranslateHttpLoader\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translate-http-loader';)"; Replacement = 'import { BiaTranslateHttpLoader } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetCurrentCulture\b)([\s\S]*?)\bgetCurrentCulture\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { getCurrentCulture } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bSTORAGE_CULTURE_KEY\b)([\s\S]*?)\bSTORAGE_CULTURE_KEY\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { STORAGE_CULTURE_KEY } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDateFormat\b)([\s\S]*?)\bDateFormat\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { DateFormat } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTranslationService\b)([\s\S]*?)[\s]*?\bBiaTranslationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { BiaTranslationService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDateHelperService\b)([\s\S]*?)[\s]*?\bDateHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/date-helper\.service';)"; Replacement = 'import { DateHelperService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bGenericDas\b)([\s\S]*?)[\s]*?\bGenericDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/generic-das\.service';)"; Replacement = 'import { GenericDas } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNavigationService\b)([\s\S]*?)[\s]*?\bNavigationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/navigation\.service';)"; Replacement = 'import { NavigationService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRefreshTokenService\b)([\s\S]*?)[\s]*?\bRefreshTokenService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/refresh-token\.service';)"; Replacement = 'import { RefreshTokenService } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaSuccessWaitRefreshSignalR\b)([\s\S]*?)[\s]*?\bbiaSuccessWaitRefreshSignalR\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/shared\/bia-action';)"; Replacement = 'import { biaSuccessWaitRefreshSignalR } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaErrorHandler\b)([\s\S]*?)\bBiaErrorHandler\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/shared\/bia-error-handler';)"; Replacement = 'import { BiaErrorHandler } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamDas\b)([\s\S]*?)\bTeamDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/services\/team-das\.service';)"; Replacement = 'import { TeamDas } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bTeamsState\b)[\s\S]*?\bTeamsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bTeamsState\b"; Replacement = '$1CoreTeamsStore.TeamsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\breducers\b"; Replacement = '$1CoreTeamsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetTeamsState\b)[\s\S]*?\bgetTeamsState\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bgetTeamsState\b"; Replacement = '$1CoreTeamsStore.getTeamsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllTeams\b)[\s\S]*?\bgetAllTeams\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bgetAllTeams\b"; Replacement = '$1CoreTeamsStore.getAllTeams'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetTeamById\b)[\s\S]*?\bgetTeamById\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bgetTeamById\b"; Replacement = '$1CoreTeamsStore.getTeamById'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllTeamsOfType\b)[\s\S]*?\bgetAllTeamsOfType\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bgetAllTeamsOfType\b"; Replacement = '$1CoreTeamsStore.getAllTeamsOfType'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamsState\b)([\s\S]*?)[\s]*?\bTeamsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers\b)([\s\S]*?)[\s]*?\breducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetTeamsState\b)([\s\S]*?)[\s]*?\bgetTeamsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllTeams\b)([\s\S]*?)[\s]*?\bgetAllTeams\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetTeamById\b)([\s\S]*?)[\s]*?\bgetTeamById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllTeamsOfType\b)([\s\S]*?)[\s]*?\bgetAllTeamsOfType\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { CoreTeamsStore } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "\bDomainTeamsActions\b"; Replacement = 'CoreTeamsActions'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCoreTeamsActions\b)([\s\S]*?)[\s]*?\bCoreTeamsActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/teams-actions';)"; Replacement = 'import { CoreTeamsActions } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamsEffects\b)([\s\S]*?)[\s]*?\bTeamsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/teams-effects';)"; Replacement = 'import { TeamsEffects } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamModule\b)([\s\S]*?)[\s]*?\bTeamModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/team\.module';)"; Replacement = 'import { TeamModule } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\binitializeApp\b)([\s\S]*?)[\s]*?\binitializeApp\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/bia-core\.module';)"; Replacement = 'import { initializeApp } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaCoreModule\b)([\s\S]*?)[\s]*?\bBiaCoreModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/bia-core\.module';)"; Replacement = 'import { BiaCoreModule } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDataItem\b)([\s\S]*?)[\s]*?\bDataItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/db';)"; Replacement = 'import { DataItem } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppDB\b)([\s\S]*?)[\s]*?\bAppDB\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/db';)"; Replacement = 'import { AppDB } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bisEmpty\b)([\s\S]*?)[\s]*?\bisEmpty\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/utils';)"; Replacement = 'import { isEmpty } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bisObject\b)([\s\S]*?)[\s]*?\bisObject\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/utils';)"; Replacement = 'import { isObject } from ''bia-ng/core''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bclone\b)([\s\S]*?)[\s]*?\bclone\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/utils';)"; Replacement = 'import { clone } from ''bia-ng/core''; import { $1$2'},
    # TODO : some constant.ts constants moving to bia-ng/core
    # TODO : some permissions moved to bia-ng/core

    # Update bia-shared imports
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaButtonGroupComponent\b)([\s\S]*?)[\s]*?\bBiaButtonGroupComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-button-group\/bia-button-group\.component';)"; Replacement = 'import { BiaButtonGroupComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaButtonGroupItem\b)([\s\S]*?)[\s]*?\bBiaButtonGroupItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-button-group\/bia-button-group\.component';)"; Replacement = 'import { BiaButtonGroupItem } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\binitExternalSiteConfig\b)([\s\S]*?)[\s]*?\binitExternalSiteConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-external-site\/bia-external-site\.component';)"; Replacement = 'import { initExternalSiteConfig } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaExternalSiteComponent\b)([\s\S]*?)[\s]*?\bBiaExternalSiteComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-external-site\/bia-external-site\.component';)"; Replacement = 'import { BiaExternalSiteComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOnlineOfflineIconComponent\b)([\s\S]*?)[\s]*?\bBiaOnlineOfflineIconComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-online-offline-icon\/bia-online-offline-icon\.component';)"; Replacement = 'import { BiaOnlineOfflineIconComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTeamSelectorComponent\b)([\s\S]*?)[\s]*?\bBiaTeamSelectorComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-team-selector\/bia-team-selector\.component';)"; Replacement = 'import { BiaTeamSelectorComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldBaseComponent\b)([\s\S]*?)[\s]*?\bBiaFieldBaseComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-field-base\/bia-field-base\.component';)"; Replacement = 'import { BiaFieldBaseComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldHelperService\b)([\s\S]*?)[\s]*?\bBiaFieldHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-field-base\/bia-field-helper\.service';)"; Replacement = 'import { BiaFieldHelperService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormComponent\b)([\s\S]*?)[\s]*?\bBiaFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-form\/bia-form\.component';)"; Replacement = 'import { BiaFormComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutComponent\b)([\s\S]*?)[\s]*?\bBiaFormLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-form-layout\/bia-form-layout\.component';)"; Replacement = 'import { BiaFormLayoutComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaInputComponent\b)([\s\S]*?)[\s]*?\bBiaInputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-input\/bia-input\.component';)"; Replacement = 'import { BiaInputComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOutputComponent\b)([\s\S]*?)[\s]*?\bBiaOutputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-output\/bia-output\.component';)"; Replacement = 'import { BiaOutputComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bHangfireContainerComponent\b)([\s\S]*?)[\s]*?\bHangfireContainerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/hangfire-container\/hangfire-container\.component';)"; Replacement = 'import { HangfireContainerComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuChangeEvent\b)([\s\S]*?)[\s]*?\bMenuChangeEvent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/api\/menuchangeevent';)"; Replacement = 'import { MenuChangeEvent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bClassicPageLayoutComponent\b)([\s\S]*?)[\s]*?\bClassicPageLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/classic-page-layout\/classic-page-layout\.component';)"; Replacement = 'import { ClassicPageLayoutComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLayoutMode\b)([\s\S]*?)[\s]*?\bLayoutMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/dynamic-layout\/dynamic-layout\.component';)"; Replacement = 'import { LayoutMode } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDynamicLayoutComponent\b)([\s\S]*?)[\s]*?\bDynamicLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/dynamic-layout\/dynamic-layout\.component';)"; Replacement = 'import { DynamicLayoutComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFullPageLayoutComponent\b)([\s\S]*?)[\s]*?\bFullPageLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/fullpage-layout\/fullpage-layout\.component';)"; Replacement = 'import { FullPageLayoutComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIeWarningComponent\b)([\s\S]*?)[\s]*?\bIeWarningComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ie-warning\/ie-warning\.component';)"; Replacement = 'import { IeWarningComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPopupLayoutComponent\b)([\s\S]*?)[\s]*?\bPopupLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/popup-layout\/popup-layout\.component';)"; Replacement = 'import { PopupLayoutComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaScrollingNotificationComponent\b)([\s\S]*?)[\s]*?\bBiaScrollingNotificationComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/scrolling-notification\/scrolling-notification\.component';)"; Replacement = 'import { BiaScrollingNotificationComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaThemeService\b)([\s\S]*?)[\s]*?\bBiaThemeService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-theme\.service';)"; Replacement = 'import { BiaThemeService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBIA_USER_CONFIG\b)([\s\S]*?)[\s]*?\bBIA_USER_CONFIG\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { BIA_USER_CONFIG } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBIA_LAYOUT_DATA\b)([\s\S]*?)[\s]*?\bBIA_LAYOUT_DATA\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { BIA_LAYOUT_DATA } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaLayoutService\b)([\s\S]*?)[\s]*?\bBiaLayoutService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout\.service';)"; Replacement = 'import { BiaLayoutService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuProfileConfig\b)([\s\S]*?)[\s]*?\bMenuProfileConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/menu-profile\.service';)"; Replacement = 'import { MenuProfileConfig } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaMenuProfileService\b)([\s\S]*?)[\s]*?\bBiaMenuProfileService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/menu-profile\.service';)"; Replacement = 'import { BiaMenuProfileService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMenuService\b)([\s\S]*?)[\s]*?\bMenuService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/menu\.service';)"; Replacement = 'import { MenuService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaConfigComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaConfigComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/config\/ultima-config\.component';)"; Replacement = 'import { BiaUltimaConfigComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaFooterComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaFooterComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/footer\/ultima-footer\.component';)"; Replacement = 'import { BiaUltimaFooterComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaLayoutComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/layout\/ultima-layout\.component';)"; Replacement = 'import { BiaUltimaLayoutComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaMenuComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaMenuComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/menu\/ultima-menu\.component';)"; Replacement = 'import { BiaUltimaMenuComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaMenuItemComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaMenuItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/menu-item\/ultima-menu-item\.component';)"; Replacement = 'import { BiaUltimaMenuItemComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaMenuProfileComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaMenuProfileComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/menu-profile\/ultima-menu-profile\.component';)"; Replacement = 'import { BiaUltimaMenuProfileComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaSidebarComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaSidebarComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/sidebar\/ultima-sidebar\.component';)"; Replacement = 'import { BiaUltimaSidebarComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaTopbarComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaTopbarComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/topbar\/ultima-topbar\.component';)"; Replacement = 'import { BiaUltimaTopbarComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaLayoutModule\b)([\s\S]*?)[\s]*?\bBiaUltimaLayoutModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/ultima-layout\.module';)"; Replacement = 'import { BiaUltimaLayoutModule } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLayoutComponent\b)([\s\S]*?)[\s]*?\bLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/layout\.component';)"; Replacement = 'import { LayoutComponent   } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPageLayoutComponent\b)([\s\S]*?)[\s]*?\bPageLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/page-layout\.component';)"; Replacement = 'import { PageLayoutComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIsNotCurrentTeamPipe\b)([\s\S]*?)[\s]*?\bIsNotCurrentTeamPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/notification-team-warning\/is-not-current-team\/is-not-current-team\.pipe';)"; Replacement = 'import { IsNotCurrentTeamPipe } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamListPipe\b)([\s\S]*?)[\s]*?\bTeamListPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/notification-team-warning\/team-list\/team-list\.pipe';)"; Replacement = 'import { TeamListPipe } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNotificationTeamWarningComponent\b)([\s\S]*?)[\s]*?\bNotificationTeamWarningComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/notification-team-warning\/notification-team-warning\.component';)"; Replacement = 'import { NotificationTeamWarningComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bSpinnerComponent\b)([\s\S]*?)[\s]*?\bSpinnerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/spinner\/spinner\.component';)"; Replacement = 'import { SpinnerComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaCalcTableComponent\b)([\s\S]*?)[\s]*?\bBiaCalcTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-calc-table\/bia-calc-table\.component';)"; Replacement = 'import { BiaCalcTableComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFrozenColumnDirective\b)([\s\S]*?)[\s]*?\bBiaFrozenColumnDirective\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-frozen-column\/bia-frozen-column\.directive';)"; Replacement = 'import { BiaFrozenColumnDirective } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableComponent\b)([\s\S]*?)[\s]*?\bBiaTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table\/bia-table\.component';)"; Replacement = 'import { BiaTableComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDictOptionDto\b)([\s\S]*?)[\s]*?\bDictOptionDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table\/dict-option-dto';)"; Replacement = 'import { DictOptionDto } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaBehaviorIcon\b)([\s\S]*?)[\s]*?\bBiaBehaviorIcon\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-behavior-controller\/bia-table-behavior-controller\.component';)"; Replacement = 'import { BiaBehaviorIcon } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableBehaviorControllerComponent\b)([\s\S]*?)[\s]*?\bBiaTableBehaviorControllerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-behavior-controller\/bia-table-behavior-controller\.component';)"; Replacement = 'import { BiaTableBehaviorControllerComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableControllerComponent\b)([\s\S]*?)[\s]*?\bBiaTableControllerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-controller\/bia-table-controller\.component';)"; Replacement = 'import { BiaTableControllerComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableFilterComponent\b)([\s\S]*?)[\s]*?\bBiaTableFilterComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-filter\/bia-table-filter\.component';)"; Replacement = 'import { BiaTableFilterComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableFooterControllerComponent\b)([\s\S]*?)[\s]*?\bBiaTableFooterControllerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-footer-controller\/bia-table-footer-controller\.component';)"; Replacement = 'import { BiaTableFooterControllerComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableHeaderComponent\b)([\s\S]*?)[\s]*?\bBiaTableHeaderComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-header\/bia-table-header\.component';)"; Replacement = 'import { BiaTableHeaderComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableInputComponent\b)([\s\S]*?)[\s]*?\bBiaTableInputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-input\/bia-table-input\.component';)"; Replacement = 'import { BiaTableInputComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableOutputComponent\b)([\s\S]*?)[\s]*?\bBiaTableOutputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-output\/bia-table-output\.component';)"; Replacement = 'import { BiaTableOutputComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamAdvancedFilterComponent\b)([\s\S]*?)[\s]*?\bTeamAdvancedFilterComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/team-advanced-filter\/team-advanced-filter\.component';)"; Replacement = 'import { TeamAdvancedFilterComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemFormComponent\b)([\s\S]*?)[\s]*?\bCrudItemFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/components\/crud-item-form\/crud-item-form\.component';)"; Replacement = 'import { CrudItemFormComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemImportFormComponent\b)([\s\S]*?)[\s]*?\bCrudItemImportFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/components\/crud-item-import-form\/crud-item-import-form\.component';)"; Replacement = 'import { CrudItemImportFormComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemTableComponent\b)([\s\S]*?)[\s]*?\bCrudItemTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/components\/crud-item-table\/crud-item-table\.component';)"; Replacement = 'import { CrudItemTableComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFormReadOnlyMode\b)([\s\S]*?)[\s]*?\bFormReadOnlyMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/model\/crud-config';)"; Replacement = 'import { FormReadOnlyMode } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bShowIconsConfig\b)([\s\S]*?)[\s]*?\bShowIconsConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/model\/crud-config';)"; Replacement = 'import { ShowIconsConfig } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudConfig\b)([\s\S]*?)[\s]*?\bCrudConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/model\/crud-config';)"; Replacement = 'import { CrudConfig } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bImportParam\b)([\s\S]*?)[\s]*?\bImportParam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-import\.service';)"; Replacement = 'import { ImportParam } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bImportDataError\b)([\s\S]*?)[\s]*?\bImportDataError\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-import\.service';)"; Replacement = 'import { ImportDataError } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bImportData\b)([\s\S]*?)[\s]*?\bImportData\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-import\.service';)"; Replacement = 'import { ImportData } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemImportService\b)([\s\S]*?)[\s]*?\bCrudItemImportService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-import\.service';)"; Replacement = 'import { CrudItemImportService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemOptionsService\b)([\s\S]*?)[\s]*?\bCrudItemOptionsService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-options\.service';)"; Replacement = 'import { CrudItemOptionsService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemSignalRService\b)([\s\S]*?)[\s]*?\bCrudItemSignalRService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-signalr\.service';)"; Replacement = 'import { CrudItemSignalRService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemSingleService\b)([\s\S]*?)[\s]*?\bCrudItemSingleService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-single\.service';)"; Replacement = 'import { CrudItemSingleService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemService\b)([\s\S]*?)[\s]*?\bCrudItemService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item\.service';)"; Replacement = 'import { CrudItemService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemComponent\b)([\s\S]*?)[\s]*?\bCrudItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item\/crud-item\.component';)"; Replacement = 'import { CrudItemComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemEditComponent\b)([\s\S]*?)[\s]*?\bCrudItemEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-edit\/crud-item-edit\.component';)"; Replacement = 'import { CrudItemEditComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemImportComponent\b)([\s\S]*?)[\s]*?\bCrudItemImportComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-import\/crud-item-import\.component';)"; Replacement = 'import { CrudItemImportComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemItemComponent\b)([\s\S]*?)[\s]*?\bCrudItemItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-item\/crud-item-item\.component';)"; Replacement = 'import { CrudItemItemComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemNewComponent\b)([\s\S]*?)[\s]*?\bCrudItemNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-new\/crud-item-new\.component';)"; Replacement = 'import { CrudItemNewComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemReadComponent\b)([\s\S]*?)[\s]*?\bCrudItemReadComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-read\/crud-item-read\.component';)"; Replacement = 'import { CrudItemReadComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemsIndexComponent\b)([\s\S]*?)[\s]*?\bCrudItemsIndexComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-items-index\/crud-items-index\.component';)"; Replacement = 'import { CrudItemsIndexComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberFormComponent\b)([\s\S]*?)[\s]*?\bMemberFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-form\/member-form\.component';)"; Replacement = 'import { MemberFormComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberFormEditComponent\b)([\s\S]*?)[\s]*?\bMemberFormEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-form-edit\/member-form-edit\.component';)"; Replacement = 'import { MemberFormEditComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberFormNewComponent\b)([\s\S]*?)[\s]*?\bMemberFormNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-form-new\/member-form-new\.component';)"; Replacement = 'import { MemberFormNewComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberTableComponent\b)([\s\S]*?)[\s]*?\bMemberTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-table\/member-table\.component';)"; Replacement = 'import { MemberTableComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMember\b)([\s\S]*?)[\s]*?\bMember\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/model\/member';)"; Replacement = 'import { Member } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMembers\b)([\s\S]*?)[\s]*?\bMembers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/model\/member';)"; Replacement = 'import { Members } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bmemberFieldsConfiguration\b)([\s\S]*?)[\s]*?\bmemberFieldsConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/model\/member';)"; Replacement = 'import { memberFieldsConfiguration } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberDas\b)([\s\S]*?)[\s]*?\bMemberDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/services\/member-das\.service';)"; Replacement = 'import { MemberDas } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberOptionsService\b)([\s\S]*?)[\s]*?\bMemberOptionsService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/services\/member-options\.service';)"; Replacement = 'import { MemberOptionsService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberService\b)([\s\S]*?)[\s]*?\bMemberService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/services\/member\.service';)"; Replacement = 'import { MemberService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureMembersStore\b)([\s\S]*?)[\s]*?\bFeatureMembersStore\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/store\/member\.state';)"; Replacement = 'import { FeatureMembersStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureMembersActions\b)([\s\S]*?)[\s]*?\bFeatureMembersActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/store\/members-actions';)"; Replacement = 'import { FeatureMembersActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMembersEffects\b)([\s\S]*?)[\s]*?\bMembersEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/store\/members-effects';)"; Replacement = 'import { MembersEffects } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberState\b)([\s\S]*?)[\s]*?\bMemberState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/store\/members-reducer';)"; Replacement = 'import { MemberState } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberEditComponent\b)([\s\S]*?)[\s]*?\bMemberEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-edit\/member-edit\.component';)"; Replacement = 'import { MemberEditComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberImportComponent\b)([\s\S]*?)[\s]*?\bMemberImportComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-import\/member-import\.component';)"; Replacement = 'import { MemberImportComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberItemComponent\b)([\s\S]*?)[\s]*?\bMemberItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-item\/member-item\.component';)"; Replacement = 'import { MemberItemComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberNewComponent\b)([\s\S]*?)[\s]*?\bMemberNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-new\/member-new\.component';)"; Replacement = 'import { MemberNewComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMembersIndexComponent\b)([\s\S]*?)[\s]*?\bMembersIndexComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/members-index\/members-index\.component';)"; Replacement = 'import { MembersIndexComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bmemberCRUDConfiguration\b)([\s\S]*?)[\s]*?\bmemberCRUDConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/member\.constants';)"; Replacement = 'import { memberCRUDConfiguration } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberModule\b)([\s\S]*?)[\s]*?\bMemberModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/member\.module';)"; Replacement = 'import { MemberModule } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromLdapFormComponent\b)([\s\S]*?)[\s]*?\bUserFromLdapFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/components\/user-from-directory-form\/user-from-directory-form\.component';)"; Replacement = 'import { UserFromLdapFormComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFilter\b)([\s\S]*?)[\s]*?\bUserFilter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/model\/user-filter';)"; Replacement = 'import { UserFilter } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectory\b)([\s\S]*?)[\s]*?\bUserFromDirectory\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/model\/user-from-directory';)"; Replacement = 'import { UserFromDirectory } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectoryDas\b)([\s\S]*?)[\s]*?\bUserFromDirectoryDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/services\/user-from-directory-das\.service';)"; Replacement = 'import { UserFromDirectoryDas } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectoryDas\b)([\s\S]*?)[\s]*?\bUserFromDirectoryDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/services\/user-from-directory-das\.service';)"; Replacement = 'import { UserFromDirectoryDas } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';[\s\S]*)\breducers\b"; Replacement = '$1UsersFromDirectoryStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUsersState\b)[\s\S]*?\bgetUsersState\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';[\s\S]*)\bgetUsersState\b"; Replacement = '$1UsersFromDirectoryStore.getUsersState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetUsersEntitiesState\b)[\s\S]*?\bgetUsersEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';[\s\S]*)\bgetUsersEntitiesState\b"; Replacement = '$1UsersFromDirectoryStore.getUsersEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllUsersFromDirectory\b)[\s\S]*?\bgetAllUsersFromDirectory\b[\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';[\s\S]*)\bgetAllUsersFromDirectory\b"; Replacement = '$1UsersFromDirectoryStore.getAllUsersFromDirectory'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers)([\s\S]*)?reducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';)"; Replacement = 'import { UsersFromDirectoryStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUsersState)([\s\S]*)?getUsersState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';)"; Replacement = 'import { UsersFromDirectoryStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetUsersEntitiesState)([\s\S]*)?getUsersEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';)"; Replacement = 'import { UsersFromDirectoryStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllUsersFromDirectory)([\s\S]*)?getAllUsersFromDirectory\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/user-from-directory\.state';)"; Replacement = 'import { UsersFromDirectoryStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFeatureUsersFromDirectoryActions\b)([\s\S]*?)[\s]*?\bFeatureUsersFromDirectoryActions\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-actions';)"; Replacement = 'import { FeatureUsersFromDirectoryActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUsersFromDirectoryEffects\b)([\s\S]*?)[\s]*?\bUsersFromDirectoryEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-effects';)"; Replacement = 'import { UsersFromDirectoryEffects } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\busersFromDirectoryAdapter\b)([\s\S]*?)[\s]*?\busersFromDirectoryAdapter\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-reducer';)"; Replacement = 'import { usersFromDirectoryAdapter } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectoryState\b)([\s\S]*?)[\s]*?\bUserFromDirectoryState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-reducer';)"; Replacement = 'import { UserFromDirectoryState } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bINIT_USERFROMDIRECTORY_STATE\b)([\s\S]*?)[\s]*?\bINIT_USERFROMDIRECTORY_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-reducer';)"; Replacement = 'import { INIT_USERFROMDIRECTORY_STATE } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\buserFromDirectoryReducers\b)([\s\S]*?)[\s]*?\buserFromDirectoryReducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/store\/users-from-directory-reducer';)"; Replacement = 'import { userFromDirectoryReducers } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserAddFromLdapComponent\b)([\s\S]*?)[\s]*?\bUserAddFromLdapComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/views\/user-add-from-directory-dialog\/user-add-from-directory-dialog\.component';)"; Replacement = 'import { UserAddFromLdapComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserFromDirectoryModule\b)([\s\S]*?)[\s]*?\bUserFromDirectoryModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-features\/users-from-directory\/user-from-directory\.module';)"; Replacement = 'import { UserFromDirectoryModule } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewFormComponent\b)([\s\S]*?)\bViewFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/components\/view-form\/view-form\.component';)"; Replacement = 'import { ViewFormComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewTeamTableComponent\b)([\s\S]*?)\bViewTeamTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/components\/view-team-table\/view-team-table\.component';)"; Replacement = 'import { ViewTeamTableComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewUserTableComponent\b)([\s\S]*?)\bViewUserTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/components\/view-user-table\/view-user-table\.component';)"; Replacement = 'import { ViewUserTableComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAssignViewToTeam\b)([\s\S]*?)\bAssignViewToTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/assign-view-to-team';)"; Replacement = 'import { AssignViewToTeam } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDefaultView\b)([\s\S]*?)\bDefaultView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/default-view';)"; Replacement = 'import { DefaultView } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamDefaultView\b)([\s\S]*?)\bTeamDefaultView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/team-default-view';)"; Replacement = 'import { TeamDefaultView } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamView\b)([\s\S]*?)\bTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/team-view';)"; Replacement = 'import { TeamView } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewTeam\b)([\s\S]*?)\bViewTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/view-team';)"; Replacement = 'import { ViewTeam } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bQUERY_STRING_VIEW\b)([\s\S]*?)\bQUERY_STRING_VIEW\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/view.constants';)"; Replacement = 'import { QUERY_STRING_VIEW } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bView\b)([\s\S]*?)\bView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/model\/view';)"; Replacement = 'import { View } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamViewDas\b)([\s\S]*?)\bTeamViewDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/services\/team-view-das\.service';)"; Replacement = 'import { TeamViewDas } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bUserViewDas\b)([\s\S]*?)\bUserViewDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/services\/user-view-das\.service';)"; Replacement = 'import { UserViewDas } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewDas\b)([\s\S]*?)\bViewDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/services\/view-das\.service';)"; Replacement = 'import { ViewDas } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bViewsState\b)[\s\S]*?\bViewsState\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bViewsState\b"; Replacement = '$1ViewsStore.ViewsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\breducers\b"; Replacement = '$1ViewsStore.reducers'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetViewsState\b)[\s\S]*?\bgetViewsState\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetViewsState\b"; Replacement = '$1ViewsStore.getViewsState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetViewsEntitiesState\b)[\s\S]*?\bgetViewsEntitiesState\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetViewsEntitiesState\b"; Replacement = '$1ViewsStore.getViewsEntitiesState'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllViews\b)[\s\S]*?\bgetAllViews\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetAllViews\b"; Replacement = '$1ViewsStore.getAllViews'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetDisplayViewDialog\b)[\s\S]*?\bgetDisplayViewDialog\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetDisplayViewDialog\b"; Replacement = '$1ViewsStore.getDisplayViewDialog'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetLastViewChanged\b)[\s\S]*?\bgetLastViewChanged\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetLastViewChanged\b"; Replacement = '$1ViewsStore.getLastViewChanged'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetDataLoaded\b)[\s\S]*?\bgetDataLoaded\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetDataLoaded\b"; Replacement = '$1ViewsStore.getDataLoaded'},
    @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetViewById\b)[\s\S]*?\bgetViewById\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\bgetViewById\b"; Replacement = '$1ViewsStore.getViewById'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewsState)([\s\S]*)?ViewsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers)([\s\S]*)?reducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetViewsState)([\s\S]*)?getViewsState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetViewsEntitiesState)([\s\S]*)?getViewsEntitiesState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllViews)([\s\S]*)?getAllViews\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetDisplayViewDialog)([\s\S]*)?getDisplayViewDialog\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetLastViewChanged)([\s\S]*)?getLastViewChanged\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetDataLoaded)([\s\S]*)?getDataLoaded\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetViewById)([\s\S]*)?getViewById\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''bia-ng/shared''; import { $1$2'},
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
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bloadAllView\b)([\s\S]*?)[\s]*?\bloadAllView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bloadAllSuccess\b)([\s\S]*?)[\s]*?\bloadAllSuccess\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bassignViewToTeam\b)([\s\S]*?)[\s]*?\bassignViewToTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bremoveUserView\b)([\s\S]*?)[\s]*?\bremoveUserView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bsetDefaultUserView\b)([\s\S]*?)[\s]*?\bsetDefaultUserView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\baddUserView\b)([\s\S]*?)[\s]*?\baddUserView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bupdateUserView\b)([\s\S]*?)[\s]*?\bupdateUserView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bupdateTeamView\b)([\s\S]*?)[\s]*?\bupdateTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\baddUserViewSuccess\b)([\s\S]*?)[\s]*?\baddUserViewSuccess\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bremoveTeamView\b)([\s\S]*?)[\s]*?\bremoveTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bsetDefaultTeamView\b)([\s\S]*?)[\s]*?\bsetDefaultTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\baddTeamView\b)([\s\S]*?)[\s]*?\baddTeamView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\baddTeamViewSuccess\b)([\s\S]*?)[\s]*?\baddTeamViewSuccess\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bfailure\b)([\s\S]*?)[\s]*?\bfailure\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bopenViewDialog\b)([\s\S]*?)[\s]*?\bopenViewDialog\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bcloseViewDialog\b)([\s\S]*?)[\s]*?\bcloseViewDialog\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bsetViewSuccess\b)([\s\S]*?)[\s]*?\bsetViewSuccess\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { ViewsActions } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewsEffects\b)([\s\S]*?)\bViewsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-effects';)"; Replacement = 'import { ViewsEffects } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewDialogComponent\b)([\s\S]*?)[\s]*?\bViewDialogComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/view\/views\/view-dialog\/view-dialog\.component';)"; Replacement = 'import { ViewDialogComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewListComponent\b)([\s\S]*?)[\s]*?\bViewListComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/view\/views\/view-list\/view-list\.component';)"; Replacement = 'import { ViewListComponent } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFormatValuePipe\b)([\s\S]*?)[\s]*?\bFormatValuePipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/format-value\.pipe';)"; Replacement = 'import { FormatValuePipe } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bJoinPipe\b)([\s\S]*?)[\s]*?\bJoinPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/join\.pipe';)"; Replacement = 'import { JoinPipe } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPluckPipe\b)([\s\S]*?)[\s]*?\bPluckPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/pluck\.pipe';)"; Replacement = 'import { PluckPipe } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bSafeUrlPipe\b)([\s\S]*?)[\s]*?\bSafeUrlPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/safe-url\.pipe';)"; Replacement = 'import { SafeUrlPipe } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTranslateFieldPipe\b)([\s\S]*?)[\s]*?\bTranslateFieldPipe\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/pipes\/translate-field\.pipe';)"; Replacement = 'import { TranslateFieldPipe } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeCommunicationService\b)([\s\S]*?)[\s]*?\bIframeCommunicationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/iframe\/iframe-communication\.service';)"; Replacement = 'import { IframeCommunicationService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeConfigMessageService\b)([\s\S]*?)[\s]*?\bIframeConfigMessageService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/iframe\/iframe-config-message\.service';)"; Replacement = 'import { IframeConfigMessageService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudHelperService\b)([\s\S]*?)[\s]*?\bCrudHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/crud-helper\.service';)"; Replacement = 'import { CrudHelperService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLayoutHelperService\b)([\s\S]*?)[\s]*?\bLayoutHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/layout-helper\.service';)"; Replacement = 'import { LayoutHelperService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTableHelperService\b)([\s\S]*?)[\s]*?\bTableHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/table-helper\.service';)"; Replacement = 'import { TableHelperService } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFieldValidator\b)([\s\S]*?)[\s]*?\bFieldValidator\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/validators\/field\.validator';)"; Replacement = 'import { FieldValidator } from ''bia-ng/shared''; import { $1$2'},
    @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bJsonValidator\b)([\s\S]*?)[\s]*?\bJsonValidator\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/validators\/json\.validator';)"; Replacement = 'import { JsonValidator } from ''bia-ng/shared''; import { $1$2'},
    
    # Clean empty imports
    @{Pattern = "import {[\s]*?} from '[\S]*?';"; Replacement = ''},
    
    # update components templates and scss coming from bia
    @{Pattern = "((templateUrl:|styleUrls: \[)[\s]*'[\S]*\/)shared\/bia-shared\/([\S]*\.component\.(html|scss)')"; Replacement = '$1../../node_modules/bia-ng/templates/$3'}
    )

  $extensions = "*.ts"
  Invoke-ReplacementsInFiles -RootPath $SourceFrontEnd -Replacements $replacementsTS -Extensions $extensions
}


# FRONT END
# BEGIN - deactivate navigation in breadcrumb for crudItemId
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp "(path:\s*':crudItemId',\s*data:\s*\{\s*breadcrumb:\s*'',\s*canNavigate:\s*)true(,\s*\})" -NewRegexp '$1false$2' -Include "*module.ts"
# END - deactivate navigation in breadcrumb for crudItemId

# BEGIN - switch to lib bia-ng
ApplyChangesToLib
ReplaceInProject ` -Source $SourceFrontEnd -OldRegexp '("includePaths":\s*\["src\/styles",\s*")src\/scss\/bia("\])' -NewRegexp '$1node_modules/bia-ng/scss$2' -Include "*angular.json"
# END - switch to lib bia-ng

# FRONT END
# Set-Location $SourceFrontEnd
# npm run clean

# BACK END
# Set-Location $SourceBackEnd
# dotnet restore --no-cache

Write-Host "Finish"
pause
