$Source = "C:\Sources\github\BIADemo";
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

function CleanIoc {
  param (
    [string]$Source
  )

  $path = Get-ChildItem -Path $Source -Include IocContainer.cs -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

  if (Test-Path $path) {

    Write-Output $path
    $pattern = "collection\.AddTransient<(I([A-Za-z]+)), \2>\(\);"
    $exception = "BackgroundJobClient"
    $insideFunction = $false
    $foundFirstBrace = $false
    $braceCount = 0

    $lines = Get-Content $path
    $outputLines = @()

    foreach ($line in $lines) {
      if ($line -match "void ConfigureInfrastructureServiceContainer") {
        $insideFunction = $true
      }

      if ($insideFunction) {
        $braceCount += ($line.Split("{")).Count - 1
        if ($braceCount -gt 0) {
          $foundFirstBrace = $true
        }
        $braceCount -= ($line.Split("}")).Count - 1
      }

      if ($insideFunction) {
        $outputLines += $line
        if ($braceCount -eq 0 -and $foundFirstBrace -eq $true) {
          $insideFunction = $false
        }
      } elseif ($line -notmatch $pattern -or $line -match $exception) {
        $outputLines += $line
      }
    }

    $outputLines | Set-Content $path
  }
}

ReplaceInProject -Source $SourceBackEnd -OldRegexp '(?<!IDomainEvent : )\bINotification\b' -NewRegexp 'IMailRepository' -Include *.cs
CleanIoc -Source $SourceBackEnd

# BEGIN - strict template activation
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '\[crudItem]="([A-z.$]+ \| async)"' -NewRegexp '*ngIf="$1; let crudItem" [crudItem]="crudItem"' -Include *.html
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '"totalCount\$ \| async"' -NewRegexp '"(totalCount$ | async) ?? 0"' -Include *.html 
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '"crudItems\$ \| async"' -NewRegexp '"(crudItems$ | async) ?? []"' -Include *.html 
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '"loading\$ \| async"' -NewRegexp '"(loading$ | async) ?? false"' -Include *.html 
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '("[\r\n ]*)([A-z.$]+\.dictOptionDtos\$[\r\n ]*\| async)([\r\n ]*")' -NewRegexp '$1($2) ?? []$3' -Include *.html 
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '\[elements]="([A-z.]+)\$ \| async"' -NewRegexp '[elements]="($1$ | async) ?? []"' -Include *.html 
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '\[([A-z]+Options)]="([\r\n ]*)([A-z.]+)\$ \| async([\r\n ]*)"' -NewRegexp '[$1]="$2($3$ | async) ?? []$4"' -Include *.html 
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "import { LazyLoadEvent } from 'primeng/api';" -NewRegexp "import { TableLazyLoadEvent } from 'primeng/table';" -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "(?-i)\bLazyLoadEvent\b" -NewRegexp 'TableLazyLoadEvent' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp 'frozeSelectColumn="(true|false)"' -NewRegexp '[frozeSelectColumn]="$1"' -Include *.html
ReplaceInProject -Source $SourceFrontEnd -OldRegexp 'showTime="(true|false)"' -NewRegexp '[showTime]="$1"' -Include *.html
ReplaceInProject -Source $SourceFrontEnd -OldRegexp '\.getPrimeNgTable\(\)([\r\n ]*)\.' -NewRegexp '.getPrimeNgTable()$1?.' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "selectedCrudItems\?" -NewRegexp 'selectedCrudItems' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "selectedCrudItems\?" -NewRegexp 'selectedCrudItems' -Include *.html
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "\.fieldsConfig\?\.advancedFilter" -NewRegexp '.fieldsConfig.advancedFilter' -Include *.html
# This one is a bit risky, could put ngIf on things that should be effectively nullable, thus hiding the component wrongfully
#ReplaceInProject -Source $SourceFrontEnd -OldRegexp '\[(?!\bngSwitch\b)(?!\bngIf\b)(?!\bappSettings\b)([A-z]+)]="(([A-z]*\.)*([A-z]+)\$ \| async)"' -NewRegexp '*ngIf="$2; let $4" [$1]="$4"' -Include *.html

# END - strict template activation

Set-Location $Source/DotNet
dotnet restore --no-cache

Write-Host "Finish"
pause
