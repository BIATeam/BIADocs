# Rights to Permissions Migration Script
# This script automatically migrates Rights constants to PermissionId enums
#
# PURPOSE:
#   Automate the migration from the legacy Rights system (static classes with string constants)
#   to the new Permissions system (enum-based PermissionId) in BIA Framework projects.
#
# OPERATIONS PERFORMED:
#   1. Extract all constants from Rights.cs file
#      - Parses all static classes and their const string definitions
#      - Extracts: class name, constant name, and constant value
#
#   2. Generate PermissionId enum entries
#      - Adds new enum values to PermissionId.cs before the "// BIAToolKit - Begin Permissions" marker
#      - Skips duplicates if they already exist
#      - Format: enum value name = constant value from Rights.cs
#
#   3. Replace all Rights references with nameof(PermissionId.xxx)
#      - Scans all .cs files (excluding bin/obj folders and Rights.cs itself)
#      - Replaces: Rights.ClassName.ConstName -> nameof(PermissionId.xxx)
#      - Also handles: BiaRights.ClassName.ConstName -> nameof(BiaPermissionId.xxx)
#
#   4. Delete the Rights.cs file
#
# NAMING CONVENTIONS:
#   - Class names are singularized: "Sites" -> "Site", "Countries" -> "Country"
#   - PascalCase is converted to Snake_Case: "ListAccess" -> "List_Access"
#   - Special case for Options: "PlaneOptions.Options" -> "Plane_Options" (keeps plural in base name)
#   - Non-Options with Options const: "Airports.Options" -> "Airport_Options"
#
# EXAMPLES OF TRANSFORMATIONS:
#   Rights.Sites.ListAccess          -> nameof(PermissionId.Site_List_Access)
#   Rights.PlaneOptions.Options      -> nameof(PermissionId.Plane_Options)
#   Rights.Airports.Options          -> nameof(PermissionId.Airport_Options)
#   BiaRights.Home.Access            -> nameof(BiaPermissionId.Home_Access)
#
# USAGE:
#   Update $BackendPath variable below, then run: .\migrate-rights-to-permissions.ps1

# Define the backend path (adapt according to your project)
$BackendPath = "C:\sources\Azure\SCardNG\DotNet"

Write-Host "=== Starting Rights to Permissions Migration ===" -ForegroundColor Cyan
Write-Host "Backend path: $BackendPath" -ForegroundColor Gray

# Function to singularize a plural English word
function Get-SingularForm {
    param([string]$Word)
    
    # Common irregular plurals
    $irregulars = @{
        'People' = 'Person'
        'Men' = 'Man'
        'Women' = 'Woman'
        'Children' = 'Child'
        'Teeth' = 'Tooth'
        'Feet' = 'Foot'
        'Mice' = 'Mouse'
        'Geese' = 'Goose'
    }
    
    if ($irregulars.ContainsKey($Word)) {
        return $irregulars[$Word]
    }
    
    # Words ending in 'ies' -> 'y'
    if ($Word -match '(.+)ies$') {
        return $matches[1] + 'y'
    }
    
    # Words ending in 'xes' -> 'x'
    if ($Word -match '(.+)xes$') {
        return $matches[1] + 'x'
    }
    
    # Words ending in 'ses' -> 'se' (e.g., Cases -> Case, not Cas)
    if ($Word -match '(.+[^s])ses$') {
        return $matches[1] + 'se'
    }
    
    # Words ending in double 'sses' -> 'ss' (e.g., Glasses -> Glass)
    if ($Word -match '(.+s)ses$') {
        return $matches[1] + 's'
    }
    
    # Words ending in 'shes' -> 'sh'
    if ($Word -match '(.+)shes$') {
        return $matches[1] + 'sh'
    }
    
    # Words ending in 'ches' -> 'ch'
    if ($Word -match '(.+)ches$') {
        return $matches[1] + 'ch'
    }
    
    # Words ending in 'zes' -> 'z'
    if ($Word -match '(.+[^z])zes$') {
        return $matches[1] + 'z'
    }
    
    # Common words ending in 's' (but not 'ss')
    if ($Word -match '(.+[^s])s$') {
        return $matches[1]
    }
    
    # If no rule applies, return as is
    return $Word
}

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
            
            # Special case: Announcements class uses BiaPermissionId
            if ($className -like "Announcement*") {
                $newReference = "nameof(BiaPermissionId.$constValue)"
            }
            else {
                $newReference = "nameof(PermissionId.$constValue)"
            }
            
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
    $marker = "// BIAToolKit - Begin Permissions"
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
        
        # Skip if Announcement permission (handled separately with BiaPermissionId)
        if($enumName -like "Announcement*") {
            continue
        }

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

# Function to convert PascalCase to Snake_Case with uppercase
function Convert-ToSnakeCase {
    param([string]$Text)
    
    # Add an underscore before each uppercase letter (except the first)
    $result = $Text -creplace '(?<!^)([A-Z])', '_$1'
    return $result
}

# Function to generate the permission name (for enum)
function Get-PermissionName {
    param(
        [string]$ClassName,
        [string]$ConstName
    )
    
    # Special case: if class name ends with "Options" and const is "Options"
    if ($ClassName -match '(.+)Options$' -and $ConstName -eq "Options") {
        # Extract the base name (e.g., "PlaneOptions" -> "Plane")
        $baseName = $matches[1]
        # Keep the plural "Options" and add "_Options"
        return "PermissionId.$baseName`Options_Options"
    }
    
    # Singularize the class name but keep its PascalCase
    $singularClassName = Get-SingularForm -Word $ClassName
    
    # If constName is "Options" (but class doesn't end with Options)
    if ($ConstName -eq "Options") {
        return "PermissionId.$singularClassName`_Options"
    }
    
    # Otherwise, combine PascalCase singular class name with Snake_Case constant
    $constSnake = Convert-ToSnakeCase -Text $ConstName
    
    return "PermissionId.$singularClassName`_$constSnake"
}

# Function to generate the complete nameof expression for replacements
function Get-PermissionNameofExpression {
    param(
        [string]$ClassName,
        [string]$ConstName,
        [bool]$UseBiaPermissionId = $false
    )
    
    $permissionName = Get-PermissionName -ClassName $ClassName -ConstName $ConstName
    
    # Replace PermissionId with BiaPermissionId if requested
    if ($UseBiaPermissionId) {
        $permissionName = $permissionName -replace 'PermissionId', 'BiaPermissionId'
    }
    
    return "nameof($permissionName)"
}

# Function to replace references in all files
function Replace-RightsReferences {
    param(
        [string]$BackendPath,
        [hashtable]$Replacements
    )
    
    Write-Host "`nStep 3: Replacing Rights constant references..." -ForegroundColor Yellow
    
    # Find all .cs files (except Rights.cs and in bin/obj)
    $csFiles = Get-ChildItem -Path $BackendPath -Filter "*.cs" -Recurse | 
        Where-Object { 
            $_.FullName -notmatch '\\bin\\' -and 
            $_.FullName -notmatch '\\obj\\' -and
            $_.Name -ne 'Rights.cs'
        }
    
    Write-Host "  Analyzing $($csFiles.Count) .cs files..." -ForegroundColor Gray
    Write-Host "  Processing $($Replacements.Count) replacement patterns..." -ForegroundColor Gray
    
    # Sort replacements by key length (descending) to avoid partial matches
    # e.g., replace "Rights.Users.ListAccess" before "Rights.Users.List"
    $sortedReplacements = $Replacements.GetEnumerator() | Sort-Object { $_.Key.Length } -Descending
    
    $totalReplacements = 0
    $filesModified = 0
    
    foreach ($file in $csFiles) {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        $fileReplacements = 0
        
        # Apply all replacements from the dictionary (sorted by length)
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
        
        # Also handle BiaRights -> BiaPermissionId
        $biaPattern = 'BiaRights\.(\w+)\.(\w+)'
        $biaMatches = [regex]::Matches($content, $biaPattern)
        
        if ($biaMatches.Count -gt 0) {
            # Build unique BiaRights replacements to avoid double counting
            $biaReplacements = @{}
            foreach ($match in $biaMatches) {
                $className = $match.Groups[1].Value
                $constName = $match.Groups[2].Value
                
                # Skip patterns ending with "Suffix" (e.g., BiaRights.XXXSuffix)
                if ($constName -eq "Suffix") {
                    Write-Host "  Skipped BiaRights pattern ending with Suffix: BiaRights.$className.$constName" -ForegroundColor DarkGray
                    continue
                }
                
                $oldBiaRef = "BiaRights.$className.$constName"
                
                # For BiaRights, we need to construct the permission name
                # since we don't have the actual constant value from Rights.cs
                $singularClassName = Get-SingularForm -Word $className
                $constSnake = Convert-ToSnakeCase -Text $constName
                $permissionName = "$singularClassName`_$constSnake"
                
                $newBiaRef = "nameof(BiaPermissionId.$permissionName)"
                
                if (-not $biaReplacements.ContainsKey($oldBiaRef)) {
                    $biaReplacements[$oldBiaRef] = $newBiaRef
                }
            }
            
            # Apply BiaRights replacements
            foreach ($oldBiaRef in $biaReplacements.Keys) {
                $newBiaRef = $biaReplacements[$oldBiaRef]
                $escapedOldRef = [regex]::Escape($oldBiaRef)
                
                if ($content -match $escapedOldRef) {
                    $content = $content -replace $escapedOldRef, $newBiaRef
                    $matchCount = ([regex]::Matches($originalContent, $escapedOldRef)).Count
                    $fileReplacements += $matchCount
                }
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