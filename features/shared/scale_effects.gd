class_name ScaleEffects
extends RefCounted
## Feature shared — efeitos de escala/movimento da UI (BR-045) em tempo real (Tween),
## substituindo as coreografias por contador de frames do legado (AutoGrow*, D-005).
## Funções estáticas: recebem o nó-alvo e usam o Tween dele. Só a fórmula pura do logo
## é testável isoladamente (as demais precisam do nó na árvore).

## Oscilação amortecida do logo (BR-045): 0.4 + e^(−0.8t)·cos(15t+11). Retorna o fator
## de escala no tempo t (segundos). Assíntota em 0.4; começa oscilando e amortece.
const LOGO_OSC_BASE := 0.4
const LOGO_OSC_DAMP := 0.8
const LOGO_OSC_FREQ := 15.0
const LOGO_OSC_PHASE := 11.0

## Recusa de entrada (BR-042): balança ±10° por 4 ciclos.
const SWING_ANGLE_DEG := 10.0
const SWING_CYCLES := 4
const SWING_STEP := 0.06  # duração de cada quarto de balanço


static func logo_osc_value(t: float) -> float:
	return LOGO_OSC_BASE + exp(-LOGO_OSC_DAMP * t) * cos(LOGO_OSC_FREQ * t + LOGO_OSC_PHASE)


# `scale`/`rotation` vivem em Node2D/Control (não em CanvasItem); acesso dinâmico via
# get() mantém estas funções utilizáveis por nós de UI e por tiles sem checagem estática.

## Balanço de recusa do contador (±10°, 4 ciclos) e volta ao zero. BR-042.
static func swing_refuse(node: CanvasItem) -> Tween:
	var tw := node.create_tween()
	var angle := deg_to_rad(SWING_ANGLE_DEG)
	var base: float = node.get("rotation")
	for i in SWING_CYCLES:
		tw.tween_property(node, "rotation", base + angle, SWING_STEP)
		tw.tween_property(node, "rotation", base - angle, SWING_STEP)
	tw.tween_property(node, "rotation", base, SWING_STEP)
	return tw


## Feedback de clique: encolhe rápido e volta (BR-045).
static func press(node: CanvasItem, factor: float = 0.9, dur: float = 0.08) -> Tween:
	var base: Vector2 = node.get("scale")
	var tw := node.create_tween()
	tw.tween_property(node, "scale", base * factor, dur)
	tw.tween_property(node, "scale", base, dur)
	return tw


## Pulsação contínua (chamada-para-ação). BR-045.
static func pulse(node: CanvasItem, factor: float = 1.08, dur: float = 0.5) -> Tween:
	var base: Vector2 = node.get("scale")
	var tw := node.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale", base * factor, dur)
	tw.tween_property(node, "scale", base, dur)
	return tw


## Fade de um nó (in/out) para as demais features reusarem. Parada sempre suave.
static func fade_to(node: CanvasItem, to_alpha: float, dur: float = 0.3) -> Tween:
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", to_alpha, dur)
	return tw
