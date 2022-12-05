$Source = "D:\Sources\GitHub\BIATeam\eSuitePortal";

$ExcludeDir = ('dist', 'node_modules', 'docs', 'scss', '.git', '.vscode')

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

ReplaceInProject -Source $Source -OldRegexp 'useClacMode' -NewRegexp 'useCalcMode'
ReplaceInProject -Source $Source -OldRegexp '<bia-table([^-]([^>]|\n)*)\(clickRow\)' -NewRegexp '<bia-table$1(clickRowId)' -Include *.html


cd $Source/DotNet
dotnet restore --no-cache


Write-Host "Finish"
pause
