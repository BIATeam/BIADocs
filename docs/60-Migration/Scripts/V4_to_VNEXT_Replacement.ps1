$Source = "C:\sources\Azure\SCardNG";
$SourceBackEnd = $Source + "\DotNet"
$SourceFrontEnd = $Source + "\Angular"
$currentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

$ExcludeDir = ('dist', 'node_modules', 'docs', 'scss', '.git', '.vscode', '.angular', '.dart_tool')

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

function ApplyChangesAngular19 {
  Write-Host "[Apply Angular 19 changes]"

  $replacementsTS = @(
      @{Pattern = "import { PrimeNGConfig } from 'primeng/api'"; Replacement = "import { PrimeNG } from 'primeng/config'"},
      @{Pattern = "PrimeNGConfig"; Replacement = "PrimeNG"},
      @{Pattern = "InputTextareaModule"; Replacement = "Textarea"},
      @{Pattern = "primeng/tristatecheckbox"; Replacement = "primeng/checkbox"},
      @{Pattern = "TriStateCheckboxModule"; Replacement = "Checkbox"},
      @{Pattern = "\bMessage\b"; Replacement = "ToastMessageOptions"},
      @{Pattern = "primeng/calendar"; Replacement = "primeng/datepicker"},
      @{Pattern = "\bCalendar\b"; Replacement = "DatePicker"},
      @{Pattern = "primeng/dropdown"; Replacement = "primeng/select"},
      @{Pattern = "DropdownModule"; Replacement = "SelectModule"},
      @{Pattern = "primeng/tabview"; Replacement = "primeng/tabs"},
      @{Pattern = "TabViewModule"; Replacement = "TabsModule"},
      @{Pattern = "primeng/inputswitch"; Replacement = "primeng/toggleswitch"},
      @{Pattern = "InputSwitchModule"; Replacement = "ToggleSwitchModule"},
      @{Pattern = "primeng/overlaypanel"; Replacement = "primeng/popover"},
      @{Pattern = "OverlayPanelModule"; Replacement = "PopoverModule"},
      @{Pattern = "primeng/sidebar"; Replacement = "primeng/drawer"},
      @{Pattern = "SidebarModule"; Replacement = "DrawerModule"},
      @{Pattern = "\bKeycloakEvent\b"; Replacement = "KeycloakEventLegacy"},
      @{Pattern = "\bKeycloakEventType\b"; Replacement = "KeycloakEventTypeLegacy"}
  )

  $replacementsHTML = @(
      @{Pattern = "(p-autoComplete[^>]*?)\[\s*size\s*\]=\s*""[^""]*"""; Replacement = "`$1size=""small"""},
      @{Pattern = "(button[^>]*?(?:pButton|p-button)[^>]*?)\s+severity=""warning"""; Replacement = "`$1severity=""warn"""},
      @{Pattern = "<p-triStateCheckbox"; Replacement = "<p-checkbox [indeterminate]=""true"""},
      @{Pattern = "</p-triStateCheckbox"; Replacement = "</p-checkbox"},
      @{Pattern = "p-calendar"; Replacement = "p-date-picker"},
      @{Pattern = "p-dropdown"; Replacement = "p-select"},
      @{Pattern = "p-tabView"; Replacement = "p-tabs"},
      @{Pattern = "p-tabPanel"; Replacement = "p-tabpanel"},
      @{Pattern = "p-accordionTab"; Replacement = "p-accordion-panel"},
      @{Pattern = "(?s)(<p-accordion-panel[^>]*?>)\s*<ng-template pTemplate=""header"">(.*?)</ng-template"; Replacement = "`$1<p-accordion-header>`$2</p-accordion-header"},
      @{Pattern = "p-toggleswitch"; Replacement = "p-inputSwitch"},
      @{Pattern = "p-overlayPanel"; Replacement = "p-popover"},
      @{Pattern = "p-sidebar"; Replacement = "p-drawer"},
      @{Pattern = "(p-drawer[^>]*?>)\s*<ng-template pTemplate=""header"">"; Replacement = "`$1<ng-template #header>"},
      @{Pattern = "(?s)<p-drawer([^>]*)>\s*<h[1-6]>(.*?)<\/h[1-6]>"; Replacement = "<p-drawer`$1 header=""`$2"">"},
      @{Pattern = '(?s)<(\w+)([^>]*class="[^"]*p-float-label[^"]*"[^>]*)>(.*?)<\/\1'; Replacement = '<p-floatlabel$2 variant="in">$3</p-floatlabel'},
      @{Pattern = '(?s)<(\w+)([^>]*class="[^"]*p-fluid[^"]*"[^>]*)>(.*?)<\/\1'; Replacement = '<p-fluid$2>$3</p-fluid'},
      @{Pattern = '(?s)<button([^>]*class="[^"]*p-link[^"]*"[^>]*)>(.*?)<\/button'; Replacement = '<p-button [link]=true $1>$2</p-button'},
      @{Pattern = '(?<=class=")([^"]*)\b(p-float-label)\b([^"]*)'; Replacement = '${1}${3}'},
      @{Pattern = '(?<=class=")([^"]*)\b(p-link)\b([^"]*)'; Replacement = '${1}${3}'},
      @{Pattern = '(?<=class=")([^"]*)\b(p-fluid)\b([^"]*)'; Replacement = '${1}${3}'},
      @{Pattern = 'class=""'; Replacement = ""},
      @{Pattern = "(?s)<p-dialog([^>]*)>\s*<p-header>(.*?)</p-header>"; Replacement = "<p-dialog`$1 header=""`$2"">"},
      @{Pattern = '(?s)(<p-checkbox[^>]*?)\s+label="([^"]+)"([^>]*?>)'; Replacement = '${1}${3}<label class="ml-2">${2}</label>'}
  )

  $extensions = "*.ts", "*.html", "*.scss"
  Get-ChildItem -Path $SourceFrontEnd -Recurse -Include $extensions| Where-Object {
    $excluded = $false
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

    foreach ($rule in $replacementsTS + $replacementsHTML) {
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
# ReplaceInProject -Source $SourceFrontEnd -OldRegexp "((templateUrl|styleUrls?):\s*\[*\s*['""])(\.\.\/)+(shared\/.+?)['""]" -NewRegexp '$1/src/app/$4' -Include *.ts
ApplyChangesAngular19

## Front end migration conclusion
$standaloneCatchUpScript = "standalone-catch-up.js"
Copy-Item "$currentDirectory\$standaloneCatchUpScript" "$SourceFrontEnd\$standaloneCatchUpScript"
Set-Location $SourceFrontEnd
node $standaloneCatchUpScript
Remove-Item "$SourceFrontEnd\$standaloneCatchUpScript"
npx prettier --write . 2>&1 | Select-String -Pattern "unchanged" -NotMatch

# New DTO location
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "bia-shared/model/base-dto';" -NewRegexp "bia-shared/model/dto/base-dto';" -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "bia-shared/model/base-team-dto';" -NewRegexp "bia-shared/model/dto/base-team-dto';" -Include *.ts

# BEGIN - Base Mapper
ReplaceInProject -Source $SourceBackEnd -OldRegexp "public override void DtoToEntity\(([\w]*)Dto dto, ([\w]*) entity(, .*)?\)" -NewRegexp 'public override void DtoToEntity($1Dto dto, ref $2 entity$3)' -Include *.cs
ReplaceInProject -Source $SourceBackEnd -OldRegexp "\.DtoToEntity\(dto, entity(, .*)?\);" -NewRegexp '.DtoToEntity(dto, ref entity$1);' -Include *.cs
# END - Base Mapper

# BEGIN - CrudItemService Injector
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "(public signalRService: .*,([ ]|\n)*public optionsService: .*OptionsService,([ ]|\n)*)//" -NewRegexp '$1protected injector: Injector,\n//' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "super\(dasService, signalRService, optionsService\);" -NewRegexp 'super(dasService, signalRService, optionsService, injector);' -Include *.ts
ReplaceInProject -Source $SourceFrontEnd -OldRegexp "import \{ Injectable \} from '@angular/core';(((\n)*)import \{ Store \} from '@ngrx/store';((\n)*)import \{ TableLazyLoadEvent \} from 'primeng/table';)" -NewRegexp 'import { Injectable, Injector } from ''@angular/core'';$1' -Include *.ts
# END - CrudItemService Injector

# BEGIN - BaseEntity
ReplaceInProject -Source $SourceBackEnd -OldRegexp ": VersionedTable, IEntity<" -NewRegexp ': BaseEntityVersioned<' -Include *.cs
# TODO verify in a V4 project with archiving:
ReplaceInProject -Source $SourceBackEnd -OldRegexp ": VersionedTable, IEntityArchivable<" -NewRegexp ': BaseEntityVersionedArchivable<' -Include *.cs
ReplaceInProject -Source $SourceBackEnd -OldRegexp ": VersionedTable, IEntityFixable<" -NewRegexp ': BaseEntityVersionedFixable<' -Include *.cs
# END - BaseEntity

# BEGIN - TeamDto in BaseDtoVersionedTeam
ReplaceInProject -Source $SourceBackEnd -OldRegexp "(\W|^)TeamDto(\W|$)" -NewRegexp '$1BaseDtoVersionedTeam$2' -Include *.cs
# END - TeamDto in BaseDtoVersionedTeam

# BEGIN - TeamDto in BaseTeamMapper
ReplaceInProject -Source $SourceBackEnd -OldRegexp "TTeamMapper<" -NewRegexp 'BaseTeamMapper<' -Include *.cs
# END - TeamDto in BaseTeamMapper

# BACK END
Set-Location $SourceFrontEnd 
npm run clean

# BACK END
# Set-Location $SourceBackEnd
# dotnet restore --no-cache





Write-Host "Finish"
pause
