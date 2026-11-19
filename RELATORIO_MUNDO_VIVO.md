# MozColheita — mundo vivo, dia/noite e entregas

Implementado na pasta principal do projecto; `fazenda-3d` e o arquivo anterior não foram alterados.

## Comandos e comportamento

- **L** avança até às 18:00; o próximo toque avança até às 06:00 do novo dia. Funciona a pé, nos veículos e na câmara livre. Não avança durante a negociação de um contrato.
- «L Dia/noite» no topo faz o mesmo. «+1 dia» e aceleração ×12 continuam disponíveis.
- Sol e céu azul durante o dia; céu escuro, iluminação lunar e interiores iluminados à noite. Canto de galo sintetizado quando começa cada novo dia.
- O mesmo relógio comanda crescimento, trabalho e prazos: avançar com L também pode vencer contratos e aplicar a multa contratada.
- A seta dourada aparece com mercadoria transportada na sacola, no reboque engatado ou no camião conduzido. Prioriza encomendas activas e escolhe um destino compatível próximo. A rota usa os portões e a rede de ruas e aparece no minimapa.
- As três empresas têm agora seis garagens de entrega: três sedes e três filiais. Os portões de enrolar abrem automaticamente. Entre com o camião e pare no cais para entregar a encomenda e vender o excedente aceite. Produtos incompatíveis ficam na carga.

## Mundo e acessos

- **55 casas**, **10 prédios** e **46 pessoas** no mapa.
- **20 veículos de ambiente**, com tractores, carros e camiões.
- As 32 novas casas dispersas têm lotes reservados; seis casas adicionais ficam nas quintas vizinhas.
- Os prédios adicionais estão separados do centro urbano. Todas as casas da comunidade e os prédios têm uma porta automática e um rés-do-chão mobilado acessível.
- As seis quintas vizinhas mantêm culturas e trabalhadores; receberam cercas e casas. Os agricultores usam animações de cultivo durante as pausas de trabalho.
- Novas ruas asfaltadas, caminhos de terra, acessos pedonais, um riacho com quatro pontes, 280 árvores e 150 pedras em MultiMesh.
- O terreno original continua a ser a base do mapa e a quinta do jogador não recebe parcelas preparadas.

## Ficheiros novos de implementação

- `scripts/daylight.gd`: céu, iluminação e síntese do canto de galo.
- `scripts/delivery_route.gd`: destino por produto/encomenda, grafo de ruas, seta e texto de navegação.
- `scripts/residence.gd`: portas automáticas, paredes com abertura e interiores acessíveis.
- `scripts/world_details.gd`: bairros dispersos, moradores, cercas, vias, vegetação, pedras e pontes.
- `icons/sol.svg`: ícone dos botões de calendário.
- `shaders/stream.gdshader`: água animada do riacho.

## Ficheiros existentes modificados

- `scripts/calendar.gd`: avanço por períodos e som de novo dia.
- `scripts/main.gd`: composição dos novos sistemas, tecla L e comandos.
- `scripts/hud.gd`: botão dia/noite e carregamento do logo como textura importada.
- `scripts/farmhouse.gd`: logo como textura importada, compatível com exportação.
- `scripts/factory.gd`: portões, marcações, acesso e entrega/venda na garagem.
- `scripts/community.gd`: ruas navegáveis, filiais e construção com interiores.
- `scripts/architecture.gd`: orientação das faces dos pisos, visíveis por cima.
- `scripts/crew.gd`: trabalhadores que terminam uma etapa afastam-se da parcela, evitando bloquear os colegas.
- `scripts/npc.gd`: animações de trabalho dos agricultores vizinhos.
- `scripts/landscape.gd`: distribuição exterior das árvores passa a ocorrer depois dos edifícios.
- `scripts/minimap.gd`: ruas, edifícios e rota de entrega.
- `scripts/traffic.gd`: rodas traseiras maiores, escape e engate visual dos tractores de ambiente.
- `validation/comunidade/test.gd`: expectativas actualizadas para o mapa ampliado.
- `README.md` e `COMO_JOGAR.txt`: comandos, fases e limitações.

## Validação

Registos, teste novo e capturas automatizadas em `validation/mundo_vivo/`; imagens em `preview/mundo_vivo/`. O teste novo verifica L, noite, manhã, canto, multas, contagens do mundo, ligação às seis garagens, selecção por produto, corredor de entrada e venda na filial. Também são executadas as regressões de prazos, logística e produção/entrega com dez trabalhadores.

## Limitações

Só o rés-do-chão dos prédios está acessível; os andares superiores são cenário, sem elevadores. O riacho é decorativo e acompanha o relevo, sem simulação de corrente/escavação. O tráfego adicional é de ambiente. Árvores exteriores são decoração; o serrote mantém as árvores de trabalho existentes na quinta. A seta planeia por ruas e obstáculos fixos conhecidos, sem prever trânsito ou cercas novas construídas pelo jogador. Permanecem os limites anteriores: mapa finito, uma equipa de produção activa e progresso apenas durante a sessão.

Resultados finais headless: `integracao-final.log` PASSOU (mundo vivo), `prazos.log` PASSOU (contratos), `logistica.log` PASSOU (veículos/armazém), `regressao-final.log` PASSOU (produção completa com dez trabalhadores). Os registos sem «final» preservam tentativas anteriores e o diagnóstico dos problemas corrigidos.

## Melhoria adicional — desenho dos carros

Criado `scripts/vehicle_art.gd`: carroçarias chanfradas, modelos distintos de carro/camião/tractor, cinco paletas de cor, vidros com reflexos pintados, grelhas, espelhos, faróis, jantes, parafusos e relevos nos pneus. Malhas estáticas são guardadas e reutilizadas para reduzir recursos e chamadas de desenho. Modificados `scripts/traffic.gd` e `scripts/truck.gd` para usar estes modelos e rodas. A cabine do camião do jogador permanece aberta para mostrar o condutor; colisões, controlos, carga e entregas mantêm o funcionamento anterior. Criado `validation/veiculos_design/capture.gd`; registos em `validation/veiculos_design/` e imagens em `preview/veiculos_design/`. README actualizado. Os carros do trânsito continuam a ser veículos de ambiente.

Validação do desenho dos veículos: `validation/veiculos_design/controlos.log`, `logistica.log` e `entregas.log` passaram. Capturas de arte com os mesmos modelos usados no jogo, em iluminação neutra: `visual.log` e quatro imagens (frota, carro, camião de trânsito e camião do jogador com condutor). A revisão visual corrigiu a orientação das faces frontais das carroçarias.
