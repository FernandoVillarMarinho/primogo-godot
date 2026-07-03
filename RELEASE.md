# Release / Cutover — Primogo (Godot 4, Android)

> Tarefa 15 do `reconstruction-plan.md`. Derivado de `_reversa_sdd/migration/cutover_plan.md`.
> Jogo **offline single-player**: não há cutover de tráfego. "Rollback" = **não publicar** /
> despublicar. Este documento é o artefato versionado; a execução (build assinado, testes
> em dispositivo, go/no-go) é interativa e tem **owner = Villar**.

## Estado do gate de entrada

- [x] **Casca completa** — 5 features + 3 autoloads, 105 testes GUT verdes, jogo inicializável (`run/main_scene=splash`).
- [x] **126→122 LevelResources** extraídos e validados (G-01 resolvida; decisão do tile 27 registrada na T03).
- [x] **Conteúdo sonoro definido** — 14 `.ogg` extraídos do APK em `assets/audio/` (G-03 caminho (a): AudioStreamPlayer nativo).
- [x] **Cheat inerte em produção** — `ProgressionStore.dev_unlock_all` guardado por `OS.is_debug_build()` (AD-06/BR-029/L-11). Não há gatilho de UI ligado; em release é no-op por construção.
- [x] **Share atrás de config** — `config/social.cfg` nasce vazio; botões ocultos (AD-08). Não bloqueia release (G-02).
- [ ] **Suíte de paridade 100% verde** — **BLOQUEADO pela Tarefa 16** (Fase 3). Depende dos golden files do APK (COD-004/009).
- [ ] **Validação visual dos placeholders** — sprites + `grid_calibration.tres` + bitmap fonts contra os prints (deferido das features T10–T14).
- [ ] **Build Android assinado (keystore NOVO)** testado em ≥ 2 dispositivos reais — passo manual do Villar (abaixo).

## Gerar o keystore NOVO (não reusar o do legado)

> O keystore do repositório legado pertence ao pacote antigo — tratar como app novo (cutover_plan §Notas).
> **Nunca versionar** o `.keystore` nem senhas (já cobertos pelo `.gitignore`: `*.keystore`, `export*.cfg`).

```sh
keytool -genkeypair -v \
  -keystore primogo-release.keystore \
  -alias primogo -keyalg RSA -keysize 2048 -validity 10000 \
  -storetype PKCS12
# Guardar storepass/keypass fora do repo (gerenciador de senhas).
```

## Export Android (Godot 4.7)

1. **Editor → Project → Export → Add… → Android.** Requer: Android Build Templates instalados (`Project → Install Android Build Template`), Android SDK + JDK configurados em `Editor Settings → Export → Android`.
   - **API alvo (2026):** target/compile **API 35 (Android 15)** — o Google Play exige target API ≥ 35 para publicar desde ago/2025. Instalar com:
     ```powershell
     sdkmanager "platform-tools" "build-tools;35.0.0" "platforms;android-35"
     ```
     (Se o template de build do Godot 4.7 fixar outro `compileSdk` no `config.gradle`, alinhar; o **target** precisa ser ≥ 35 para a Play.)
2. **Options** a fixar no preset (mobile, orçamento zero — sem .NET):
   - `package/unique_name = com.villar.primogo` (definir o domínio final do Villar)
   - `package/name = Primogo`
   - `screen/orientation = Portrait` (bate com `handheld/orientation=1`)
   - `graphics/opengl_debug = off`; renderer já é `gl_compatibility` (`project.godot`)
   - Ícone/splash: apontar para os assets finais na validação visual.
3. **Signing (release):** apontar `keystore/release` para `primogo-release.keystore` e `keystore/release_user = primogo`; as senhas via variáveis de ambiente do editor, nunca no `.cfg` versionado.
   - `export_presets.cfg` é **gitignored** de propósito (contém caminhos de máquina/segredos): cada dev recria localmente seguindo estes passos.
4. Build: **Export Project** (release, não debug) → `primogo-release.apk` / `.aab` em `exports/` (também gitignored).

## Passos do release (owner = Villar)

| # | Passo | Duração |
|---|-------|---------|
| 1 | Congelar specs (tag no repo) + gerar build release | 1 dia |
| 2 | Smoke test manual (ver script abaixo) | 1 dia |
| 3 | Faixa de teste interno no Play Console (ou APK direto) | 2–3 dias |
| 4 | Beta fechado (dispositivos variados, progressão longa) | 1 semana |
| 5 | Correções do beta + rebuild | variável |
| 6 | Promoção à produção | 1 dia |

## Smoke test manual (passo 2)

- Onboarding: tutorial 1 (`UP→RIGHT→DOWN→LEFT`) e tutorial 2 (`RIGHT→LEFT→[balão]→LEFT`).
- Uma fase de cada layout (5x5, 6x7, 7x7, 7x8, 8x8).
- Economia: vitória (recompensa + desbloqueio), derrota (reset punitivo), gate de entrada (2★/3★/grátis/recusa com balanço).
- Toggles de som (música/efeitos) persistem entre sessões.
- Pausa / retry / próximo; 12ª fase → volta à seleção.
- Save sobrevive a fechar e reabrir o app (`save_version`).

## Critérios go/no-go (antes do passo 6)

- **GO** se: zero crashes no beta; paridade confirmada nos fluxos do smoke; progressão persiste entre sessões.
- **NO-GO** se: qualquer crash reproduzível; regra de economia divergente do oráculo; perda de save entre sessões.

**Registro go/no-go:** _(preencher na decisão — data, dispositivos, resultado)_

## Rollback

- **Antes da produção:** nada a fazer — faixas de teste são descartáveis.
- **Após a produção:** despublicar ou reverter para a faixa anterior. Sem dados de servidor. Saves locais versionados desde o 1º release (`save_version`) para proteger updates futuros.

## Alvos secundários (opcional)

Web/desktop (exportações Godot) repetem os passos 2–6 de forma abreviada; **Android é o gate principal**.
