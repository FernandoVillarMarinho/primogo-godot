extends GutTest
## Tarefa 07 — autoload progression_store: persistência round-trip do save,
## primeiro jogo, mapeamento de estados e emissão de sinais.

const StoreScript = preload("res://autoload/progression_store.gd")
const TMP := "user://test_prog.cfg"

var TH := {"three_star": 5, "two_star": 8, "max": 12}
var _stores: Array = []


func _fresh_store() -> Node:
	var s := StoreScript.new()
	s.save_path = TMP
	s.progress = PlayerProgress.new()  # evita depender do _ready (fora da árvore)
	_stores.append(s)
	return s


func after_each() -> void:
	for s in _stores:
		s.free()
	_stores.clear()
	for p in [TMP, TMP + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func test_first_game_defaults_when_no_file() -> void:
	var s := _fresh_store()
	s.load_progress()  # sem arquivo → defaults + grava inicial
	assert_eq(s.energy(), 50, "primeiro jogo começa com 50")
	assert_true(FileAccess.file_exists(TMP), "grava o save inicial")


func test_win_persists_and_reloads() -> void:
	var s1 := _fresh_store()
	s1.progress.global_energy = 10
	s1.register_win(1, 1, 10, TH)  # +5 → 15, record 10, WON, desbloqueia (1,2)

	var s2 := _fresh_store()
	s2.load_progress()  # relê do disco
	assert_eq(s2.energy(), 15, "energia persistida")
	assert_eq(s2.progress.record_of(1, 1), 10, "recorde persistido")
	assert_eq(s2.unlock_of(1, 1), PlayerProgress.UnlockState.WON, "estado WON persistido")
	assert_eq(s2.unlock_of(1, 2), PlayerProgress.UnlockState.UNLOCKED, "desbloqueio persistido")


func test_state_string_mapping_round_trip() -> void:
	var s := _fresh_store()
	s.progress.unlocks[Vector2i(2, 3)] = PlayerProgress.UnlockState.UNLOCKED
	s.save()
	var s2 := _fresh_store()
	s2.load_progress()
	assert_eq(s2.unlock_of(2, 3), PlayerProgress.UnlockState.UNLOCKED, "unlocked ↔ 'unlocked'")


func test_audio_and_flags_persist() -> void:
	var s := _fresh_store()
	s.set_audio_pref("music", true)
	s.mark_tutorial_done("t2")
	var s2 := _fresh_store()
	s2.load_progress()
	assert_true(s2.progress.audio_prefs["music_muted"], "mute de música persistido")
	assert_true(s2.progress.tutorial_flags["t2_done"], "flag de tutorial persistida")


func test_emits_signals() -> void:
	var s := _fresh_store()
	watch_signals(s)
	s.progress.global_energy = 10
	s.register_win(1, 1, 10, TH)
	assert_signal_emitted(s, "level_won")
	assert_signal_emitted(s, "energy_changed")
	assert_signal_emitted(s, "next_unlocked")


func test_atomic_save_leaves_no_tmp() -> void:
	var s := _fresh_store()
	s.save()
	assert_false(FileAccess.file_exists(TMP + ".tmp"), "o tmp é renomeado, não sobra")
	assert_true(FileAccess.file_exists(TMP))


# Tarefa 15 — cheat de desenvolvimento guardado (AD-06/BR-029): item do gate de cutover.
func test_dev_cheat_guarded_and_non_persistent() -> void:
	var s := _fresh_store()
	var events: Array = s.dev_unlock_all(3)
	if OS.is_debug_build():
		# Em debug (ambiente de teste), o cheat funciona mas NÃO persiste (cheat de sessão).
		assert_eq(events[0]["type"], "session_unlocked", "debug: desbloqueia a sessão")
		assert_false(FileAccess.file_exists(TMP), "cheat não persiste (nada gravado)")
	else:
		# Em release, é no-op por construção (inerte em produção, L-11).
		assert_true(events.is_empty(), "release: cheat inerte")
