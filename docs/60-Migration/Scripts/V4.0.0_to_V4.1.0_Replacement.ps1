$Source = "D:\Source\GitHub\BIATeam\BIADemo";
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




# Set-Location $Source/DotNet
dotnet restore --no-cache

Write-Host "Finish"
pause
