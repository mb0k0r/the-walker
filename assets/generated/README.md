# Primera tanda visual generada

Generada con la herramienta integrada ImageGen usando `assets/concepts/market_direction_v1.png` únicamente como referencia de estilo y paleta.

## Archivos

- `source/market_tileset_source_v1.png`: atlas fuente de suelos, muros, arcos, túneles y puestos. Requiere normalización manual a tiles de 32 px antes de convertirse en TileSet.
- `processed/wayfarer_sheet_v1.png`: hoja transparente 4×4; filas abajo, izquierda, derecha y arriba. Ya se utiliza provisionalmente en el juego.
- `processed/npcs_sheet_v1.png`: hoja transparente de Neria, Mara y Apatē. ImageGen produjo siete frames por personaje, no ocho; se usa el primer frame de cada fila y se conserva como fuente para completar animaciones.
- `processed/market_props_v1.png`: hoja transparente 6×4. Incluye letreros, espejos, provisiones, telas, cajas, barriles, lámparas, mesas y viajeros. Sus celdas son de 256×256 y varios props ya se utilizan en el graybox.
- `source/*_chroma.png`: originales con fondo magenta, conservados para futuras correcciones de borde.

Las hojas transparentes fueron procesadas con `remove_chroma_key.py`, usando muestreo automático del borde, matte suave y despill. Se validó canal RGBA, esquina transparente y cobertura visible.

## Prompts resumidos

- Tiles: atlas cenital tres cuartos, modular, sin personajes ni texto, paleta ocre/umber/oliva/pizarra/carmesí.
- Caminante: grilla 4×4, cuatro direcciones y cuatro frames por dirección sobre fondo `#ff00ff`.
- NPC: tres filas para Neria, Mara y Apatē, reposo y gesto sobre fondo `#ff00ff`.
- Props: grilla 6×4 con veinticuatro elementos aislados sobre fondo `#ff00ff`.

Todos los prompts exigieron pixel art nítido, escala consistente, ausencia de armas, logos, marcas de agua, etiquetas y texto incrustado.
