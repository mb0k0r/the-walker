# Arquitectura

El proyecto usa Godot 4.6.3, GDScript, renderer GL Compatibility y una resolución interna de 640×360 con escalado entero.

## Capas

- `game/world`: navegación, interacción y graybox del Mercado del Umbral.
- `game/encounters`: definiciones, estado del encuentro y resolución de desenlaces.
- `game/state`: sesión global y guardado local versionado.
- `game/ui`: menú, globos de diálogo, decisiones, diario y códice.
- `game/localization`: selector ES/EN y catálogo generado.
- `dialogues`: contenido de Dialogue Manager, separado de reglas y efectos.
- `tests`: pruebas GUT de estado, outcomes, guardado y localización.

El guardado principal vive en `user://autosave.json`. Incluye versión de esquema, escena lógica, posición, idioma, flags, estadísticas, desenlace, diario y códice. Un JSON inválido no bloquea el menú: muestra una advertencia y permite Nueva partida.

El contenido fuente aprobado se conserva en `docs/APATE_CONTENT_SOURCE.txt`. `scripts/extract_localization.ps1` genera el CSV bilingüe y las pruebas verifican que todos los IDs usados por los diálogos existan en ambos idiomas.
