extends GutTest
## Tarefa 02 — contrato do save (SaveSchema): defaults, clamps e round-trip do ConfigFile.

const TMP_PATH := "user://test_save.cfg"


func after_each() -> void:
	if FileAccess.file_exists(TMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PATH))


func test_default_config_has_version_and_full_energy() -> void:
	var cfg := SaveSchema.default_config()
	assert_eq(cfg.get_value(SaveSchema.SEC_META, "save_version"), SaveSchema.CURRENT_VERSION)
	assert_eq(cfg.get_value(SaveSchema.SEC_ENERGY, "global"), SaveSchema.ENERGY_DEFAULT)


func test_default_flags_and_audio_are_false() -> void:
	var cfg := SaveSchema.default_config()
	assert_false(cfg.get_value(SaveSchema.SEC_FLAGS, "tutorial1_done"))
	assert_false(cfg.get_value(SaveSchema.SEC_FLAGS, "tutorial2_done"))
	# semântica invertida do legado já resolvida: false = tocando
	assert_false(cfg.get_value(SaveSchema.SEC_AUDIO, "music_muted"))
	assert_false(cfg.get_value(SaveSchema.SEC_AUDIO, "effects_muted"))


func test_energy_clamped_to_range() -> void:
	assert_eq(SaveSchema.clamp_energy(60), SaveSchema.ENERGY_MAX, "acima do máximo satura em 50")
	assert_eq(SaveSchema.clamp_energy(-5), 0, "abaixo de zero satura em 0")
	assert_eq(SaveSchema.clamp_energy(30), 30, "valor válido permanece")


func test_state_validation() -> void:
	assert_true(SaveSchema.is_valid_state(SaveSchema.STATE_WON))
	assert_true(SaveSchema.is_valid_state(SaveSchema.STATE_LOCKED))
	assert_false(SaveSchema.is_valid_state("banana"), "estado desconhecido é inválido")


func test_level_key_format() -> void:
	assert_eq(SaveSchema.level_key(1, 1), "1_1")
	assert_eq(SaveSchema.level_key(12, 10), "12_10")


func test_configfile_round_trip() -> void:
	var cfg := SaveSchema.default_config()
	cfg.set_value(SaveSchema.SEC_ENERGY, "global", 37)
	cfg.set_value(SaveSchema.SEC_LEVELS, "1_1/record", 9)
	cfg.set_value(SaveSchema.SEC_LEVELS, "1_1/state", SaveSchema.STATE_WON)
	var err := cfg.save(TMP_PATH)
	assert_eq(err, OK, "ConfigFile.save deveria retornar OK")

	var reloaded := ConfigFile.new()
	assert_eq(reloaded.load(TMP_PATH), OK, "ConfigFile.load deveria retornar OK")
	assert_eq(reloaded.get_value(SaveSchema.SEC_ENERGY, "global"), 37)
	assert_eq(reloaded.get_value(SaveSchema.SEC_LEVELS, "1_1/record"), 9)
	assert_eq(reloaded.get_value(SaveSchema.SEC_LEVELS, "1_1/state"), SaveSchema.STATE_WON)
