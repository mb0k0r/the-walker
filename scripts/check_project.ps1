param(
	[string]$Godot = "",
	[switch]$Full
)

$ErrorActionPreference = "Stop"
$Project = (Resolve-Path "$PSScriptRoot\..").Path
$StartedAt = Get-Date

if (-not $Godot) {
	$candidates = @(
		$env:GODOT_EXE,
		"C:\Users\Marcelo\Downloads\Godot_v4.6.3-stable_win64_console.exe",
		"C:\Users\Marcelo\Downloads\Godot_v4.6.3-stable_win64.exe"
	) | Where-Object { $_ }
	$Godot = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

if (-not $Godot -or -not (Test-Path -LiteralPath $Godot)) {
	throw "No se encontró Godot 4.6.3. Usa -Godot con la ruta del ejecutable."
}

function Invoke-GodotStep {
	param(
		[string]$Name,
		[string[]]$CommandArguments
	)

	Write-Host "`n== $Name ==" -ForegroundColor Cyan
	& $Godot @CommandArguments
	if ($LASTEXITCODE -ne 0) {
		throw "$Name falló con código $LASTEXITCODE."
	}
}

Write-Host "== Localización ==" -ForegroundColor Cyan
& "$PSScriptRoot\extract_localization.ps1"
if (-not $?) {
	throw "La generación de localización falló."
}

Invoke-GodotStep "Importación y validación" @(
	'--headless',
	'--editor',
	'--path', $Project,
	'--quit'
)

Invoke-GodotStep "Pruebas automáticas" @(
	'--headless',
	'--path', $Project,
	'-s', 'res://addons/gut/gut_cmdln.gd',
	'-gdir=res://tests',
	'-ginclude_subdirs',
	'-gdisable_colors',
	'-gjunit_xml_file=res://test-results.xml',
	'-gexit'
)

if ($Full) {
	Invoke-GodotStep "Exportación Web" @(
		'--headless',
		'--path', $Project,
		'--export-release', 'Web',
		(Join-Path $Project 'build\web\index.html')
	)
	if (-not (Test-Path -LiteralPath (Join-Path $Project 'build\web\index.html'))) {
		throw "La exportación Web no generó index.html."
	}
}

$Elapsed = (Get-Date) - $StartedAt
Write-Host "`nVerificación completada en $([math]::Round($Elapsed.TotalSeconds, 1)) s." -ForegroundColor Green
