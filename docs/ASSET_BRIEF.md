# Recursos por producir

La imagen `assets/concepts/market_direction_v1.png` es una propuesta de tono, no un spritesheet listo para el juego. Se generó como concept board pixel art con mercado medieval al crepúsculo, luz ocre, sombras azul pizarra y cuatro estudios humanos: Caminante, Neria, Mara y Apatē.

## Primera tanda visual

- Tileset PNG con transparencia: tiles de 32×32; suelo, muro, sendero, túnel, puestos y bordes. Preferible atlas de 512×512.
- Caminante: hoja direccional de 4 direcciones, reposo y caminar; frames de 32×48 o 48×48.
- Neria, Mara y Apatē: reposo de 4 frames y un gesto de 4 frames; misma caja que el Caminante.
- Props: letrero falso/corregido, espejos, provisiones, telas, cajas, viajeros y lámparas; grilla de 32 px.
- Opcional tras probar espacio: retratos 64×64 con fondo transparente para los cuatro personajes.

Todos los PNG deben usar nearest-neighbor, paleta consistente, contorno legible a 640×360, vista cenital tres cuartos y sin texto incrustado.

## Primera tanda de audio

- Ambiente de mercado en loop, 60–90 s, discreto y sin voces inteligibles.
- Pasos sobre piedra/tierra: 6 variaciones cortas.
- Interacción, pista encontrada, decisión y autosave: un sonido breve por evento.
- Motivo del Mercado y motivo de Apatē: loops sobrios de 60–90 s, sin melodía triunfal.

Formatos preferidos: OGG para loops largos, WAV para efectos cortos. Mantener música y efectos en entregas separadas para los buses `Music` y `SFX`.

## Prompt de la propuesta v1

Concept board pixel art 16:9 para un mercado medieval de peregrinación llamado Mercado del Umbral, al crepúsculo; portón de piedra, puestos, camino central, letrero hacia un túnel sospechoso, provisiones, espejos, viajeros y lámparas. Estudios separados del Caminante encapuchado, Neria observadora, Mara cansada y sincera, y Apatē como mercader humano carismático con una inquietud sutil. Paleta ocre/umber/oliva con sombras azul pizarra y acentos carmesí; tono adulto, contemplativo, alegoría cristiana, sin combate, interfaz, texto ni marcas de agua.
