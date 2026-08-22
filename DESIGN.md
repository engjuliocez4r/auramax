# AURAMAX 67 — DOCUMENTO DE DESIGN CONSOLIDADO

Versão de 22 de agosto de 2026. Substitui todos os registos anteriores, incluindo o NotebookLM.

Autor e diretor criativo: Julio Cezar (`engjuliocez4r`)
Motor: Godot 4.7.2 · Repositório: `github.com/engjuliocez4r/auramax`

---

## O QUE APRENDEMOS (o mais importante)

**1. O QUE PRENDE O JOGADOR — VALIDADO EM PROTÓTIPO**
Não é o número a subir nem a recompensa visual. É a perceção de que a habilidade muda o resultado: ser mais ágil e manter o ritmo dá mais pontos por clique.
Consequência: o bónus de ritmo é a mecânica CENTRAL, não um extra. O feedback de "estou no ritmo" deve ser a coisa mais afinada do jogo, com prioridade acima dos efeitos de festa.
Evidência: protótipo web jogado várias vezes seguidas com arte genérica e boneco placeholder. A diversão está na mecânica, não na arte.

---

## IDENTIDADE

**2. NOME E IDENTIFICADORES**
Nome na loja: Auramax 67. Repositório: `github.com/engjuliocez4r/auramax`. Application ID (permanente): `io.github.engjuliocez4r.auramax` — sem o "67", porque é imutável após publicação e o meme pode envelhecer.
Público-alvo: 9-13 anos. Toda a decisão de design é medida contra esta idade.

**3. VOCABULÁRIO ÚNICO**
Tudo é "aura". Ganha-se aura, sobe-se de "nível de aura", farma-se aura. Não usar "XP" nem "level" na interface.

---

## ESTRUTURA DE ECRÃS

**4. FLUXO**
Splash da produtora → (primeira vez: criação de personagem) → Casa → Duelo / Quarto / Opções.

**5. CRIAÇÃO DE PERSONAGEM (só na primeira abertura)**
Escolha de rapaz ou rapariga, alguns acessórios gratuitos, escolha de bandeira, idioma, e o nome. Máximo 30 segundos e três ecrãs — se for longo, o miúdo fecha antes de jogar. Sem contador de moedas (é um jogador novo, não tem saldo).

**6. ECRÃ DE CASA**
Nome do jogador no lugar nobre do topo, assente numa barra fina de nível de aura — identidade e progresso juntos. O nome do jogo só aparece se o jogador não definir nenhum.
Avatar grande ao centro, vestido com o que possui. Tocar nele faz-lhe caretas, gritos e poses — é brinquedo, não atalho. Os cosméticos comprados aparecem nessas reações.
Dois botões grandes lado a lado: História (mostra progresso, ex. "alvo 3 de 12") e Arcade.
Um botão médio por baixo: O Quarto. Ponto vermelho quando há novidade.
Ícone de engrenagem pequeno no canto.
Hierarquia deliberada: quatro entradas com pesos diferentes, não quatro botões iguais.

**7. O QUARTO (vestir, loja e troféus fundidos)**
Três abas: Vestir, Loja, Troféus. Comprar e vestir no mesmo sítio — obrigar a mudar de ecrã para equipar é irritante.
Vista dos itens alternável entre tira lateral e grelha, à escolha do jogador.
Botão "Pronto" recolhe os menus e mostra só o avatar no cenário — é o momento de orgulho.
O cenário do quarto é personalizável e vendável (barato de produzir, boa margem).

---

## MECÂNICA DE JOGO

**8. INPUT PRINCIPAL — CLIQUE ALTERNADO**
Metade esquerda e metade direita do ecrã, alternadamente. Sem botões desenhados a ocupar espaço.
O bónus de ritmo é o que dá valor ao clique (ver ponto 1).
CLARIFICAÇÃO (2026-08-22): o streak de ritmo decai sozinho com a inatividade, em vez de congelar. Depois de um período de graça sem toques, o streak desce de forma constante ao longo do tempo até chegar a zero; a intensidade acompanha essa descida naturalmente, arrefecendo os orbs em vez de os cortar de repente. Retomar os toques durante a decadência continua a partir do streak já decaído, não do zero — parar custa progresso, mas não é um castigo abrupto.
Razão: um streak que fica congelado até ao próximo toque parece um bug, não uma pausa. A decadência transmite a sensação de energia a esfriar, coerente com toda a escalada de intensidade construída à volta dela.

**9. CORTINA DE ESPETÁCULO**
No início do duelo, as duas metades (verde à esquerda, roxo à direita) abrem-se como cortinas de teatro, mostrando as zonas de toque, e recolhem. Depois disso, cada toque acende brevemente a metade correspondente, de forma subtil. Nunca voltam a ser opacas. Ensina sem parecer tutorial.
Modo fácil e opções permitem mantê-las visíveis.
CLARIFICAÇÃO (2026-08-22): as zonas são totalmente transparentes em repouso — sem nenhum split visível no ecrã — e só existem como um breve flash por toque, que sobe e volta a desaparecer por completo. Não escalam com a intensidade nem com mais nada. São feedback funcional — indicam onde tocar — nunca feedback emocional. Toda a escalada emocional (intensidade) flui exclusivamente para os orbs e para a barra de aura, nunca para as zonas.
Razão: misturar feedback funcional com emocional fazia as zonas dominar o ecrã precisamente quando os efeitos de partículas deviam assumir o protagonismo, e escondia os orbs convergentes.

**10. FEEDBACK DE TOQUE (sempre ativo)**
Visual: a metade tocada acende por instantes.
Tátil: vibração curta a cada clique, desligável nas opções, ligada por defeito. Mais forte quando o burst dispara.
Sonoro: som distinto para cada lado, reforçando a alternância pelo ouvido.
Razão: a alternância é a mecânica central e precisa de ser sentida, não só vista.

**11. GESTO "SIX SEVEN" — MECÂNICA PRINCIPAL, DESDE A V1**
Telemóvel na palma da mão, levanta e baixa. Presente desde a primeira versão, em todos os modos.
Deteção: acelerómetro no eixo Y, descontada a gravidade. O padrão é pico positivo seguido de pico negativo dentro de uma janela de tempo (o acelerómetro mede aceleração, não posição).
Ciclo de três repetições. À terceira, o locutor grita "SIX SEVEN!" e o burst enche. O jogo acompanha a contagem visualmente: primeira repetição o avatar mexe, segunda o ecrã começa a acender, terceira rebenta. Parar a meio apenas reinicia a contagem, sem castigo.
Tolerância generosa. Um falso positivo é barato; um falso negativo faz o miúdo desistir.
Valor de marketing: é demonstrável sem ecrã — um miúdo mostra o jogo ao amigo só com o gesto.

**12. DIVISÃO DE FUNÇÕES**
Clique = aura (o rendimento). Gesto = burst (a intensidade). Não competem porque não fazem a mesma coisa.
O gesto sozinho não gera aura, logo multiplica zero — o que elimina a batota (telemóvel amarrado a um ventilador) sem precisar de sistema anti-batota.
A jogada ótima é fazer os dois em simultâneo, que é exatamente o gesto do meme original.

**13. BURST — RECURSO, NÃO MULTIPLICADOR CONTÍNUO**
A barra só sobe, nunca arrefece. Enche devagar. Ao encher, dispara automaticamente.
Visualmente é um núcleo circular de energia a carregar, com três entalhes correspondentes às três repetições do gesto. Não é uma barra genérica.

**14. BURST — MOMENTO DE FESTA**
Ecrã inteiro a piscar, chuva de papel picado dourado, grito da multidão, locutor a anunciar. Cliques multiplicados.
O objetivo é emocional, não mecânico: é o momento que o miúdo conta ao amigo.
Nota técnica: partículas em GPU, medir performance em gama baixa — o público não tem topos de gama.

**15. LOCUTOR**
Texto grande atravessando o topo, com som de multidão. Aparece só quando há algo a dizer.
Reage a padrões: ritmo certo, alternância perfeita, gesto completo.
O locutor não anuncia o boost — o locutor É o evento. Voz e recompensa são a mesma coisa. O jogador aprende a caçar as frases dele.

---

## MODOS

**16. MODO HISTÓRIA**
Progressão por cenários, cada um com um chefe. Escalada deliberadamente absurda: bairro, feira, estádio de futebol, rua à noite, Las Vegas, Lua, Marte, espaço.
O adversário não joga ao vivo — é um alvo parado com nome, cara e número (ex. "Rei do Cassino — 50.000"). Sem IA, sem timing. É uma tabela de nomes e números.
Cada cenário tem o SEU chefe, adequado ao local.
Ao vencer: baú com moedas mais um cosmético do adversário derrotado (os óculos dele, o boné, o capacete). Troféu vestível que conta uma história sem texto.
Recompensas em moedas e cosméticos, nunca em poderes — poderes exigem balanceamento.

**17. TEMPO (só no modo história)**
Modelo Super Mario World: generoso, raramente o obstáculo real, mas presente. Impede o nível de ser vagueado indefinidamente.
O tempo restante converte-se em bónus de aura ou moedas no fim — o que dá razão para repetir níveis já vencidos.

**18. MODO ARCADE**
Sem tempo, sem limiares. Existe para expressão.
Medidor de velocidade de cliques, com achievements próprios por atingir determinados ritmos.
Achievements exclusivos deste modo, ligados a padrões de movimento (à maneira das manobras de skate).
Achievements locais na primeira versão, não Google Play Games Services.

**19. GAME OVER E CONTINUAR**
Se o tempo esgota: ecrã de game over. Duas formas de continuar de onde parou — ver um vídeo com recompensa, ou gastar moedas já possuídas.
NÃO existe opção de comprar moedas com dinheiro real neste ecrã. A compra de pacotes existe apenas dentro da loja, em momento neutro.
Razão: o público tem 9-13 anos. Vender no pico de frustração é o padrão que os reguladores perseguem e que põe em risco a aprovação na Play Store.
Efeito positivo: as moedas ganham tensão — guardar para a loja ou gastar para continuar.

---

## ECRÃ DE DUELO — LAYOUT

**20. COMPOSIÇÃO E HIERARQUIA VISUAL**
Ordem de dominância: 1) o avatar, elemento maior e mais brilhante, ~45% da altura do ecrã; 2) a multidão e o palco; 3) o cenário de fundo, sempre mais escuro e desfocado — atmosfera, nunca competição; 4) a UI, mínima e encostada às bordas.
Quatro camadas de profundidade: fundo em perspetiva com luzes; multidão em silhueta com contraluz; herói iluminado por spotlight num estrado; silhuetas cortadas nos cantos inferiores para dar parallax.
Barra de aura horizontal no topo, com o valor atual à esquerda e o alvo à direita — legível num relance.
Adversário pequeno no canto superior direito. Ao ser derrotado, o cartão parte-se e liberta o cosmético.
Contador de tempo pequeno no canto superior direito.
Núcleo de burst pequeno no canto inferior direito, longe do centro (onde o polegar tapa).
Faixa do locutor no topo, entra e sai.
O nome do jogador NÃO aparece durante o duelo — ele sabe quem é, e aquele espaço é palco.

**21. AVATAR ANIMADO, NÃO SETAS**
Sem mãos desenhadas nem indicadores estilo Dance Dance Revolution. O jogador faz o gesto e vê o SEU avatar executá-lo. É espelho, e é daí que nasce o vínculo.
Funciona com qualquer avatar por causa da arquitetura em camadas.

---

## IDENTIDADE DO JOGADOR

**22. NOME CUSTOMIZÁVEL**
Cores e multicolor desde o início. A partir do nível de aura 30, desbloqueia brilhos e animações.
Barato de construir (texto com shader), altíssimo valor percebido, e é o tipo de coisa que esta idade mostra aos amigos.

**23. AVATAR EM CAMADAS**
Sprites sobrepostos (corpo, cabelo, óculos, acessórios), não sprite único.
Permite personalização progressiva e vínculo com a personagem construída peça a peça.
Não se limita a Gigachad/sigma — vários corpos e estilos. Manter coerência visual para não parecer um saco de assets.

**24. BANDEIRAS**
Onboarding: escolha livre de bandeira nacional, que ondula no cenário. Não detetada pelo telemóvel — o miúdo escolhe a que quiser.
Loja: bandeiras decorativas (pirata, chamas, padrões).
Evitar territórios disputados e símbolos politicamente sensíveis — risco de bloqueio regional ou classificação etária mais alta.

**25. RECOMPENSAS DE NÍVEL**
Ao subir de nível de aura: moedas e um item. Os melhores itens continuam exclusivos da loja.
Subir de nível alimenta a loja em vez de a tornar irrelevante.

---

## LOOP COMPLETO

**26.** Clicas alternado mantendo o ritmo → ganhas aura e sobes a barra → fazes o gesto SIX SEVEN → burst enche → dispara → festa e multiplicador → passas o alvo dentro do tempo → ganhas o cosmético do adversário e o bónus de tempo → vais ao quarto → vestes o teu avatar → ele aparece melhor no duelo seguinte e nas caretas do ecrã de casa.

---

## PRODUÇÃO DE ARTE

**27. CONCEPT ART VS ASSETS**
As imagens geradas até agora são CONCEPT ART — ilustrações completas com cenário, luz e UI cozidos numa só imagem. Não são utilizáveis como assets. Servem como referência visual e para mostrar a um ilustrador.
Para produção são precisos PNGs separados com fundo transparente, alinhados ao mesmo esqueleto.

**28. MANTER A COERÊNCIA VISUAL**
Guardar a melhor imagem gerada como referência mestra e usá-la sempre como imagem de referência.
Guardar o bloco de STYLE do prompt num ficheiro de texto e colá-lo sempre igual, nunca reescrever de memória.

**29. AVATAR — SÓ VISTA FRONTAL**
Não são precisas vistas laterais nem de costas. O jogo passa-se num palco, de frente para o jogador; a personagem nunca caminha nem se vira.
Vantagem decisiva: cada cosmético é UM desenho em vez de quatro. A loja não triplica de custo.
Uma única pose base frontal, simétrica, braços relaxados, luz plana sem sombras. A animação faz-se no Godot, rodando as partes (cabeça, tronco, braços em dois segmentos, pernas).
Poses especiais isoladas (vitória, por exemplo) podem ser geradas à parte, mas nunca como sistema.

**30. CAMINHOS PARA A ARTE FINAL**
Opção A: packs de assets prontos em camadas (itch.io, OpenGameArt). Rápido, suficiente para portfólio.
Opção B: ilustrador (~200-500€ por avatar completo com camadas), usando o concept art como referência.
Opção C: formas geométricas como placeholder, construir a mecânica primeiro, arte no fim.
Decisão tomada: C agora, A depois. O código a funcionar vale mais que arte bonita sem jogo por baixo.

---

## PENDENTES

**31. POR AFINAR A JOGAR (não decidir em papel)**
Velocidade de enchimento do burst. Duração do burst. Janela de tempo entre repetições do gesto (instinto inicial: cerca de um segundo). Limiares do acelerómetro. Generosidade do tempo em cada nível. Curva de dificuldade dos limiares dos adversários. Tolerância da janela de ritmo (o mais crítico de todos, ver ponto 1).

**32. A VERIFICAR ANTES DA SUBMISSÃO**
Enquadramento do público na Play Store: categoria infantil tem restrições sobre anúncios e compras; declarar 13+ muda o enquadramento mas reduz alcance. Decisão de negócio.
Direitos de imagem: "Gigachad" é baseado numa pessoa real (Ernest Khalimov) e já gerou problemas comerciais a terceiros. Música phonk é maioritariamente protegida.
Requisitos técnicos da Play Store para 2026 (target SDK) — confirmar na altura, mudam todos os anos.

**33. NOTA SOBRE DISTRIBUIÇÃO**
Play Store e web dão retorno financeiro semelhante para um jogo novo sem marketing: o problema é a descoberta, não a plataforma.
Play Store custa 25 dólares, 14 dias de teste fechado com 12 testadores, verificação de identidade, política de privacidade e formulário de segurança de dados.
Web publica-se hoje, com link partilhável.
Para o objetivo declarado (portfólio), um link jogável em três segundos vale mais a um recrutador que uma app que ele teria de instalar. O Godot exporta para ambos — decidir no fim, não agora.

---

## EM GAVETA (só se a comunidade pedir)

**34.** Modo versus ao vivo com bot de IA. Campeonato online de gesto (exige servidor, contas e anti-batota).

---

## ESTADO DO PROJETO

**35. FEITO (design e configuração)**
Projeto Godot 4 configurado (mobile, portrait, 720x1280). Pasta local, repositório GitHub, `.gitignore`, estrutura de pastas (`assets/`, `scenes/`, `scripts/`) em snake_case. Renomeação completa para Auramax. Quatro mockups de referência gerados. Protótipo web jogável testado e validado.

**36. PRÓXIMO PASSO (à data do ponto 35)**
Zonas de toque alternado com bónus de ritmo. **Já concluído** — ver secção "ESTADO DO CÓDIGO" no fim deste documento.

---

## ACRESCENTOS DE TOM E CONTEÚDO

**37. O JOGO NÃO É DE DANÇA — É DE ABSURDO**
Investigação sobre o fenómeno real de "aura farming": não se resume a dançar. Há fantasias completas, pessoas a atirarem-se ao chão, braços a abanar, movimentos deliberadamente ridículos.
Consequência de design: o avatar não deve executar apenas passos de dança elegantes. Deve ter poses absurdas, exageradas, cómicas. É isso que ganha o público de 9-13 anos.
Diferenciação: nenhum concorrente vai por aqui — estão todos presos ao barco indonésio.

**38. FANTASIAS COMO ITEM PRINCIPAL DA LOJA**
Fantasias completas (não só acessórios) são o item de maior valor percebido e, graças à decisão de vista frontal única (ponto 29), custam UM desenho cada.
Exemplos de direção: dinossauro insuflável, animais absurdos, frutas, objetos.
AVISO DE IP: não usar personagens protegidos (Pokémon, Mario, super-heróis). A Nintendo em particular é agressiva na defesa de IP. Criar versões originais que evocam sem copiar.

**39. CERIMÓNIA DE TROFÉU**
Ao derrotar cada chefe, há um momento dedicado de entrega: o cosmético dele passa para o jogador com destaque, com o locutor a anunciar. Não é só um item que aparece no inventário — é um momento.
Barato de produzir, alto retorno emocional. Reforça o ponto 16.

**40. MAPA DE PROGRESSÃO**
Ecrã de mapa entre o botão "História" e o duelo. O jogador vê o percurso completo, onde está, e para onde vai a seguir. Locais já vencidos ficam marcados.
Razão: querer chegar ao próximo sítio é motivação por si só. Sem mapa, a progressão é invisível.
Lista de locais proposta: rua, escola, feira, ginásio, campo de futebol, estúdio de TV, campo de golfe, futebol americano, basebol, Taj Mahal, floresta amazónica, Las Vegas, Lua, Marte, espaço.
NOTA DE CUSTO: cada local é um cenário desenhado. Fazer os primeiros quatro muito bem e deixar os restantes para expansão.

**41. TRANSIÇÕES NARRATIVAS ENTRE CAPÍTULOS**
A progressão não é uma lista de locais soltos. Momentos-chave ligam blocos de cenários com pequenas animações absurdas, sem jogabilidade, de poucos segundos.
Exemplo definido: ao vencer o alienígena no centro espacial (SpaceX/NASA), um raio abduz o avatar e leva-o num disco voador até à Lua, onde enfrenta o próximo chefe.
Função: dar razão narrativa à mudança de local e criar antecipação.
REGRA: só nas transições GRANDES (Terra → espaço, espaço → outro planeta). Se cada nível tiver animação, deixa de ser especial e passa a ser interrupção.
Custo: baixo. Um raio, o avatar a subir, corte para o novo cenário. Três segundos chegam.

---

## ARQUITETURA

**42. PRINCÍPIO ORIENTADOR**
Separar o que muda do que não muda, em três camadas. As camadas de cima dependem das de baixo, nunca o contrário. A lógica não sabe o que a arte faz; a arte não sabe como a lógica calcula.

**43. AS TRÊS CAMADAS**
- **Dados** — níveis, chefes, cosméticos, limiares. Ficheiros (`.tres` ou JSON), não código.
- **Lógica** — ritmo, burst, deteção do gesto, estado do duelo. Lê dados, emite sinais.
- **Apresentação** — ColorRect, sprites, HUD, partículas. Escuta sinais e reage.

Consequência prática: trocar o ColorRect verde por arte final não toca numa linha de lógica. É isto que permite construir com formas geométricas agora (ponto 30, opção C) e substituir depois.

**44. DESIGN DATA-DRIVEN**
Níveis, adversários e cosméticos vivem em ficheiros de dados, não em código.
Acrescentar a Lua = acrescentar uma linha num ficheiro. Acrescentar um cosmético = acrescentar uma entrada.
É isto que torna o jogo expansível sem refactor.

**45. COMPOSIÇÃO EM VEZ DE HERANÇA**
Modelo de nós do Godot. O avatar não é uma classe "AvatarComChapéu" — é um nó com filhos que se somam.
Adicionar um cosmético é adicionar um filho, não criar uma subclasse.
Casa diretamente com a decisão do avatar em camadas (ponto 23).

**46. PADRÃO OBSERVADOR (sinais do Godot)**
A lógica emite eventos: `ritmo_perfeito`, `burst_cheio`, `gesto_completo`, `alvo_atingido`.
Quem quiser reage — o papel picado, o locutor, a vibração, o som.
A lógica não sabe que existe papel picado. Desacopla apresentação de regras.

**47. SINGLETON / AUTOLOAD PARA ESTADO GLOBAL**
Um único `GameState` guarda aura, nível de aura, moedas e itens possuídos.
Fonte única de verdade — evita que cada cena tenha a sua cópia e discordem entre si.

**48. PARÂMETROS EXPOSTOS, NUNCA HARDCODED**
Tudo o que está na lista de "afinar a jogar" (ponto 31) declara-se com `@export`.
Aparece no inspetor do Godot e afina-se com slider, sem editar código nem recompilar.

**49. MÁQUINA DE ESTADOS PARA O DUELO**
Estados explícitos: `A_COMEÇAR`, `A_JOGAR`, `EM_BURST`, `VITÓRIA`, `DERROTA`.
Impede bugs de estados sobrepostos ("ganhei e perdi ao mesmo tempo").

**50. NOTA DE APRENDIZAGEM**
O código é escrito com apoio de IA, mas as decisões de arquitetura são do autor e devem ser compreendidas.
Conceitos a estudar para conseguir defender o projeto: separação em camadas, design data-driven, composição vs herança, padrão observador, singleton, máquina de estados.
O objetivo do projeto é portfólio — o valor está em saber explicar porquê, não em ter código gerado.

---

## IDENTIDADE E CONFIGURAÇÃO

**51. IDENTIDADE EDITÁVEL APÓS CRIAÇÃO**
Nome, bandeira e idioma são alteráveis nas opções a qualquer momento, não apenas no onboarding.
Consequência técnica: os campos do `GameState` nascem com setters e sinais próprios, nunca write-once.

**52. IDADE — DECISÃO ADIADA**
Não perguntar a idade na v1. Perguntar constitui *age gate* e ativa obrigações legais (COPPA nos EUA, GDPR-K na UE) sobre dados e publicidade.
A decisão fica para antes da submissão, junto com o enquadramento do público na Play Store (ponto 32).

**53. IDEIAS DE ACHIEVEMENTS (por decidir quando chegar a hora)**
- Primeiro gesto SIX SEVEN executado com sucesso (marca o momento em que o jogador descobre a mecânica assinatura)
- 67 gestos SIX SEVEN acumulados: "Super Six Seven Aura"

Princípio: usar o 67 como número recorrente em marcos, por ser o número identitário do jogo.
Nota técnica: o `AchievementManager` será um componente que escuta sinais existentes e conta. Não exige refactor, desde que cada mecânica nova emita sinal para os eventos que possam vir a ser celebrados — incluindo o gesto do acelerómetro, quando for construído.

---

## ARRANQUE DO DUELO

**54. ECRÃ DE PREPARAÇÃO ("get ready")**
Aparece SEMPRE, antes de cada duelo. É ritual, não tutorial.
Locutor grita uma chamada ("Estás preparado?" / "Força!"), com som de multidão.
Contagem curta — cerca de dois segundos. Numa primeira vez cria expectativa; à trigésima é uma barreira entre o miúdo e o jogo.
A DECIDIR POR TESTE: apenas "get ready" seguido de "GO", ou contagem numérica 3-2-1-vai. Testar as duas e sentir qual funciona.
Nota de localização: as falas não são traduções literais. Cada idioma leva a expressão natural (em PT-PT "Vai!" ou "Força!", não "Ação").

**55. DEMONSTRAÇÃO DOS LADOS (só no primeiro contacto)**
Distinta do get ready. Cortinas fechadas, pisca o lado roxo com "clica aqui", depois o verde, e as cortinas abrem.
Ensina por demonstração, não por texto de tutorial.
O jogo arranca sozinho no fim da demonstração, sem esperar clique. Mas se o jogador clicar durante a demonstração, corta e arranca logo — quem já sabe salta, quem não sabe é ensinado.
Referência: ecrãs de "get ready" dos arcades Neo Geo.

**56. MULTIDÃO REATIVA AO STREAK**
A multidão de fundo reage à intensidade: parada em repouso, a dançar e saltar à medida que o streak cresce, em festa no burst.
Nota de arquitetura: não exige mecânica nova. A multidão é apenas mais um consumidor do sinal `intensity_changed` que já existe, tal como a cor das zonas e as bolinhas de poder.

---
---

# ESTADO DO CÓDIGO — PARA CONTINUAR

Esta secção existe para que qualquer agente (ou o próprio autor) possa retomar o trabalho sem perder contexto.

## Convenções obrigatórias

- **Todo o código, nomes de nós, variáveis, funções e comentários em INGLÊS.** Os documentos de design são em português; o código não.
- Ficheiros e pastas em `snake_case` (Android é case-sensitive).
- Nenhum valor afinável hardcoded — usar `@export`.
- Nenhuma string visível hardcoded — usar `tr()` com chave.
- Todo o áudio encaminhado para o bus correto, nunca Master diretamente.
- Comentários explicam o PORQUÊ, não o quê.
- A camada de lógica não manipula apresentação diretamente (exceto o tint mínimo das zonas). Tudo o resto via sinais.

## Já construído e commitado

**Fundação** (commit `5763696`)
- `default_bus_layout.tres` — buses Master, Music, Announcer, SFX. Procura por nome, nunca por índice.
- `scripts/settings_manager.gd` (autoload `SettingsManager`) — volume/mute por bus, hápticos on/off, locale. Persiste em `user://settings.cfg`. Sinal `setting_changed(key, value)`.
- `scripts/game_state.gd` (autoload `GameState`) — `player_name`, `flag_id`, `avatar_gender`, `aura_level`, `coins`, `owned_cosmetics`, `equipped_cosmetics`. Setters com validação e sinais por campo. Persiste em `user://save.cfg`.
- `scripts/music_manager.gd` (autoload `MusicManager`) — dicionário `TRACKS` data-driven, crossfade com tween, ignora ficheiros em falta com aviso.
- `scripts/locale_manager.gd` (autoload `LocaleManager`) — envolve `TranslationServer`, `SUPPORTED_LOCALES` = en, pt, es, fr, de, it.
- `assets/i18n/announcer_lines.csv` — importado para `.translation` por locale. **Nota**: o Godot não aceita o `.csv` diretamente em `locale/translations`; tem de listar os `.translation` gerados.

**Locutor e duelo** (commit `80dca59`)
- `scenes/announcer.tscn` / `scripts/announcer.gd` — `LineLabel`, `VoicePlayer` (bus Announcer), `CrowdPlayer` (bus SFX). `announce(event_key)` escolhe linha aleatória do pool, anima entrada/saída, toca voz de `assets/audio/voice/{locale}/{line_key}.ogg` se existir, senão só texto.
- **Totalmente desacoplado**: em `_ready()` liga-se ao sinal `streak_changed` do pai via `has_signal()`. O duelo nunca referencia o locutor.
- `scenes/duel.tscn` / `scripts/duel.gd` — `LeftZone`/`RightZone` (#00FF66 / #9D00FF, quase transparentes), `AuraBar`, `AuraLabel`, `StreakLabel`, `OrbSpawner`, instância do locutor.
- Alternância obrigatória, janela de ritmo adaptativa, bónus de aura escalado pelo streak com teto, valor único `intensity` suavizado por lerp a alimentar tint das zonas, brilho da barra e emissão de orbs.
- Orbs desenhados proceduralmente (`Polygon2D`) por não existirem texturas.
- Sinais: `valid_tap`, `invalid_tap`, `streak_changed`, `aura_changed`, `intensity_changed`, `milestone_reached`, `burst_ready` (declarado, não implementado).

**Correção pendente/aplicada**
- Extração do calendário de milestones (5, 10, depois +3) para um `Resource` partilhado, para eliminar a duplicação entre `duel.gd` e `announcer.gd`.

## Verificado

Executado em headless com `Godot_v4.7.2-stable_win64_console.exe --headless`, exit code 0, sem erros. Testado com harness temporário de 22 toques alternados (removido depois): acumulação de aura, milestone a disparar no streak 5, escalada de tier, e reset por toque inválido — todos confirmados.

## Problema conhecido

As zonas verde e roxa estão **demasiado visíveis** no estado atual. Devem estar quase invisíveis em repouso e só acender subtilmente ao toque. Ajustar `zone_base_alpha` (~0.04) e `zone_max_alpha` (~0.18) no inspetor, ou rever os valores por defeito.

## Próximos passos, por ordem

1. **Afinar a visibilidade das zonas** — problema acima. É rápido e melhora imediatamente a sensação.
2. **Ecrã de preparação e demonstração dos lados** (pontos 54 e 55).
3. **Burst e festa** (pontos 13 e 14). O sinal `burst_ready()` já está declarado à espera. Máquina de estados do duelo (ponto 49) entra aqui.
4. **Gesto SIX SEVEN** (ponto 11). Acelerómetro no eixo Y, ciclo de três repetições, tolerância generosa. Deve emitir sinal próprio para futuros achievements.
5. **Avatar em camadas** (pontos 21, 23, 29). Placeholders geométricos primeiro.
6. **Adversário, tempo e condição de vitória** (pontos 16, 17).
7. **Ecrã de casa, O Quarto, opções, onboarding** (pontos 5, 6, 7).
8. **AchievementManager** — componente que escuta sinais existentes e conta (ponto 53).

## Modo de trabalho preferido pelo autor

- Um passo de cada vez, respostas breves, sem monólogos.
- Pensar e decidir ANTES de gerar código.
- Prompts entregues como bloco pronto a colar no Claude Code, sem explicação à volta.
- Grande parte da conversa é por voz — respostas devem ser fáceis de ouvir.
- O progresso é guiado por inspiração, não por calendário rígido.
