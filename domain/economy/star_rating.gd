class_name StarRating
extends RefCounted
## Fórmula ÚNICA de estrelas (BR-023 / RN-17 / StarManager.GetStars canônico). Pura.
## L-02: a variante invertida (`starInLevels`/`ReadMovesInLevels`) era cache morto — não portada.
##
## record = maior energia restante ao vencer (BR-022). thresholds = {three_star, two_star, max}.
## record == 0 → 0★ (não vencido); record ≥ max - t3 → 3★; record ≥ max - t2 → 2★; senão 1★.

static func stars_for(record: int, thresholds: Dictionary) -> int:
	if record <= 0:
		return 0
	var max_moves: int = int(thresholds.get("max", 0))
	var t3: int = int(thresholds.get("three_star", 0))
	var t2: int = int(thresholds.get("two_star", 0))
	if record >= max_moves - t3:
		return 3
	elif record >= max_moves - t2:
		return 2
	return 1
