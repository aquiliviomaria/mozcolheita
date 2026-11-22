# Vida na casa e documentação — 22/11/2026

Implementação na pasta principal MozColheita, Godot 4.6, GDScript tipado.

## Funcionalidades

- E junto à cama, à noite, inicia a pose deitada e uma transição curta. O relógio avança exactamente até às 06:00 do dia seguinte. Energia fica em 100, vida recupera até 15 e alimentação diminui 8, respeitando os limites. Acordar restaura posição de pé, pose, colisão e ferramenta. A cama não avança tempo durante o dia.
- Sono usa a mesma função de avanço de calendário, culturas e vencimento contratual que os atalhos. Crescimento apenas para culturas regadas. Multas são aplicadas uma vez; o aviso de quebra de contrato é preservado ao acordar. Trabalhadores não completam percursos instantaneamente.
- E junto às cadeiras senta; E novamente come. WASD/Esc levanta. A mesa tem pratos, frutos/alimentos e copos visíveis. Há quatro refeições iniciais; depois consome um produto da sacola ou do stock do armazém. Sem recursos, a comida desaparece. Sem necessidades por recuperar não há consumo.
- Recuperação alimentar partilha a função de necessidades existente: até +35 alimentação, +30 energia e +10 vida. J continua disponível fora da interacção doméstica.
- Refeições conservadas na gravação. Ao guardar sentado, guarda-se a posição segura anterior; ao retomar limpa-se o estado doméstico temporário. Guardar durante a curta transição de sono é bloqueado. O formato anterior sem campo `casa` continua válido e recebe quatro refeições iniciais.
- Cinco janelas transparentes, com aberturas físicas nas paredes, incluindo janela lateral junto à cama. Molduras e vidro com colisão, sem parede opaca por trás.
- Mais mobília: duas cadeiras, armário, estante com livros, bancada de cozinha, mesa de centro e mesa de cabeceira; mantidos cama, sofá, mesa e tapete. Cores das paredes e chão suavizadas para reduzir o excesso de amarelo no interior.
- README reorganizado em apresentação, início, ciclo de jogo, experiências divertidas, agricultura/rotação, casa, máquinas, economia/contratos, contratação, controlos, mundo, gravação, arquitectura, verificação, limites e relatórios. Funcionalidades actuais separadas das ideias futuras.

## Ficheiros desta actualização

Criados:

- `scripts/home_life.gd`
- `RELATORIO_VIDA_CASA.md`
- `validation/vida_casa/test.gd`, `capture.gd`, `.gdignore` e registos
- `preview/vida_casa/casa-janelas.png`, `mesa-refeicao.png`, `janela-cama.png`, `descanso-noite.png`

Modificados:

- `scripts/farmhouse.gd`: paredes com vãos, vidros, molduras, cores e composição do sistema doméstico.
- `scripts/main.gd`: encaminhamento de E e controlo de entradas durante poses domésticas.
- `scripts/calendar.gd`: avanço comum de calendário, culturas e prazos.
- `scripts/vitals.gd`: recuperação alimentar reutilizável.
- `scripts/persistence.gd`: refeições, validação opcional compatível, retoma a pé e guarda segura durante interacções.
- `README.md`: reescrita da documentação principal.
- `COMO_JOGAR.txt`: controlos e regras da casa.

## Verificação

| Verificação | Resultado / registo em `validation/vida_casa/` |
|---|---|
| Arranque headless | Sem erros de script — `arranque.log` |
| Sono, refeições, gravação e janelas | VIDA NA CASA PASSOU, zero falhas — `test-final.log` |
| Acesso físico à casa, rampa, porta e controlos | CASA ABERTA PASSOU, zero falhas — `acesso.log` |
| Prazos, penalizações e tempo | PRAZOS PASSOU, zero falhas — `prazos.log` |
| Persistência e recuperação de cópia danificada | GRAVAÇÃO PASSOU, zero falhas — `persistencia.log` |
| Quatro capturas revistas no jogo | `visual-final.log` e `preview/vida_casa/` |

## Limites

Comer usa uma refeição inicial ou um produto; não há receitas/cozedura. O stock funciona como despensa partilhada com o armazém, sem transporte doméstico separado. Armário, livros e bancada são decoração. Sono é uma transição curta até amanhecer, sem simulação de sonhos ou calendário offline. A mobília é procedural e partilha o estilo actual do jogo.
