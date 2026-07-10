extends Node
## Autoload: audio_bus — gate central de som.
##
## `AudioStreamPlayer` nativo com buses `Music`/`Effects` (AD-07/RES-010). Mute central
## = mute do bus, garantindo por construção que nenhum one-shot dispara mutado (BR-053,
## correção T-04). Música persiste entre cenas porque este nó é autoload (BR-054). Fachada
## única de efeitos/stingers (BR-055) — substitui a checagem de mute descentralizada do
## legado (8+ chamadores, D-009) e o mecanismo tag+DontDestroyOnLoad+dedupe (D-008).
##
## Origem no legado: SoundManager + FMOD* + Switch + OnLoad — fundidos.
## Implementação da Tarefa 08 (fonte: _reversa_sdd/migration).

# --- buses (devem bater com default_bus_layout.tres) -------------------------
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_EFFECTS := "Effects"

const EFFECT_VOICES := 6      # vozes para one-shots simultâneos sem cortar uns aos outros
const FADE_TIME := 0.4        # fadeout de música/paradas (BR-053/BR-046: parada sempre com fade)
const SILENT_DB := -60.0

# --- vocabulário sonoro (BR-055) ---------------------------------------------
# Efeitos de gameplay. Mapeamento provisório contra os assets extraídos do APK
# (BR-055 🟡: conferir contra a config do Inspector no Unity ao validar em runtime).
const SFX_ICE_APPEAR := preload("res://assets/audio/gelo_nascendo.ogg")     # gelo surgindo
const SFX_ICE_MELT := preload("res://assets/audio/gelo_derretendo.ogg")     # gelo derretendo
const SFX_COLLISION := preload("res://assets/audio/colisao_gelo.ogg")       # colisão não divisível
const SFX_PRIME_SWAP := preload("res://assets/audio/movimentacao.ogg")      # troca de primo
# Efeitos de UI (suprimidos com overlay aberto — RN-45).
const SFX_CLICK_OK := preload("res://assets/audio/click_ok.ogg")
const SFX_CLICK_BACK := preload("res://assets/audio/click_back.ogg")
const SFX_MENU_INTRO := preload("res://assets/audio/menu_intro_sfx.ogg")
const SFX_PHASE_SELECT := preload("res://assets/audio/selecao_nivel.ogg")   # clique na caixa da fase (0,21s)
# Stingers de resultado (unificam as entradas duplicadas do legado — BR-055).
const STINGER_WIN := preload("res://assets/audio/stinger_vitoria.ogg")
const STINGER_LOSE := preload("res://assets/audio/stinger_derrota.ogg")
# Música / ambiência (loop).
const MUSIC_MENU := preload("res://assets/audio/menu_loop.ogg")
const MUSIC_MENU_INTRO := preload("res://assets/audio/menu_intro.ogg")
const MUSIC_GAMEPLAY := preload("res://assets/audio/gameplay.ogg")
# selecao_nivel.ogg é um EFEITO de 0,21s (manifesto FSB5) — em loop virava um zumbido
# contínuo (3º teste em dispositivo). A tela de seleção usa a ambiência de pássaros.
const MUSIC_LEVEL_SELECT := preload("res://assets/audio/ambiencia_passaros.ogg")
const AMBIENCE_BIRDS := preload("res://assets/audio/ambiencia_passaros.ogg")

# --- estado ------------------------------------------------------------------
var suppress_ui_effects: bool = false   # RN-45: silencia sons de botão com overlay aberto

var _music_bus: int = 0
var _effects_bus: int = 0
var _music_player: AudioStreamPlayer
var _effect_players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music_muted: bool = false
var _effects_muted: bool = false
var _after_intro: AudioStream = null   # loop a emendar quando a intro (sem loop) terminar


func _ready() -> void:
	_ensure_buses()
	_build_players()
	_apply_prefs_from_store()
	_connect_store()


# ------------------------------------------------------------------ setup

## Cria os buses se ausentes (auto-heal — funciona mesmo sem o .tres carregado, ex.: testes).
func _ensure_buses() -> void:
	_music_bus = _ensure_bus(BUS_MUSIC)
	_effects_bus = _ensure_bus(BUS_EFFECTS)


func _ensure_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		return idx
	idx = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, BUS_MASTER)
	return idx


func _build_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	_music_player.finished.connect(_on_music_finished)   # emenda intro → loop
	add_child(_music_player)
	for i in EFFECT_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_EFFECTS
		add_child(p)
		_effect_players.append(p)


# ------------------------------------------------------------------ integração com o save

## Lê o estado de mute persistido (ProgressionStore, AD-04) e aplica direto no bus,
## sem fade no boot. Silencioso se o store ainda não existir (ex.: teste isolado).
func _apply_prefs_from_store() -> void:
	var store := get_node_or_null("/root/ProgressionStore")
	if store == null or store.progress == null:
		return
	_music_muted = bool(store.progress.audio_prefs.get("music_muted", false))
	_effects_muted = bool(store.progress.audio_prefs.get("effects_muted", false))
	AudioServer.set_bus_mute(_music_bus, _music_muted)
	AudioServer.set_bus_mute(_effects_bus, _effects_muted)
	if _music_muted:
		_music_player.volume_db = SILENT_DB


## Aplicação reativa (BR-053): mudou o toggle no store → reflete no bus imediatamente.
func _connect_store() -> void:
	var store := get_node_or_null("/root/ProgressionStore")
	if store == null:
		return
	store.audio_pref_changed.connect(_on_audio_pref_changed)


func _on_audio_pref_changed(kind: String, muted: bool) -> void:
	match kind:
		"music": set_music_muted(muted)
		"effects": set_effects_muted(muted)


# ------------------------------------------------------------------ mute (gate central)

## Efeitos: mute = mute do bus. Gate por construção — nenhum one-shot na fila soa mutado.
func set_effects_muted(muted: bool) -> void:
	_effects_muted = muted
	AudioServer.set_bus_mute(_effects_bus, muted)


## Música: mutar faz fadeout e então silencia o bus; desmutar retoma imediatamente (BR-053).
func set_music_muted(muted: bool) -> void:
	_music_muted = muted
	if muted:
		var tw := create_tween()
		tw.tween_property(_music_player, "volume_db", SILENT_DB, FADE_TIME)
		tw.tween_callback(func() -> void: AudioServer.set_bus_mute(_music_bus, true))
	else:
		AudioServer.set_bus_mute(_music_bus, false)
		_music_player.volume_db = 0.0


func is_music_muted() -> bool:
	return _music_muted


func is_effects_muted() -> bool:
	return _effects_muted


# ------------------------------------------------------------------ música (persistente)

## Toca música em loop. Se a mesma faixa já está tocando, não reinicia (BR-054) —
## a menos que `restart` seja pedido (ex.: voltar ao menu reinicia a música do menu).
func play_music(stream: AudioStream, restart: bool = false) -> void:
	if stream == null:
		return
	_after_intro = null   # troca explícita cancela uma emenda intro→loop pendente
	if _music_player.stream == stream and _music_player.playing and not restart:
		return
	_set_loop(stream, true)
	_music_player.stream = stream
	_music_player.volume_db = SILENT_DB if _music_muted else 0.0
	_music_player.play()


## Intro única emendada no loop (abertura → menu, BR-054): a intro toca SEM loop e, ao
## terminar naturalmente, o loop assume. Qualquer `play_music` no meio cancela a emenda.
func play_music_with_intro(intro: AudioStream, loop_stream: AudioStream) -> void:
	if intro == null or loop_stream == null:
		return
	_set_loop(intro, false)
	_music_player.stream = intro
	_music_player.volume_db = SILENT_DB if _music_muted else 0.0
	_music_player.play()
	_after_intro = loop_stream


func _on_music_finished() -> void:
	if _after_intro != null:
		var next := _after_intro
		play_music(next)


## Faixa em reprodução no momento (null se silêncio) — deixa as cenas decidirem se
## trocam a música ou preservam uma emenda intro→loop em andamento.
func current_music() -> AudioStream:
	return _music_player.stream if _music_player.playing else null


## Para a música. Parada sempre com fadeout, salvo pedido explícito (RN-46).
func stop_music(fade: bool = true) -> void:
	if not _music_player.playing:
		return
	if fade:
		var tw := create_tween()
		tw.tween_property(_music_player, "volume_db", SILENT_DB, FADE_TIME)
		tw.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


# ------------------------------------------------------------------ efeitos e stingers (fachada)

## Dispara um one-shot numa voz livre (round-robin). Se o bus Effects estiver mudo,
## nada soa — o gate é o próprio bus, não uma checagem por chamador (D-009).
func play_effect(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := _effect_players[_next_voice]
	_next_voice = (_next_voice + 1) % _effect_players.size()
	_set_loop(stream, false)
	p.stream = stream
	p.play()


## Stinger de resultado (VITÓRIA/DERROTA). Mesmo caminho dos efeitos (bus Effects).
func play_stinger(stream: AudioStream) -> void:
	play_effect(stream)


## Efeito de UI (botões). Suprimido enquanto um overlay está aberto (RN-45).
func play_ui(stream: AudioStream) -> void:
	if suppress_ui_effects:
		return
	play_effect(stream)


# ------------------------------------------------------------------ conversão do legado

## Convenção invertida dos toggles do legado: 0 = ligado, 1 = mudo (BR-032). Usada no
## import/migração de dados; em runtime o estado já é booleano (music_muted/effects_muted).
static func muted_from_legacy_toggle(value: int) -> bool:
	return value == 1


# ------------------------------------------------------------------ interno

func _set_loop(stream: AudioStream, loop: bool) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = loop
	elif stream is AudioStreamMP3:
		stream.loop = loop
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
