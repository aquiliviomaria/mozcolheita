# MozColheita — primeira implementação de diversão e revisão do HUD

Alterações na pasta principal MozColheita. O terreno e o saldo inicial de 500.000 MT foram mantidos.

## O que já funciona

### Guardar e continuar

F5 guarda; F9 retoma, incluindo no menu inicial. Há um botão Continuar e gravação automática a cada minuto real de jogo e ao sair. O ficheiro `user://quinta.mozsave` usa versão, comprimento e SHA-256; é escrito num temporário e conserva uma cópia `.bak`. Se o principal estiver danificado, tenta a cópia. Uma gravação inválida não altera a sessão actual. Os testes usam ficheiros separados e não gravam automaticamente na quinta do jogador.

São conservados dinheiro, sacola, armazém, culturas e rotação do solo, crescimento, sementes, madeira, personagem e posição, veículos e cargas, engates, árvores cortadas, cercas construídas, missões, histórico, prazos, reputação, necessidades e trabalhos individuais/em grupo. IDs de instância de trabalhadores e reservas são reconstruídos ao reabrir o jogo. Não há cobrança ou reembolso ao carregar.

O relógio não avança com o jogo fechado. Ao retomar, o jogador fica a pé, veículos parados, implementos desligados e velocidade normal. Os trabalhadores recuperam os seus contratos, filas e reservas e prosseguem. Não se guarda a meio da negociação/aperto de mão nem no instante em que se está a finalizar uma missão.

### Trabalho agrícola mais satisfatório

Preparar, semear, regar e colher apresentam partículas, som espacial e texto com o resultado verdadeiro. A colheita mostra a quantidade obtida. Seis conjuntos de partículas/texto são reutilizados, com alcance de 24 m e limitação de frequência para as máquinas não saturarem som/imagem. Efeitos visuais não creditam dinheiro nem produtos.

### Contratos com escolhas e progressão

H → Entregas permite combinar Pequena / Regular / Grande com Normal / Prioritária / Urgente. Antes de aceitar mostra quantidade, recompensa, multa, prazo, equipa recomendada, custo e margem estimados, distância aproximada e reputação. Entregas grandes têm mais prazo; urgência aumenta recompensa e risco. Todos os perfis deixam pelo menos quatro dias para permitir o crescimento de três dias e a entrega.

A estimativa assume solo natural, rendimento mínimo, trabalhadores recomendados e dificuldade normal. O orçamento real continua separado, visível e sujeito a confirmação em Grupo. Os preços mínimos foram equilibrados para cobrir a equipa recomendada normal e deixar margem. Mais funcionários ou dificuldade elevada podem reduzir essa margem. Também se pode trabalhar manualmente.

Sucessos dão reputação na empresa, melhorando o preço de ofertas futuras; atrasos retiram reputação, uma única vez. Preço, bónus, prazo e multa de contratos aceites ficam fixos. Reputação é guardada.

### HUD e comandos pedidos

- O topo deixa de mostrar dia/hora e os botões +1 dia/×12. Só L alterna dia/noite; os prazos continuam no painel de missões.
- Corações, alimentação e energia têm ícones grandes e números. Ferramentas clicáveis ficam à esquerda; missões/estado do veículo à direita; minimapa no canto inferior direito.
- O desenho de comando e os seus símbolos foram retirados. As acções aparecem em cartões de ícone com a tecla no centro e realce quando activa.
- Tractor/camião: W acelerador, Ctrl travão, T turbo em conjunto com W, S recuar, A/D virar, G engatar, Espaço máquina, C carga e E sair.
- Drone: WASD voar, Espaço subir, Ctrl descer, R irrigar, F regressar e rato para câmara.
- B mantém o botão de abastecimento quando há uma semeadora engatada.
- J consome um produto da sacola ou do stock junto ao armazém. Recupera alimentação, energia e vida; as necessidades diminuem suavemente durante o jogo activo. Sem alimento, a saúde desce lentamente até 20, sem morte automática.
- A seta de entrega ficou menor e deixa de aparecer durante pilotagem do drone/câmara livre.

## Ficheiros criados de implementação

- `scripts/persistence.gd`
- `scripts/farm_feedback.gd`
- `scripts/vitals.gd`
- `scripts/input_drive.gd`
- `scripts/driving_hud.gd`
- `icons/vida.svg`, `icons/fome.svg`, `icons/energia.svg`
- `icons/acelerador.svg`, `icons/travao.svg`, `icons/turbo.svg`
- `icons/direccao.svg`, `icons/subir.svg`, `icons/descer.svg`
- `icons/regressar.svg`, `icons/recuar.svg`, `icons/maquina.svg`

## Ficheiros existentes modificados

- `scripts/main.gd`: composição, F5/F9/J, eventos de entrada e saída com gravação.
- `scripts/hud.gd`: continuar, guardar, perfis de encomenda, topo simplificado e notificações.
- `scripts/terrain.gd`: feedback após uma acção agrícola bem-sucedida.
- `scripts/deliveries.gd`: perfis, estimativas, equilíbrio de preços e reputação.
- `scripts/tractor.gd`: travão e leitura partilhada do acelerador/direcção.
- `scripts/drone.gd`: leitura de entradas dos eixos/subida/descida.
- `scripts/camera.gd`: eixo de câmara de dispositivo reconhecido pelo Godot.
- `scripts/delivery_route.gd`: dimensão/visibilidade da seta.
- `README.md`, `COMO_JOGAR.txt`: instruções actuais e fases verificadas.

## Testes e capturas criados

Em `validation/diversao/`: `.gdignore`, `persistence_test.gd`, `feedback_test.gd`, `contracts_test.gd`, `resume_crew_test.gd`, `hud_test.gd`, `capture.gd` e respectivos registos.

Resultados finais em Godot 4.6:

| Verificação | Registo | Resultado |
|---|---|---|
| Guardar/reabrir numa nova instância e recuperar cópia | `05-gravacao-final.log` | PASSOU |
| Efeitos e produção única | `02-feedback.log` | PASSOU |
| Perfis, estimativas, reputação e preço fixo | `03-contratos.log` | PASSOU |
| Prazos, recompensas e multas | `03-prazos.log` | PASSOU |
| Guardar a meio e terminar cultivo/carga após retomar | `04-retoma-equipa.log` | PASSOU |
| L, ícones com teclas, necessidades, acelerador e travão reais | `05-hud-final.log` | PASSOU |
| Regressão de condução | `04-veiculos.log` | PASSOU |
| Regressão de logística | `04-logistica.log` | PASSOU |
| Produção/entrega com dez trabalhadores | `05-regressao.log` | PASSOU |

As capturas finais revistas estão em `preview/diversao/`: `menu-gravacao.png`, `campo-hud.png`, `entregas-pequenas.png`, `entregas-grandes.png`, `colheita-feedback.png`, `tractor-icones.png` e `drone-icones.png`. Registo gráfico: `visual-icones.log`; Mesa/llvmpipe apenas avisou que não suporta a alteração de VSync.

## Limitações e fases seguintes

Esta primeira implementação cobre gravação, feedback agrícola, contratos variados, reputação e o HUD pedido. Histórias/relações pessoais com vizinhos, feiras/eventos dinâmicos e compra de melhorias físicas da quinta ficam para uma fase seguinte; não são apresentados como concluídos.

Há uma quinta guardada e uma cópia anterior, sem vários slots nem sincronização cloud. O formato está ligado à actual composição de pessoas/veículos do mapa; alterações futuras da composição exigem migração. O trabalho recomeça com os veículos parados e os trabalhadores a pé, podendo recolher novamente o tractor/equipamento. Estimativas de contrato não incluem trajectos exactos, obstáculos construídos posteriormente nem dificuldade extra. Teclado, travão e eventos dos botões foram testados; não havia comando físico disponível para validar hardware. As animações, sons e modelos continuam procedurais.
