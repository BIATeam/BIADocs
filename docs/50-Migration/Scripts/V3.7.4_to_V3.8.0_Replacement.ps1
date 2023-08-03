$Source = "C:\Sources\Github.com\BIATeam\BIADemo";
$SourceNG =  $Source + "\Angular\src\app"

$ExcludeDir = ('dist', 'node_modules', 'docs', 'scss', '.git', '.vscode', '.angular')

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
	
    Get-ChildItem -LiteralPath $Source -File -Include $Include | ForEach-Object  {
        $oldContent = [System.IO.File]::ReadAllText($_.FullName);
        $found = $oldContent | select-string -Pattern $OldRegexp
        if ($found.Matches)
        {
            $newContent = $oldContent -Replace $OldRegexp, $NewRegexp 
            if ($oldContent -ne $newContent) {
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

# fxLayoutAlign Cross Axis
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="start"' -NewRegexp 'class="flex justify-content-start align-items-start align-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="flex-start"' -NewRegexp 'class="flex justify-content-start align-items-start align-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="center"' -NewRegexp 'class="flex justify-content-center align-items-center align-content-center"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="flex-end"' -NewRegexp 'class="flex justify-content-end align-items-end align-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="end"' -NewRegexp 'class="flex justify-content-end align-items-end align-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="space-around"' -NewRegexp 'class="flex justify-content-around align-content-around"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="space-between"' -NewRegexp 'class="flex justify-content-between align-content-between"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="baseline"' -NewRegexp 'style="align-items: baseline; align-content: stretch;"' -Include *.html

# fxLayoutAlign Main Axis
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="space-evenly"' -NewRegexp 'class="flex justify-content-evenly"' -Include *.html

# fxLayoutAlign Both Axis
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlign="([^"]*)\s([^"]*)"' -NewRegexp 'fxLayoutAlignX="$1" fxLayoutAlignY="$2"' -Include *.html

# fxLayoutAlign X Axis
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignX="start"' -NewRegexp 'class="flex justify-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignX="flex-start"' -NewRegexp 'class="flex justify-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignX="center"' -NewRegexp 'class="flex justify-content-center"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignX="end"' -NewRegexp 'class="flex justify-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignX="flex-end"' -NewRegexp 'class="flex justify-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignX="space-around"' -NewRegexp 'class="flex justify-content-around"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignX="space-between"' -NewRegexp 'class="flex justify-content-between"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignX="baseline"' -NewRegexp 'style="align-items: baseline; align-content: stretch;"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignX="stretch"' -NewRegexp 'style="max-width: 100%;"' -Include *.html

# fxLayoutAlign Y Axis
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="start"' -NewRegexp 'class="flex align-items-start align-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="flex-start"' -NewRegexp 'flex align-items-start class="align-content-start"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="center"' -NewRegexp 'class="flex align-items-center align-content-center"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="end"' -NewRegexp 'class="flex align-items-end align-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="flex-end"' -NewRegexp 'class="flex align-items-end align-content-end"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="space-around"' -NewRegexp 'class="flex align-content-around"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxLayoutAlignY="space-between"' -NewRegexp 'class="flex align-content-between"' -Include *.html

#fxFlex
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex="([0-9]*)px"' -NewRegexp 'class="flex flex-1" style="max-width:$1px;"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex="([0-9]*)"' -NewRegexp 'class="flex flex-1" style="max-width:$1%;"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex="({{[^"]*}})"' -NewRegexp 'class="flex flex-1" style="max-width:$1%;"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex="\*"' -NewRegexp 'class="flex flex-1"' -Include *.html
ReplaceInProject -Source $SourceNG -OldRegexp 'fxFlex ' -NewRegexp 'class="flex flex-1" ' -Include *.html

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

cd $Source/DotNet
dotnet restore --no-cache

Write-Host "Finish"
pause
