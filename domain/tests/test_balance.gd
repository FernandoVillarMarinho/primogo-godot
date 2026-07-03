extends GutTest
## Balance transcrito (StarManager.movementsInLevel) — carrega thresholds.tres e valida
## a integração com StarRating; confere entry_cost/rewards.

const BAL := "res://resources/balance/"


func test_thresholds_load_and_known_values() -> void:
	var bt := ResourceLoader.load(BAL + "thresholds.tres") as BalanceThresholds
	assert_not_null(bt, "thresholds.tres carrega")
	if bt == null:
		return
	assert_eq(bt.entries.size(), 122, "122 fases transcritas")
	var l11 := bt.for_level(1, 1)
	assert_eq(int(l11["three_star"]), 5)
	assert_eq(int(l11["two_star"]), 8)
	assert_eq(int(l11["max"]), 12, "Level_01_01: max 12 movimentos")
	assert_eq(int(bt.for_level(2, 0)["max"]), 50, "tutorial 2_0: max 50")
	assert_false(bt.placeholder, "valores reais, não placeholder")


func test_stars_end_to_end_with_real_thresholds() -> void:
	var bt := ResourceLoader.load(BAL + "thresholds.tres") as BalanceThresholds
	if bt == null:
		return
	var th := bt.for_level(1, 1)  # {5,8,12} → max-t3=7, max-t2=4
	assert_eq(StarRating.stars_for(12, th), 3, "record 12 (perfeito) → 3★")
	assert_eq(StarRating.stars_for(7, th), 3, "record 7 = max-t3 → 3★")
	assert_eq(StarRating.stars_for(5, th), 2, "record 5 → 2★")
	assert_eq(StarRating.stars_for(3, th), 1, "record 3 (<4) mas vencido → 1★")
	assert_eq(StarRating.stars_for(0, th), 0, "sem recorde → 0★")


func test_entry_cost_and_rewards_load() -> void:
	var ec := ResourceLoader.load(BAL + "entry_cost.tres") as EntryCost
	assert_not_null(ec)
	assert_eq(ec.cost_for(1, 1), 2, "custo de entrada uniforme = 2")
	var rw := ResourceLoader.load(BAL + "rewards.tres") as Rewards
	assert_not_null(rw)
	assert_eq(rw.pair_for(3), Vector2i(5, 4), "3★ → +5/+4")
	assert_eq(rw.pair_for(1), Vector2i.ZERO, "1★ → +0")
