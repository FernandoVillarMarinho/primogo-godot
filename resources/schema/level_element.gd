class_name LevelElement
extends Resource
## Um elemento posicionado no tabuleiro de uma fase.
## `elements[0]` do LevelResource é sempre o jogador (BR).
##
## Fronteira de serialização — o domínio puro (domain/board, Tarefa 05) consome
## os valores, não este tipo Resource diretamente.

@export var x: int = 0
@export var y: int = 0             ## y cresce para baixo (BR-017)
@export var primo_index: int = 0  ## índice na janela da cadeia (legado: Element.primo)
