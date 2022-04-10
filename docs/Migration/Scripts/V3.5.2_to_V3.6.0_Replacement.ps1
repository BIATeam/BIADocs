$Source = "D:\xxxx\ProjectName";

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
	
    $Destination = $Source + "FINAL"
    Get-ChildItem $Source -Recurse -Include  $Include | ForEach-Object  {
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

ReplaceInProject -Source $Source -OldRegexp 'Das.put\(([^{].*),(.*)\)' -NewRegexp 'Das.put({ item: $1, id: $1.id })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.post\(([^{].*)\)' -NewRegexp 'Das.post({item: $1})' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.delete\(([^{].*)\)' -NewRegexp 'Das.delete({ id: id })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.deletes\(([^{].*)\)' -NewRegexp 'Das.deletes({ ids: ids })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.save\(([^{].*),(.*)\)' -NewRegexp 'Das.save({ items: $1, endpoint: $2 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.save\(([^{].*)\)' -NewRegexp 'Das.save({ items: $1 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.getList\(([^{].*),(.*)\)' -NewRegexp 'Das.getList({ endpoint: $1, options: $2 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.getList\(''(.*)''\)' -NewRegexp 'Das.getList({ endpoint: ''$1'' })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.getListByPost\(([^{].*)\)' -NewRegexp 'Das.getListByPost({ event: $1 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.get\(([^{].*)\).pipe' -NewRegexp 'Das.get({ id: $1 }).pipe' -Include *.ts


ReplaceInProject -Source $Source -OldRegexp '<bia-table([^-]([^>]|\n)*)\[canEdit\]' -NewRegexp '<bia-table$1[canClickRow]' -Include *.html
ReplaceInProject -Source $Source -OldRegexp '<bia-table([^-]([^>]|\n)*)\(edit\)' -NewRegexp '<bia-table$1(clickRow)' -Include *.html



cd $Source/DotNet
dotnet restore --no-cache


Write-Host "Finish"
pause
