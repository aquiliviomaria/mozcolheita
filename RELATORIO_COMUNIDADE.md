# Relatório MozColheita — comunidade, personagens e contratos

Implementação na pasta principal MozColheita. Data: 19/11/2026. GDScript tipado, Godot 4.6 estável, renderizador Compatibility. Sem dependências externas novas.

## Resultado

- Dois avatares 3D seleccionáveis, inspirados no logótipo, com rig e sete animações procedurais partilhados; condutor, aperto de mão e kit mantidos.
- Casa principal com logótipo e ponto inicial; terreno mais verde e suave, cidade nivelada; crescimento de três dias e controlo de tempo/câmara.
- 17 casas, seis prédios de 10/20/40 pisos, estradas com marcações, 26 NPCs, doze veículos de ambiente e 24 animais em três criações.
- Camião de 500 unidades, caixas abertas com produtos e contagem, empresas especializadas e entrega física na garagem.
- Uma equipa de até dez trabalhadores, contratação explícita, orçamento variável, etapas autónomas e carga final; três tractores livres podem ser usados pela equipa.
- Prazos de encomendas e serviços, urgência, recompensa e multa apresentados antes da aceitação, tempo restante, aviso de 20%, multa única automática e histórico de sucesso/falha.

## Ficheiros de implementação criados

- `scripts/architecture.gd`
- `scripts/avatar.gd`
- `scripts/calendar.gd`
- `scripts/community.gd`
- `scripts/crew.gd`
- `scripts/deliveries.gd`
- `scripts/farmhouse.gd`
- `scripts/produce_crate.gd`
- `scripts/produce_mesh.gd`
- `scripts/traffic.gd`
- `scripts/truck.gd`

## Ficheiros existentes modificados

- `COMO_JOGAR.txt`
- `README.md`
- `scripts/camera.gd`
- `scripts/contract.gd`
- `scripts/crop.gd`
- `scripts/economy.gd`
- `scripts/factory.gd`
- `scripts/hud.gd`
- `scripts/landscape.gd`
- `scripts/layout.gd`
- `scripts/main.gd`
- `scripts/minimap.gd`
- `scripts/navigation.gd`
- `scripts/npc.gd`
- `scripts/player.gd`
- `scripts/tasks.gd`
- `scripts/terrain.gd`
- `scripts/tools.gd`
- `scripts/tractor.gd`
- `scripts/trailer.gd`
- `scripts/village.gd`
- `scripts/warehouse.gd`
- `shaders/ground.gdshader`

## Documentação, testes, registos e capturas criados

- `RELATORIO_COMUNIDADE.md` (este relatório)
- `preview/comunidade/moz-comunidade-agricultor.png`
- `preview/comunidade/moz-comunidade-agricultora.png`
- `preview/comunidade/moz-comunidade-armazem.png`
- `preview/comunidade/moz-comunidade-camiao.png`
- `preview/comunidade/moz-comunidade-casa.png`
- `preview/comunidade/moz-comunidade-cidade.png`
- `preview/comunidade/moz-comunidade-entregas.png`
- `preview/comunidade/moz-comunidade-grupo.png`
- `preview/comunidade/moz-comunidade-historico.png`
- `preview/comunidade/moz-comunidade-menu-homem.png`
- `preview/comunidade/moz-comunidade-menu-mulher.png`
- `preview/comunidade/moz-comunidade-prazos.png`
- `validation/comunidade/.gdignore`
- `validation/comunidade/01-personagens.log`
- `validation/comunidade/02-quinta.log`
- `validation/comunidade/03-mundo.log`
- `validation/comunidade/04-entregas.log`
- `validation/comunidade/05-grupos.log`
- `validation/comunidade/06-prazos.log`
- `validation/comunidade/capture.gd`
- `validation/comunidade/deadlines.gd`
- `validation/comunidade/integracao.log`
- `validation/comunidade/logistica.log`
- `validation/comunidade/percurso.log`
- `validation/comunidade/prazos.log`
- `validation/comunidade/regressao.log`
- `validation/comunidade/test.gd`
- `validation/comunidade/veiculos.log`
- `validation/comunidade/visual.log`

## Verificações

Arranques C1–C6 aprovados sem erros. Seis suites aprovadas: sistemas, veículos, percurso/ciclo completo, logística, integração da comunidade/equipa e prazos. A suite da equipa executa efectivamente preparação, plantio, rega, crescimento, colheita e carga de 100 unidades por dez trabalhadores, com tractores indisponíveis para verificar o trabalho manual. Os testes de veículos/logística verificam uso e procura/engate físico de equipamentos.

Prazos: urgência altera prazo/recompensa/multa; aviso nos últimos 20%; entregas parciais e tardias; pagamento/bónus únicos; sanção única; encerramento e reembolso da equipa; serviço individual vencido; histórico; salto de dias; aceleração de toda a simulação.

As doze capturas foram vistas e revistas. A renderização de software Mesa emite apenas o aviso de V-Sync não suportado pelo controlador. Os comandos reproduzíveis estão no README. As capturas de falha financeira pertencem à sessão de demonstração; o saldo inicial continua a ser 500.000 MT.

## Limitações

- Progresso e histórico não são gravados entre sessões.
- Avatares e animações são procedurais: aproximação 3D à referência, sem modelos esculpidos ou clips importados.
- Mapa finito de 800 × 800 m; iluminação diurna fixa.
- Tráfego e animais são ambiente: não têm economia urbana, reprodução ou gestão pecuária completa.
- Existe uma equipa activa de produção, até dez membros, e três empresas com encomendas de dimensão predefinida. Contratos individuais continuam limitados pelos três tractores.
- Equipamentos com acesso persistentemente bloqueado têm alternativa de trabalho manual. A navegação não simula gestão complexa de trânsito entre vários tractores.
- Saltar dias avança calendário, culturas e vencimentos; o trabalho físico continua a decorrer na simulação. ×12 acelera todos os sistemas. A entrega final do camião é feita pelo jogador.
- As multas podem deixar saldo negativo. Produtos incompatíveis, excedentes e carga de funcionários são conservados; multas e prémios têm protecção contra duplicação.

O ícone/logótipo existente e o ficheiro binário do relevo original não foram substituídos. A versão arquivada `.mozcolheita-anterior/` permanece intacta.
