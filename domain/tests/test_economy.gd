extends GutTest
## Tarefa 06 — domínio Progression: estrelas (BR-023), gate (BR-033), recompensa
## (BR-027), desbloqueio (BR-024), energia (BR-025), punição (BR-028). Puro.

var TH := {"three_star": 5, "two_star": 8, "max": 12}  # max-t3=7, max-t2=4


# ---------------------------------------------------------------- estrelas

func test_stars_formula() -> void:
	assert_eq(StarRating.stars_for(0, TH), 0, "record 0 = não vencido")
	assert_eq(StarRating.stars_for(10, TH), 3, "record 10 ≥ 7 → 3★")
	assert_eq(StarRating.stars_for(5, TH), 2, "record 5 (≥4, <7) → 2★")
	assert_eq(StarRating.stars_for(2, TH), 1, "record 2 (<4) mas vencido → 1★")


# ---------------------------------------------------------------- gate (BR-033)

func test_entry_paid_debits_two() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 50
	var ev := pp.try_enter(1, 2, TH)
	assert_eq(ev[0]["type"], "entry_granted")
	assert_eq(ev[0]["mode"], "paid")
	assert_eq(pp.global_energy, 48, "entrada paga debita 2")


func test_entry_three_stars_is_free() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 50
	pp.records[Vector2i(1, 2)] = 10  # 3★
	var ev := pp.try_enter(1, 2, TH)
	assert_eq(ev[0]["mode"], "free", "3★ = replay perfeito grátis")
	assert_eq(pp.global_energy, 50, "não debita")


func test_entry_level1_free_when_broke() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 0
	assert_eq(pp.try_enter(1, 1, TH)[0]["mode"], "free", "nível 1 grátis quando sem energia")
	assert_eq(pp.try_enter(1, 2, TH)[0]["type"], "entry_refused", "nível > 1 sem energia é recusado")


func test_entry_redirects_tutorial_02_01() -> void:
	var pp := PlayerProgress.new()
	var ev := pp.try_enter(2, 1, TH)
	assert_eq(ev[0]["type"], "entry_redirected", "02-01 sem tutorial 2 feito → redireciona")
	pp.mark_tutorial_done("t2")
	assert_eq(pp.try_enter(2, 1, TH)[0]["type"], "entry_granted", "após tutorial 2, entra normal")


# ---------------------------------------------------------------- vitória / recompensa

func test_first_win_three_stars_rewards_five() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 10
	pp.register_win(1, 1, 10, TH)  # record 10 → 3★, 1ª vitória
	assert_eq(pp.global_energy, 15, "1ª vitória 3★ → +5")
	assert_eq(pp.record_of(1, 1), 10)
	assert_eq(pp.unlock_of(1, 1), PlayerProgress.UnlockState.WON)
	assert_eq(pp.unlock_of(1, 2), PlayerProgress.UnlockState.UNLOCKED, "desbloqueia a próxima")


func test_replay_three_stars_rewards_four() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 10
	pp.register_win(1, 1, 10, TH)   # 1ª vitória
	pp.register_win(1, 1, 11, TH)   # replay, melhora recorde
	assert_eq(pp.record_of(1, 1), 11)
	assert_eq(pp.global_energy, 19, "replay 3★ → +4 (15 + 4)")


func test_one_star_rewards_zero() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 30
	pp.register_win(1, 1, 2, TH)  # record 2 → 1★
	assert_eq(pp.global_energy, 30, "1★ → +0 (L-01)")


func test_reward_saturates_at_50() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 48
	pp.register_win(1, 1, 10, TH)  # +5, mas satura em 50
	assert_eq(pp.global_energy, 50)


func test_win_last_level_completes_stage() -> void:
	var pp := PlayerProgress.new()
	var ev := pp.register_win(1, 12, 10, TH)
	assert_true(pp.stages_completed.has(1), "vencer o 12º marca o estágio")
	var types := ev.map(func(e): return e["type"])
	assert_true(types.has("stage_completed"))


# ---------------------------------------------------------------- derrota / punição

func test_loss_with_low_energy_resets_stage() -> void:
	var pp := PlayerProgress.new()
	pp.records[Vector2i(3, 1)] = 8
	pp.unlocks[Vector2i(3, 1)] = PlayerProgress.UnlockState.WON
	pp.global_energy = 1
	var ev := pp.register_loss(3, 5)
	assert_eq(pp.record_of(3, 1), 0, "punição zera recordes do estágio")
	assert_eq(pp.unlock_of(3, 1), PlayerProgress.UnlockState.LOCKED, "e trava todos os níveis")
	var types := ev.map(func(e): return e["type"])
	assert_true(types.has("stage_reset"))


func test_loss_with_energy_does_not_reset() -> void:
	var pp := PlayerProgress.new()
	pp.records[Vector2i(3, 1)] = 8
	pp.global_energy = 5
	var ev := pp.register_loss(3, 5)
	assert_eq(pp.record_of(3, 1), 8, "com energia > 1 não há punição")
	var types := ev.map(func(e): return e["type"])
	assert_false(types.has("stage_reset"))


# ---------------------------------------------------------------- prefs

func test_audio_and_tutorial_flags() -> void:
	var pp := PlayerProgress.new()
	pp.set_audio_pref("music", true)
	assert_true(pp.audio_prefs["music_muted"])
	pp.mark_tutorial_done("t1")
	assert_true(pp.tutorial_flags["t1_done"])
