class_name TutorialSequence
extends RefCounted
## Feature tutorial — fonte de verdade das sequências (BR-048), unificada e parametrizada
## (TutorialManager+TutorialManager2 fundidos). Pura, testável. O passo BALLOON (clique no
## balão) não é uma direção de swipe; só as direções alimentam o gate de movimento do
## domínio (BR-009). O gate do balão é por identidade do PASSO, não por static (T-05, BR-049).

const BALLOON := 100   # passo "clique no balão" (distinto das direções do Match)

const T1 := [Match.Direction.UP, Match.Direction.RIGHT, Match.Direction.DOWN, Match.Direction.LEFT]
const T2 := [Match.Direction.RIGHT, Match.Direction.LEFT, BALLOON, Match.Direction.LEFT]


## Nível-tutorial por identidade: (1,0) = tutorial 1 (1ª execução); (2,1) = tutorial 2
## (1ª visita à 02-01). Detecção pela fase carregada, não por página estática (D-003).
static func is_tutorial(stage: int, level: int) -> bool:
	return (stage == 1 and level == 0) or (stage == 2 and level == 1)


static func sequence_for(stage: int, level: int) -> Array:
	if stage == 2 and level == 1:
		return T2.duplicate()
	return T1.duplicate()


static func which(stage: int, level: int) -> String:
	return "t2" if (stage == 2 and level == 1) else "t1"


## Só as direções (sem o passo BALLOON) vão para o gate de movimento do domínio (BR-009).
static func move_sequence(seq: Array) -> Array:
	return seq.filter(func(s): return s != BALLOON)


## O passo atual é o clique no balão? Gate por identidade do passo (BR-049, T-05).
static func is_balloon_step(seq: Array, index: int) -> bool:
	return index >= 0 and index < seq.size() and seq[index] == BALLOON
