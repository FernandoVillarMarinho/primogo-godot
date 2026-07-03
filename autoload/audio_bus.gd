extends Node
## Autoload: audio_bus — gate central de som.
##
## `AudioStreamPlayer` nativo com buses `Music`/`Effects` (AD-07/RES-010).
## Mute central = mute do bus; música persistente entre cenas; fachada de efeitos/stingers.
## Converte a convenção invertida dos toggles do legado (0 = ligado) na leitura do save.
##
## Origem no legado: SoundManager + FMOD* + Switch + OnLoad — fundidos (BR-053..055).
## STUB (Tarefa 01). Implementação completa na Tarefa 08.

func _ready() -> void:
	# TODO Tarefa 08: garantir buses Music/Effects, tocar música persistente,
	# expor play_effect()/play_stinger() e set_music_muted()/set_effects_muted().
	pass
