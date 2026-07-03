class_name LevelElement
extends Resource
## Um elemento posicionado no tabuleiro de uma fase.
## `elements[0]` do LevelResource é sempre o jogador (Primogo).
##
## `primo` é o VALOR do primo (legado: Element.primo, usado direto em GameManager.CreateTile),
## não um índice. Confirmado na extração da Fase 0.

@export var x: int = 0
@export var y: int = 0     ## y cresce para baixo (BR-017)
@export var primo: int = 0 ## valor do primo (legado: Element.primo)
