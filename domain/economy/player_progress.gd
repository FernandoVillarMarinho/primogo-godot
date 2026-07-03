class_name PlayerProgress
extends RefCounted
## Aggregate raiz do contexto Progression. Puro, sem persistência (o progression_store,
## Tarefa 07, hidrata/salva). Comandos retornam eventos (AD-02).
##
## Rastreabilidade: GlobalStats + StarManager + GameScene(recompensa) + gates — fundidos.
## Estrelas são DERIVADAS do recorde (P4), nunca armazenadas.

enum UnlockState { LOCKED, UNLOCKED, WON }

const ENERGY_MAX := 50       # BR-025
const ENTRY_COST := 2        # BR-026 (energyCost uniforme = 2)
const LEVELS_PER_STAGE := 12 # BR-024

var global_energy: int
var records: Dictionary       # Vector2i(stage, level) -> int (maior sobra ao vencer)
var unlocks: Dictionary       # Vector2i(stage, level) -> UnlockState
var stages_completed: Array   # Array[int]
var tutorial_flags: Dictionary
var audio_prefs: Dictionary


func _init() -> void:
	global_energy = ENERGY_MAX  # primeiro jogo começa com 50 (BR-025)
	records = {}
	unlocks = {}
	stages_completed = []
	tutorial_flags = {"t1_done": false, "t2_done": false}
	audio_prefs = {"music_muted": false, "effects_muted": false}


# ------------------------------------------------------------------ consultas

func record_of(stage: int, level: int) -> int:
	return int(records.get(Vector2i(stage, level), 0))


func stars_of(stage: int, level: int, thresholds: Dictionary) -> int:
	return StarRating.stars_for(record_of(stage, level), thresholds)


func unlock_of(stage: int, level: int) -> int:
	return int(unlocks.get(Vector2i(stage, level), UnlockState.LOCKED))


# ------------------------------------------------------------------ comandos

## Gate de entrada (BR-033), ordem exata do legado (LevelSelect.OnClick):
## redirect tutorial 02-01 → 3★ grátis → débito de 2 → nível 1 grátis (fallback) → recusa.
func try_enter(stage: int, level: int, thresholds: Dictionary) -> Array:
	if stage == 2 and level == 1 and not bool(tutorial_flags["t2_done"]):
		return [{"type": "entry_redirected", "to": "tutorial"}]

	if stars_of(stage, level, thresholds) == 3:  # BR-031 replay perfeito grátis
		return [{"type": "entry_granted", "mode": "free"}]

	if global_energy >= ENTRY_COST:
		global_energy -= ENTRY_COST
		return [
			{"type": "entry_granted", "mode": "paid"},
			{"type": "energy_changed", "energy": global_energy},
		]

	if level == 1:  # fase 01 grátis (fallback quando sem energia)
		return [{"type": "entry_granted", "mode": "free"}]

	return [{"type": "entry_refused"}]


## Vitória (BR-022/024/027). remaining_energy = orçamento restante ao vencer.
## Recompensa deriva do recorde PÓS-atualização e de ter sido a 1ª vitória (BR-027).
func register_win(stage: int, level: int, remaining_energy: int, thresholds: Dictionary) -> Array:
	var key := Vector2i(stage, level)
	var events: Array = []

	var was_won := record_of(stage, level) > 0  # GetStars()>0 ANTES de atualizar
	var old_record := record_of(stage, level)
	var new_record := maxi(old_record, remaining_energy)
	records[key] = new_record
	if new_record != old_record:
		events.append({"type": "record_updated", "record": new_record})

	unlocks[key] = UnlockState.WON
	events.append({"type": "level_won", "stage": stage, "level": level})

	if level < LEVELS_PER_STAGE:
		var nk := Vector2i(stage, level + 1)
		if int(unlocks.get(nk, UnlockState.LOCKED)) == UnlockState.LOCKED:
			unlocks[nk] = UnlockState.UNLOCKED
			events.append({"type": "next_unlocked", "stage": stage, "level": level + 1})
	elif level == LEVELS_PER_STAGE:
		if not stages_completed.has(stage):
			stages_completed.append(stage)
		events.append({"type": "stage_completed", "stage": stage})

	var reward := _reward_for(StarRating.stars_for(new_record, thresholds), was_won)
	if reward > 0:
		global_energy = mini(ENERGY_MAX, global_energy + reward)  # satura em 50
		events.append({"type": "energy_rewarded", "amount": reward})
		events.append({"type": "energy_changed", "energy": global_energy})
	return events


## Derrota (BR-028). Punição severa quando energia global ≤ 1: zera recordes E trava
## todos os 12 níveis do estágio (ResetStarsInStage + ResetWinLevels).
func register_loss(stage: int, level: int) -> Array:
	var events: Array = [{"type": "match_registered", "stage": stage, "level": level}]
	if global_energy <= 1:
		for l in range(1, LEVELS_PER_STAGE + 1):
			var k := Vector2i(stage, l)
			records[k] = 0
			unlocks[k] = UnlockState.LOCKED
		events.append({"type": "stage_reset", "stage": stage})
	return events


func set_audio_pref(kind: String, muted: bool) -> Array:
	var flag := "music_muted" if kind == "music" else "effects_muted"
	audio_prefs[flag] = muted
	return [{"type": "audio_pref_changed", "kind": kind, "muted": muted}]


func mark_tutorial_done(which: String) -> Array:
	var flag := "t1_done" if which == "t1" else "t2_done"
	tutorial_flags[flag] = true
	return [{"type": "tutorial_flag_set", "which": which}]


## Cheat de sessão (BR-029) — desbloqueia tudo sem persistir. O gate de build de
## desenvolvimento (OS.is_debug_build, AD-06) vive no autoload (Tarefa 07).
func unlock_all_session(stages: int) -> Array:
	for s in range(1, stages + 1):
		for l in range(1, LEVELS_PER_STAGE + 1):
			var k := Vector2i(s, l)
			if int(unlocks.get(k, UnlockState.LOCKED)) == UnlockState.LOCKED:
				unlocks[k] = UnlockState.UNLOCKED
	return [{"type": "session_unlocked"}]


func _reward_for(stars: int, was_won: bool) -> int:
	match stars:
		3: return 4 if was_won else 5
		2: return 2 if was_won else 3
		_: return 0
