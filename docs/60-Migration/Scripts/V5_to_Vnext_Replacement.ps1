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

function ApplyChangesToLib {
  Write-Host "[Apply changes to biang lib]"

  $replacementsTS = @(
      # Update bia-core imports
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaCoreModule\b)([\s\S]*?)[\s]*?\bBiaCoreModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/bia-core\.module';)"; Replacement = 'import { BiaCoreModule } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTranslationService\b)([\s\S]*?)[\s]*?\bBiaTranslationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { BiaTranslationService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAppDB\b)([\s\S]*?)[\s]*?\bAppDB\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/db';)"; Replacement = 'import { AppDB } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaEnvironmentService\b)([\s\S]*?)\bBiaEnvironmentService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-environment\.service';)"; Replacement = 'import { BiaEnvironmentService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaNgxLoggerServerService\b)([\s\S]*?)\bBiaNgxLoggerServerService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-ngx-logger-server\.service';)"; Replacement = 'import { BiaNgxLoggerServerService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaSignalRService\b)([\s\S]*?)\bBiaSignalRService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-signalr\.service';)"; Replacement = 'import { BiaSignalRService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTranslateHttpLoader\b)([\s\S]*?)\bBiaTranslateHttpLoader\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translate-http-loader';)"; Replacement = 'import { BiaTranslateHttpLoader } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetCurrentCulture\b)([\s\S]*?)\bgetCurrentCulture\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-translation\.service';)"; Replacement = 'import { getCurrentCulture } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaErrorHandler\b)([\s\S]*?)\bBiaErrorHandler\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/shared\/bia-error-handler';)"; Replacement = 'import { BiaErrorHandler } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAuthService\b)([\s\S]*?)[\s]*?\bAuthService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/auth\.service';)"; Replacement = 'import { AuthService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaMessageService\b)([\s\S]*?)[\s]*?\bBiaMessageService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-message\.service';)"; Replacement = 'import { BiaMessageService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPermissionGuard\b)([\s\S]*?)[\s]*?\bPermissionGuard\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/guards\/permission\.guard';)"; Replacement = 'import { PermissionGuard } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOptionService\b)([\s\S]*?)[\s]*?\bBiaOptionService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-option\.service';)"; Replacement = 'import { BiaOptionService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bclone\b)([\s\S]*?)[\s]*?\bclone\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/utils';)"; Replacement = 'import { clone } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaOnlineOfflineInterceptor\b)([\s\S]*?)[\s]*?\bbiaOnlineOfflineInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-online-offline\.interceptor';)"; Replacement = 'import { biaOnlineOfflineInterceptor } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOnlineOfflineInterceptor\b)([\s\S]*?)[\s]*?\bBiaOnlineOfflineInterceptor\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/interceptors\/bia-online-offline\.interceptor';)"; Replacement = 'import { BiaOnlineOfflineInterceptor } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bAbstractDas\b)([\s\S]*?)[\s]*?\bAbstractDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/abstract-das\.service';)"; Replacement = 'import { AbstractDas } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaOnlineOfflineService\b)([\s\S]*?)[\s]*?\bBiaOnlineOfflineService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-online-offline\.service';)"; Replacement = 'import { BiaOnlineOfflineService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bbiaSuccessWaitRefreshSignalR\b)([\s\S]*?)[\s]*?\bbiaSuccessWaitRefreshSignalR\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/shared\/bia-action';)"; Replacement = 'import { biaSuccessWaitRefreshSignalR } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaInjectExternalService\b)([\s\S]*?)[\s]*?\bBiaInjectExternalService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/bia-inject-external\.service';)"; Replacement = 'import { BiaInjectExternalService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaMatomoService\b)([\s\S]*?)[\s]*?\bBiaMatomoService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/matomo\/bia-matomo\.service';)"; Replacement = 'import { BiaMatomoService } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bGenericDas\b)([\s\S]*?)[\s]*?\bGenericDas\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/generic-das\.service';)"; Replacement = 'import { GenericDas } from ''biang/core''; import { $1$2'},
      @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bgetAllTeams\b)[\s\S]*?\bgetAllTeams\b[\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';[\s\S]*)\bgetAllTeams\b"; Replacement = '$1BiaTeamsStore.getAllTeams'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bgetAllTeams\b)([\s\S]*?)[\s]*?\bgetAllTeams\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/store\/team\.state';)"; Replacement = 'import { BiaTeamsStore } from ''biang/core''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNavigationService\b)([\s\S]*?)[\s]*?\bNavigationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-core\/services\/navigation\.service';)"; Replacement = 'import { NavigationService } from ''biang/core''; import { $1$2'},
      
      # Update models imports
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldConfig\b)([\s\S]*?)[\s]*?\bBiaFieldConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldConfig } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldsConfig\b)([\s\S]*?)[\s]*?\bBiaFieldsConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldsConfig } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPrimeNGFiltering\b)([\s\S]*?)[\s]*?\bPrimeNGFiltering\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { PrimeNGFiltering } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPropType\b)([\s\S]*?)[\s]*?\bPropType\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { PropType } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldNumberFormat\b)([\s\S]*?)[\s]*?\bBiaFieldNumberFormat\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldNumberFormat } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bNumberMode\b)([\s\S]*?)[\s]*?\bNumberMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { NumberMode } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldDateFormat\b)([\s\S]*?)[\s]*?\bBiaFieldDateFormat\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldDateFormat } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFieldNumberFormat\b)([\s\S]*?)[\s]*?\bBiaFieldNumberFormat\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-field-config';)"; Replacement = 'import { BiaFieldNumberFormat } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBaseDto\b)([\s\S]*?)[\s]*?\bBaseDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/base-dto';)"; Replacement = 'import { BaseDto } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamDto\b)([\s\S]*?)[\s]*?\bTeamDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/team-dto';)"; Replacement = 'import { TeamDto } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bVersionedDto\b)([\s\S]*?)[\s]*?\bVersionedDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/versioned-dto';)"; Replacement = 'import { VersionedDto } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bOptionDto\b)([\s\S]*?)[\s]*?\bOptionDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/option-dto';)"; Replacement = 'import { OptionDto } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamAdvancedFilterDto\b)([\s\S]*?)[\s]*?\bTeamAdvancedFilterDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/team-advanced-filter-dto';)"; Replacement = 'import { TeamAdvancedFilterDto } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDataResult\b)([\s\S]*?)[\s]*?\bDataResult\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/data-result';)"; Replacement = 'import { DataResult } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfig\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfig } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigField\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigField\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigField } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigGroup\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigGroup\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigGroup } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigRow\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigRow\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigRow } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigTab\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigTab\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigTab } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigTabGroup\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigTabGroup\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigTabGroup } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormLayoutConfigColumnSize\b)([\s\S]*?)[\s]*?\bBiaFormLayoutConfigColumnSize\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-form-layout-config';)"; Replacement = 'import { BiaFormLayoutConfigColumnSize } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudState\b)([\s\S]*?)[\s]*?\bCrudState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/crud-state';)"; Replacement = 'import { CrudState } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDEFAULT_CRUD_STATE\b)([\s\S]*?)[\s]*?\bDEFAULT_CRUD_STATE\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/crud-state';)"; Replacement = 'import { DEFAULT_CRUD_STATE } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFixableDto\b)([\s\S]*?)[\s]*?\bFixableDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/fixable-dto';)"; Replacement = 'import { FixableDto } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bArchivableDto\b)([\s\S]*?)[\s]*?\bArchivableDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/archivable-dto';)"; Replacement = 'import { ArchivableDto } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bteamFieldsConfigurationColumns\b)([\s\S]*?)[\s]*?\bteamFieldsConfigurationColumns\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto\/team-dto';)"; Replacement = 'import { teamFieldsConfigurationColumns } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bKeyValuePair\b)([\s\S]*?)[\s]*?\bKeyValuePair\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/key-value-pair';)"; Replacement = 'import { KeyValuePair } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPagingFilterFormatDto\b)([\s\S]*?)[\s]*?\bPagingFilterFormatDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/paging-filter-format';)"; Replacement = 'import { PagingFilterFormatDto } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDtoState\b)([\s\S]*?)[\s]*?\bDtoState\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/dto-state\.enum';)"; Replacement = 'import { DtoState } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTargetedFeature\b)([\s\S]*?)[\s]*?\bTargetedFeature\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/signalR';)"; Replacement = 'import { TargetedFeature } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeMessage\b)([\s\S]*?)[\s]*?\bIframeMessage\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/iframe-message';)"; Replacement = 'import { IframeMessage } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeam\b)([\s\S]*?)[\s]*?\bTeam\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-domains\/team\/model\/team';)"; Replacement = 'import { Team } from ''biang/models''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaNavigation\b)([\s\S]*?)[\s]*?\bBiaNavigation\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/model\/bia-navigation';)"; Replacement = 'import { BiaNavigation } from ''biang/models''; import { $1$2'},
      @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bRoleMode\b)[\s\S]*?\bRoleMode\b[\s\S]*?} from '[\s\S]*?\/constants';[\s\S]*)\bRoleMode.AllRoles\b"; Replacement = '$1RoleMode.allRoles'},
      @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bRoleMode\b)[\s\S]*?\bRoleMode\b[\s\S]*?} from '[\s\S]*?\/constants';[\s\S]*)\bRoleMode.MultiRoles\b"; Replacement = '$1RoleMode.multiRoles'},
      @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\bRoleMode\b)[\s\S]*?\bRoleMode\b[\s\S]*?} from '[\s\S]*?\/constants';[\s\S]*)\bRoleMode.SingleRole\b"; Replacement = '$1RoleMode.singleRole'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bRoleMode\b)([\s\S]*?)[\s]*?\bRoleMode\b[,]?([\s\S]*?} from '[\s\S]*?\/constants';)"; Replacement = 'import { RoleMode } from ''biang/models''; import { $1$2'},

      # Update bia-shared imports
      @{Pattern = "(import {(?=(?:(?!import {)[\s\S])*\breducers\b)[\s\S]*?\breducers\b[\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';[\s\S]*)\breducers\b"; Replacement = '$1ViewsStore.reducers'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\breducers)([\s\S]*)?reducers\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/view\.state';)"; Replacement = 'import { ViewsStore } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bViewsEffects\b)([\s\S]*?)\bViewsEffects\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-effects';)"; Replacement = 'import { ViewsEffects } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaButtonGroupComponent\b)([\s\S]*?)[\s]*?\bBiaButtonGroupComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-button-group\/bia-button-group\.component';)"; Replacement = 'import { BiaButtonGroupComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaButtonGroupItem\b)([\s\S]*?)[\s]*?\bBiaButtonGroupItem\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/bia-button-group\/bia-button-group\.component';)"; Replacement = 'import { BiaButtonGroupItem } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableBehaviorControllerComponent\b)([\s\S]*?)[\s]*?\bBiaTableBehaviorControllerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-behavior-controller\/bia-table-behavior-controller\.component';)"; Replacement = 'import { BiaTableBehaviorControllerComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableControllerComponent\b)([\s\S]*?)[\s]*?\bBiaTableControllerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-controller\/bia-table-controller\.component';)"; Replacement = 'import { BiaTableControllerComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableHeaderComponent\b)([\s\S]*?)[\s]*?\bBiaTableHeaderComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-header\/bia-table-header\.component';)"; Replacement = 'import { BiaTableHeaderComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableComponent\b)([\s\S]*?)[\s]*?\bBiaTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table\/bia-table\.component';)"; Replacement = 'import { BiaTableComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTeamAdvancedFilterComponent\b)([\s\S]*?)[\s]*?\bTeamAdvancedFilterComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/team-advanced-filter\/team-advanced-filter\.component';)"; Replacement = 'import { TeamAdvancedFilterComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemService\b)([\s\S]*?)[\s]*?\bCrudItemService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item\.service';)"; Replacement = 'import { CrudItemService } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemsIndexComponent\b)([\s\S]*?)[\s]*?\bCrudItemsIndexComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-items-index\/crud-items-index\.component';)"; Replacement = 'import { CrudItemsIndexComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFrozenColumnDirective\b)([\s\S]*?)[\s]*?\bBiaFrozenColumnDirective\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-frozen-column\/bia-frozen-column\.directive';)"; Replacement = 'import { BiaFrozenColumnDirective } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableFilterComponent\b)([\s\S]*?)[\s]*?\bBiaTableFilterComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-filter\/bia-table-filter\.component';)"; Replacement = 'import { BiaTableFilterComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableFooterControllerComponent\b)([\s\S]*?)[\s]*?\bBiaTableFooterControllerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-footer-controller\/bia-table-footer-controller\.component';)"; Replacement = 'import { BiaTableFooterControllerComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableInputComponent\b)([\s\S]*?)[\s]*?\bBiaTableInputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-input\/bia-table-input\.component';)"; Replacement = 'import { BiaTableInputComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaTableOutputComponent\b)([\s\S]*?)[\s]*?\bBiaTableOutputComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table-output\/bia-table-output\.component';)"; Replacement = 'import { BiaTableOutputComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemTableComponent\b)([\s\S]*?)[\s]*?\bCrudItemTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/components\/crud-item-table\/crud-item-table\.component';)"; Replacement = 'import { CrudItemTableComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDynamicLayoutComponent\b)([\s\S]*?)[\s]*?\bDynamicLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/dynamic-layout\/dynamic-layout\.component';)"; Replacement = 'import { DynamicLayoutComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLayoutMode\b)([\s\S]*?)[\s]*?\bLayoutMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/dynamic-layout\/dynamic-layout\.component';)"; Replacement = 'import { LayoutMode } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudConfig\b)([\s\S]*?)[\s]*?\bCrudConfig\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/model\/crud-config';)"; Replacement = 'import { CrudConfig } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemNewComponent\b)([\s\S]*?)[\s]*?\bCrudItemNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-new\/crud-item-new\.component';)"; Replacement = 'import { CrudItemNewComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bSpinnerComponent\b)([\s\S]*?)[\s]*?\bSpinnerComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/spinner\/spinner\.component';)"; Replacement = 'import { SpinnerComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberItemComponent\b)([\s\S]*?)[\s]*?\bMemberItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-item\/member-item\.component';)"; Replacement = 'import { MemberItemComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemSignalRService\b)([\s\S]*?)[\s]*?\bCrudItemSignalRService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-signalr\.service';)"; Replacement = 'import { CrudItemSignalRService } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemItemComponent\b)([\s\S]*?)[\s]*?\bCrudItemItemComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-item\/crud-item-item\.component';)"; Replacement = 'import { CrudItemItemComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemEditComponent\b)([\s\S]*?)[\s]*?\bCrudItemEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-edit\/crud-item-edit\.component';)"; Replacement = 'import { CrudItemEditComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFullPageLayoutComponent\b)([\s\S]*?)[\s]*?\bFullPageLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/fullpage-layout\/fullpage-layout\.component';)"; Replacement = 'import { FullPageLayoutComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPopupLayoutComponent\b)([\s\S]*?)[\s]*?\bPopupLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/popup-layout\/popup-layout\.component';)"; Replacement = 'import { PopupLayoutComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberModule\b)([\s\S]*?)[\s]*?\bMemberModule\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/member\.module';)"; Replacement = 'import { MemberModule } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberFormEditComponent\b)([\s\S]*?)[\s]*?\bMemberFormEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-form-edit\/member-form-edit\.component';)"; Replacement = 'import { MemberFormEditComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberEditComponent\b)([\s\S]*?)[\s]*?\bMemberEditComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-edit\/member-edit\.component';)"; Replacement = 'import { MemberEditComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bLayoutComponent\b)([\s\S]*?)[\s]*?\bLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/layout\.component';)"; Replacement = 'import { LayoutComponent   } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bPageLayoutComponent\b)([\s\S]*?)[\s]*?\bPageLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/page-layout\.component';)"; Replacement = 'import { PageLayoutComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bDictOptionDto\b)([\s\S]*?)[\s]*?\bDictOptionDto\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-table\/dict-option-dto';)"; Replacement = 'import { DictOptionDto } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemOptionsService\b)([\s\S]*?)[\s]*?\bCrudItemOptionsService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/services\/crud-item-options\.service';)"; Replacement = 'import { CrudItemOptionsService } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberFormNewComponent\b)([\s\S]*?)[\s]*?\bMemberFormNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-form-new\/member-form-new\.component';)"; Replacement = 'import { MemberFormNewComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberNewComponent\b)([\s\S]*?)[\s]*?\bMemberNewComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-new\/member-new\.component';)"; Replacement = 'import { MemberNewComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberTableComponent\b)([\s\S]*?)[\s]*?\bMemberTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/components\/member-table\/member-table\.component';)"; Replacement = 'import { MemberTableComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMembersIndexComponent\b)([\s\S]*?)[\s]*?\bMembersIndexComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/members-index\/members-index\.component';)"; Replacement = 'import { MembersIndexComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bMemberImportComponent\b)([\s\S]*?)[\s]*?\bMemberImportComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/views\/member-import\/member-import\.component';)"; Replacement = 'import { MemberImportComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bmemberCRUDConfiguration\b)([\s\S]*?)[\s]*?\bmemberCRUDConfiguration\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/members\/member\.constants';)"; Replacement = 'import { memberCRUDConfiguration } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaFormComponent\b)([\s\S]*?)[\s]*?\bBiaFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/form\/bia-form\/bia-form\.component';)"; Replacement = 'import { BiaFormComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemFormComponent\b)([\s\S]*?)[\s]*?\bCrudItemFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/components\/crud-item-form\/crud-item-form\.component';)"; Replacement = 'import { CrudItemFormComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bFormReadOnlyMode\b)([\s\S]*?)[\s]*?\bFormReadOnlyMode\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/model\/crud-config';)"; Replacement = 'import { FormReadOnlyMode } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaLayoutService\b)([\s\S]*?)[\s]*?\bBiaLayoutService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/services\/layout.service';)"; Replacement = 'import { BiaLayoutService } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemImportComponent\b)([\s\S]*?)[\s]*?\bCrudItemImportComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-import\/crud-item-import\.component';)"; Replacement = 'import { CrudItemImportComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemReadComponent\b)([\s\S]*?)[\s]*?\bCrudItemReadComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/views\/crud-item-read\/crud-item-read\.component';)"; Replacement = 'import { CrudItemReadComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudItemImportFormComponent\b)([\s\S]*?)[\s]*?\bCrudItemImportFormComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/feature-templates\/crud-items\/components\/crud-item-import-form\/crud-item-import-form\.component';)"; Replacement = 'import { CrudItemImportFormComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bCrudHelperService\b)([\s\S]*?)[\s]*?\bCrudHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/crud-helper\.service';)"; Replacement = 'import { CrudHelperService } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bloadAllView\b)([\s\S]*?)[\s]*?\bloadAllView\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/features\/view\/store\/views-actions';)"; Replacement = 'import { loadAllView } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bTableHelperService\b)([\s\S]*?)[\s]*?\bTableHelperService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/table-helper.service';)"; Replacement = 'import { TableHelperService } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaCalcTableComponent\b)([\s\S]*?)[\s]*?\bBiaCalcTableComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/table\/bia-calc-table\/bia-calc-table\.component';)"; Replacement = 'import { BiaCalcTableComponent } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeCommunicationService\b)([\s\S]*?)[\s]*?\bIframeCommunicationService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/iframe\/iframe-communication\.service';)"; Replacement = 'import { IframeCommunicationService } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bIframeConfigMessageService\b)([\s\S]*?)[\s]*?\bIframeConfigMessageService\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/services\/iframe\/iframe-config-message\.service';)"; Replacement = 'import { IframeConfigMessageService } from ''biang/shared''; import { $1$2'},
      @{Pattern = "import {(?=(?:(?!import {)[\s\S])*\bBiaUltimaLayoutComponent\b)([\s\S]*?)[\s]*?\bBiaUltimaLayoutComponent\b[,]?([\s\S]*?} from '[\s\S]*?\/bia-shared\/components\/layout\/ultima\/layout\/ultima-layout\.component';)"; Replacement = 'import { BiaUltimaLayoutComponent } from ''biang/shared''; import { $1$2'},
      
      # Clean empty imports
      @{Pattern = "import {[\s]*?} from '[\S]*?';"; Replacement = ''},
      
      # update components templates and scss coming from bia
      @{Pattern = "((templateUrl:|styleUrls: \[)[\s]*'[\S]*\/)shared\/bia-shared\/(feature-templates[\S]*\.component\.(html|scss)')"; Replacement = '$1../../node_modules/biang/templates/$3'}
      @{Pattern = "((templateUrl:|styleUrls: \[)[\s]*'[\S]*\/)shared\/bia-shared\/components\/([\S]*\.component\.(html|scss)')"; Replacement = '$1../../node_modules/biang/templates/$3'}
      )

  $extensions = "*.ts"
  Write-Host "Looking for files ($extensions) to analyze..."
  Get-ChildItem -Path $SourceFrontEnd -Recurse -Include $extensions| Where-Object {
    $excluded = $false
    Write-Host $_.FullName
    foreach ($exclude in $ExcludeDir) {
        if ($_.FullName -match [regex]::Escape("\$exclude\")) {
            $excluded = $true
            break
        }
    }
    -not $excluded
  } | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $fileModified = $false
    $fileReplacements = @()

    foreach ($rule in $replacementsTS) {
      $newContent = $content -creplace $rule.Pattern, $rule.Replacement
      if ($newContent -cne $content) {
          $content = $newContent
          $fileModified = $true
          $fileReplacements += "  => replaced $($rule.Pattern) by $($rule.Replacement)"
      }
    }
    
    if ($fileModified) {
        Write-Host $_.FullName -ForegroundColor Green
        $fileReplacements | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
        [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.Encoding]::UTF8)
    }
  }
}

# FRONT END
ApplyChangesToLib

# FRONT END
# Set-Location $SourceFrontEnd
# npm run clean

# BACK END
# Set-Location $SourceBackEnd
# dotnet restore --no-cache

Write-Host "Finish"
pause
