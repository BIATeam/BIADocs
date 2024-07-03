$Source = "C:\Sources\Github.com\BIATeam\BIADemo";
# $Source = "D:\Source\GitHub\BIATeam\BIADemo";
$SourceBackEnd = $Source + "\DotNet"
$SourceFrontEnd = $Source + "\Angular"

$ExcludeDir = ('dist', 'node_modules', 'docs', 'scss', '.git', '.vscode', '.angular')

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
          $contenuFichier = $contenuFichier.Insert($positionFermetureClasse, $FunctionBodyRep + "`n")

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
  $contenuFichier -split "`n" | ForEach-Object {

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

InsertFunctionInClass -Source $SourceFrontEnd -MatchBegin "class (\w+Service) extends CrudItemService" -FunctionBody @"
    public clearAll(){
        this.store.dispatch(FeatureEnginesActions.clearAll());
    }
    public clearCurrent(){
      this._currentCrudItem = <Engine>{};
      this._currentCrudItemId = 0;
      this.store.dispatch(FeatureEnginesActions.clearCurrent());
  }
"@ -ReplaceSeqences @("Engines", "Engine") -ReplaceByMatch1 @("\(Feature(\w+)Actions.loadAllByPost", "class (\w+)Service extends CrudItemService") -NoMatchCondition "public clearAll\(\)"  -MatchCondition ""

InsertFunctionInClass -Source $SourceFrontEnd -MatchBegin "export namespace (Feature\w+Actions)" -FunctionBody @"
  
  export const clearAll = createAction('[' + EngineCRUDConfiguration.storeKey +'] Clear all in state');
  
  export const clearCurrent = createAction('[' + EngineCRUDConfiguration.storeKey +'] Clear current');
"@ -ReplaceSeqences @("Engine") -ReplaceByMatch1 @(" (\w+)CRUDConfiguration\.storeKey") -NoMatchCondition "export const clearAll" -MatchCondition "CRUDConfiguration\.storeKey"

ReplaceInProject -Source $SourceFrontEnd -OldRegexp 'this\.biaMessageService\.showError\(\)' -NewRegexp 'this.biaMessageService.showErrorHttpResponse(err)' -Include *-effects.ts

ReplaceInProject -Source $SourceFrontEnd -OldRegexp "pluck\('event'\),(([^{]|\n)*)switchMap\(\(\) =>" -NewRegexp 'switchMap(() =>' -Include notifications-effects.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "pluck\('([^']*)'\)" -NewRegexp 'map(x => x?.$1)' -Include *-effects.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "pluck," -NewRegexp '' -Include *-effects.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "pluck" -NewRegexp '' -Include *-effects.ts

ReplaceInProject -Source $SourceFrontEnd -OldRegexp "import \* as FileSaver from 'file-saver';" -NewRegexp "import { saveAs } from 'file-saver';" -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "FileSaver.saveAs" -NewRegexp "saveAs" -Include *.ts

ReplaceInProject -Source $SourceFrontEnd -OldRegexp "throwError\(([^']*)\)" -NewRegexp 'throwError(() => $1)' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "throwError\(\(\) => \(\) =>" -NewRegexp 'throwError(() =>' -Include *.ts

ReplaceInProject -Source $SourceFrontEnd -OldRegexp ".loadAllByPost, \(state, \{ event \}\)" -NewRegexp ".loadAllByPost, state" -Include *-reducer.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp ".failure, \(state, \{ error \}\)" -NewRegexp ".failure, state" -Include *-reducer.ts

# naming-convention
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([.| ])SortTeams\(' -NewRegexp '$1sortTeams('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([.| ])SortRoles\(' -NewRegexp '$1sortRoles('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([.| ])GetCurrentViewName\(' -NewRegexp '$1getCurrentViewName('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([.| ])InitSub\(' -NewRegexp '$1initSub('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([. | ])GetViewPreference\(' -NewRegexp '$1getViewPreference('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([. | ])OnDisplay\(' -NewRegexp '$1onDisplay('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([. | ])OnHide\(' -NewRegexp '$1onHide('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([. | ])DecodeToken\(' -NewRegexp '$1decodeToken('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([. | ])ReLogin\(' -NewRegexp '$1reLogin('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([. | ])DifferentialNotificationTeam\(' -NewRegexp '$1differentialNotificationTeam('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp ' DifferentialTranslation<T' -NewRegexp ' differentialTranslation<T'
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([.])DifferentialTranslation\(' -NewRegexp '$1differentialTranslation('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp ' Differential<T' -NewRegexp ' differential<T'
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([.])Differential\(' -NewRegexp '$1differential('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp ' Clone<T' -NewRegexp ' clone<T'
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '([.])Clone\(' -NewRegexp '$1clone('
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "InjectComponent: " -NewRegexp "injectComponent: " -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "\['InjectComponent'\]" -NewRegexp "['injectComponent']" -Include *.ts

[string] $presentationApiFolder = GetPresentationApiFolder -Source $SourceBackEnd
Write-Host "Migration BackEnd"

if (-not ([string]::IsNullOrWhiteSpace($presentationApiFolder))) {
  [string] $controllersFolder = $presentationApiFolder + "\Controllers"
  ReplaceInProject -Source $controllersFolder -OldRegexp '\s*catch \(Exception\)(([^{]|\n)*)(([500]|\n)*)(([^}]|\n)*)\}' -NewRegexp '' -Include *.cs
}

cd $Source/DotNet
dotnet restore --no-cache

Write-Host "Finish"
pause
