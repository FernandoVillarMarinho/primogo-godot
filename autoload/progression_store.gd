extends Node
## Autoload ProgressionStore — estado vivo da progressão + persistência.
##
## Única porta de escrita do save `user://save.cfg` (AD-04). Embrulha o domínio puro
## `PlayerProgress` (Tarefa 06) e converte seus eventos em sinais Godot (AD-02).
## Gravação atômica (tmp + rename) protege contra corte de energia no mobile.

signal energy_changed(energy: int)
signal level_won(stage: int, level: int)
signal next_unlocked(stage: int, level: int)
signal stage_completed(stage: int)
signal stage_reset(stage: int)
signal entry_granted(mode: String)
signal entry_refused()
signal entry_redirected(destination: String)
signal audio_pref_changed(kind: String, muted: bool)

var progress: PlayerProgress
var save_path: String = SaveSchema.PATH


func _ready() -> void:
	load_progress()


# ------------------------------------------------------------------ persistência

func load_progress() -> void:
	progress = PlayerProgress.new()
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		save()  # primeiro jogo: grava o save inicial com os defaults
		return
	_from_config(cfg)


## Gravação atômica: escreve em tmp, remove o antigo e renomeia (AD-04).
func save() -> void:
	var cfg := _to_config()
	var tmp := save_path + ".tmp"
	if cfg.save(tmp) != OK:
		push_error("progression_store: falha ao gravar %s" % tmp)
		return
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	DirAccess.rename_absolute(tmp, save_path)


func _from_config(cfg: ConfigFile) -> void:
	progress.global_energy = SaveSchema.clamp_energy(
		int(cfg.get_value(SaveSchema.SEC_ENERGY, "global", PlayerProgress.ENERGY_MAX)))

	if cfg.has_section(SaveSchema.SEC_LEVELS):
		for key in cfg.get_section_keys(SaveSchema.SEC_LEVELS):
			var parts := key.split("/")
			var sl := parts[0].split("_")
			var vk := Vector2i(int(sl[0]), int(sl[1]))
			var value: Variant = cfg.get_value(SaveSchema.SEC_LEVELS, key)
			if parts[1] == "record":
				progress.records[vk] = int(value)
			elif parts[1] == "state":
				progress.unlocks[vk] = _state_to_enum(str(value))

	progress.stages_completed = cfg.get_value(SaveSchema.SEC_STAGES, "completed", [])
	progress.tutorial_flags["t1_done"] = bool(cfg.get_value(SaveSchema.SEC_FLAGS, "tutorial1_done", false))
	progress.tutorial_flags["t2_done"] = bool(cfg.get_value(SaveSchema.SEC_FLAGS, "tutorial2_done", false))
	progress.audio_prefs["music_muted"] = bool(cfg.get_value(SaveSchema.SEC_AUDIO, "music_muted", false))
	progress.audio_prefs["effects_muted"] = bool(cfg.get_value(SaveSchema.SEC_AUDIO, "effects_muted", false))


func _to_config() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.set_value(SaveSchema.SEC_META, "save_version", SaveSchema.CURRENT_VERSION)
	cfg.set_value(SaveSchema.SEC_ENERGY, "global", progress.global_energy)
	for k in progress.records:
		cfg.set_value(SaveSchema.SEC_LEVELS, "%d_%d/record" % [k.x, k.y], int(progress.records[k]))
	for k in progress.unlocks:
		cfg.set_value(SaveSchema.SEC_LEVELS, "%d_%d/state" % [k.x, k.y], _enum_to_state(int(progress.unlocks[k])))
	cfg.set_value(SaveSchema.SEC_STAGES, "completed", progress.stages_completed)
	cfg.set_value(SaveSchema.SEC_FLAGS, "tutorial1_done", progress.tutorial_flags["t1_done"])
	cfg.set_value(SaveSchema.SEC_FLAGS, "tutorial2_done", progress.tutorial_flags["t2_done"])
	cfg.set_value(SaveSchema.SEC_AUDIO, "music_muted", progress.audio_prefs["music_muted"])
	cfg.set_value(SaveSchema.SEC_AUDIO, "effects_muted", progress.audio_prefs["effects_muted"])
	return cfg


func _enum_to_state(state: int) -> String:
	match state:
		PlayerProgress.UnlockState.WON: return SaveSchema.STATE_WON
		PlayerProgress.UnlockState.UNLOCKED: return SaveSchema.STATE_UNLOCKED
		_: return SaveSchema.STATE_LOCKED


func _state_to_enum(s: String) -> int:
	match s:
		SaveSchema.STATE_WON: return PlayerProgress.UnlockState.WON
		SaveSchema.STATE_UNLOCKED: return PlayerProgress.UnlockState.UNLOCKED
		_: return PlayerProgress.UnlockState.LOCKED


# ------------------------------------------------------------------ comandos (delegam + persistem)

func try_enter(stage: int, level: int, thresholds: Dictionary) -> Array:
	return _run(progress.try_enter(stage, level, thresholds))


func register_win(stage: int, level: int, remaining_energy: int, thresholds: Dictionary) -> Array:
	return _run(progress.register_win(stage, level, remaining_energy, thresholds))


func register_loss(stage: int, level: int) -> Array:
	return _run(progress.register_loss(stage, level))


func set_audio_pref(kind: String, muted: bool) -> Array:
	return _run(progress.set_audio_pref(kind, muted))


func mark_tutorial_done(which: String) -> Array:
	return _run(progress.mark_tutorial_done(which))


# ------------------------------------------------------------------ consultas

func energy() -> int:
	return progress.global_energy


func stars_of(stage: int, level: int, thresholds: Dictionary) -> int:
	return progress.stars_of(stage, level, thresholds)


func unlock_of(stage: int, level: int) -> int:
	return progress.unlock_of(stage, level)


# ------------------------------------------------------------------ interno

func _run(events: Array) -> Array:
	_emit(events)
	save()  # escrita atômica no fim de fase e nos toggles (AD-04)
	return events


func _emit(events: Array) -> void:
	for e in events:
		match e["type"]:
			"energy_changed": energy_changed.emit(int(e["energy"]))
			"level_won": level_won.emit(int(e["stage"]), int(e["level"]))
			"next_unlocked": next_unlocked.emit(int(e["stage"]), int(e["level"]))
			"stage_completed": stage_completed.emit(int(e["stage"]))
			"stage_reset": stage_reset.emit(int(e["stage"]))
			"entry_granted": entry_granted.emit(str(e["mode"]))
			"entry_refused": entry_refused.emit()
			"entry_redirected": entry_redirected.emit(str(e["to"]))
			"audio_pref_changed": audio_pref_changed.emit(str(e["kind"]), bool(e["muted"]))
