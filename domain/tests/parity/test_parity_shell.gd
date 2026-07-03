extends GutTest
## Suíte de PARIDADE (PAR-07) — casca de navegação e áudio. Characterization dos autoloads
## `scene_router` e `audio_bus` (BR-038/041/053..055). Roda headless.

# ================================================================ PAR-07 · navegação serializada

func test_par07_one_scene_change_at_a_time() -> void:
	var RouterScript = load("res://autoload/scene_router.gd")
	var r: Node = RouterScript.new()
	add_child_autofree(r)
	assert_true(r._prepare_navigation(RouterScript.Context.BOARD, {}), "1ª transição prossegue")
	assert_false(r._prepare_navigation(RouterScript.Context.MENU, {}), "2º pedido ignorado durante a transição")


func test_par07_back_by_context() -> void:
	var RouterScript = load("res://autoload/scene_router.gd")
	var r: Node = RouterScript.new()
	add_child_autofree(r)
	assert_eq(r.back_target(RouterScript.Context.MENU), RouterScript.QUIT, "Menu → sair")
	assert_eq(r.back_target(RouterScript.Context.LEVEL_SELECT), RouterScript.Context.MENU, "Seleção → Menu")
	assert_eq(r.back_target(RouterScript.Context.BOARD), RouterScript.Context.LEVEL_SELECT, "Fase → Seleção")


# ================================================================ PAR-07 · gate central de áudio

func test_par07_effects_mute_gate_by_construction() -> void:
	# @idempotencia: efeitos mutados → nenhum one-shot toca, por construção do bus.
	var BusScript = load("res://autoload/audio_bus.gd")
	var b: Node = BusScript.new()
	add_child_autofree(b)
	b.set_effects_muted(true)
	var ei := AudioServer.get_bus_index(BusScript.BUS_EFFECTS)
	assert_true(AudioServer.is_bus_mute(ei), "bus de efeitos mudo silencia todo o vocabulário")
	AudioServer.set_bus_mute(ei, false)  # limpa p/ não vazar


func test_par07_music_unmute_is_immediate() -> void:
	var BusScript = load("res://autoload/audio_bus.gd")
	var b: Node = BusScript.new()
	add_child_autofree(b)
	b.set_music_muted(false)
	var mi := AudioServer.get_bus_index(BusScript.BUS_MUSIC)
	assert_false(AudioServer.is_bus_mute(mi), "religar a música retoma imediatamente")


# ================================================================ PAR-07 · toggle persiste

func test_par07_audio_toggle_persists() -> void:
	var StoreScript = load("res://autoload/progression_store.gd")
	var s: Node = StoreScript.new()
	s.save_path = "user://test_par_audio.cfg"
	s.progress = PlayerProgress.new()
	s.set_audio_pref("music", true)
	var s2: Node = StoreScript.new()
	s2.save_path = s.save_path
	s2.progress = PlayerProgress.new()
	s2.load_progress()
	assert_true(s2.progress.audio_prefs["music_muted"], "toggle de música persiste após reinício")
	s.free()
	s2.free()
	if FileAccess.file_exists("user://test_par_audio.cfg"):
		DirAccess.remove_absolute("user://test_par_audio.cfg")
