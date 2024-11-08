# Set the root folder of the .NET solution
$solutionFolder = "C:\sources\Azure.DevOps.Safran\DigitalManufacturing-CheckVersion\eSuitePortal\DotNet"

# Recursively get all .cs files in the solution folder
$csFiles = Get-ChildItem -Path $solutionFolder -Recurse -Include *.cs

foreach ($file in $csFiles) {
    Write-Host "Processing file: $($file.FullName)"
    $content = Get-Content -Path $file.FullName -Raw

    # Remove the implementation of IFilteredServiceBase<>
	$content = [regex]::Replace($content, "
		(\s*:\s*IFilteredServiceBase<[^>]+>\s*(,|\s|\{)?) |   # Case where it's the only or first interface
		(\s*,\s*IFilteredServiceBase<[^>]+>)                 # Case where it's not the first interface
	", {
		if ($args[1]) {
			# If it's the first or only interface
			if ($args[1].Trim().StartsWith(":") -and $args[1].Trim().EndsWith(",")) {
				return " : " # If followed by other interfaces, keep the colon
			} elseif ($args[1].Trim().StartsWith(":")) {
				return "" # If no other interfaces, remove the colon entirely
			}
		} elseif ($args[2]) {
			# If it's not the first interface, simply remove the ", IFilteredServiceBase<...>"
			return ""
		}
	}, 'IgnorePatternWhitespace')

    # Replace FilteredServiceBase with OperationalDomainServiceBase (only full words)
	$content = [regex]::Replace($content, "\bFilteredServiceBase\b", "OperationalDomainServiceBase")

	# Replace AppServiceBase with DomainServiceBase (only full words)
	$content = [regex]::Replace($content, "\bAppServiceBase\b", "DomainServiceBase")

	if ($file.FullName -match "\.Presentation\.|\.Application\.") {
		# Replace IClientForHubRepository with IClientForHubService (only full words)
		$content = [regex]::Replace($content, "\bIClientForHubRepository\b", "IClientForHubService")
	}

    # Remove the specific block of code
    $content = [regex]::Replace($content, "(?ms)#if\s+UseHubForClientInContact\s+using\s+BIA\.Net\.Core\.Domain\.RepoContract;\s+#endif", "")

    # Write the updated content back to the file
    Set-Content -Path $file.FullName -Value $content
}

Write-Host "Transformation complete."
