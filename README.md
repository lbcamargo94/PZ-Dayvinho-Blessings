# Bênçãos do Dayvinho

Mod para **Project Zomboid Build 42** que adiciona o item **Dayvinho de Bolso** ao mundo do jogo. Carregue-o no inventário e receba bênçãos temporárias a cada 1 dia in-game — ou uma maldição, se você se comportar mal.

---

## Como funciona

### 1. Encontre o Dayvinho de Bolso

O item é raro (~**1% de chance** por container elegível) e pode aparecer em:

- Quartos de dormir e quartos infantis
- Guarda-roupas e cômodas
- Estantes de lojas de decoração e brinquedos
- Caixotes e balcões de loja

Mantenha-o no inventário. Ele não precisa estar equipado.

### 2. Receba uma bênção a cada 1 dia in-game

A cada **1 dia in-game** (≈ 24 minutos reais na velocidade padrão), o Dayvinho verifica se uma bênção será concedida. **Sono e avanço de tempo não contam** — o timer usa o relógio real.

| Etapa | Chance |
| --- | --- |
| Dayvinho coopera | 50% |
| Bênção **Lendária** (se cooperou) | 5% |
| Bênção **Normal** (se cooperou) | 95% |

> **Cooldown:** 24 horas **in-game** entre bênçãos. Persiste ao salvar e recarregar.

### 3. Tipos de bênção (24 no total)

As bênçãos são sorteadas aleatoriamente por peso. A versão **Lendária** tem duração 1,5× maior e efeitos mais intensos.

| Bênção | Efeito | Duração |
| --- | --- | --- |
| **XP Boost** | +10% / +20% de XP em **1 habilidade sorteada** das 35 | 15 min |
| **Sorte** | +10 / +15 de Luck | 30 min |
| **Achado Valioso** | Raio de foraging +15% / +22% | 10 min |
| **Presente do Jardim** | 1 item aleatório (2 no lendário) | Instantâneo |
| **Barriga Cheia** | Reduz fome gradualmente | 30 min |
| **Água Fresca** | Reduz sede em 50% / 70% | Instantâneo |
| **Descanso Revigorante** | Reduz fadiga em 15% / 25% | Instantâneo |
| **Espírito Forte** | Reduz estresse e tédio gradualmente | 30 min |
| **Bom Humor** | Reduz infelicidade em 25% / 40% | Instantâneo |
| **Paz Interior** | Reduz estresse em 30% / 45% | Instantâneo |
| **Sono Tranquilo** | Próximo sono será mais reparador | Instantâneo |
| **Mãos Habilidosas** | Velocidade de ação +10% / +15% | 20 min |
| **Pescador Abençoado** | Multiplicador de pesca +10% / +15% | 30 min |
| **Colheita Feliz** | Plantas crescem mais rápido (+ bônus de espírito) | 30 min |
| **Lenhador Sortudo** | Mais toras por corte (+ bônus de endurance) | 20 min |
| **Passos Leves** | Menos ruído ao se mover | 20 min |
| **Olhos Atentos** | Raio de foraging +12% / +20% | 20 min |
| **Instinto de Sobrevivência** | Reduz pânico em 10% / 20% | 10 min |
| **Mochila Organizada** | Reduz desconforto gradualmente (carga mais leve) | 30 min |
| **Cura Natural** | Recuperação de ferimentos gradual | 30 min |
| **Corpo Resistente** | Restaura endurance gradualmente | 20 min |
| **Bênção da Coragem** | Reduz pânico gradualmente | 30 min |
| **Sol Abençoado** | Para a chuva (se estiver chovendo) | Instantâneo |
| **Arco-Íris** | Narrativo + redução leve de infelicidade | Instantâneo |

Ao expirar, o personagem recebe uma mensagem de encerramento.

---

### 4. Sistema de Maldições

Se o jogador tiver o Dayvinho no inventário e executar uma das **5 ações proibidas** via menu de contexto, uma maldição é ativada imediatamente.

**Ações que invocam maldição:**

| Ação | Gatilho no menu |
| --- | --- |
| Queimar | Burn / Queimar |
| Destruir | Destroy / Destruir |
| Descartar | Trash / Discard / Lixo |
| Explodir | Explode / Detonar |
| Atropelar | Run Over / Atropelar |

**Efeitos possíveis (1 sorteado aleatoriamente, duração 10 minutos reais):**

| Maldição | Efeito |
| --- | --- |
| Má Sorte | -10 de Luck |
| Pânico Acelerado | Pânico aumenta gradualmente |
| Fome Repentina | +20% de fome imediata |
| Sede Repentina | +20% de sede imediata |
| Corpo Fraco | -10% de endurance imediata |
| Mais Barulho | Pânico aumenta gradualmente (ruído surrogate) |
| Infelicidade | +20% de infelicidade imediata |
| Estresse | +15% de estresse imediato |
| Alucinação | Narrativo + infelicidade leve |

---

## O Item

| Propriedade | Valor |
| --- | --- |
| ID | `Base.DayvinhoDeBolso` |
| Peso | 0,1 |
| Ícone | `LawnGnome` (anão de jardim existente no jogo) |
| Empilhável | Não |
| Equipável | Não |

---

## Estrutura do projeto

```
DayvinhoBlessings/
├── workshop.txt                        — metadados para publicação na Steam Workshop
├── preview.png                         — imagem de capa do Workshop (256×256)
└── Contents/mods/DayvinhoBlessings/42/
    ├── mod.info
    ├── poster.png                      — imagem exibida no menu de mods do jogo
    └── media/
        ├── scripts/
        │   └── items_dayvinho.txt      — definição do item
        └── lua/
            ├── shared/
            │   ├── DayvinhoBlessings/
            │   │   ├── Logger.lua      — sistema de logs do mod (INFO/WARN/ERROR/DEBUG)
            │   │   └── Distributions.lua — spawn do item no mundo (1%)
            │   └── Translate/
            │       ├── EN/
            │       │   ├── ItemName.json — nome em inglês
            │       │   ├── Tooltip.json  — tooltip em inglês
            │       │   └── UI.json       — ~120 chaves de mensagem
            │       └── PTBR/
            │           ├── ItemName.json — nome em português
            │           ├── Tooltip.json  — tooltip em português
            │           └── UI.json       — ~120 chaves em português
            └── client/
                └── DayvinhoBlessings/
                    ├── Messages.lua    — tabela de chaves e funções getText
                    ├── Blessings.lua   — 24 tipos de bênção (apply/tick/remove)
                    ├── Curses.lua      — 9 efeitos de maldição + hook de menu
                    └── Main.lua        — motor de timer, efeitos e eventos
```

---

## Arquivos em detalhe

### `Logger.lua`

Módulo centralizado de logging do mod. Roda no contexto **shared** (disponível para todos os scripts). Expõe:

- `Log.info(msg)` / `Log.warn(msg)` / `Log.error(msg)` / `Log.debug(msg)`
- `Log.try(fn, contexto)` — wrapper de `pcall` que loga automaticamente erros com o contexto indicado
- `Log.setLevel("DEBUG")` — ativa modo verboso em runtime para debug

Todas as mensagens saem com o prefixo `[DayvinhoBlessings]` e aparecem no console do jogo (F11) e nos arquivos de log em `Zomboid/Logs/`.

### `Distributions.lua`
Hook em `OnFillContainer`. Verifica cômodo e container elegíveis; rola **1%** de chance e adiciona o item. Roda no contexto **shared** (singleplayer e multiplayer).

### `Messages.lua`
Tabela de chaves `UI_DayBless_*` e `UI_DayCurse_*`. Expõe:
- `getForBlessing(id)` — mensagem aleatória para o tipo de bênção
- `getFail()` — mensagem de falha do timer
- `getEnd()` — mensagem de expiração de bênção
- `getCurseMsg(triggerType)` — mensagem temática por tipo de ação maldita
- `getCurseEnd()` — mensagem de expiração de maldição

### `Blessings.lua`
Define os 24 tipos de bênção em uma tabela com peso, duração e funções `apply / onTick / onRemove`. Expõe `pickRandom()` (seleção ponderada) e `getDef(id)`.

### `Curses.lua`
Define os 9 efeitos de maldição. Registra `OnFillWorldObjectContextMenu` para detectar as 5 ações proibidas no menu de contexto e acionar `DayvinhoBlessings_Main.triggerCurse()`.

### `Main.lua`
Motor central. Roda no contexto **client**.

**Eventos utilizados:**

| Evento PZ | Função |
| --- | --- |
| `OnGameStart` | Reseta estado, constrói cache de perks |
| `OnTick` | Timer de 1 dia in-game, processa efeitos ativos (tick/expiração) |
| `LevelPerk` | Aplica XP bônus quando `xp_boost` está ativo |

**Timer:** usa `os.time()` com intervalo de 1440 segundos reais (1 dia in-game a 60x). Durante o sono, o tempo real passa devagar — o sono efetivamente não conta para o timer.

**Efeitos ativos:** tabela `_activeEffects` com lifecycle `{id, kind, endTime, onTick, onRemove, data}`. Bênçãos e maldições coexistem.

**XP Boost:** quando ativo, o handler `LevelPerk` calcula `level × 75 × mult` para cada habilidade que sobe de nível.

**Persistência:** `player:getModData()["DayvinhoBlessings"].nextBlessingWorldHours` guarda o horário in-game do próximo cooldown, sobrevivendo a saves e reloads.

### `Translate/EN/` e `Translate/PTBR/`
Arquivos JSON no formato padrão do PZ B42. Idiomas sem arquivo próprio recebem fallback EN.

- `ItemName.json` — chave `"Base.DayvinhoDeBolso"`
- `Tooltip.json` — chave `"Tooltip_DayvinhoDeBolso"`
- `UI.json` — ~120 chaves (`UI_DayBless_*` e `UI_DayCurse_*`)

---

## Compatibilidade

- **Build:** Project Zomboid B42.19+
- **Multiplayer:** compatível (bênçãos e maldições são client-side por jogador)
- **Outros mods:** não modifica arquivos base, sem conflito esperado

---

## Histórico de versões

| Versão | Descrição |
| --- | --- |
| `v1.0.0` | Implementação inicial: item, spawn, bênçãos de XP por level-up, PT-BR |
| `v1.0.1` | Ícone trocado para `LawnGnome` |
| `v1.0.2` | Corrigido: `GardenGnome` não existe nos texture packs |
| `v1.0.3` | Corrigido: typo `DayvinhoDeBollo` → `DayvinhoDeBolso` |
| `v1.1.0` | Conversão para padrão EN + sistema de tradução JSON (EN + PTBR) |
| `v2.0.0` | Rework completo: timer de 6h, 24 tipos de bênção com efeitos reais, sistema de maldições com 5 gatilhos e 9 efeitos, ~120 chaves de tradução |
| `v2.0.1` | XP Boost agora afeta apenas 1 habilidade sorteada (não todas as 35) |
| `v2.0.2` | Timer ajustado de 6h → 1 dia in-game (1440s reais) |
| `v2.0.3` | API de stats migrada B41→B42 (CharacterStat enum); hook de maldições corrigido para `OnFillWorldObjectContextMenu` |
| `v2.0.4` | XP Boost corrigido: cache de perks usa `Perks.getMaxIndex()` com loop seguro; handler `LevelPerk` usa `tostring(perk)` para match do cache; XP aplicado via `player:getXp():AddXP()` (B42) |
| `v2.0.5` | Sistema de logs exclusivo do mod: `Logger.lua` com níveis INFO/WARN/ERROR/DEBUG, prefixo `[DayvinhoBlessings]`, wrapper `Log.try()` para pcall com log automático de erros |
| `v2.0.6` | Compatibilidade B42.19: `containsType` → `containsTypeRecurse` (crítico); `sun`: `climate:isRaining/stopRaining` → `RainManager`; `backpack`: `setMaxWeight` (inexistente em B42) → surrogate DISCOMFORT |
| `v2.0.7` | Reorganização da estrutura do projeto: mod movido para `DayvinhoBlessings/` (padrão Workshop); `poster.png` adicionado ao `mod.info` |
| `v2.0.8` | Fix crítico: `next()` não disponível no Kahlua do PZ → substituído por check com `pairs` no rebuild do cache de perks |
| `v2.0.9` | Fix crítico: `math.random()` não existe no contexto server do PZ → substituído por `ZombRandFloat(0,1)` em `Distributions.lua` (o `OnFillContainer` roda server-side) |
