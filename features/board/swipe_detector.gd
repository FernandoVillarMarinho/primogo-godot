class_name SwipeDetector
extends RefCounted
## Feature board — traduz um gesto de swipe na direção dominante do `Match` (BR-008).
## O eixo y cresce para baixo na tela e no grid (BR-017), então swipe para baixo = DOWN.
## Deslocamentos abaixo do limiar não são swipe (retorna NONE, sem custo).

const MIN_SWIPE := 24.0  # px


static func direction_for(delta: Vector2, min_dist: float = MIN_SWIPE) -> int:
	if delta.length() < min_dist:
		return Match.Direction.NONE
	if absf(delta.x) >= absf(delta.y):
		return Match.Direction.RIGHT if delta.x > 0.0 else Match.Direction.LEFT
	return Match.Direction.DOWN if delta.y > 0.0 else Match.Direction.UP
