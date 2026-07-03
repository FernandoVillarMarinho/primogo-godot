extends Node
## Autoload: progression_store — estado vivo da progressão + persistência.
##
## Única porta de escrita do save `user://save.cfg` (ConfigFile). Embrulha
## `domain/economy` (energia global, estrelas, recordes, desbloqueios).
## Fronteira: nenhuma cena de `features/` escreve o save diretamente — tudo passa por aqui.
##
## Origem no legado: singletons DontDestroyOnLoad + PlayerPrefs espalhado (BR-032, AD-04).
## STUB (Tarefa 01). Implementação completa na Tarefa 07.

const SAVE_PATH := "user://save.cfg"
const SAVE_VERSION := 1

func _ready() -> void:
	# TODO Tarefa 07: carregar/validar o save, instanciar domain/economy,
	# expor consultas (energia, estrelas, estado de fase) e a escrita atômica no fim de fase.
	pass
