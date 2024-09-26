$Source = "C:\Sources\Github.com\BIATeam\BIADemo";
$SourceNG = $Source + "\Angular\src\app"
$SourceNet = $Source + "\DotNet"

$ExcludeDir = ('dist', 'node_modules', 'docs', 'scss', '.git', '.vscode', '.angular', 'bin', 'obj')

function ReplaceInProject {
  param (
    [string]$Source,
    [string]$OldRegexp,
    [string]$NewRegexp,
    [string[]]$Include
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
    [string[]]$Include
  )
  foreach ($childDirectory in Get-ChildItem -Force -Path $Source -Directory -Exclude $ExcludeDir) {
    ReplaceInProjectRec -Source $childDirectory.FullName -OldRegexp $OldRegexp -NewRegexp $NewRegexp -Include $Include
  }
	
  Get-ChildItem -LiteralPath $Source -File -Include $Include | ForEach-Object {
    $oldContent = [System.IO.File]::ReadAllText($_.FullName);
    $found = $oldContent | select-string -Pattern $OldRegexp -CaseSensitive

    if ($found.Matches) {
      $newContent = $oldContent -creplace $OldRegexp, $NewRegexp 
      if ($oldContent -cne $newContent) {
        Write-Host "     => " $_.FullName
        [System.IO.File]::WriteAllText($_.FullName, $newContent)
      }
    }

  }
}


Write-Host "Migration replacement"

ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayout="([^"]*)\swrap"' -NewRegexp 'fxLayout="$1" class="flex-wrap"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutWrap="wrap"' -NewRegexp 'class="flex-wrap"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutWrap' -NewRegexp 'class="flex-wrap"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayout="([^"]*)\sinline"' -NewRegexp 'fxLayout="$1" style="display: inline-flex"' -Include *.html

ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutGap="20px"' -NewRegexp 'class="gap-3"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutGap="8px"' -NewRegexp 'class="gap-2"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutGap="5px"' -NewRegexp 'class="gap-1"' -Include *.html

ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayout="row"([^>]*)fxLayoutAlign="stretch"' -NewRegexp 'fxLayout="row"$1style="max-height: 100%"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayout="column"([^>]*)fxLayoutAlign="stretch"' -NewRegexp 'fxLayout="row"$1style="max-width: 100%"' -Include *.html

ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayout="row"' -NewRegexp 'class="flex flex-row"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayout="column"' -NewRegexp 'class="flex flex-column"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayout="row-reverse"' -NewRegexp 'class="flex flex-row-reverse"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayout="column-reverse"' -NewRegexp 'class="flex flex-column-reverse"' -Include *.html

# fxLayoutAlign Both Axis
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="([^"]*)\s([^"]*)"' -NewRegexp 'fxLayoutAlign="$1" fxLayoutAlignY="$2"' -Include *.html

# fxLayoutAlign Main Axis
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="start"' -NewRegexp 'class="flex justify-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="flex-start"' -NewRegexp 'class="flex justify-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="center"' -NewRegexp 'class="flex justify-content-center"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="flex-end"' -NewRegexp 'class="flex justify-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="end"' -NewRegexp 'class="flex justify-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="space-around"' -NewRegexp 'class="flex justify-content-around"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="space-between"' -NewRegexp 'class="flex justify-content-between"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="space-evenly"' -NewRegexp 'class="flex justify-content-evenly"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="baseline"' -NewRegexp 'class="flex align-self-baseline"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="stretch"' -NewRegexp 'class="flex align-self-stretch"' -Include *.html

# fxLayoutAlign Cross Axis
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="start"' -NewRegexp 'class="flex align-items-start align-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="flex-start"' -NewRegexp 'flex align-items-start class="align-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="center"' -NewRegexp 'class="flex align-items-center align-content-center"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="end"' -NewRegexp 'class="flex align-items-end align-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="flex-end"' -NewRegexp 'class="flex align-items-end align-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="space-around"' -NewRegexp 'class="flex align-content-around"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="space-between"' -NewRegexp 'class="flex align-content-between"' -Include *.html

#fxFlex
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex="([0-9]*)px"' -NewRegexp 'class="flex-1" style="max-width:$1px;"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex="([0-9]*)"' -NewRegexp 'class="flex-1" style="max-width:$1%;"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex="({{[^"]*}})"' -NewRegexp 'class="flex-1" style="max-width:$1%;"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex="\*"' -NewRegexp 'class="flex-1"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex ' -NewRegexp 'class="flex-1" ' -Include *.html

#fxFlexAlign
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlexAlign="start"' -NewRegexp 'class="flex align-self-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlexAlign="center"' -NewRegexp 'class="flex align-self-center"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlexAlign="end"' -NewRegexp 'class="flex align-self-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlexAlign="baseline"' baseline 'class="flex align-self-baseline"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlexAlign="stretch"' -NewRegexp 'class="flex align-self-stretch"' -Include *.html

# Aggregation of Class and style
ReplaceInProject -Source $SourceNG -OldRegexp 'class="([^"]*)" class="([^"]*)"' -NewRegexp 'class="$1 $2"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'class="([^"]*)"([^>]*)class="([^"]*)"' -NewRegexp 'class="$1 $3"$2' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'class="([^"]*)" class="([^"]*)"' -NewRegexp 'class="$1 $2"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'class="([^"]*)"([^>]*)class="([^"]*)"' -NewRegexp 'class="$1 $3"$2' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'style="([^"]*)" style="([^"]*)"' -NewRegexp 'style="$1; $2"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'style="([^"]*)"([^>]*)style="([^"]*)"' -NewRegexp 'style="$1; $3"$2' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'style="([^"]*)" style="([^"]*)"' -NewRegexp 'style="$1; $2"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'style="([^"]*)"([^>]*)style="([^"]*)"' -NewRegexp 'style="$1; $3"$2' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'style="([^"]*);;([^"]*)"' -NewRegexp 'style="$1;$2' -Include *.html

#Reduce nomber of class flex
ReplaceInProject -Source $SourceNG -OldRegexp 'class="([^"]*)\sflex\s([^"]*)\sflex\s([^"]*)"' -NewRegexp 'class="$1 flex $2 $3"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'class="flex\s([^"]*)\sflex\s([^"]*)"' -NewRegexp 'class="flex $1 $2"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'class="([^"]*)\sflex\s([^"]*)\sflex\s([^"]*)"' -NewRegexp 'class="$1 flex $2 $3"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'class="flex\s([^"]*)\sflex\s([^"]*)"' -NewRegexp 'class="flex $1 $2"' -Include *.html

#Replace Navigation
ReplaceInProject -Source $SourceNG -OldRegexp 'this.router.navigate\(\[''\.\./'' \+(.*) \+ ''/(.*)''\]' -NewRegexp 'this.router.navigate([$1, ''$2'']' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'this.router.navigate\(\[''\.\./([a-z]+)''\]' -NewRegexp 'this.router.navigate([''$1'']' -Include *.html

#Replace Primeflex class
ReplaceInProject -Source $SourceNG -OldRegexp 'p-m(.)-' -NewRegexp 'm$1-' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'p-grid' -NewRegexp 'grid' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'p-col-' -NewRegexp 'col-' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'p-col"' -NewRegexp 'col"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'p-col ' -NewRegexp 'col ' -Include *.html

#Revert Auto migration V3.7.0 to V3.7.1 (code warning)
ReplaceInProject -Source $SourceNet -OldRegexp '\(([^\s]*) != null && (\1\?\.Any\(\) == true)\)' -NewRegexp '($2)' -Include *.cs
ReplaceInProject -Source $SourceNet -OldRegexp '\(([^\s]*) == null \|\| (\1\?\.Any\(\) != true)\)' -NewRegexp '($2)' -Include *.cs

# Angular 14 migration
ReplaceInProject -Source $SourceNG -OldRegexp 'FormBuilder' -NewRegexp 'UntypedFormBuilder' -Include *.ts
ReplaceInProject -Source $SourceNG -OldRegexp 'FormGroup' -NewRegexp 'UntypedFormGroup' -Include *.ts
ReplaceInProject -Source $SourceNG -OldRegexp 'FormArray' -NewRegexp 'UntypedFormArray' -Include *.ts
ReplaceInProject -Source $SourceNG -OldRegexp 'FormControl' -NewRegexp 'UntypedFormControl' -Include *.ts
ReplaceInProject -Source $SourceNG -OldRegexp 'UntypedUntyped' -NewRegexp 'Untyped' -Include *.ts

# Angular 15 migration
ReplaceInProject -Source $SourceNG -OldRegexp '[@]HostBinding[(]''class.bia-flex''[)] flex = true;' -NewRegexp '@HostBinding(''class'') classes = ''bia-flex'';' -Include *.ts
ReplaceInProject -Source $SourceNG -OldRegexp 'new EventEmitter[(][)];' -NewRegexp 'new EventEmitter<void>();' -Include *.ts
ReplaceInProject -Source $SourceNG -OldRegexp 'getPrimeNgTable[(][)].columns.map' -NewRegexp 'getPrimeNgTable().columns?.map' -Include *.ts
ReplaceInProject -Source $SourceNet -OldRegexp 'this.filtersContext.Add' -NewRegexp 'this.FiltersContext.Add' -Include *.cs

cd $Source/DotNet
dotnet restore --no-cache

Write-Host "Finish"
pause
