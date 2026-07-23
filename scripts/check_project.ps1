param(
	[string]$Godot = "C:\Users\Marcelo\Downloads\Godot_v4.6.3-stable_win64.exe"
)

$ErrorActionPreference = "Stop"
$Project = (Resolve-Path "$PSScriptRoot\..").Path

if (-not (Test-Path -LiteralPath $Godot)) {
	throw "Godot executable not found at $Godot"
}

& powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\extract_localization.ps1"
if ($LASTEXITCODE -ne 0) {
	exit $LASTEXITCODE
}

$import = Start-Process -FilePath $Godot -ArgumentList @('--headless', '--editor', '--path', $Project, '--quit') -WindowStyle Hidden -Wait -PassThru
if ($import.ExitCode -ne 0) {
	exit $import.ExitCode
}

$tests = Start-Process -FilePath $Godot -ArgumentList @('--headless', '--path', $Project, '-s', 'res://addons/gut/gut_cmdln.gd', '-gdir=res://tests', '-ginclude_subdirs', '-gdisable_colors', '-gjunit_xml_file=res://test-results.xml', '-gexit') -WindowStyle Hidden -Wait -PassThru
exit $tests.ExitCode
