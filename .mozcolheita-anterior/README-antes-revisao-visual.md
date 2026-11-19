# MozColheita — versão autónoma

Godot 4.3 ou superior, 3D, GDScript tipado. Uma única cena mínima constrói o mundo por código. Sem plugins, autoloads ou recursos externos. Abra o `project.godot` da pasta principal MozColheita e prima F5. Capital inicial: **500.000 MT**.

## Validação por fases

Execute dentro desta pasta:

```sh
godot --headless --path . --quit
godot --headless --path . -- --teste
```

| Fase | Implementado | Resultado em Godot 4.6 | Como testar |
|---|---|---|---|
| 1 | Escolha homem/mulher, avatar articulado e chapéu, relevo original, extraído dos mapas da versão anterior, quinta vedada de 60 × 60 m, portão automático, galpão, armazém, grelha e três fábricas, câmara orbital | PASSOU: arranque e verificações funcionais, sem erros/avisos | Escolher personagem; WASD/Shift; rato e roda/+/-; caminhar até ao portão sul; H abre ajuda |
| 2 | Kit K e teclas 1–6, ferramentas visíveis, corte e madeira, construção/reparação, sementes secas, rega, quatro etapas de crescimento e lotes MultiMesh | PASSOU: arranque e testes funcionais, sem erros/avisos | 4 lavra; 6 semeia; esperar não faz crescer; 5 rega; após 60 s, 1 colhe. K abre kit e permite roda; fora do kit a roda faz zoom |
| 3 | Três tractores, doze implementos (quatro tipos em três locais), condutor articulado, E/G/Espaço, engate por distância e sinal verde, trabalho em três linhas | PASSOU: arranque e regressão, sem erros/avisos | E entra; conduzir até à máquina; G engata; Espaço liga; E sai parado. Máquinas dentro do galpão e nas plataformas norte/sul |
| 4 | Três drones, plataformas fixas, rotores, F assume/devolve, jogador imóvel, câmara remota, voo WASD/Espaço/Ctrl e limites | PASSOU: arranque e regressão, sem erros/avisos | Aproximar de uma plataforma a leste dos tractores; F pilota; Espaço sobe, Ctrl desce; F regressa |
| 5 | Seis NPCs locais e doze trabalhadores nas fazendas vizinhas, percursos pela estrada e portão, contratação, salários de 8 MT, sete tipos de ordem, reserva de células e fila máxima de cinco | PASSOU: arranque, limite da fila e sementeira remunerada, sem erros/avisos | E contrata junto a um NPC; H escolhe trabalhador, ordem e tractor; adicionar até cinco ordens; H fecha e retoma a execução |
| 6 | Proposta, confirmação E, câmara dos dois personagens, balão, voz do sistema quando disponível ou som sintetizado, mãos guiadas por dois ossos e três apertos | PASSOU: arranque, confirmação, encontro das mãos e conclusão, sem erros/avisos | E junto de um NPC livre inicia proposta; E confirma quando próximo; Esc recusa; após o aperto o contrato fica activo |
| 7 | Capital de 500.000 MT, stock por cultura, depósito automático, levantamento de carga, venda pelo jogador/funcionário, preços variáveis distintos e compra de sementes | PASSOU: arranque, conservação, venda sem duplicação, depósito automático e entrega remunerada, sem erros/avisos | Entrar na zona pintada do armazém deposita; E recolhe carga; E junto à fachada de uma fábrica vende; H consulta stock e compra sementes |

A implementação activa está na **raiz**. A versão anterior e as gravações antigas não são usadas por esta versão; os ficheiros anteriores estão em `.mozcolheita-anterior/`, excluída da importação.

## Limitações conhecidas

Todas as sete fases estão implementadas. O projecto usa modelos procedurais simples; o drone respeita limites do mapa, mas não simula colisões com edifícios. A água é ilimitada e não há desgaste periódico da vedação. O portão abre para jogador e veículos do grupo de tractores.

As tarefas deslocam o funcionário e actuam no mundo. A venda já usa a economia e os preços da fábrica seleccionada. Produtos colhidos pelo funcionário ficam na sua carga até ordenar transporte ou venda.

A voz depende das vozes portuguesas instaladas no sistema. O som de diálogo é sintetizado quando TTS não está disponível; o texto mantém a fala completa.


## Relevo e fazendas vizinhas

O terreno original foi preservado em `data/relevo_original.bin`: alturas dos mapas guardados da versão anterior, amostradas a cada 2 m numa área de 800 × 800 m. A posição original da quinta (105, 126) corresponde à origem desta versão. A conversão foi feita uma vez; o jogo usa malhas e colisão HeightMap nativas do Godot, sem Terrain3D em execução. O ficheiro inclui versão, tamanho, espaçamento e origem.

Há seis fazendas vizinhas, a mais de 200 m do centro, com culturas em MultiMesh, galpões, acessos e dois trabalhadores cada. A grelha agrícola principal continua dentro da quinta. Edifícios, plantas, vedações e pontos de aparecimento acompanham as alturas do terreno.

## Menu à volta do campo

À esquerda ficam os seis itens; em baixo à esquerda, as quatro culturas. À direita ficam os comandos com ícones e teclas. No topo aparecem dinheiro, hora, sementes, madeira e carga. O centro fica livre para jogar. **Tab** liberta/captura o cursor para clicar nos ícones; **H** abre a gestão e **K** o kit. As acções indisponíveis ficam desactivadas.

| Tecla | Acção |
|---|---|
| WASD / Shift | Andar / correr; conduzir ou pilotar |
| Rato / roda / + / − | Rodar a câmara / zoom; roda escolhe ferramenta dentro do kit |
| 1–6 | Mãos, martelo, serrote, enxada, regador, semeadora |
| Clique esquerdo | Usar ferramenta |
| E | Interagir, entrar/sair do tractor, conversar e confirmar contrato |
| G / Espaço | Acoplar máquina / activar trabalho do tractor |
| F / Espaço / Ctrl | Assumir/devolver drone / subir / descer; R liga/desliga irrigação |
| H / K / Tab / Esc | Gestão / kit / cursor / fechar ou cancelar |

A cena de entrada é `main.tscn`. `scripts/main.gd` compõe os módulos `landscape`, `village`, `player`, `camera`, `terrain`, `crop`, `fence`, `tools`, `tractor`, `implement`, `drone`, `npc`, `tasks`, `contract`, `factory`, `warehouse`, `economy` e `hud`. Os SVG de `icons/` são lidos directamente, sem depender de importações.

Para testar o percurso físico completo do funcionário:

```sh
godot --headless --path . -- --teste-percurso
```

Não existe gravação persistente nesta versão. Os trabalhadores usam desvio local de obstáculos e os vizinhos simulam trabalho por percursos e gestos. As alturas originais foram conservadas; os edifícios e culturas desta versão são procedurais.


## Verificação final — 18/11/2026

Godot 4.6: arranque headless, regressão das sete fases e percurso físico completo passaram. A regressão inclui relevo com colisão, seis fazendas e dezoito NPCs, ícones nas margens, engate/condutor, limites do drone, irrigação aérea, contratação, salários e conservação dos produtos nas vendas. O percurso executa semear → regar → crescer → colher → armazenar → vender, atravessando o portão.

As capturas em `preview/` mostram a interface, o terreno e as fazendas. No ambiente de captura Mesa/llvmpipe, o controlador emite um aviso de V-Sync não suportado; os três comandos headless terminam sem erros nem avisos. As limitações de gravação e navegação descritas acima continuam aplicáveis.


## Revisão visual e de desenho — fases actuais

Esta revisão substitui as dimensões e a parcela inicial descritas no histórico acima.

| Fase | Mudanças | Validação |
|---|---|---|
| V1 — disposição | Quinta de 192 × 156 m (29.952 m²), seis portões automáticos de 12 m, estacionamento separado, corredores de 18 m livres de máquinas. Cultivo criado apenas ao lavrar; não há grelha nem solo preparado visível no início. Percursos consideram todos os portões e edifícios. Colisão entre personagens e veículos. | Godot 4.6, arranque headless: passou sem erros/avisos. |

Teste V1: comece numa quinta natural, prepare uma célula com 4, visite os seis acessos e confirme que abrem. As máquinas ficam no parque do galpão, nunca nos portões. A parcela lógica é criada apenas quando necessária; os desenhos do solo usam lotes MultiMesh.

| V2 — culturas | Tomate com ramos, folhas compostas e tomates vermelhos; milho com espigas e pendão; couve com roseta e folhas curvadas; cenoura com raiz e folhas finas. Quatro etapas e modelos partilhados, incluindo geometria reduzida para fazendas distantes. | Godot 4.6, arranque headless: passou sem erros/avisos. |

Teste V2: lavrar, semear uma das quatro culturas, esperar a seco, regar e acompanhar os estágios até aos 60 s. Couve substitui a antiga alface na economia e nos menus.

### V3 — personagens

Corpos e rostos com volumes contínuos, seis tons de pele distribuídos independentemente do género, proporções de ombros/quadris diferentes, narizes, orelhas, olhos discretos e cabelo. Mulheres usam saias de dois comprimentos e cabelo comprido, sem chapéu; homens usam calças e chapéu. Mantidos os pivôs de caminhada, condução e aperto de mão. Colisões e afastamento local ajudam a separar NPCs. Arranque Godot 4.6 headless: passou sem erros/avisos.

Teste: observar os homens e mulheres junto à estrada, contratar com E e confirmar, depois atribuir tarefas pelo painel H. As personagens continuam a usar modelos procedurais; não são digitalizações fotográficas.

### V4 — terreno

Mantido o mapa de alturas original. Solo com textura procedural de ruído em várias escalas, manchas de terra/vegetação, grão fino e rugosidade alta; céu em gradiente e iluminação mais quente. Árvores distantes excluem a quinta ampliada e os edifícios das fazendas vizinhas. Arranque Godot 4.6 headless: passou sem erros/avisos. O shader também será verificado na revisão gráfica final.

### V5 — interface

Menu com logótipo, ícones e botão Começar; homem por defeito, sem escolha de género. Logótipo pequeno no jogo, minimapa permanente no canto inferior direito com portões, edifícios, veículos e pessoas (actualização 8 Hz, sem câmara 3D adicional). H abre separadores Culturas/Equipa/Mercado/Controlos; K abre ferramentas. Arranque Godot 4.6 headless: passou sem erros/avisos.

Teste: iniciar, confirmar que o minimapa acompanha a posição, abrir H/K e regressar ao campo; Esc regressa ao menu.

### V6 — carrinha de transporte

Carrinha de quatro rodas, engate G e sinal verde. C (ou Espaço) transfere carga com o tractor parado: longe de edifícios carrega a sacola; junto ao armazém descarrega ou recolhe stock se estiver vazia; na fachada da fábrica vende. Capacidade 120 unidades, excedente fica na origem, caixas visíveis acompanham a carga. Máquinas estacionadas têm colisão. Arranque e regressão headless Godot 4.6 passaram sem erros/avisos; teste físico do funcionário também passou.

Testes automáticos verificam capacidade, conservação do excedente, acoplamento, descarga no armazém, venda e ausência de receita duplicada. Carga partilhada por todas as culturas, sem exigir tractor específico.
