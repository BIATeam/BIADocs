function Move-MigrationFiles {
  param (
    [string]$SourceDir,
    [string]$DestDir,
    [string]$OldNamespace,
    [string]$NewNamespace,
    [string]$Label
  )

  if (-not (Test-Path $SourceDir)) {
    Write-Host "`n$Label : source folder not found, skipping: $SourceDir" -ForegroundColor Yellow
    return
  }

  $files = Get-ChildItem -Path $SourceDir -File -Filter "*.cs"
  if ($files.Count -eq 0) {
    Write-Host "`n$Label : no .cs files found in source folder, skipping." -ForegroundColor Yellow
    Write-Host "Deleting old migration folder: $($SourceDir.FullName)" -ForegroundColor Cyan
    Remove-Item -Path $SourceDir -Recurse -Force
    Write-Host "Old migration folder deleted." -ForegroundColor Green
    Write-Host "$Label : done." -ForegroundColor Green
    return
  }

  Write-Host "`n$Label : moving $($files.Count) .cs file(s) from '$SourceDir' to '$DestDir'" -ForegroundColor Cyan

  if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
  }

  foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $updatedContent = $content -replace [regex]::Escape($OldNamespace), $NewNamespace
    $destFile = Join-Path $DestDir $file.Name
    [System.IO.File]::WriteAllText($destFile, $updatedContent, [System.Text.Encoding]::UTF8)
    Remove-Item -Path $file.FullName -Force
    Write-Host "  Moved & updated namespace: $($file.Name)" -ForegroundColor Green
  }

  Write-Host "Deleting old migration folder: $SourceDir" -ForegroundColor Cyan
  Remove-Item -Path $SourceDir -Recurse -Force
  Write-Host "Old migration folder deleted." -ForegroundColor Green

  Write-Host "$Label : done." -ForegroundColor Green
}

function Move-EfMigrationsToProjects {
  param (
    [string]$SourceBackEnd
  )

  # Find the Infrastructure.Data project folder (direct child whose name ends with .Infrastructure.Data)
  $infraDataFolder = Get-ChildItem -Path $SourceBackEnd -Directory |
    Where-Object { $_.Name -match '\.Infrastructure\.Data$' } |
    Select-Object -First 1

  if ($null -eq $infraDataFolder) {
    Write-Host "Infrastructure.Data project folder not found in $SourceBackEnd" -ForegroundColor Red
    return
  }

  $infraDataProjectName = $infraDataFolder.Name
  Write-Host "Found Infrastructure.Data project: $infraDataProjectName" -ForegroundColor Cyan

  # SQL Server: Migrations -> *.Migrations.SqlServer\Migrations
	Move-MigrationFiles `
	  -SourceDir    (Join-Path $infraDataFolder.FullName "Migrations") `
	  -DestDir      (Join-Path "$($infraDataFolder.FullName).Migrations.SqlServer" "Migrations") `
	  -OldNamespace "$infraDataProjectName.Migrations" `
	  -NewNamespace "$infraDataProjectName.Migrations.SqlServer.Migrations" `
	  -Label        "SqlServer"

  # PostgreSQL: MigrationsPostGreSql -> *.Migrations.PostgreSQL\Migrations
  Move-MigrationFiles `
    -SourceDir    (Join-Path $infraDataFolder.FullName "MigrationsPostGreSql") `
    -DestDir      (Join-Path "$($infraDataFolder.FullName).Migrations.PostgreSQL" "Migrations") `
    -OldNamespace "$infraDataProjectName.MigrationsPostGreSql" `
    -NewNamespace "$infraDataProjectName.Migrations.PostgreSQL.Migrations" `
    -Label        "PostgreSQL"
}

Move-EfMigrationsToProjects -SourceBackEnd "C:\sources\Project\DotNet"
