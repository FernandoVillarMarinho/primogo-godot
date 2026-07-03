class_name OptionsOverlay
extends OverlayBase
## Feature main_menu — overlay de opções (S-03). Estende OverlayBase (dim @0,5, trava
## anti-clique-duplo de 1s, sinais que substituem o static optionsActive — BR-043).
## Toggles de música/efeitos independentes e persistentes (BR-038): escrevem no
## ProgressionStore (única porta do save, AD-04), que reemite p/ o AudioBus aplicar o
## mute — fonte única, sem checagem espalhada.

signal credits_requested()


func _ready() -> void:
	super()   # OverlayBase: monta o dim e esconde
	_build_panel()


func _build_panel() -> void:
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_theme_constant_override("separation", 16)
	add_child(panel)

	var music := CheckButton.new()
	music.text = "MÚSICA"
	music.button_pressed = not AudioBus.is_music_muted()   # ligado = não-mudo
	music.toggled.connect(func(on: bool) -> void: ProgressionStore.set_audio_pref("music", not on))
	panel.add_child(music)

	var effects := CheckButton.new()
	effects.text = "EFEITOS"
	effects.button_pressed = not AudioBus.is_effects_muted()
	effects.toggled.connect(func(on: bool) -> void: ProgressionStore.set_audio_pref("effects", not on))
	panel.add_child(effects)

	var credits := Button.new()
	credits.text = "CRÉDITOS"
	credits.pressed.connect(func() -> void: credits_requested.emit())
	panel.add_child(credits)

	var close_btn := Button.new()
	close_btn.text = "FECHAR"
	close_btn.pressed.connect(_on_close_pressed)
	panel.add_child(close_btn)


## Fechar ignora cliques durante a trava de 1s pós-abertura (BR-043).
func _on_close_pressed() -> void:
	if not is_input_locked():
		close()
