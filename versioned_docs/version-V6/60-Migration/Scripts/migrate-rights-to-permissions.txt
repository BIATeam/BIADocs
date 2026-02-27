# Rights to Permissions Migration Script
# This script migrates Rights constants to PermissionId enums using a hybrid approach
#
# PURPOSE:
#   Automate the migration from the legacy Rights system (static classes with string constants)
#   to the new Permissions system (enum-based PermissionId) in BIA Framework projects.
#
# OPERATIONS PERFORMED:
#   1. Extract all constants from Rights.cs file
#      - Parses all static classes and their const string definitions
#      - Extracts: class name, constant name, and constant value
#      - Excludes Announcement* classes (handled separately in manual dictionary)
#
#   2. Generate PermissionId enum entries
#      - Adds new enum values to PermissionId.cs before the "// BIAToolKit - Begin Permissions" marker
#      - Skips duplicates if they already exist
#      - Uses constant values directly as enum names (e.g., "Site_List_Access")
#
#   3. Replace all Rights and BiaRights references
#      - Scans all .cs files (excluding bin/obj folders and Rights.cs itself)
#      - Rights.ClassName.ConstName -> nameof(PermissionId.Value) - automatic from Rights.cs parsing
#      - BiaRights patterns -> nameof(BiaPermissionId.Value) - from manual dictionary $biaRightsReplacements
#      - Rights.Announcements.* -> nameof(BiaPermissionId.Announcement_*) - from manual dictionary
#      - String literals (e.g., "Background_Task_Admin") - from manual dictionary
#      - Suffixes patterns -> BiaPermissionSuffixes.* - from manual dictionary
#
#   4. Delete the Rights.cs file
#
# MANUAL DICTIONARY:
#   The $biaRightsReplacements hashtable must be filled with:
#   - All BiaRights.* references (BIA Framework rights)
#   - All Rights.Announcements.* references (project announcements using BiaPermissionId)
#   - String literal permissions that need replacement
#   - Permission suffixes mappings to BiaPermissionSuffixes
#
# EXAMPLES OF TRANSFORMATIONS:
#   Automatic (from Rights.cs parsing):
#     Rights.Sites.ListAccess -> nameof(PermissionId.Site_List_Access)
#   
#   Manual (from $biaRightsReplacements dictionary):
#     BiaRights.Home.Access -> nameof(BiaPermissionId.Home_Access)
#     Rights.Announcements.Read -> nameof(BiaPermissionId.Announcement_Read)
#     "Background_Task_Admin" -> nameof(BiaPermissionId.Background_Task_Admin)
#     BiaRights.Members.ListAccessSuffix -> BiaPermissionSuffixes.Members.ListAccessSuffix
#
# USAGE:
#   1. Fill the $biaRightsReplacements dictionary with your BiaRights, Announcements, and special patterns
#   2. Update $BackendPath variable below
#   3. Run: .\migrate-rights-to-permissions.ps1

# Define the backend path (adapt according to your project)
$BackendPath = "C:\sources\BIADemo\DotNet"

# Manual dictionary for BiaRights replacements
# Format: "BiaRights.ClassName.ConstName" = "nameof(BiaPermissionId.Value)"
$biaRightsReplacements = @{
    # BIA Framework Rights replacements
    # TODO: Fill this dictionary with your BiaRights constants
    # Example:
    # "BiaRights.Home.Access" = "nameof(BiaPermissionId.Home_Access)"

    "BiaRights.Roles.Options" = "nameof(BiaPermissionId.Roles_Options)"
    "BiaRights.Roles.ListForCurrentUser" = "nameof(BiaPermissionId.Roles_List_For_Current_User)"
    "BiaRights.Permissions.Options" = "nameof(BiaPermissionId.Permissions_Options)"
    "BiaRights.LdapDomains.List" = "nameof(BiaPermissionId.LdapDomains_List)"
    "BiaRights.Languages.Options" = "nameof(BiaPermissionId.Languages_Options)"
    "BiaRights.ProfileImage.Get" = "nameof(BiaPermissionId.ProfileImage_Get)"
    "BiaRights.Home.Access" = "nameof(BiaPermissionId.Home_Access)"
    "BiaRights.Logs.Create" = "nameof(BiaPermissionId.Logs_Create)"
    "BiaRights.Teams.Options" = "nameof(BiaPermissionId.Team_Options)"
    "BiaRights.Teams.AccessAll" = "nameof(BiaPermissionId.Team_Access_All)"
    "BiaRights.Teams.ListAccess" = "nameof(BiaPermissionId.Team_List_Access)"
    "BiaRights.Teams.SetDefaultTeam" = "nameof(BiaPermissionId.Team_Set_Default_Team)"
    "BiaRights.Teams.SetDefaultRoles" = "nameof(BiaPermissionId.Team_Set_Default_Roles)"
    "BiaRights.Users.Options" = "nameof(BiaPermissionId.User_Options)"
    "BiaRights.Users.ListAccess" = "nameof(BiaPermissionId.User_List_Access)"
    "BiaRights.Users.List" = "nameof(BiaPermissionId.User_List)"
    "BiaRights.Users.ListAD" = "nameof(BiaPermissionId.User_List_AD)"
    "BiaRights.Users.Read" = "nameof(BiaPermissionId.User_Read)"
    "BiaRights.Users.Add" = "nameof(BiaPermissionId.User_Add)"
    "BiaRights.Users.Delete" = "nameof(BiaPermissionId.User_Delete)"
    "BiaRights.Users.Save" = "nameof(BiaPermissionId.User_Save)"
    "BiaRights.Users.Sync" = "nameof(BiaPermissionId.User_Sync)"
    "BiaRights.Users.UpdateRoles" = "nameof(BiaPermissionId.User_Update_Roles)"
    "BiaRights.Views.Read" = "nameof(BiaPermissionId.View_Read)"
    "BiaRights.Views.List" = "nameof(BiaPermissionId.View_List)"
    "BiaRights.Views.AddUserView" = "nameof(BiaPermissionId.View_Add_UserView)"
    "BiaRights.Views.UpdateUserView" = "nameof(BiaPermissionId.View_Update_UserView)"
    "BiaRights.Views.DeleteUserView" = "nameof(BiaPermissionId.View_Delete_UserView)"
    "BiaRights.Views.DeleteTeamView" = "nameof(BiaPermissionId.View_Delete_TeamView)"
    "BiaRights.Views.SetDefaultUserView" = "nameof(BiaPermissionId.View_Set_Default_UserView)"
    "BiaRights.Notifications.ListAccess" = "nameof(BiaPermissionId.Notification_List_Access)"
    "BiaRights.Notifications.Read" = "nameof(BiaPermissionId.Notification_Read)"
    "BiaRights.Notifications.Create" = "nameof(BiaPermissionId.Notification_Create)"
    "BiaRights.Notifications.Update" = "nameof(BiaPermissionId.Notification_Update)"
    "BiaRights.Notifications.Delete" = "nameof(BiaPermissionId.Notification_Delete)"
    "BiaRights.NotificationTypes.Options" = "nameof(BiaPermissionId.NotificationType_Options)"
    "BiaRights.Impersonation.ConnectionRights" = "nameof(BiaPermissionId.Impersonation_Connection_Rights)"
    "Rights.Announcements.ListAccess" = "nameof(BiaPermissionId.Announcement_List_Access)"
    "Rights.Announcements.Create" = "nameof(BiaPermissionId.Announcement_Create)"
    "Rights.Announcements.Read" = "nameof(BiaPermissionId.Announcement_Read)"
    "Rights.Announcements.Update" = "nameof(BiaPermissionId.Announcement_Update)"
    "Rights.Announcements.Delete" = "nameof(BiaPermissionId.Announcement_Delete)"
    "Rights.Announcements.Save" = "nameof(BiaPermissionId.Announcement_Save)"
    "Rights.AnnouncementTypeOptions.Options" = "nameof(BiaPermissionId.AnnouncementType_Options)"
    "`"Background_Task_Admin`"" = "nameof(BiaPermissionId.Background_Task_Admin)"
    "`"Background_Task_Read_Only`"" = "nameof(BiaPermissionId.Background_Task_Read_Only)"

    # Suffixes
    "BiaRights.Members.ListAccessSuffix" = "BiaPermissionSuffixes.Members.ListAccessSuffix"
    "BiaRights.Members.CreateSuffix" = "BiaPermissionSuffixes.Members.CreateSuffix"
    "BiaRights.Members.ReadSuffix" = "BiaPermissionSuffixes.Members.ReadSuffix"
    "BiaRights.Members.UpdateSuffix" = "BiaPermissionSuffixes.Members.UpdateSuffix"
    "BiaRights.Members.DeleteSuffix" = "BiaPermissionSuffixes.Members.DeleteSuffix"
    "BiaRights.Members.SaveSuffix" = "BiaPermissionSuffixes.Members.SaveSuffix"
    "BiaRights.Views.AddTeamViewSuffix" = "BiaPermissionSuffixes.TeamViews.AddTeamViewSuffix"
    "BiaRights.Views.UpdateTeamViewSuffix" = "BiaPermissionSuffixes.TeamViews.UpdateTeamViewSuffix"
    "BiaRights.Views.SetDefaultTeamViewSuffix" = "BiaPermissionSuffixes.TeamViews.SetDefaultTeamViewSuffix"
    "BiaRights.Views.AssignToTeamSuffix" = "BiaPermissionSuffixes.TeamViews.AssignToTeamSuffix"
}

Write-Host "=== Starting Rights to Permissions Migration ===" -ForegroundColor Cyan
Write-Host "Backend path: $BackendPath" -ForegroundColor Gray

# Function to extract constants from Rights.cs file
function Get-RightsConstants {
    param([string]$RightsFilePath)
    
    Write-Host "`nStep 1: Extracting constants from Rights.cs..." -ForegroundColor Yellow
    
    if (-not (Test-Path $RightsFilePath)) {
        Write-Host "ERROR: Rights.cs file not found at: $RightsFilePath" -ForegroundColor Red
        return @{Constants = @(); Replacements = @{}}
    }
    
    $content = Get-Content $RightsFilePath -Raw
    $constants = @()
    $replacements = @{}
    
    # Pattern to extract all static classes
    $classPattern = 'public\s+static\s+class\s+(\w+)\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}'
    $classMatches = [regex]::Matches($content, $classPattern)
    
    foreach ($classMatch in $classMatches) {
        $className = $classMatch.Groups[1].Value
        $classBody = $classMatch.Groups[2].Value

        # Special case: Announcements class uses BiaPermissionId
        if ($className -like "Announcement*") {
            continue;
        }
        
        # Pattern to extract all const string in this class
        $constPattern = 'public\s+const\s+string\s+(\w+)\s*=\s*"([^"]+)"'
        $constMatches = [regex]::Matches($classBody, $constPattern)
        
        foreach ($constMatch in $constMatches) {
            $constName = $constMatch.Groups[1].Value
            $constValue = $constMatch.Groups[2].Value
            
            # Store constant info for PermissionId.cs generation
            $constants += [PSCustomObject]@{
                ClassName = $className
                ConstName = $constName
                Value = $constValue
                FullPath = "Rights.$className.$constName"
            }
            
            # Build the replacement mapping using the actual constant value
            $oldReference = "Rights.$className.$constName"
            
            $newReference = "nameof(PermissionId.$constValue)"
            $replacements[$oldReference] = $newReference
            
            Write-Host "  Found: $oldReference = `"$constValue`" -> $newReference" -ForegroundColor Gray
        }
    }
    
    Write-Host "Total of $($constants.Count) constants extracted." -ForegroundColor Green
    return @{Constants = $constants; Replacements = $replacements}
}

# Function to convert a description with underscores to readable text
function Get-Description {
    param([string]$Value)
    
    return $Value -replace '_', ' '
}

# Function to generate the enum name based on the value
function Get-EnumName {
    param([string]$Value)
    
    # The enum name is simply the value (already in correct format)
    return $Value
}

# Function to add permissions to PermissionId.cs
function Add-PermissionsToEnum {
    param(
        [string]$PermissionIdPath,
        [array]$Constants
    )
    
    Write-Host "`nStep 2: Adding permissions to PermissionId.cs..." -ForegroundColor Yellow
    
    if (-not (Test-Path $PermissionIdPath)) {
        Write-Host "ERROR: PermissionId.cs file not found at: $PermissionIdPath" -ForegroundColor Red
        return $false
    }
    
    $content = Get-Content $PermissionIdPath -Raw
    
    # Search for the marker line
    $marker = "// BIAToolKit - Begin PermissionId"
    if ($content -notmatch [regex]::Escape($marker)) {
        Write-Host "ERROR: The marker '$marker' was not found in PermissionId.cs" -ForegroundColor Red
        return $false
    }
    
    # Extract existing enums
    $existingEnumsPattern = '^\s*(\w+),?\s*$'
    $lines = $content -split "`r?`n"
    $existingEnums = @()
    
    foreach ($line in $lines) {
        if ($line -match $existingEnumsPattern -and $line -notmatch '^\s*//' -and $line -notmatch 'enum|{|}') {
            $enumName = $matches[1].Trim(',').Trim()
            if ($enumName) {
                $existingEnums += $enumName
            }
        }
    }
    
    Write-Host "  Existing enums detected: $($existingEnums.Count)" -ForegroundColor Gray
    
    # Filter constants to exclude existing enums and remove duplicates by value
    $uniqueConstants = @()
    $seenValues = @{}
    
    foreach ($const in $Constants) {
        $enumName = Get-EnumName -Value $const.Value

        # Skip if already exists in PermissionId.cs
        if ($existingEnums -contains $enumName) {
            continue
        }
        
        # Skip if we've already seen this value (handle duplicates in Rights.cs)
        if ($seenValues.ContainsKey($enumName)) {
            Write-Host "  Duplicate value detected: $enumName (from $($const.ClassName).$($const.ConstName), already added from $($seenValues[$enumName]))" -ForegroundColor Yellow
            continue
        }
        
        $seenValues[$enumName] = "$($const.ClassName).$($const.ConstName)"
        $uniqueConstants += $const
    }
    
    Write-Host "  Unique new permissions to add: $($uniqueConstants.Count)" -ForegroundColor Gray
    
    # Build new entries
    $newEntries = @()
    $addedCount = 0
    
    foreach ($const in $uniqueConstants) {

        $enumName = Get-EnumName -Value $const.Value
        $description = Get-Description -Value $const.Value
        
        # Build the entry with proper indentation (8 spaces)
        # Don't add leading blank line for the first entry
        if ($addedCount -eq 0) {
            $entry = "/// <summary>`r`n"
            $entry += "        /// $description.`r`n"
            $entry += "        /// </summary>`r`n"
            $entry += "        $enumName,`r`n"
        }
        else {
            $entry = "`r`n        /// <summary>`r`n"
            $entry += "        /// $description.`r`n"
            $entry += "        /// </summary>`r`n"
            $entry += "        $enumName,`r`n"
        }
        
        $newEntries += $entry
        $addedCount++
        Write-Host "  Added: $enumName" -ForegroundColor Green
    }
    
    if ($newEntries.Count -eq 0) {
        Write-Host "No new permissions to add." -ForegroundColor Gray
        return $true
    }
    
    # Insert new entries before the marker
    $markerIndex = $content.IndexOf($marker)
    $beforeMarker = $content.Substring(0, $markerIndex)
    $afterMarker = $content.Substring($markerIndex)
    
    $newContent = $beforeMarker + ($newEntries -join "") + "`r`n        " + $afterMarker
    
    Set-Content -Path $PermissionIdPath -Value $newContent -NoNewline -Encoding UTF8
    
    $skippedCount = $Constants.Count - $addedCount
    Write-Host "  $addedCount new permissions added, $skippedCount skipped." -ForegroundColor Green
    return $true
}

# Function to replace references in all files
function Replace-RightsReferences {
    param(
        [string]$BackendPath,
        [hashtable]$Replacements
    )
    
    Write-Host "`nStep 3: Replacing Rights constant references..." -ForegroundColor Yellow
    
    # Merge BiaRights replacements with Rights replacements
    $allReplacements = $Replacements.Clone()
    foreach ($key in $biaRightsReplacements.Keys) {
        $allReplacements[$key] = $biaRightsReplacements[$key]
    }
    
    # Find all .cs files (except Rights.cs and in bin/obj)
    $csFiles = Get-ChildItem -Path $BackendPath -Filter "*.cs" -Recurse | 
        Where-Object { 
            $_.FullName -notmatch '\\bin\\' -and 
            $_.FullName -notmatch '\\obj\\' -and
            $_.Name -ne 'Rights.cs'
        }
    
    Write-Host "  Analyzing $($csFiles.Count) .cs files..." -ForegroundColor Gray
    Write-Host "  Processing $($allReplacements.Count) replacement patterns ($($Replacements.Count) from Rights.cs + $($biaRightsReplacements.Count) from BiaRights)..." -ForegroundColor Gray
    
    # Sort replacements by key length (descending) to avoid partial matches
    # e.g., replace "Rights.Users.ListAccess" before "Rights.Users.List"
    $sortedReplacements = $allReplacements.GetEnumerator() | Sort-Object { $_.Key.Length } -Descending
    
    $totalReplacements = 0
    $filesModified = 0
    
    foreach ($file in $csFiles) {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        $fileReplacements = 0
        
        # Apply all replacements from the merged dictionary (sorted by length)
        foreach ($replacement in $sortedReplacements) {
            $oldRef = $replacement.Key
            $newRef = $replacement.Value
            $escapedOldRef = [regex]::Escape($oldRef)
            
            if ($content -match $escapedOldRef) {
                $content = $content -replace $escapedOldRef, $newRef
                $matchCount = ([regex]::Matches($originalContent, $escapedOldRef)).Count
                $fileReplacements += $matchCount
            }
        }
        
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
            $totalReplacements += $fileReplacements
            $filesModified++
            Write-Host "  Modified: $($file.Name) ($fileReplacements replacements)" -ForegroundColor Green
        }
    }
    
    Write-Host "  Total: $totalReplacements replacements in $filesModified files." -ForegroundColor Green
    return $totalReplacements
}

# Main function
function Start-Migration {
    param([string]$BackendPath)
    
    # Verify that the path exists
    if (-not (Test-Path $BackendPath)) {
        Write-Host "ERROR: The path $BackendPath does not exist." -ForegroundColor Red
        return
    }
    
    # Search for Rights.cs file
    $rightsFile = Get-ChildItem -Path $BackendPath -Filter "Rights.cs" -Recurse | 
        Where-Object { $_.FullName -notmatch '\\bin\\' -and $_.FullName -notmatch '\\obj\\' } |
        Select-Object -First 1
    
    if (-not $rightsFile) {
        Write-Host "ERROR: Rights.cs file not found in $BackendPath" -ForegroundColor Red
        return
    }
    
    Write-Host "Rights.cs file found: $($rightsFile.FullName)" -ForegroundColor Gray
    
    # Search for PermissionId.cs file
    $permissionIdFile = Get-ChildItem -Path $BackendPath -Filter "PermissionId.cs" -Recurse | 
        Where-Object { $_.FullName -notmatch '\\bin\\' -and $_.FullName -notmatch '\\obj\\' } |
        Select-Object -First 1
    
    if (-not $permissionIdFile) {
        Write-Host "ERROR: PermissionId.cs file not found in $BackendPath" -ForegroundColor Red
        return
    }
    
    Write-Host "PermissionId.cs file found: $($permissionIdFile.FullName)" -ForegroundColor Gray
    
    # Step 1: Extract constants and build replacement dictionary
    $result = Get-RightsConstants -RightsFilePath $rightsFile.FullName
    $constants = $result.Constants
    $replacements = $result.Replacements
    
    if ($constants.Count -eq 0) {
        Write-Host "ERROR: No constants found in Rights.cs" -ForegroundColor Red
        return
    }
    
    # Step 2: Add permissions
    $success = Add-PermissionsToEnum -PermissionIdPath $permissionIdFile.FullName -Constants $constants
    
    if (-not $success) {
        Write-Host "ERROR while adding permissions. Stopping script." -ForegroundColor Red
        return
    }
    
    # Step 3: Replace references using the replacement dictionary
    $replacementCount = Replace-RightsReferences -BackendPath $BackendPath -Replacements $replacements
    
    # Step 4: Delete Rights.cs
    Write-Host "`nStep 4: Deleting Rights.cs file..." -ForegroundColor Yellow
    
    try {
        Remove-Item -Path $rightsFile.FullName -Force
        Write-Host "  Rights.cs file successfully deleted." -ForegroundColor Green
    }
    catch {
        Write-Host "  ERROR while deleting Rights.cs: $_" -ForegroundColor Red
    }
    
    Write-Host "`n=== Migration completed successfully ===" -ForegroundColor Cyan
    Write-Host "Summary:" -ForegroundColor White
    Write-Host "  - $($constants.Count) constants migrated" -ForegroundColor White
    Write-Host "  - $replacementCount references updated" -ForegroundColor White
    Write-Host "  - Rights.cs deleted" -ForegroundColor White
}

# Execution
Start-Migration -BackendPath $BackendPath