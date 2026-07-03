class_name SaveSchema
extends RefCounted
## Contrato do save local `user://save.cfg` (ConfigFile) — target_data_model.md §1.
## Índices 1-based (como o jogador vê). Único dono da escrita: `progression_store` (Tarefa 07);
## esta classe é só o **contrato** (seções, chaves, defaults, restrições) que ele honra.

const PATH := "user://save.cfg"
const CURRENT_VERSION := 1
const ENERGY_MAX := 50
const ENERGY_DEFAULT := 50

# Seções
const SEC_META := "meta"
const SEC_ENERGY := "energy"
const SEC_LEVELS := "levels"     # chaves "<stage>_<level>/record" e "<stage>_<level>/state"
const SEC_STAGES := "stages"
const SEC_FLAGS := "flags"
const SEC_AUDIO := "audio"

# Estados de fase (legado Level_<s0>_<n0> = 0|2|1)
const STATE_LOCKED := "locked"
const STATE_UNLOCKED := "unlocked"
const STATE_WON := "won"
const VALID_STATES: PackedStringArray = [STATE_LOCKED, STATE_UNLOCKED, STATE_WON]


## Config de primeiro jogo (arquivo ausente): energia cheia, tudo travado, flags falsas.
## A liberação da 1ª fase de cada estágio (BR-036) é aplicada pelo progression_store.
static func default_config() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.set_value(SEC_META, "save_version", CURRENT_VERSION)
	cfg.set_value(SEC_ENERGY, "global", ENERGY_DEFAULT)
	cfg.set_value(SEC_STAGES, "completed", [])
	cfg.set_value(SEC_FLAGS, "tutorial1_done", false)
	cfg.set_value(SEC_FLAGS, "tutorial2_done", false)
	cfg.set_value(SEC_AUDIO, "music_muted", false)
	cfg.set_value(SEC_AUDIO, "effects_muted", false)
	return cfg


static func clamp_energy(value: int) -> int:
	return clampi(value, 0, ENERGY_MAX)


static func is_valid_state(state: String) -> bool:
	return VALID_STATES.has(state)


static func level_key(stage: int, level: int) -> String:
	return "%d_%d" % [stage, level]
