# Modelo de contenido

`EncounterDefinition` describe identidad, pistas, fases y referencias. `EncounterState` guarda lo reunido y las elecciones de interpretación y aplicación. `OutcomeResolver` resuelve una sola de las cuatro salidas, en prioridad fija:

1. Verdad comprendida y aplicada.
2. Verdad comprendida pero no aplicada.
3. Interpretación incompleta con aplicación bien intencionada.
4. Atajo aceptado o engaño no discernido.

`GameSession` aplica los efectos, desbloquea diario/códice y crea el diccionario serializable. Las escenas solo presentan el mundo; las líneas narrativas viven en `dialogues/apate.dialogue` y las traducciones en `game/localization/translations.csv`.

## Flujo de Apatē

Aviso alegórico → introducción → letrero → Neria/Mara en cualquier orden → Apatē → interpretación → aplicación → desenlace → exploración posterior.

El laboratorio permite saltar directamente a Apatē con pistas precargadas para repetir las combinaciones sin recorrer el prólogo.
