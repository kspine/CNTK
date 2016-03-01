# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

# WARNING. This will run in Microsoft Internal Environment ONLY
# Generating CNTK Binary drops in Jenkins environment

# Command line parameters
# Verbose is automatically enabled
[CmdletBinding()]
param
(
	# Supposed to be taken from Jenkins BUILD_CONFIGURATION
	[string]$buildConfig,
	
	# Supposed to be taken from Jenkins TARGET_CONFIGURATION
	[string]$targetConfig,
	
	# File share path. Supposed to have sub-folders corresponding to $targetConfig
	[string]$sharePath
)

# Set to Stop on Error
$ErrorActionPreference = 'Stop'

# Manual parameters check rather than using [Parameter(Mandatory=$True)]
# to avoid the risk of interactive prompts inside a Jenkins job
$usage = " parameter is missing. Usage example: make_binary_drop_windows.ps1 -buildConfig Release -targetConfig gpu -sharePath \\server\share"
If (-not $buildConfig) {Throw "buildConfig" + $usage}
If (-not $targetConfig) {Throw "targetConfig" + $usage}
If (-not $sharePath) {Throw "sharePath" + $usage}

# Set Verbose mode
if ($verbose)
{
	 $VerbosePreference = "continue"
}

Write-Verbose "Making binary drops..."

# If not a Release build quit
If ($buildConfig -ne "Release")
{
	Write-Verbose "Not a release build. No binary drops generation"
	Exit
}

# Set Paths
$basePath = "BinaryDrops\ToZip"
$baseDropPath = Join-Path $basePath -ChildPath cntk
$zipFile = "BinaryDrops\BinaryDrops.zip"
$buildPath = "x64\Release"
If ($targetConfig -eq "CPU")
{
	$buildPath = "x64\Release_CpuOnly"
}
$sharePath = Join-Path $sharePath -ChildPath $targetConfig


# Make binary drop folder
New-Item -Path $baseDropPath -ItemType "directory"

# Copy build binaries
Write-Verbose "Copying build binaries ..."
Copy-Item $buildPath -Recurse -Destination $baseDropPath\cntk

# Clean unwanted items
If (Test-Path $baseDropPath\cntk\UnitTests) {Remove-Item $baseDropPath\cntk\UnitTests -Recurse}
Remove-Item $baseDropPath\cntk\*test*.exe
Remove-Item $baseDropPath\cntk\*.pdb
Remove-Item $baseDropPath\cntk\*.lib
Remove-Item $baseDropPath\cntk\*.exp
Remove-Item $baseDropPath\cntk\*.metagen

# Copy Examples
Write-Verbose "Copying Examples ..."
Copy-Item Examples -Recurse -Destination $baseDropPath\Examples

# Copy all items from the share
# For whatever reason Copy-Item in the line below does not work
# Copy-Item $sharePath"\*"  -Recurse -Destination $baseDropPath
# Copying with Robocopy
Write-Verbose "Copying dependencies and other files from Remote Share ..."
robocopy $sharePath $baseDropPath /s /e

Write-Verbose "Making ZIP and cleaning up..."

# Make ZIP file
$source = Join-Path $PWD.Path -ChildPath $basePath
$destination = Join-Path $PWD.Path -ChildPath $zipFile
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::CreateFromDirectory($source, $destination)

# Remove ZIP sources
If (Test-Path $basePath) {Remove-Item $basePath -Recurse}
