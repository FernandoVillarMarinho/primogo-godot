extends Node
## Autoload: scene_router — navegação serializada.
##
## Troca de cena com fade (BR-041) e "Voltar" resolvido por contexto (BR-040).
## A identidade da fase viaja com os dados carregados — nunca por static global
## (elimina a fragilidade `LevelSelect.currentLevel` do legado).
##
## Origem no legado: SceneController + máquina do Fade — fundidos.
## STUB (Tarefa 01). Implementação completa na Tarefa 09.

func _ready() -> void:
	# TODO Tarefa 09: goto_scene(path, payload) com fade in/out; pilha de contexto para "Voltar".
	pass
