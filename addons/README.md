# addons/

## GUT (Godot Unit Test) — obrigatório para a suíte de domínio

O GUT não é versionado neste repositório (fica sob `.gitignore` do addon por escolha).
Instale a versão 9.x (compatível com Godot 4) de uma destas formas:

- **AssetLib** dentro do editor: buscar "GUT", instalar em `res://addons/gut`.
- **git:** `git clone --depth 1 --branch v9.3.0 https://github.com/bitwes/Gut.git` e copiar
  `Gut/addons/gut` para `res://addons/gut`.

Depois, habilite o plugin em `Project → Project Settings → Plugins`.

O CI (`.github/workflows/ci.yml`) instala o GUT automaticamente antes de rodar os testes,
então não é necessário versioná-lo.
