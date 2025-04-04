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

ReplaceInProject -Source $Source -OldRegexp 'this\.columns\.map\(\(x\) => \(columns\[x\.value\.split\("'"\."'"\)\[1\]\] = this\.translateService\.instant\(x\.value\)\)\);' -NewRegexp 'this.nameOfTheListComponent.getPrimeNgTable().columns.map((x: PrimeTableColumn) => (columns[x.field] = this.translateService.instant(x.header)));' -Include *index.component.ts
ReplaceInProject -Source $Source -OldRegexp 'public override Func<(.*), object\[\]> DtoToRecord\(\)' -NewRegexp 'public override Func<$1, object[]> DtoToRecord(List<string> headerNames = null)' -Include *.cs

cd $Source/DotNet
dotnet restore --no-cache


Write-Host "Finish"
pause
