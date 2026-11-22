# Casa acessível e remoção dos painéis auxiliares

Actualização de 22/11/2026, na pasta principal MozColheita.

- Retiradas a cobertura e as colunas altas da varanda; mantidos pavimento, bancos, corrimão e rampa.
- Porta principal verde, com moldura, painéis e puxador, abre automaticamente quando o jogador se aproxima de qualquer lado. A folha tem colisão e abre para fora, deixando o vão livre.
- Substituído o bloco sólido da casa por paredes independentes e abertura real de entrada. Chão interior à mesma altura da varanda. Sala com tapete, sofá, cama, mesa e luz quente; corredor central livre.
- O telhado principal fica visível no exterior e oculta-se enquanto o jogador está dentro, permitindo ver a sala. A varanda permanece sempre descoberta.
- Retiradas as caixas auxiliares junto ao minimapa: irrigação, veículo, sem equipamento, sementes e carga. Mantidos os ícones de acção, atalhos, lógica de engate, transporte, rega e abastecimento.

Ficheiros de jogo modificados: `scripts/farmhouse.gd`, `scripts/driving_hud.gd`. Documentação: `README.md`, `COMO_JOGAR.txt` e este relatório. Validação criada em `validation/casa_aberta/`: teste físico, script de captura, `.gdignore` e registos; imagens em `preview/casa_aberta/`.

Godot 4.6 headless: arranque sem erros; teste CASA ABERTA PASSOU, zero falhas. Verifica percurso físico da posição inicial, subida da rampa, entrada até ao centro da sala, saída pela mesma porta, colisão das paredes, ocultação/reposição do telhado, remoção dos painéis auxiliares e preservação dos comandos de tractor/drone.

O mobiliário é cenário; esta alteração não adiciona funções de dormir ou gestão doméstica. A entrada e o interior não exigem carregamento de outra cena.
