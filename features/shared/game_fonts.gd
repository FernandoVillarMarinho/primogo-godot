class_name GameFonts
## Bitmap fonts originais (DEV-002), convertidas dos .fnt do legado
## (`Assets/Resources/Fonts*`, métricas exatas — nada inferido). Só têm os glifos 0–9 e
## espaço: texto/ícones ("Nível", ⚡, /) continuam fora delas, por sprite ou fonte do tema.
## Mapa de uso fiel ao legado:
##  - PLAYER  = Fonts2/font       → dígitos do tile do jogador (GameManager 790/854)
##  - TILE    = Fonts2/OrangeFont → tiles congelados e balão (GameManager 934, BalloonController 32)
##  - NUMBERS = Fonts/numbers     → contador de energia da seleção (LevelSelect 62)
##  - SELECT  = Fonts/font_Select → números das caixas da seleção (LevelSelect 78)

const PLAYER := preload("res://assets/images/fonts2/font.fnt")
const TILE := preload("res://assets/images/fonts2/orangefont.fnt")
const NUMBERS := preload("res://assets/images/fonts/numbers.fnt")
const SELECT := preload("res://assets/images/fonts/font_select.fnt")
