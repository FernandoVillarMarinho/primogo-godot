class_name TutorialSequence
extends RefCounted
## Feature tutorial — fonte de verdade das sequências (BR-048), unificada e parametrizada
## (TutorialManager+TutorialManager2 fundidos). Pura, testável. O passo BALLOON (clique no
## balão) não é uma direção de swipe; só as direções alimentam o gate de movimento do
## domínio (BR-009). O gate do balão é por identidade do PASSO, não por static (T-05, BR-049).

const BALLOON := 100   # passo "clique no balão" (distinto das direções do Match)

const T1 := [Match.Direction.UP, Match.Direction.RIGHT, Match.Direction.DOWN, Match.Direction.LEFT]
## T2 corrigida no 4º teste em dispositivo: a sequência legada (RIGHT, LEFT, balão, LEFT)
## nunca alcançava o 6 em (4,3) — a ESQUERDA deslizava pela linha 2 e o descongelamento
## não acontecia. Coreografia pedagógica correta na 02-01: DIREITA (leva o 3 para o lado),
## BAIXO (o 3 descongela o 6 e conquista o primo 2), balão (seleciona o 2), ESQUERDA
## (divide o 4). O 4 foi realocado de (0,1) para (0,3) no level_02_01.tres.
const T2 := [Match.Direction.RIGHT, Match.Direction.DOWN, BALLOON, Match.Direction.LEFT]

## Instruções curtas exibidas na tela, uma por passo (4º teste: o jogador precisava de
## orientação explícita — "Descongele o 6", "Clique no primo 2", "Divida o 4").
const T1_CAPTIONS := [
	"Deslize para CIMA para mover o fogo",
	"Agora deslize para a DIREITA",
	"Deslize para BAIXO",
	"E para a ESQUERDA para completar o passeio",
]
const T2_CAPTIONS := [
	"Deslize para a DIREITA para levar o número 3 para o lado",
	"Descongele o número 6: deslize para BAIXO (6 ÷ 3 = 2)",
	"Você conquistou o primo 2! Clique nele na lista para selecioná-lo",
	"Agora divida o número 4: deslize para a ESQUERDA (4 ÷ 2 = 2)",
]


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


static func captions_for(stage: int, level: int) -> Array:
	if stage == 2 and level == 1:
		return T2_CAPTIONS.duplicate()
	return T1_CAPTIONS.duplicate()


## Só as direções (sem o passo BALLOON) vão para o gate de movimento do domínio (BR-009).
static func move_sequence(seq: Array) -> Array:
	return seq.filter(func(s): return s != BALLOON)


## O passo atual é o clique no balão? Gate por identidade do passo (BR-049, T-05).
static func is_balloon_step(seq: Array, index: int) -> bool:
	return index >= 0 and index < seq.size() and seq[index] == BALLOON
