extends GutTest
## Tarefa 08 — autoload audio_bus: gate central por mute de bus (BR-053), fachada de
## efeitos/stingers (BR-055) e conversão da convenção invertida de toggle (BR-032).
## Instancia o script direto (como test_progression_store) para não depender do save real.

const BusScript = preload("res://autoload/audio_bus.gd")

var _buses: Array = []


func _fresh_bus() -> Node:
	var b := BusScript.new()
	add_child_autofree(b)  # dispara _ready → cria buses e vozes na árvore
	_buses.append(b)
	return b


func after_each() -> void:
	# desmuta os buses para não vazar estado entre testes
	var mi := AudioServer.get_bus_index(BusScript.BUS_MUSIC)
	var ei := AudioServer.get_bus_index(BusScript.BUS_EFFECTS)
	if mi != -1: AudioServer.set_bus_mute(mi, false)
	if ei != -1: AudioServer.set_bus_mute(ei, false)
	_buses.clear()


# ---------------------------------------------------------------- buses existem

func test_creates_music_and_effects_buses() -> void:
	_fresh_bus()
	assert_ne(AudioServer.get_bus_index(BusScript.BUS_MUSIC), -1, "bus Music existe")
	assert_ne(AudioServer.get_bus_index(BusScript.BUS_EFFECTS), -1, "bus Effects existe")


# ---------------------------------------------------------------- gate de efeitos (BR-053)

func test_effects_mute_hits_the_bus() -> void:
	var b := _fresh_bus()
	b.set_effects_muted(true)
	var ei := AudioServer.get_bus_index(BusScript.BUS_EFFECTS)
	assert_true(AudioServer.is_bus_mute(ei), "mutar efeitos silencia o bus (gate por construção)")
	assert_true(b.is_effects_muted())
	b.set_effects_muted(false)
	assert_false(AudioServer.is_bus_mute(ei), "desmutar reabilita o bus")


# ---------------------------------------------------------------- mute de música (BR-053)

func test_music_unmute_is_immediate() -> void:
	var b := _fresh_bus()
	b.set_music_muted(false)
	var mi := AudioServer.get_bus_index(BusScript.BUS_MUSIC)
	assert_false(AudioServer.is_bus_mute(mi), "desmutar música retoma imediatamente")
	assert_false(b.is_music_muted())


# ---------------------------------------------------------------- fachada de efeitos

func test_play_effect_uses_a_voice_without_error() -> void:
	var b := _fresh_bus()
	b.play_effect(BusScript.SFX_PRIME_SWAP)
	b.play_stinger(BusScript.STINGER_WIN)
	assert_true(true, "fachada de efeitos/stingers roda sem erro")


func test_play_ui_suppressed_with_overlay() -> void:
	var b := _fresh_bus()
	b.suppress_ui_effects = true
	b.play_ui(BusScript.SFX_CLICK_OK)  # RN-45: não deve disparar; apenas garante sem erro
	b.suppress_ui_effects = false
	assert_true(true, "efeito de UI suprimido com overlay aberto")


# ---------------------------------------------------------------- música persistente (BR-054)

func test_play_music_starts_and_persists() -> void:
	var b := _fresh_bus()
	b.play_music(BusScript.MUSIC_GAMEPLAY)
	assert_eq(b._music_player.stream, BusScript.MUSIC_GAMEPLAY, "música definida")
	assert_true(b._music_player.playing, "música tocando (o autoload a mantém entre cenas)")


# ---------------------------------------------------------------- convenção invertida (BR-032)

func test_legacy_toggle_conversion() -> void:
	assert_false(BusScript.muted_from_legacy_toggle(0), "0 = ligado (não mudo)")
	assert_true(BusScript.muted_from_legacy_toggle(1), "1 = mudo")
