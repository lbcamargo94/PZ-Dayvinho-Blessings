# Bênçãos do Dayvinho

Mod para **Project Zomboid Build 42** que adiciona o item **Dayvinho de Bolso** ao mundo do jogo. Quem o encontrar pode receber bênçãos temporárias que aumentam o ganho de XP nas habilidades de sobrevivência.

---

## Como funciona

### 1. Encontre o Dayvinho de Bolso

O item é **muito raro** (~0,1% de chance por container elegível) e pode aparecer em:

- Quartos de dormir e quartos infantis
- Guarda-roupas e cômodas
- Estantes de lojas de decoração e brinquedos
- Caixotes e balcões de loja

Mantenha-o no inventário. Ele não precisa estar equipado.

### 2. Receba uma bênção

A cada **level-up de qualquer habilidade**, o jogo rola uma chance de ativar uma bênção:

| Tipo | Chance | Duração |
|------|--------|---------|
| Bênção normal | 0,5% | 10 minutos reais |
| Bênção lendária | 0,05% | 10 minutos reais |

Quando ativada, o personagem reage com uma mensagem de bênção.

> **Cooldown:** 12 horas **in-game** entre bênçãos. O cooldown persiste ao salvar e recarregar.

### 3. Ganhe XP bônus

Enquanto a bênção estiver ativa, cada level-up nas **habilidades suportadas** concede XP extra automaticamente:

| Habilidade | Bônus normal | Bônus lendário |
|------------|-------------|----------------|
| Pesca | +150 XP | +225 XP |
| Carpintaria | +100 XP | +150 XP |
| Agricultura | +100 XP | +150 XP |
| Mecânica | +125 XP | +187 XP |
| Metalurgia | +100 XP | +150 XP |
| Manutenção | +100 XP | +150 XP |
| Culinária | +125 XP | +187 XP |
| Costura | +125 XP | +187 XP |

Ao expirar, o personagem emite uma mensagem de encerramento.

---

## O Item

| Propriedade | Valor |
|-------------|-------|
| ID | `Base.DayvinhoDeBolso` |
| Peso | 0,1 |
| Ícone | `LawnGnome` (anão de jardim existente no jogo) |
| Empilhável | Não |
| Equipável | Não |

---

## Estrutura do projeto

```
Contents/mods/DayvinhoBlessings/42/
├── mod.info
└── media/
    ├── scripts/
    │   └── items_dayvinho.txt          — definição do item
    └── lua/
        ├── shared/
        │   ├── DayvinhoBlessings/
        │   │   └── Distributions.lua   — spawn do item no mundo
        │   └── Translate/
        │       ├── EN/
        │       │   ├── ItemName.json   — nome em inglês
        │       │   ├── Tooltip.json    — tooltip em inglês
        │       │   └── UI.json         — mensagens em inglês
        │       └── PTBR/
        │           ├── ItemName.json   — nome em português
        │           ├── Tooltip.json    — tooltip em português
        │           └── UI.json         — mensagens em português
        └── client/
            └── DayvinhoBlessings/
                ├── Main.lua            — sistema de bênçãos
                └── Messages.lua        — chaves de tradução por habilidade
```

---

## Arquivos em detalhe

### `mod.info`
Metadados do mod. ID: `DayvinhoBlessings`, compatível com PZ 42.

### `items_dayvinho.txt`
Define `Base.DayvinhoDeBolso` no módulo `Base` do jogo. O `DisplayName` é o fallback em inglês; as traduções reais vêm dos JSON em `Translate/`.

### `Distributions.lua`
Hook no evento `OnFillContainer`. Verifica se o tipo de cômodo e de container são elegíveis; se sim, rola 0,1% de chance e adiciona o item. Roda no contexto **shared** (funciona em singleplayer e multiplayer).

### `Messages.lua`
Tabela de chaves de tradução por categoria de habilidade (`Fishing`, `Woodwork`, `Farming`, `Mechanics`, `MetalWelding`, `Maintenance`, `Cooking`, `Tailoring`, `Legendary`, `Generic`, `End`). Expõe três funções:
- `getForSkill(skillType)` — retorna uma mensagem aleatória para a habilidade indicada
- `getLegendary()` — retorna uma mensagem de bênção lendária
- `getEnd()` — retorna uma mensagem de encerramento

Todas as strings usam `getText(key)`, o sistema padrão de localização do PZ.

### `Main.lua`
Núcleo do sistema de bênçãos. Roda no contexto **client**.

**Eventos utilizados:**

| Evento PZ | Função |
|-----------|--------|
| `OnGameStart` | Reseta estado, constrói cache de perks, inicia grace period |
| `LevelPerk` | Verifica trigger de bênção e aplica XP bônus |
| `OnTick` | Detecta expiração da bênção e notifica o jogador |

**Grace period:** os primeiros 120 ticks após `OnGameStart` são ignorados para evitar disparos falsos ao carregar um save.

**Persistência:** o horário (em horas in-game) da última bênção é salvo via `player:getModData()["DayvinhoBlessings"].lastBlessingHours`, que o PZ persiste automaticamente no save.

**Cache de perks:** `buildPerkCache()` itera todos os perks do jogo via `Perks.fromIndex` e `PerkFactory.getPerk` para criar um mapa `{ [typeString] = perkEnum }`. Isso evita iterar todos os perks a cada level-up.

### `Translate/EN/` e `Translate/PTBR/`
Arquivos JSON no formato padrão do PZ B42. O jogo faz merge automático com as traduções base. Idiomas sem arquivo próprio neste mod recebem o fallback EN.

**Arquivos:**
- `ItemName.json` — chave `"Base.DayvinhoDeBolso"`
- `Tooltip.json` — chave `"Tooltip_DayvinhoDeBolso"`
- `UI.json` — 43 chaves `UI_DayBless_*` (4 por habilidade + legendária, genérica e encerramento)

---

## Compatibilidade

- **Build:** Project Zomboid B42.19+
- **Multiplayer:** compatível (distribuição e bênçãos são client-side por jogador)
- **Outros mods:** não modifica arquivos base, sem conflito esperado

---

## Histórico de versões

| Versão | Descrição |
|--------|-----------|
| `v1.0.0` | Implementação inicial: item, spawn, sistema de bênçãos, mensagens em PT-BR |
| `v1.0.1` | Ícone trocado para `LawnGnome` |
| `v1.0.2` | Corrigido: `GardenGnome` não existe nos texture packs; ícone correto é `LawnGnome` |
| `v1.0.3` | Corrigido: typo `DayvinhoDeBollo` → `DayvinhoDeBolso` em todos os arquivos |
| `v1.1.0` | Conversão para padrão EN do jogo + sistema de tradução JSON (EN + PTBR) |