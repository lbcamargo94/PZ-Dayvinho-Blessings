-- ============================================================
--  Messages.lua — Mensagens motivacionais por habilidade
-- ============================================================

DayvinhoBlessings_Messages = {}

local _messages = {
    Fishing = {
        "Dayvinho sussurra: 'Os peixes não resistem a você!'",
        "Com Dayvinho ao seu lado, o rio revela seus segredos.",
        "Dayvinho abençoa seu anzol com sorte divina!",
        "Os peixes sentem a presença de Dayvinho e se rendem.",
    },
    Woodwork = {
        "Dayvinho guia suas mãos: 'Construa com fé!'",
        "A madeira cede à sabedoria de Dayvinho!",
        "Cada corte, uma bênção. Cada tábua, um milagre.",
        "Dayvinho aprova sua carpintaria. Continue!",
    },
    Farming = {
        "Dayvinho abençoa a terra. A colheita será farta!",
        "Com fé e adubo, tudo cresce. Dayvinho aprova!",
        "A plantação prospera sob os olhares de Dayvinho.",
        "Dayvinho sussurra: 'A terra te nutre. Nutra-a de volta.'",
    },
    Mechanics = {
        "Dayvinho murmurou: 'Aperte mais um pouco...'",
        "Mecanismos complexos? Não para um abençoado por Dayvinho!",
        "Os motores cantam quando Dayvinho está presente.",
        "Dayvinho ilumina cada parafuso, cada engrenagem.",
    },
    MetalWelding = {
        "O fogo da forja brilha mais com a bênção de Dayvinho!",
        "Dayvinho sussurra: 'O metal obedece ao verdadeiro mestre.'",
        "Cada solda, uma obra de arte abençoada.",
        "Dayvinho aprecia quem domina o fogo e o aço.",
    },
    Maintenance = {
        "Dayvinho cuida das suas ferramentas como você cuida dele!",
        "Equipamentos duram mais sob a proteção de Dayvinho.",
        "Com Dayvinho, nada se desgasta... por enquanto.",
        "Dayvinho sussurra: 'Cuide bem do que você tem.'",
    },
    Cooking = {
        "Dayvinho aprova! Um toque de fé no tempero.",
        "Os mortos-vivos não resistem ao aroma desta receita abençoada.",
        "Cozinhar é uma arte. Com Dayvinho, é um milagre.",
        "Dayvinho lhe ensina o tempero secreto da sobrevivência.",
    },
    Tailoring = {
        "Dayvinho alinha cada ponto com precisão divina!",
        "Roupas feitas com fé duram mais que qualquer tecido.",
        "As agulhas dançam com a bênção de Dayvinho!",
        "Dayvinho sussurra: 'Vista-se para sobreviver.'",
    },
    Legendary = {
        "BENCAO LENDARIA! Dayvinho sorri para voce, escolhido!",
        "Dayvinho concedeu sua graca maxima! Aproveite bem!",
        "Uma bencao lendaria! Dayvinho escolheu voce hoje!",
    },
    Generic = {
        "Dayvinho sorriu para voce. Sinta a bencao!",
        "Um calor suave emana do Dayvinho de Bolso...",
        "Dayvinho sussurra palavras de encorajamento.",
        "A sorte esta do seu lado por alguns momentos!",
        "Dayvinho acredita em voce. Hora de brilhar!",
    },
    End = {
        "A bencao de Dayvinho se dissipou...",
        "Dayvinho descansou. Ate a proxima bencao.",
        "O poder de Dayvinho retornou ao bolicho.",
    },
}

function DayvinhoBlessings_Messages.getForSkill(skillType)
    local list = _messages[skillType] or _messages.Generic
    return list[math.random(#list)]
end

function DayvinhoBlessings_Messages.getLegendary()
    local list = _messages.Legendary
    return list[math.random(#list)]
end

function DayvinhoBlessings_Messages.getEnd()
    local list = _messages.End
    return list[math.random(#list)]
end