# Primogo — resumo para o Villar

*Atualizado em 03/07/2026. Linguagem simples, sem jargão.*

## O que é isto

O **Primogo** (seu jogo de puzzle de números primos, originalmente feito em Unity) foi
**reconstruído do zero na Godot 4** — um motor de jogos gratuito e mais leve, ideal para
Android. A reconstrução partiu das especificações que o Reversa extraiu do jogo antigo.

## Em que pé está (o essencial)

- ✅ **O jogo está funcionando por inteiro, por dentro.** Toda a lógica (as regras do
  puzzle, a energia, as estrelas, o desbloqueio de fases, os tutoriais, os menus, o som)
  está pronta e **testada automaticamente** — são **140 testes**, todos passando.
- ✅ **As 122 fases originais** foram extraídas do jogo antigo e recriadas.
- ✅ **Os sons** (14 efeitos e músicas) foram extraídos e ligados.
- ✅ **A arte original está DENTRO do jogo** (10/07/2026): as imagens que você trouxe
  (pasta `ImagensPrimogo`) foram todas importadas — a chama do jogador, os blocos de
  gelo, o dragão laranja, os números desenhados, os cenários de cada tamanho de
  tabuleiro, o menu, a seleção de fases, o tutorial com a mãozinha. **Nada mais de
  retângulos coloridos.**
- ✅ **O APK de teste foi gerado e assinado com o visual novo** — o jogo abre e roda no
  Android com a cara do jogo original.
- ⏳ **Falta só o ajuste fino do visual**: comparar tela a tela com as capturas do jogo
  antigo e corrigir pequenas posições/tamanhos (tudo já ficou parametrizado para isso).

Em uma frase: **o carro está pronto, pintado e rodando; falta polir os detalhes da pintura.**

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
