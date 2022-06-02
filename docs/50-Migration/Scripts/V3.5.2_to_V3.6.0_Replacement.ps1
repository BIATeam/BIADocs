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

ReplaceInProject -Source $Source -OldRegexp 'Das.put\(([^{].*),(.*)\)' -NewRegexp 'Das.put({ item: $1, id: $1.id })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.post\(([^{].*)\)' -NewRegexp 'Das.post({item: $1})' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.delete\(([^{].*)\)' -NewRegexp 'Das.delete({ id: id })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.deletes\(([^{].*)\)' -NewRegexp 'Das.deletes({ ids: ids })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.save\(([^{].*),(.*)\)' -NewRegexp 'Das.save({ items: $1, endpoint: $2 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.save\(([^{].*)\)' -NewRegexp 'Das.save({ items: $1 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.getList\(([^{].*),(.*)\)' -NewRegexp 'Das.getList({ endpoint: $1, options: $2 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.getList\(([^{].*)\)' -NewRegexp 'Das.getList({ endpoint: $1 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.getListByPost\(([^{].*)\)' -NewRegexp 'Das.getListByPost({ event: $1 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp '\.getListItemsByPost<((?!TOut).*)>\(([^{].*)\)' -NewRegexp '.getListItemsByPost<$1>({ event: $2 })' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'Das.get\(([^{].*)\).pipe' -NewRegexp 'Das.get({ id: $1 }).pipe' -Include *.ts


ReplaceInProject -Source $Source -OldRegexp '<bia-table([^-]([^>]|\n)*)\[canEdit\]' -NewRegexp '<bia-table$1[canClickRow]' -Include *.html
ReplaceInProject -Source $Source -OldRegexp '<bia-table([^-]([^>]|\n)*)\(edit\)' -NewRegexp '<bia-table$1(clickRow)' -Include *.html




ReplaceInProject -Source $Source -OldRegexp '/domains/app-settings/' -NewRegexp '/domains/bia-domains/app-settings/' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp '/domains/language-option/' -NewRegexp '/domains/bia-domains/language-option/' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp '/domains/notification/' -NewRegexp '/domains/bia-domains/notification/' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp '/domains/notification-type-option/' -NewRegexp '/domains/bia-domains/notification-type-option/' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp '/domains/role-option/' -NewRegexp '/domains/bia-domains/role-option/' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp '/domains/team/' -NewRegexp '/domains/bia-domains/team/' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp '/domains/user-option/' -NewRegexp '/domains/bia-domains/user-option/' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp '/features/background-task/' -NewRegexp '/features/bia-features/background-task/' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp '/features/notifications/' -NewRegexp '/features/bia-features/notifications/' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp '/features/users/' -NewRegexp '/features/bia-features/users/' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp '/features/users-from-directory/' -NewRegexp '/features/bia-features/users-from-directory/' -Include *.ts



ReplaceInProject -Source $Source -OldRegexp 'import \{ loadAllUserOptions \}' -NewRegexp 'import { DomainUserOptionsActions }' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp 'loadAllUserOptions' -NewRegexp 'DomainUserOptionsActions.loadAll' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'import \{ loadAllRoleOptions \}' -NewRegexp 'import { DomainRoleOptionsActions }' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp 'loadAllRoleOptions' -NewRegexp 'DomainRoleOptionsActions.loadAll' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'import \{ loadAllNotificationTypeOptions \}' -NewRegexp 'import { DomainNotificationTypeOptionsActions }' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp 'loadAllNotificationTypeOptions' -NewRegexp 'DomainNotificationTypeOptionsActions.loadAll' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'import \{ loadAllLanguageOptions \}' -NewRegexp 'import { DomainLanguageOptionsActions }' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp 'loadAllLanguageOptions' -NewRegexp 'DomainLanguageOptionsActions.loadAll' -Include *.ts

ReplaceInProject -Source $Source -OldRegexp 'import \{ loadDomainAppSettings \}' -NewRegexp 'import { DomainAppSettingsActions }' -Include *.ts
ReplaceInProject -Source $Source -OldRegexp 'loadDomainAppSettings' -NewRegexp 'DomainAppSettingsActions.loadAll' -Include *.ts

cd $Source/DotNet
dotnet restore --no-cache


Write-Host "Finish"
pause
