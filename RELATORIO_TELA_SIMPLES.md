# Tela simples, varanda e iluminação — 22/11/2026

Implementação na pasta principal MozColheita, em GDScript tipado para Godot 4.6.

## Alterações

- Retirados da tela de jogo os botões H/K/L/V/F5 do topo, lista lateral de ferramentas, ícone da ferramenta activa, resumo permanente das empresas/encomendas e missão dos tomates, legendas fixas WASD/K/etc. Os atalhos e sistemas continuam disponíveis. H abre gestão/missões e K abre o kit; L alterna noite/manhã, V controla a câmara livre e F5 guarda. Não foram apagados contratos, objectivos ou progresso.
- Permanecem vida, alimentação, energia, saldo, logótipo e minimapa. Apenas avisos temporários aparecem sobre o campo. Ao conduzir ou pilotar aparecem os ícones de acção com as teclas ao centro e estado do veículo. O botão contextual B de abastecimento permanece no veículo com semeadora.
- Varanda elevada na casa principal: pavimento, cobertura existente, corrimão com passagem central, balaústres, dois bancos e rampa suave. O jogador começa em (-8, -34), diante da rampa. O acesso foi verificado fisicamente com o controlador, sem saltar.
- Luzes nocturnas nos três tractores, camião, 20 veículos de trânsito e três drones: lentes emissivas, faróis dianteiros que iluminam o chão, luzes traseiras vermelhas; drones com sinais de navegação e foco descendente. Funcionam com o calendário, incluindo L e retoma da gravação. Faróis desligam durante o dia. Sem sombras e com corte gradual por distância para reduzir custo.
- Rotas dos veículos sobre o eixo das estradas: circuito urbano e circuito exterior, com veículos distribuídos pelo perímetro, no mesmo sentido para evitar encontros frontais. Retiradas deslocações para bermas e ligações diagonais fora das ruas. Aproximação aos pontos limitada pela distância restante para não ultrapassar curvas.

## Ficheiros

Criado: `scripts/vehicle_lights.gd`.

Modificados nesta actualização: `scripts/hud.gd`, `scripts/driving_hud.gd`, `scripts/farmhouse.gd`, `scripts/tractor.gd`, `scripts/truck.gd`, `scripts/drone.gd`, `scripts/traffic.gd`, `scripts/community.gd`, `scripts/world_details.gd`, `README.md`, `COMO_JOGAR.txt`.

Validação criada: `validation/simplicidade/test.gd`, `validation/simplicidade/capture.gd`, `.gdignore` e registos de execução. Actualizadas expectativas de interface em `validation/diversao/hud_test.gd` e de início em `validation/comunidade/test.gd`.

## Verificação

- Importação headless: concluída em Godot 4.6, sem erros de script (`importacao.log`).
- `test-final.log`: PASSOU, zero falhas. HUD simples, H/K/L funcionais, necessidades, persistência, condução/travão, ícones, drone, amostragem de cada metro das 20 rotas incluindo fecho, 27 sistemas de luz com estados diurno/nocturno e subida física à varanda.
- `regressao.log`: COMUNIDADE PASSOU, zero falhas. Avatares, agricultura, entrega na garagem, pagamento único e equipa de dez trabalhadores até carregar o camião.
- Três capturas revistas do jogo: casa/varanda, tractor nocturno e drone nocturno em `preview/simplicidade/`; execução em `validation/simplicidade/visual.log`. A captura adicional da estrada foi descartada por a câmara ficar dentro de um edifício; as rotas foram verificadas por amostragem geométrica no teste headless.

## Limites

O trânsito continua a ser ambiente cinemático: pára perante obstáculos e não simula mudanças de faixa ou ultrapassagens. Os faróis iluminam superfícies; não criam feixes volumétricos. A varanda é exterior e o interior da casa principal mantém a implementação existente. Gravações anteriores conservam a posição guardada do jogador; a nova posição inicial aplica-se ao início de sessão.
