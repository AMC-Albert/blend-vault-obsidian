# Setup script for pnpm workspace
param(
	[switch]$Install,
	[switch]$Clean,
	[switch]$Status
)

$workspaceDir = $PSScriptRoot
$pluginsDir = Split-Path $workspaceDir -Parent

function Write-ColorOutput {
	param([string]$Message, [string]$Color = "White")
	Write-Host $Message -ForegroundColor $Color
}

function Get-DirectorySize {
	param([string]$Path)
	if (Test-Path $Path) {
		return (Get-ChildItem -Path $Path -Recurse -File | Measure-Object -Property Length -Sum).Sum
	}
	return 0
}

if ($Status) {
	Write-ColorOutput "=== WORKSPACE STATUS ===" "Cyan"
	
	# Check if pnpm is installed
	try {
		$pnpmVersion = & pnpm --version 2>$null
		Write-ColorOutput "checkmark pnpm version: $pnpmVersion" "Green"
	} catch {
		Write-ColorOutput "X pnpm not found. Install with: npm install -g pnpm" "Red"
		exit 1
	}
	# Check workspace setup
	$workspaceFile = Join-Path $workspaceDir "pnpm-workspace.yaml"
	if (Test-Path $workspaceFile) {
		Write-ColorOutput "checkmark pnpm workspace configured" "Green"
	} else {
		Write-ColorOutput "X pnpm workspace not configured" "Red"
	}
	
	# Check individual plugin dependencies
	$plugins = Get-ChildItem -Path $pluginsDir -Directory | Where-Object { 
		$_.Name -notmatch "^(shared-|node_modules|\.)" -and
		(Test-Path (Join-Path $_.FullName "package.json"))
	}
	
	$totalSize = 0
	foreach ($plugin in $plugins) {
		$nodeModulesPath = Join-Path $plugin.FullName "node_modules"
		if (Test-Path $nodeModulesPath) {
			$size = Get-DirectorySize $nodeModulesPath
			$totalSize += $size
			$sizeMB = [math]::Round($size / 1MB, 2)
			Write-ColorOutput "  $($plugin.Name): $sizeMB MB (individual)" "Yellow"
		} else {
			Write-ColorOutput "  $($plugin.Name): No node_modules" "White"
		}
	}
	# Check shared node_modules
	$sharedNodeModules = Join-Path $workspaceDir "node_modules"
	if (Test-Path $sharedNodeModules) {
		$sharedSize = Get-DirectorySize $sharedNodeModules
		$sharedSizeMB = [math]::Round($sharedSize / 1MB, 2)
		Write-ColorOutput "Shared node_modules: $sharedSizeMB MB" "Green"
	} else {
		Write-ColorOutput "No shared node_modules found" "White"
	}
	
	if ($totalSize -gt 0) {
		$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
		Write-ColorOutput "Total individual: $totalSizeMB MB" "Red"
	}
	
	exit
}

if ($Clean) {
	Write-ColorOutput "=== CLEANING WORKSPACE ===" "Cyan"
	
	# Remove all node_modules
	Get-ChildItem -Path $pluginsDir -Recurse -Directory -Name "node_modules" | ForEach-Object {
		$path = Join-Path $pluginsDir $_
		Write-ColorOutput "Removing: $_" "Yellow"
		Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
	}
	# Remove pnpm lock file
	$lockFile = Join-Path $workspaceDir "pnpm-lock.yaml"
	if (Test-Path $lockFile) {
		Remove-Item $lockFile -Force
	}
	
	Write-ColorOutput "Cleanup completed!" "Green"
	exit
}

Write-ColorOutput "=== SETTING UP PNPM WORKSPACE ===" "Cyan"

# Check if pnpm is installed
try {
	$pnpmVersion = & pnpm --version 2>$null
	Write-ColorOutput "checkmark pnpm version: $pnpmVersion" "Green"
} catch {
	Write-ColorOutput "X pnpm not found. Installing pnpm..." "Yellow"
	npm install -g pnpm
}

# Discover plugins automatically by finding directories with package.json
$plugins = Get-ChildItem -Path $pluginsDir -Directory | Where-Object { 
	$_.Name -notmatch "^(shared-|node_modules|\.)" -and
	(Test-Path (Join-Path $_.FullName "package.json"))
} | Sort-Object Name

Write-ColorOutput "Discovered $($plugins.Count) plugins:" "Yellow"
foreach ($plugin in $plugins) {
	Write-ColorOutput "  - $($plugin.Name)" "White"
}

# Create pnpm-workspace.yaml content dynamically
$packageList = $plugins | ForEach-Object { "  - '../$($_.Name)'" }
$workspaceContent = @"
packages:
$($packageList -join "`n")
"@

$workspaceFile = Join-Path $workspaceDir "pnpm-workspace.yaml"
Set-Content -Path $workspaceFile -Value $workspaceContent
Write-ColorOutput "checkmark Created pnpm-workspace.yaml" "Green"

if ($Install) {
	Write-ColorOutput "Installing dependencies with pnpm..." "Yellow"
	Set-Location $workspaceDir
	& pnpm install
	
	Write-ColorOutput "=== INSTALLATION COMPLETE ===" "Cyan"
	# Show space savings
	$sharedNodeModules = Join-Path $workspaceDir "node_modules"
	if (Test-Path $sharedNodeModules) {
		$sharedSize = Get-DirectorySize $sharedNodeModules
		$sharedSizeMB = [math]::Round($sharedSize / 1MB, 2)
		
		# Calculate what the space would be without workspace (estimate)
		$pluginCount = $plugins.Count
		$estimatedIndividualSizeMB = $sharedSizeMB * $pluginCount
		$actualSavingsMB = $estimatedIndividualSizeMB - $sharedSizeMB
		$savingsPercent = [math]::Round(($actualSavingsMB / $estimatedIndividualSizeMB) * 100, 1)
		
		Write-ColorOutput "Shared dependencies size: $sharedSizeMB MB" "Green"
		Write-ColorOutput "Estimated savings: $actualSavingsMB MB (~$savingsPercent% reduction)" "Green"
		Write-ColorOutput "Without workspace: ~$estimatedIndividualSizeMB MB across $pluginCount plugins" "White"
	}
}
