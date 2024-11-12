$Source = "C:\Sources\Azure.DevOps.Safran\eFollow";
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

function CleanIoc {
  param (
    [string]$Source
  )

  $path = Get-ChildItem -Path $Source -Include IocContainer.cs -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

  if (Test-Path $path) {

    Write-Output $path
    $pattern = "collection\.AddTransient<(I([A-Za-z]+)), \2>\(\);"
    $exception = "BackgroundJobClient"
  
  (Get-Content $path) | Foreach-Object {
      if ($_ -notmatch $pattern -or $_ -match $exception) {
        $_
      }
    } | Set-Content $path
  }
}

function RemoveIFilteredServiceBase {
  $csFiles = Get-ChildItem -Path $SourceBackEnd -Recurse -Include *.cs

  foreach ($file in $csFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $content = [regex]::Replace($content, "
      (\s*:\s*IFilteredServiceBase<[^>]+>\s*(,)?)\n |   # Case where it's the only or first interface
      (\s*,\s*IFilteredServiceBase<[^>]+>)                 # Case where it's not the first interface
    ", {
      if ($args[0]) {
        if ($args[0].Value.Trim().StartsWith(":") -and $args[0].Value.Trim().EndsWith(",")) {
          return " : "
        } else {
          return "`n" 
        }
      }
    }, 'IgnorePatternWhitespace')
    Set-Content -Path $file.FullName -Value $content
  }
}

function ReplaceIClientForHubRepository {
  $csFiles = Get-ChildItem -Path $SourceBackEnd -Recurse -Include *.cs
  foreach ($file in $csFiles) {
    if ($file.FullName -match "\.Presentation\.|\.Application\.") {
      $content = Get-Content -Path $file.FullName -Raw
      $content = [regex]::Replace($content, "\bIClientForHubRepository\b", "IClientForHubService")
      Set-Content -Path $file.FullName -Value $content
    }
  }
}

# BEGIN - typing components and config
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "class ([A-z]+)TableComponent([\r\n ]+)extends BiaCalcTableComponent([\r\n ]+)" -NewRegexp 'class $1TableComponent$2extends BiaCalcTableComponent<$1>$3' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "import { ([A-z]+)FieldsConfiguration } from '([\./]+)\/model\/([A-z\-]+)';([\s\S]+)export const \1CRUDConfiguration: CrudConfig =" -NewRegexp 'import { #capitalize#$1, $1FieldsConfiguration } from ''$2/model/$3'';$4export const $1CRUDConfiguration: CrudConfig<#capitalize#$1> =' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "import { ([A-z]+)FieldsConfiguration } from '([\./]+)\/model\/([A-z\-]+)';([\s\S]+)export const \1CRUDConfiguration: CrudConfig =" -NewRegexp 'import { #capitalize#$1, $1FieldsConfiguration } from ''$2/model/$3'';$4export const $1CRUDConfiguration: CrudConfig<#capitalize#$1> =' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "export const ([A-z]+)FieldsConfiguration: BiaFieldsConfig =" -NewRegexp 'export const $1FieldsConfiguration: BiaFieldsConfig<#capitalize#$1> =' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp 'export class ([A-z]+)IndexComponent([\s\S]+): BiaTableComponent;([\s\S]+): Observable<((?!OptionDto)[A-z]+)\[]>;' -NewRegexp 'export class $1IndexComponent$2: BiaTableComponent<$4>;$3: Observable<$4[]>;' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp 'export class ([A-z]+)IndexComponent([\s\S]+): Observable<((?!OptionDto)[A-z]+)\[]>;([\s\S]+): BiaTableComponent;' -NewRegexp 'export class $1IndexComponent$2: Observable<$3[]>;$4: BiaTableComponent<$3>;' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp 'export class ([A-z]+)IndexComponent([\s\S]+): Observable<((?!OptionDto)[A-z]+)\[]>;([\s\S]+): BiaFieldsConfig(?!<)' -NewRegexp 'export class $1IndexComponent$2: Observable<$3[]>;$4: BiaFieldsConfig<$3>' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp 'export class ([A-z]+)IndexComponent([\s\S]+): BiaFieldsConfig(?!<)([\s\S]+): Observable<((?!OptionDto)[A-z]+)\[]>;' -NewRegexp 'export class $1IndexComponent$2: BiaFieldsConfig<$4>$3: Observable<$4[]>;' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp 'export class ([A-z]+)IndexComponent([\s\S]+): Observable<((?!OptionDto)[A-z]+)\[]>;([\s\S]+): BiaFieldConfig(?!<)' -NewRegexp 'export class $1IndexComponent$2: Observable<$3[]>;$4: BiaFieldConfig<$3>' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp 'class ([A-z]+)TableFilterComponent extends BiaTableFilterComponent(?!<)' -NewRegexp 'class $1TableFilterComponent<TDto extends BaseDto> extends BiaTableFilterComponent<TDto>' -Include *.ts
# END - typing components and config

# BEGIN - Replacements after reorganize layers DotNet
ReplaceInProject -Source $SourceBackEnd -OldRegexp '\bFilteredServiceBase\b' -NewRegexp 'OperationalDomainServiceBase' -Include *.cs
ReplaceInProject -Source $SourceBackEnd -OldRegexp '\bAppServiceBase\b"' -NewRegexp 'DomainServiceBase' -Include *.cs
ReplaceInProject -Source $SourceBackEnd -OldRegexp '(?ms)#if\s+UseHubForClientInContact\s+using\s+BIA\.Net\.Core\.Domain\.RepoContract;\s+#endif' -NewRegexp '' -Include *.cs
RemoveIFilteredServiceBase
ReplaceIClientForHubRepository
# END - Replacements after reorganize layers DotNet

# Set-Location $Source/DotNet
dotnet restore --no-cache

Write-Host "Finish"
pause
