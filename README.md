# MozColheita

Simulação agrícola 3D em Moçambique, escrita em GDScript tipado e validada no **Godot 4.6**. Abra o `project.godot` desta pasta principal e prima F5, ou execute `./Jogar.sh`. Capital inicial: **500.000 MT**.

## Personagens e início

O menu apresenta agricultor e agricultora seleccionáveis, com pré-visualização 3D. Ambos usam o mesmo controlador e rig articulado. As personagens seguem a referência do logótipo: pele castanha, olhos expressivos, sorriso, camisa creme, jardineira verde com bandeira, cinto e botas. O agricultor usa chapéu de palha; a agricultora tem cabelo encaracolado, lenço, brincos e tecido inspirado na capulana à cintura.

Animações procedurais: repouso, caminhada, corrida, plantio, rega, colheita e transporte. Mantêm-se aperto de mão e condução com condutor visível. O jogador começa em **(-8, -37)**, à frente da casa principal com alpendre e logótipo.

## Quinta e calendário

Quinta de 192 × 156 m, seis portões e terreno natural por preparar. Edifícios, acessos e estacionamentos não podem ser cultivados. Sequência: **preparar → semear → regar → crescer → colher**. A primeira rega inicia o crescimento; sementes secas não avançam.

Uma cultura precisa de **três dias completos de jogo** desde a rega. Um dia dura dez minutos reais em velocidade normal. O botão **Tempo ×1/12** acelera toda a simulação, incluindo trabalhadores e veículos. **+1 dia** avança calendário, crescimento e vencimento de contratos; os funcionários continuam os seus percursos físicos. Os prazos podem vencer ao saltar dias.

Tomate, milho, couve e cenoura têm modelos e estágios próprios. A rotação conserva a lógica de famílias, saúde do solo e variação do rendimento. A textura do terreno é mais verde. O ficheiro de alturas original permanece intacto; a execução atenua o relevo e nivela a cidade para obter curvas suaves sem montanhas.

## Controlos

| Comando | Acção |
|---|---|
| WASD / Shift | Andar / correr; WASD conduz veículos |
| Rato / roda / + / − | Câmara / zoom; roda selecciona ferramentas dentro de K |
| K / 1–6 | Kit: mãos, martelo, serrote, enxada, regador, semeadora |
| Clique / Espaço | Usar ferramenta; no tractor liga/desliga o implemento |
| E | Interagir, conversar, entrar/sair de veículo parado |
| G | Engatar/soltar implemento ou carrinha no tractor parado |
| C | Carregar, depositar ou vender carga do veículo parado |
| B | Abastecer sementes junto à máquina ou com semeadora engatada |
| F / Espaço / Ctrl / R | Drone: assumir/devolver, subir, descer, regar |
| H | Culturas, Equipa, Mercado, Entregas, Grupo, Histórico, Controlos |
| V | Câmara livre; WASD desloca e Q/E altera altura |
| L | Passar para a noite / manhã do novo dia, com canto de galo |
| Botões +1 dia / Tempo ×1/12 | Avançar calendário / acelerar toda a simulação |
| Tab / Esc | Cursor / fechar painel, cancelar proposta ou abrir menu |

O HUD mantém logótipo, saldo/calendário, encomendas e comandos contextuais. O minimapa fica no canto inferior direito. Os painéis têm deslocação vertical quando necessário.

## Máquinas, garagem e carga

Três tractores, doze implementos (preparadores, semeadoras, irrigadores e ceifeiras), três carrinhas de 120 unidades, três drones e um **camião de 500 unidades**. Um tractor utiliza um equipamento de cada vez. O engate verifica o espaço e mostra o indicador verde. W+T activa turbo.

Cada semeadora tem depósito próprio de 300 sementes. B enche as sementes em falta a 2 MT/unidade; H → Mercado também abastece as máquinas dos funcionários. Compras não são feitas silenciosamente por contratos individuais.

A garagem/armazém tem portas automáticas de passagem. Entrar com a colheita deposita-a; sair conserva o stock. Uma carrinha ou camião que entra vazio recolhe stock até à sua capacidade. Ao entrar carregado, descarrega; é necessário sair e entrar novamente para a operação seguinte. C também permite transferências manuais. Caixas abertas mostram tomate, espigas com grãos, couve e cenoura, com quantidades reais. Há pavimento e iluminação interior.

## Comunidade

Seis fazendas vizinhas, 55 casas, dez prédios de 10/20/40 pisos, estradas asfaltadas e de terra, 46 NPCs, vinte veículos de ambiente (carros, tractores e camiões), criações com oito porcos, oito galinhas e oito bovinos. Os acessos novos ficam fora da quinta.

Janelas e culturas usam MultiMesh; produtos e primitivas partilham malhas. Avatares distantes deixam de ser desenhados. A navegação combina grafo de portões/edifícios com desvio local A*, limitado a um cálculo por quadro de física. Veículos com implementos usam corredores mais largos.

## Empresas, prazos e consequências

H → **Entregas** apresenta encomendas e urgência antes da aceitação:

| Empresa | Compra | Posição da garagem |
|---|---|---|
| Tomates do Zambeze | Tomate | (-60, 110) |
| Moageira Nhamatanda | Milho | (0, 110) |
| Hortícolas Maputo | Couve e cenoura; encomenda de couve | (60, 110) |

Prazos: **normal 8 dias**, **prioritária 6 dias**, **urgente 4 dias**. Maior urgência aumenta o preço, o bónus e a multa. O painel mostra quantidade, prazo, recompensa e penalização antes de aceitar; o preço aceite fica fixado. O HUD e o painel mostram tempo restante, e há aviso ao chegar aos últimos 20%.

Estacione o camião dentro da garagem da empresa para concluir a entrega. Entregas parciais pagam as unidades aceites; completar a quantidade dentro do prazo paga o bónus. A mercadoria não aceite permanece na carga. A venda normal continua disponível com C/E.

**Vencimento:** a encomenda fica falhada, a multa aprovada é descontada automaticamente uma única vez e a equipa associada é encerrada com devolução da reserva não executada. Entregas tardias não concluem a encomenda. Uma multa pode deixar o saldo negativo. Sucessos e falhas constam de H → **Histórico**, durante a sessão.

A meta livre de produção continua a recompensar colheitas efectivas. Encomendas e serviços aceites têm prazo.

## Contratação individual e de grupo

E junto de um NPC permite escolher tarefa, quantidade, parcela, tractor, dificuldade e empresa. São obrigatórios trabalho e confirmação do pagamento antes do aperto de mão. O orçamento mostra prazo e multa; serviços vencidos descontam a penalização, devolvem o trabalho não executado e entram no histórico. Colher e vender têm tarifas superiores a regar. Mantêm-se até três contratos individuais com tractores exclusivos.

H → **Grupo** contrata de uma a dez pessoas para uma encomenda aceite. Escolha empresa, número, dificuldade e centro da parcela. O orçamento discrimina trabalho, sementes e coordenação, além do prazo e da multa da encomenda. O camião deve estar estacionado e ter espaço antes da contratação.

Após confirmar, a equipa prepara, planta, rega, aguarda crescimento, colhe e carrega o camião. Utiliza até três tractores livres com equipamento; os restantes trabalham manualmente. Máquinas indisponíveis ou com acesso persistentemente bloqueado levam a trabalho manual. As sementes da equipa fazem parte do orçamento. O excedente é conservado no armazém. Os trabalhadores libertam a zona de carga após entregar.

O jogador recebe aviso quando a carga está pronta e conduz o camião à empresa. Cancelar a equipa devolve a reserva não executada; a encomenda e o seu prazo continuam activos. A multa da encomenda é aplicada uma vez, sem multiplicar pelo número de funcionários.

## Implementação por fases e validação

| Fase | Trabalho | Arranque headless |
|---|---|---|
| C1 | Personagens e selecção | Aprovado |
| C2 | Casa, três dias, câmara, caixas abertas | Aprovado |
| C3 | Bairros, cidade, tráfego e animais | Aprovado |
| C4 | Camião, empresas e encomendas | Aprovado |
| C5 | Equipa de até dez trabalhadores | Aprovado |
| C6 | Prazos, urgência, multas e histórico | Aprovado |

Os registos desta alteração estão em `validation/comunidade/`; os anteriores em `validation/revisao/`.

```sh
./Jogar.sh --headless --quit
./Jogar.sh --headless -- --teste
./Jogar.sh --headless -- --teste-veiculos
./Jogar.sh --headless -- --teste-percurso
./Jogar.sh --headless -- --teste-logistica
./Jogar.sh --headless --script validation/comunidade/test.gd
./Jogar.sh --headless --script validation/comunidade/deadlines.gd
```

A integração verifica os avatares, três dias de crescimento, câmara livre, comunidade, entrega física do camião e produção/carga por dez trabalhadores sem tractores disponíveis. As outras suites cobrem máquinas e condução, engate autónomo, ciclo agrícola, economia, obstáculos, capacidade e conservação da carga. Prazos verificam urgência, aviso de 20%, entregas parciais/tardias, recompensa única, multa única, falha do grupo, serviços individuais, histórico e salto de dias.

As capturas revistas estão em `preview/comunidade/`. Para as reproduzir: `./Jogar.sh --script validation/comunidade/capture.gd`. As capturas de falha usam uma sessão de demonstração; o jogo continua a iniciar com 500.000 MT.

## Ficheiros e limites

A lista exacta de ficheiros criados/modificados, verificações e limitações encontra-se em **RELATORIO_COMUNIDADE.md**. Toda a implementação activa fica nesta pasta principal MozColheita, sem plugins nativos. A versão anterior permanece em `.mozcolheita-anterior/`.

Não há gravação persistente; histórico, progresso e contratos duram a sessão. Avatares e animações são procedurais, sem escultura ou clips importados. O mapa é finito (800 × 800 m), o ciclo de iluminação acompanha dia/noite e o tráfego/animais têm comportamento de ambiente, sem economia urbana ou reprodução animal. Existe uma equipa de produção activa de cada vez, com até dez membros; três empresas oferecem encomendas de dimensão predefinida. Saltar dias avança crescimento/prazos; a execução física dos trabalhadores prossegue ao retomar a simulação. A entrega final é conduzida pelo jogador.

Actualização do mundo vivo — fase 1: **L** alterna para as 18:00 e para as 06:00 do dia seguinte. O botão «L Dia/noite» faz o mesmo; «+1 dia» continua disponível. Céu azul e sol durante o dia, céu escuro e luz lunar à noite. Cada novo dia toca um canto de galo sintetizado. O calendário, crescimento e prazos avançam juntos. Verificação: importação e arranque headless Godot 4.6, registos em `validation/mundo_vivo/01-*.log`.

Mundo vivo — fase 2: seis garagens de entrega (três empresas e três filiais), portas de enrolar automáticas, acessos de dez metros e marcações do cais. Entrar e parar entrega a encomenda e vende o excedente aceite pela empresa. Com mercadoria na sacola, no reboque engatado ou no camião conduzido, uma seta indica a fábrica compatível mais próxima, dando prioridade às encomendas activas. A rota passa pelos portões e pela rede de estradas, também desenhada no minimapa. Verificação: importação e arranque headless em `validation/mundo_vivo/02-*.log`.

Mundo vivo — fase 3: mais 32 casas dispersas, seis casas nas quintas, quatro prédios separados dos blocos centrais, vinte residentes adicionais e oito veículos de ambiente (cinco tractores). Casas e prédios têm portas automáticas e um rés-do-chão mobilado acessível; os andares superiores continuam a ser cenário. As seis quintas vizinhas têm cercas de produção e agricultores com animações de cultivo. Novas vias de asfalto e terra, um riacho com quatro pontes, 280 árvores e 150 pedras em MultiMesh. A distribuição reserva espaço para edifícios e estradas. Verificação: arranque headless sem erros de script, registos `validation/mundo_vivo/03-*.log`.

Design dos veículos: carro de passageiros com carroçaria chanfrada, vidros com reflexos, faróis, grelha, espelhos e puxadores; camião de trânsito com cabine própria, seis rodas e caixa reforçada; tractor do trânsito com capô, escape, guarda-lamas e rodas agrícolas. Cinco combinações de cor por modelo. O camião conduzível recebeu frente, espelhos, estribos, para-choques e rodas detalhadas, preservando cabine aberta, condutor visível e transporte de 500 unidades. As malhas de carroçaria/rodas são partilhadas por `scripts/vehicle_art.gd`. Verificações e capturas: `validation/veiculos_design/` e `preview/veiculos_design/`.

Verificação do desenho dos veículos: condução, logística e entregas passaram em Godot 4.6; quatro capturas de arte foram revistas. O relatório completo de ficheiros e limitações está em `RELATORIO_MUNDO_VIVO.md`.
