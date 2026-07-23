param(
	[string]$Source = "$PSScriptRoot\..\docs\APATE_CONTENT_SOURCE.txt",
	[string]$Output = "$PSScriptRoot\..\game\localization\translations.csv"
)

$ErrorActionPreference = "Stop"
$lines = Get-Content -LiteralPath $Source -Encoding utf8
$entries = [ordered]@{}
$currentKey = $null
$currentLanguage = $null
$es = [System.Collections.Generic.List[string]]::new()
$en = [System.Collections.Generic.List[string]]::new()
$boundaryPattern = '^(#|PLAYER:?$|APATE:?$|NARRATOR:?$|OUTCOME:?$|RESULTADO:?$|RESULTADO:|INTERACTABLE ID:|PROMPT KEY:|ID:|Al finalizar:|Al inspeccionarlo:|Si |PASSAGE REFS:|Después:|Esta última|La diferencia|OUTCOME SI|Cambios visuales)'

function Save-Entry {
	if (-not $script:currentKey) {
		return
	}

	$esText = (($script:es -join "`n").Trim())
	$enText = (($script:en -join "`n").Trim())
	if ($esText -and $enText) {
		$script:entries[$script:currentKey] = [pscustomobject]@{ es = $esText; en = $enText }
	}
}

foreach ($line in $lines) {
	if ($line -match '^(?:PROMPT )?KEY:\s*([A-Z0-9_]+)\s*$') {
		Save-Entry
		$currentKey = $Matches[1]
		$currentLanguage = $null
		$es = [System.Collections.Generic.List[string]]::new()
		$en = [System.Collections.Generic.List[string]]::new()
		continue
	}

	if (-not $currentKey) {
		continue
	}

	if ($line -match '^ES:\s?(.*)$') {
		$currentLanguage = 'es'
		if ($Matches[1]) {
			$es.Add($Matches[1])
		}
		continue
	}

	if ($line -match '^EN:\s?(.*)$') {
		$currentLanguage = 'en'
		if ($Matches[1]) {
			$en.Add($Matches[1])
		}
		continue
	}

	if ($currentLanguage -eq 'en' -and $line -match $boundaryPattern) {
		$currentLanguage = $null
		continue
	}

	if ($currentLanguage -eq 'es') {
		$es.Add($line)
	} elseif ($currentLanguage -eq 'en') {
		$en.Add($line)
	}
}

Save-Entry

$manual = [ordered]@{
	CHARACTER_WAYFARER = @('Caminante', 'Wayfarer')
	CHARACTER_NARRATOR = @('Narrador', 'Narrator')
	UI_GAME_TITLE = @('El Caminante', 'The Wayfarer')
	UI_NEW_GAME = @('Nueva partida', 'New Game')
	UI_CONTINUE = @('Continuar', 'Continue')
	UI_ENCOUNTER_LAB = @('Laboratorio de encuentros', 'Encounter Lab')
	UI_SETTINGS = @('Configuración', 'Settings')
	UI_LANGUAGE = @('Idioma', 'Language')
	UI_SPANISH = @('Español', 'Spanish')
	UI_ENGLISH = @('Inglés', 'English')
	UI_MUSIC = @('Música', 'Music')
	UI_SFX = @('Sonidos', 'Sound Effects')
	UI_BACK = @('Volver', 'Back')
	UI_QUIT_TO_MENU = @('Volver al menú', 'Return to Menu')
	UI_RESET_SLICE = @('Reiniciar encuentro', 'Restart Encounter')
	UI_ERASE_SAVE = @('Borrar partida', 'Delete Save')
	UI_JOURNAL = @('Diario', 'Journal')
	UI_CODEX = @('Códice', 'Codex')
	UI_CLOSE = @('Cerrar', 'Close')
	UI_INTERACT = @('[E] Interactuar', '[E] Interact')
	UI_SIGN = @('Letrero oriental', 'Eastern road sign')
	UI_TALK_NERIA = @('Hablar con Neria', 'Talk to Neria')
	UI_TALK_MARA = @('Hablar con Mara', 'Talk to Mara')
	UI_TALK_APATE = @('Hablar con Apatē', 'Talk to Apatē')
	UI_NOT_READY = @('Reúne al menos dos pistas antes de confrontar a Apatē.', 'Gather at least two clues before confronting Apatē.')
	UI_CLUE_FOUND = @('Pista añadida al diario', 'Clue added to journal')
	UI_SAVED = @('Partida guardada', 'Game saved')
	UI_EMPTY_JOURNAL = @('Todavía no hay entradas.', 'There are no entries yet.')
	UI_EMPTY_CODEX = @('Todavía no hay entradas.', 'There are no entries yet.')
	UI_ALLEGORY_ACCEPT = @('Comprendo', 'I understand')
	UI_LOCATION_MARKET = @('Mercado del Umbral', 'Threshold Market')
	UI_OBJECTIVE_EXPLORE = @('Investiga el letrero y habla con los habitantes.', 'Inspect the sign and speak with the townsfolk.')
	UI_OBJECTIVE_CONFRONT = @('Confronta la propuesta de Apatē.', "Confront Apatē’s offer.")
	UI_COMPLETED = @('Encuentro completado', 'Encounter completed')
	UI_CORRUPT_SAVE = @('La partida guardada no pudo leerse. Puedes comenzar una nueva.', 'The saved game could not be read. You can start a new one.')
	UI_PAUSED = @('Pausa', 'Paused')
	UI_RESUME = @('Continuar', 'Resume')
	UI_HINT_JOURNAL = @('J: Diario   C: Códice   Esc: Pausa', 'J: Journal   C: Codex   Esc: Pause')
	UI_REFS = @('Referencias: Hebreos 3:13 · Colosenses 2:8 · Mateo 13:22', 'References: Hebrews 3:13 · Colossians 2:8 · Matthew 13:22')
}

foreach ($key in $manual.Keys) {
	$entries[$key] = [pscustomobject]@{ es = $manual[$key][0]; en = $manual[$key][1] }
}

function Quote-Csv([string]$value) {
	return '"' + $value.Replace('"', '""') + '"'
}

$outputDirectory = Split-Path -Parent $Output
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$csv = [System.Collections.Generic.List[string]]::new()
$csv.Add('key,es,en')
foreach ($key in $entries.Keys) {
	$entry = $entries[$key]
	$csv.Add("$(Quote-Csv $key),$(Quote-Csv $entry.es),$(Quote-Csv $entry.en)")
}

Set-Content -LiteralPath $Output -Value $csv -Encoding UTF8
Write-Output "Generated $($entries.Count) localized entries at $Output"
