# El Caminante

Vertical slice narrativo creado con Godot 4.6.3.

## Ejecutar

```powershell
& "C:\Users\Marcelo\Downloads\Godot_v4.6.3-stable_win64.exe" --path .
```

## Controles

- WASD o flechas: mover
- E o Enter: interactuar
- J: diario
- C: códice
- Esc: pausar o cerrar paneles

El contenido de `encounter.apate_market` es provisional y está aislado en `game/content/` y `dialogues/`.

La hoja de animación jugable normalizada está en
`assets/generated/processed/wayfarer_sheet_v2.png`. Puede regenerarse desde la
fuente con `scripts/normalize_wayfarer_sheet.gd`.

## Verificación rápida

```powershell
.\scripts\check_project.ps1
```

El comando importa el proyecto y ejecuta las pruebas unitarias y de integración.
Para comprobar también la exportación Web:

```powershell
.\scripts\check_project.ps1 -Full
```

Las pruebas recorren automáticamente los cuatro desenlaces de Apatē, el teclado,
el movimiento, los diálogos consecutivos y el guardado/carga. GitHub ejecuta la
misma suite antes de publicar la versión Web.
