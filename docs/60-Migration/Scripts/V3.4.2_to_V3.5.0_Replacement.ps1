$Source = "D:\xxxx\ProjectName";

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

ReplaceInProject -Source $Source -OldRegexp 'ui-icon-' -NewRegexp 'pi pi-' -Include *.ts, *.html, *.scss
ReplaceInProject -Source $Source -OldRegexp 'chevron-down' -NewRegexp 'angle-down' -Include *.ts, *.html, *.scss
ReplaceInProject -Source $Source -OldRegexp 'filter-list' -NewRegexp 'filter' -Include *.ts, *.html, *.scss
ReplaceInProject -Source $Source -OldRegexp 'md-inputfield' -NewRegexp 'p-float-label' -Include *.ts, *.html, *.scss
ReplaceInProject -Source $Source -OldRegexp 'ui-button-secondary' -NewRegexp 'p-button-outlined' -Include *.ts, *.html, *.scss
ReplaceInProject -Source $Source -OldRegexp 'ui-' -NewRegexp 'p-' -Include *.ts, *.html, *.scss



ReplaceInProject -Source $Source -OldRegexp ' mapper = new (.*)Mapper\(\);' -NewRegexp ' mapper = this.InitMapper<$1Dto, $1Mapper>();' -Include *.cs

ReplaceInProject -Source $Source -OldRegexp 'FileFiltersDto' -NewRegexp 'PagingFilterFormatDto' -Include *.cs

ReplaceInProject -Source $Source -OldRegexp 'VersionedTable, IEntity' -NewRegexp 'VersionedTable, IEntity<int>' -Include *.cs
ReplaceInProject -Source $Source -OldRegexp 'VersionedTable, IEntity<int><int>' -NewRegexp 'VersionedTable, IEntity<int>' -Include *.cs

ReplaceInProject -Source $Source -OldRegexp ': BaseDto' -NewRegexp ': BaseDto<int>' -Include *.cs
ReplaceInProject -Source $Source -OldRegexp ': BaseDto<int><int>' -NewRegexp ': BaseDto<int>' -Include *.cs

ReplaceInProject -Source $Source -OldRegexp ': FilteredServiceBase<(.*)>' -NewRegexp ': FilteredServiceBase<$1, int>' -Include *.cs
ReplaceInProject -Source $Source -OldRegexp ': FilteredServiceBase<(.*), int, int>' -NewRegexp ': FilteredServiceBase<$1, int>' -Include *.cs

ReplaceInProject -Source $Source -OldRegexp 'ITGenericRepository<(.*)>' -NewRegexp 'ITGenericRepository<$1, int>' -Include *.cs
ReplaceInProject -Source $Source -OldRegexp 'ITGenericRepository<(.*), int, int>' -NewRegexp 'ITGenericRepository<$1, int>' -Include *.cs

ReplaceInProject -Source $Source -OldRegexp ': AppServiceBase<(.*)>' -NewRegexp ': AppServiceBase<$1, int>' -Include *.cs
ReplaceInProject -Source $Source -OldRegexp ': AppServiceBase<$1, int, int>' -NewRegexp ': AppServiceBase<$1, int>' -Include *.cs

ReplaceInProject -Source $Source -OldRegexp ': ICrudAppServiceBase<(.*),(.*),(.*)>' -NewRegexp ': ICrudAppServiceBase<$1,$2, int,$3>' -Include *.cs
ReplaceInProject -Source $Source -OldRegexp ': ICrudAppServiceBase<(.*),(.*), int, int,(.*)>' -NewRegexp ': ICrudAppServiceBase<$1,$2, int,$3>' -Include *.cs

ReplaceInProject -Source $Source -OldRegexp ': CrudAppServiceBase<(.*),(.*),(.*),(.*)>' -NewRegexp ': CrudAppServiceBase<$1,$2, int,$3,$4>' -Include *.cs
ReplaceInProject -Source $Source -OldRegexp ': CrudAppServiceBase<(.*),(.*), int, int,(.*),(.*)>' -NewRegexp ': CrudAppServiceBase<$1,$2, int,$3,$4>' -Include *.cs

ReplaceInProject -Source $Source -OldRegexp ': BaseMapper<(.*),(.*)>' -NewRegexp ': BaseMapper<$1,$2, int>' -Include *.cs
ReplaceInProject -Source $Source -OldRegexp ': BaseMapper<(.*),(.*), int, int>' -NewRegexp ': BaseMapper<$1,$2, int>' -Include *.cs

cd $Source/DotNet
dotnet restore --no-cache


Write-Host "Finish"
pause
