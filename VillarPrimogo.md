# Primogo — resumo para o Villar

*Atualizado em 12/07/2026. Linguagem simples, sem jargão.*

## O que é isto

O **Primogo** (seu jogo de puzzle de números primos, originalmente feito em Unity) foi
**reconstruído do zero na Godot 4** — um motor de jogos gratuito e mais leve, ideal para
Android. A reconstrução partiu das especificações que o Reversa extraiu do jogo antigo.

## Em que pé está (o essencial)

- ✅ **O jogo está funcionando por inteiro, por dentro.** Toda a lógica (as regras do
  puzzle, a energia, as estrelas, o desbloqueio de fases, os tutoriais, os menus, o som)
  está pronta e **testada automaticamente** — são **148 testes**, todos passando.
- ✅ **As 122 fases originais** foram extraídas do jogo antigo e recriadas.
- ✅ **Os sons** (14 efeitos e músicas) foram extraídos e ligados.
- ✅ **A arte original está DENTRO do jogo** (10/07/2026): as imagens que você trouxe
  (pasta `ImagensPrimogo`) foram todas importadas — a chama do jogador, os blocos de
  gelo, o dragão laranja, os números desenhados, os cenários de cada tamanho de
  tabuleiro, o menu, a seleção de fases, o tutorial com a mãozinha. **Nada mais de
  retângulos coloridos.**
- ✅ **O APK de teste foi gerado e assinado com o visual novo** — o jogo abre e roda no
  Android com a cara do jogo original.
- ✅ **Duas rodadas de teste no seu celular já corrigidas** (10/07/2026). Na 1ª: tamanho
  dos blocos igual ao quadriculado, telas centralizadas e a splash com a animação da
  história. Na 2ª (12 itens): números centrados no fogo/gelo/caixas, balão igual ao do
  jogo antigo (fileira à esquerda com o número da fase na aba), contador de jogadas em
  branco legível, estrelas douradas encaixando sobre as cinzas, setas alinhadas, PRIMOGO
  aparecendo uma vez só, abertura sem "buracos" na imagem, **mago animado quando perde**,
  créditos com tempo de ler os nomes, **festinha quando você conquista um primo novo**
  (o número cresce, solta faíscas e voa para o balão — ajuda a fixar a sequência dos
  primos) e o **fogo deslizando fluido** como no 2048.
- ✅ **Os ajustes da "versão 2026" (do seu 3º teste) estão feitos** (10/07/2026):
  - **Os primos agora acumulam**: você começa com o primo da fase e, a cada composto
    dividido, ganha mais um — e pode **trocar entre todos eles** clicando na lista
    (cada troca gasta 1 de energia e muda o fogo na hora).
  - **O primo em uso fica destacado**: sobe um pouco, cresce e a caixinha fica dourada;
    os outros ficam guardados na lista, **sempre em ordem crescente** (2, 3, 5, 7...).
  - **O último primo da fase também faz a festinha**: a tela de vitória agora espera a
    celebração terminar antes de aparecer.
  - **Vitória mais ágil**: o cartão de parabéns entra num pulo e as trocas de tela
    ficaram 2× mais rápidas.
  - **Estrelas encaixando**: as laterais agora giram ±18,5° (medido na própria arte)
    para cobrir exatamente as cinzas.
  - **O zumbido sumiu**: aquele som contínuo na seleção de fases era um efeito de 0,2s
    tocando em loop por engano; agora toca a ambiência de pássaros do jogo original.
  - **PAUSE arrumado**: o menu de pausa não fica mais por cima da palavra PAUSE, e o
    número da energia saiu de trás do raio.
  - **Créditos 2026**: entrou a logomarca do **DJDE** e a equipe do Projeto (você como
    coordenador-geral + os 7 coordenadores dos núcleos), com tempo para ler.
  - **Abertura com música**: a música começa junto com a imagem, e o passeio da câmera
    agora mostra a tela inteira do mago e a neve atingindo a cidade (continuando a
    desviar do pedaço da arte que se perdeu).
- ✅ **Os ajustes do seu 4º pedido estão feitos** (12/07/2026):
  - **Tela cheia no computador**: o jogo abre direto em tela cheia (e, se sair dela,
    vira uma janela grande e centralizada — nunca mais o "quadradinho").
  - **O 142 virou 143** — e não era só ele: o jogo antigo calculava os números com um
    arredondamento errado do computador, e isso corrompia **63 números em 24 fases**
    (tinha até fase mostrando **0**!). Consertei a conta na raiz, conferi as 122 fases
    uma a uma (866 números) e criei um teste automático que garante que **todo número
    exibido é divisível por algum primo da fase**. O 143 ÷ 13 = 11 funciona.
  - **A lista de primos não repete mais**: aquele "13 | 13" era a aba antiga do balão
    duplicando o primo inicial — a aba saiu, ficou uma fileira só, com **todos os
    quadradinhos alinhados na mesma linha**. O primo em uso é indicado **só pela
    caixinha dourada pulsando de leve** (nada de subir/descer).
  - **Festinha de conquista caprichada**: o primo conquistado aparece **em chamas**,
    dá um pulo, solta faíscas, **voa num arco** até o lugar certo na lista (em ordem
    crescente) e o quadradinho **pisca confirmando o encaixe**. Se você reconquistar
    um primo que já tinha, o quadradinho dele pisca (sem duplicar). E a tela de
    vitória **espera tudo isso terminar**.
  - **O tutorial da fase 2-1 funciona**: o roteiro antigo mandava o fogo para um lugar
    onde o 6 nem estava — por isso não descongelava. Agora é: **direita** (leva o 3),
    **baixo** (o 3 descongela o 6 e você ganha o primo 2), **clique no primo 2** (que
    fica pulsando com a mãozinha apontando) e **esquerda** (divide o 4). Cada passo tem
    uma **instrução escrita na tela** que avança conforme você acerta.
  - **Fases em ordem de leitura**: 1, 2, 3 na primeira linha; 4, 5, 6 na segunda —
    da esquerda para a direita, de cima para baixo (era em colunas). Cada botão abre
    a fase certa.
  - **Créditos com "Voltar"**: dá para **pular os créditos** a qualquer momento pelo
    botão no canto (ou o botão voltar do celular) — e o **Jogar não trava mais** depois
    dos créditos (a tela invisível dos créditos ficava "roubando" os cliques).
  - **Créditos bonitos e uniformes**: a logo do **DJDE desceu para o jardim verde**
    (sem cobrir o PRIMOGO), e TODOS os nomes — inclusive os da "Idealização do
    Projeto" — agora têm a mesma sombra, o mesmo tamanho e a mesma centralização.
- ⏳ **Falta o 5º teste no celular**: conferir esses ajustes no aparelho.

Em uma frase: **o carro está pronto, pintado e rodando; falta a última volta de inspeção.**

## O APK de teste (para o seu celular)

Arquivo: **`exports/primogo-teste.apk`** (~44 MB, agora com a arte original). É uma
versão de **teste** (não é a da loja). Para instalar no seu celular:

1. Copie o `primogo-teste.apk` para o celular (cabo USB, Google Drive, ou mande no seu
   próprio WhatsApp e baixe).
2. No celular, toque no arquivo. O Android vai avisar sobre "instalar de fontes
   desconhecidas" — **permita** para o app que você está usando (Arquivos ou navegador).
3. Instale, abra e teste — agora comparando com a sua memória do jogo original.

> Esse APK serve só para você testar no seu aparelho. **Não pode ir para a loja assim** —
> a loja exige uma versão "de release" assinada com a sua chave própria (ver adiante).

## Próximos passos (do teste até a loja)

1. **Testar no celular (agora).** Instale o APK acima e jogue. O objetivo é conferir se
   o visual bate com o jogo antigo (as capturas de tela guardadas ajudam na comparação).

2. **Ajuste fino da arte.** Onde algo parecer fora do lugar (um bloco desalinhado, a
   mãozinha do tutorial em posição estranha, o dragão grande demais), é ajuste de
   parâmetro — me diga o que viu que eu corrijo.

3. **Conferência de paridade.** Jogar ~10 partidas comparando com o jogo antigo, para
   confirmar que energia, estrelas e desbloqueios batem exatamente. (Precisa do APK antigo
   como referência.)

4. **Gerar a versão de release.** Configurar a sua **chave de assinatura própria**
   (`meu_jogo_release.keystore`, que já existe) dentro do preset de exportação e gerar o
   arquivo `.aab` assinado. Guia técnico completo em **`RELEASE.md`**.

5. **Publicar na Google Play.** Subir o `.aab` no Play Console, fazer uma faixa de teste
   interno, depois beta, e por fim produção. A loja em 2026 exige **Android 15 (API 35)** —
   que já está configurado. Checklist de go/no-go também no `RELEASE.md`.

## Onde estão as coisas

- **Código do jogo:** este repositório (`primogo-godot`).
- **Guia técnico de release/assinatura:** `RELEASE.md`.
- **Relatório de paridade (o que foi conferido vs. o jogo antigo):** `PARITY.md`.
- **APK de teste:** `exports/primogo-teste.apk` (não vai para o Git; é gerado sob demanda).
- **Especificações completas (Reversa):** pasta `_reversa_sdd/` no repositório principal.

## O que ainda depende de você (não é código)

- Instalar o APK e testar no celular.
- Fornecer/validar a arte final e as URLs sociais (Facebook/Instagram), se quiser os botões.
- Rodar as ~10 partidas de conferência com o jogo antigo.
- Configurar a chave de release no preset e publicar na loja.
