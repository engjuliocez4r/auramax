# AURAMAX 67 — DOCUMENTO DE DESIGN CONSOLIDADO

Versão de 23 de agosto de 2026. Substitui todos os registos anteriores, incluindo o NotebookLM.

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
**Implementado (esqueleto)** — ver secção "ESTADO DO CÓDIGO" no fim deste documento.
Nome do jogador no lugar nobre do topo, assente numa barra fina de nível de aura — identidade e progresso juntos. O nome do jogo só aparece se o jogador não definir nenhum.
Avatar grande ao centro, vestido com o que possui. Tocar nele faz-lhe caretas, gritos e poses — é brinquedo, não atalho. Os cosméticos comprados aparecem nessas reações.
Dois botões grandes lado a lado: História (mostra progresso, ex. "alvo 3 de 12") e Arcade.
Um botão médio por baixo: O Quarto. Ponto vermelho quando há novidade.
Ícone de engrenagem pequeno no canto.
Hierarquia deliberada: quatro entradas com pesos diferentes, não quatro botões iguais.
NOTA DE ESQUELETO: "História" e "Arcade" apontam ambos, por agora, diretamente para `scenes/duel.tscn` — não existe ainda mapa de progressão (ponto 40) nem comportamento real de arcade (ponto 18). O toque no avatar (caretas/gritos/poses) e o ponto vermelho de novidade em "O Quarto" ainda não existem; o avatar é uma forma de cor lisa (placeholder), não a camada de avatar real. A barra de aura sob o nome usa `GameState.ego_points`/`ego` como aproximação provisória — não é ainda a curva de ego definitiva.

**7. O QUARTO (vestir, loja e troféus fundidos)**
**Implementado (esqueleto)** — ver secção "ESTADO DO CÓDIGO" no fim deste documento.
Três abas: Vestir, Loja, Troféus. Comprar e vestir no mesmo sítio — obrigar a mudar de ecrã para equipar é irritante.
Vista dos itens alternável entre tira lateral e grelha, à escolha do jogador.
Botão "Pronto" recolhe os menus e mostra só o avatar no cenário — é o momento de orgulho.
O cenário do quarto é personalizável e vendável (barato de produzir, boa margem).
NOTA DE ESQUELETO: as três abas apenas trocam a visibilidade de três painéis placeholder ("Em breve") — sem inventário, loja ou troféus reais ainda. "Pronto" limita-se, por agora, a voltar à Casa, tal como o botão de retrocesso separado; o comportamento real de recolher os menus e revelar só o avatar fica para quando a camada de avatar existir. Sem alternância tira lateral/grelha ainda.

---

## MECÂNICA DE JOGO

**8. INPUT PRINCIPAL — CLIQUE ALTERNADO**
Metade esquerda e metade direita do ecrã, alternadamente. Sem botões desenhados a ocupar espaço.
O bónus de ritmo é o que dá valor ao clique (ver ponto 1).

**9. CORTINA DE ESPETÁCULO**
No início do duelo, as duas metades (verde à esquerda, roxo à direita) abrem-se como cortinas de teatro, mostrando as zonas de toque, e recolhem. Depois disso, cada toque acende brevemente a metade correspondente, de forma subtil. Nunca voltam a ser opacas. Ensina sem parecer tutorial.
Modo fácil e opções permitem mantê-las visíveis.
O tint das zonas NÃO escala com a intensidade. As zonas são feedback funcional — indicam onde tocar — e mantêm-se visualmente constantes (transparentes em repouso). Só o flash breve de cada toque as altera. Toda a escalada emocional flui para as partículas e a barra de aura, nunca para as zonas.
Razão registada: misturar feedback funcional com emocional fazia as zonas dominarem o ecrã precisamente quando as partículas deviam assumir, e tapava a convergência das orbs.

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
**Implementado** — ver secção "ESTADO DO CÓDIGO" no fim deste documento.
Progressão por cenários, cada um com um chefe. Escalada deliberadamente absurda: bairro, feira, estádio de futebol, rua à noite, Las Vegas, Lua, Marte, espaço.
O adversário não joga ao vivo — é um alvo parado com nome, cara e número (ex. "Rei do Cassino — 50.000"). Sem IA, sem timing. É uma tabela de nomes e números.
Cada cenário tem o SEU chefe, adequado ao local.
Ao vencer: baú com moedas mais um cosmético do adversário derrotado (os óculos dele, o boné, o capacete). Troféu vestível que conta uma história sem texto.
Recompensas em moedas e cosméticos, nunca em poderes — poderes exigem balanceamento.

**17. TEMPO (só no modo história)**
**Implementado** — ver secção "ESTADO DO CÓDIGO" no fim deste documento.
Modelo Super Mario World: generoso, raramente o obstáculo real, mas presente. Impede o nível de ser vagueado indefinidamente.
O tempo restante converte-se em bónus de aura ou moedas no fim — o que dá razão para repetir níveis já vencidos.

**18. MODO ARCADE**
Sem tempo, sem limiares. Existe para expressão, não para progressão.
O jogador escolhe qualquer chefe JÁ DERROTADO no modo história e volta a enfrentá-lo sem pressão, ou simplesmente brinca com o gesto SIX SEVEN livremente.
Consequência: como só dá acesso a conteúdo já vencido, o arcade NÃO alimenta a aura da história. Não existe atalho — a progressão faz-se sempre no modo história.
Efeito colateral positivo: quanto mais o jogador avança, mais cenários e chefes tem disponíveis para brincar. O arcade cresce como recompensa implícita.
Medidor de velocidade de cliques, com achievements próprios ligados a padrões de movimento (à maneira das manobras de skate). Achievements locais na v1, não Google Play Games Services.

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
Núcleo de burst centrado horizontalmente, na zona inferior do ecrã, por baixo do avatar e com folga clara em relação a ele. NUNCA nos cantos: durante o clique alternado os polegares assentam exatamente nos cantos inferiores, e um medidor aí fica tapado pela mão. O centro fica livre e ganha simetria.
O contador de streak faz parte do HUD (ver ponto 57).
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

## PROGRESSÃO, ECONOMIA E LIÇÕES DE IMPLEMENTAÇÃO

**57. CONTADOR DE STREAK — VISÍVEL DESDE O INÍCIO**
Faz parte do HUD do duelo.
Razão: o jogador precisa de ver o número para APRENDER a regra. Sem ele, "manter o ritmo" é abstrato; com ele, percebe exatamente o que conta como acerto e o que quebra a sequência.
Número sempre visível, discreto, sem competir com o avatar. A cada marco (5, 10, 15, ...) dá um zoom in-out rápido em sincronia com a fala do locutor — deixa de ser informação e passa a fazer parte da celebração.
Chegar a 67 streaks numa só sequência é marco especial: fala própria do locutor, efeito visual distinto e achievement (ver ponto 53).

**58. REFERÊNCIAS VISUAIS ELEITAS**
Referência MESTRA (versão final do ecrã de duelo): define o ESTILO — traço do avatar, tratamento de luz, silhuetas da multidão, profundidade em quatro camadas, hierarquia do ponto 20, barra de aura horizontal com valor atual à esquerda e alvo à direita, cartão do adversário.
IMPORTANTE: o cenário Las Vegas é apenas o exemplo onde esse estilo foi capturado. Cada local do mapa (ponto 40) terá cenário próprio. Replica-se o TRATAMENTO, não o sítio.
Referência do BURST: da versão anterior do mesmo ecrã, aproveita-se APENAS o objeto do núcleo — círculo com volume, espiral interior, entalhes metálicos. Alvo visual para quando a forma geométrica for substituída por arte.
Ambas continuam a ser concept art, não assets (ponto 27).

**59. CURVA DE INTENSIDADE**
A intensidade não é razão linear que satura cedo. Sobe por curva suave (smoothstep) até um streak configurável (`intensity_full_streak`, valor inicial 40).
Razão: com saturação ao streak 10, todos os streaks acima pareciam iguais e a escalada perdia-se.

**60. REGRAS DE INPUT APRENDIDAS NA IMPLEMENTAÇÃO**
- O primeiro toque depois de qualquer reset de streak conta sempre, seja qual for o lado. Rejeitá-lo por "repetir o lado" castigaria o jogador por algo que não podia saber.
- O Windows promove cada toque físico num clique de rato sintético. Sem tratamento, cada toque era processado duas vezes e o segundo invalidava sempre o par. Resolvido com `pointing/emulate_mouse_from_touch=false` no `project.godot`, mais dedupe por tempo no código.
- As partículas começam a emitir exatamente no limiar de streak configurado, não um acima.

**61. MÉTODO DE TRABALHO — LIÇÃO APRENDIDA**
Quando um prompt pede para REMOVER um mecanismo, tem de dizer explicitamente o que FICA. Ao pedir a remoção do decaimento gradual do streak, foi removido também o relógio que zerava sem input, reintroduzindo um bug já corrigido.
Refactors de sistemas que já funcionam são a principal fonte de regressões neste projeto. Preferir sempre acrescentar componentes novos que escutam sinais existentes, em vez de reestruturar código validado.
Corolário aprendido com o get ready: features que dependem de ecrãs ainda inexistentes (casa, onboarding) não devem ser enxertadas no duelo. Construir na ordem certa evita malabarismo.

**62. MODELO DE PROGRESSÃO — AURA E EGO**
**Implementado** — ver secção "ESTADO DO CÓDIGO" no fim deste documento.
Duas moedas de progresso, com propósitos distintos:
- **AURA** — o progresso da história. Contínuo de 0 até 1.000.000. NUNCA zera entre duelos. Cada adversário é um posto de controlo: derrotado o chefe dos 30.000, o duelo seguinte começa nos 30.000 e vai até aos 60.000, e assim por diante. Chegar ao milhão é o fim da história: o jogador torna-se o Auramax 67.
- **EGO** — o nível permanente do jogador, o número que se mostra aos amigos ("sou ego 32"). Sobe com um valor fixo por chefe derrotado, mais o bónus do tempo que sobrou.
Nomenclatura na interface: no duelo a barra chama-se AURA; no ecrã de casa o permanente chama-se EGO. Palavra curta e universal para 9-13 anos.
DECISÃO ANTI-BATOTA: a aura farmada não converte em ego. Clicar muito depressa não dá progresso permanente direto — dá uma vitória mais rápida, e é a rapidez que paga, via bónus de tempo. O incentivo continua, apontado ao sítio certo.

**63. ESTRUTURA POR CENÁRIO — ROUNDS E CHEFE FINAL**
Cada cenário (ponto 40) não é um único duelo contra um chefe — é UMA sequência contínua de 10 rounds dentro do mesmo cenário, com o mesmo duelo a decorrer sem interrupção de jogabilidade.
Aura contínua por cenário: 10 limiares (10.000, 20.000, 30.000 ... até 100.000). Os limiares NÃO são adversários individuais com cara e nome — são marcos de progresso dentro do mesmo confronto.
Nos rounds 1 a 9: ao atingir o limiar, ecrã de resultado normal (ponto 64) com taunt do locutor ou do próprio chefe (visível ao fundo desde o início, comentando). Tempo e o par moedas/ego são atribuídos em CADA round, não só no final — o tempo tem função de progressão constante, não só de clímax. O duelo continua imediatamente a seguir, sem voltar à casa.
No round 10 (100.000): é o CHEFE de verdade. Cerimónia especial — cosmético do chefe, chuva de papel picado, arte do chefe derrotado ao fundo, o jogador em primeiro plano com um troféu.
Razão de produção: com muitos cenários (dezenas a caminho da Lua e além), dar um cosmético por adversário individual não escala. Com chefe de cenário, o custo de arte fica fixo — um cosmético por cenário, não um por round — mesmo que existam centenas de rounds no total do jogo.
O tempo REINICIA a cada round (Super Mario World, ponto 17, aplicado por round e não ao cenário inteiro).
A dificuldade continua a viver nos INTERVALOS entre limiares consecutivos, agora dentro do mesmo cenário em vez de entre adversários.

**64. ECRÃ DE RESULTADO DO DUELO**
**Implementado** — ver secção "ESTADO DO CÓDIGO" no fim deste documento.
Sequência ao ultrapassar o número do adversário:
1. O cartão do adversário parte-se e liberta o cosmético (ponto 20)
2. O tempo para
3. Ecrã ou popup de resultado, mostrando por ordem: aura total atingida; tempo restante convertido em bónus de ego; ego ganho pela vitória; barra de ego a encher e a subir de nível se atingir; moedas ganhas; cerimónia do troféu, com o cosmético a passar para o jogador (ponto 39); mensagem do locutor conforme o desempenho
4. Botão para continuar → mapa ou casa
O ecrã de resultado é onde todo o esforço se converte em recompensa visível. É ele que fecha o loop.

**65. GAME OVER — O QUE SE PERDE**
**Implementado** — ver secção "ESTADO DO CÓDIGO" no fim deste documento.
Se o tempo esgota, o jogador escolhe entre: ver um vídeo com recompensa, gastar moedas que já possui, ou aceitar o game over.
Aceitar o game over devolve a aura ao valor do último posto de controlo (o chefe anterior). O progresso do duelo em curso perde-se, mas nunca o que já estava consolidado.
O estado é guardado automaticamente pelo `GameState`.
Confirma-se o ponto 19: nunca há compra de moedas com dinheiro real neste ecrã.

**66. MOEDAS**
Ganham-se ao vencer cada chefe e servem para comprar cosméticos na loja, ou para continuar após game over.
Existirão pacotes de moedas comprados com dinheiro real, disponíveis APENAS na loja, em momento neutro (ponto 19).
AVISO A RESOLVER ANTES DA SUBMISSÃO (liga ao ponto 32): compras integradas com público de 9-13 anos colocam a app na categoria infantil da Play Store, com regras próprias sobre apresentação e pressão de compra. Não construir o sistema assumindo que passa sem escrutínio.

**67. PENDENTE: PROGRESSÃO PERSISTENTE AO LONGO DE UM PLAYTHROUGH COMPLETO**
Por decidir quando existirem mais adversários/locais (ponto 40): o que acontece quando o jogador chega ao fim do conteúdo atual? Precisa de design real — ecrã de fim de capítulo, loop para conteúdo em construção, mensagem de "voltar em breve", etc. Não decidir agora, só quando o roster deixar de ser trivial de esgotar.
NOTA: com apenas 3 adversários de história implementados, `duel.gd` faz atualmente um loop-back para o primeiro adversário (repõe `GameState.defeated_opponents` e `current_aura`) quando o roster se esgota, só para permitir testar o loop repetidamente sem apagar o save à mão. Isto é **provisório, só para teste**, e está comentado como tal no código — remover e substituir por tratamento real assim que existirem adversários suficientes para o loop deixar de ser necessário.

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

**Correções e afinações aplicadas**
- Extração do calendário de milestones para um `Resource` partilhado (`assets/data/rhythm_milestones.tres`), eliminando a duplicação entre `duel.gd` e `announcer.gd`.
- Zonas totalmente transparentes em repouso (`zone_base_alpha = 0.0`), desacopladas da intensidade.
- Orbs refeitas: entram lentamente das bordas do ecrã como pirilampos e convergem para `AuraCore`, centrado a 55% da altura. Intensidade controla densidade e brilho, nunca velocidade.
- `PowerRing`: anéis finos, ovais, muito ténues, fixos em `AuraCore`, contraindo apenas por raio (íris a fechar). Máximo 3 em simultâneo.
- Streak reset conduzido por RELÓGIO em `_process`, independente de input. Reset total e instantâneo ao fim de `streak_timeout` (1 s), sem decaimento gradual.
- `_last_side` limpo no reset, para o primeiro toque seguinte contar em qualquer lado.
- Curva de intensidade em smoothstep até `intensity_full_streak` (40).

**Burst e celebração** (componente separado, sem máquina de estados)
- `scenes/burst_core.tscn` / `scripts/burst_core.gd` — núcleo circular centrado horizontalmente na zona inferior, desenhado proceduralmente com arco de preenchimento, brilho interior e três entalhes (as três repetições do gesto).
- `burst_meter` enche por marcos, NUNCA decresce, dispara automaticamente ao encher.
- Implementado como flag booleana `is_bursting`, **NÃO** como máquina de estados — a tentativa com `State` enum causou regressão total e foi revertida. Input nunca é bloqueado.
- Durante o burst: aura multiplicada por `burst_multiplier`, confetti dourado em GPU particles, tint dourado no ecrã, orbs no máximo, háptico reforçado, locutor com pool próprio.
- Sinais novos: `burst_meter_changed`, `burst_started`, `burst_ended`.
- Contador de streak com zoom in-out a cada marco.

**Adversário, tempo, vitória e ecrã de resultado** (pontos 16, 17, 62, 64, 65 — modelo histórico, ver bloco seguinte para o estado atual)
- `scripts/opponent.gd` (`Opponent`, `Resource`) — `id`, `display_name` (chave de tradução), `aura_threshold`, `ego_reward` (renomeado de `rank_reward`), `coin_reward`, `cosmetic_id`, `scene_id`, `duel_duration`. Três instâncias em `assets/data/opponents/` (30.000 / 60.000 / 90.000 — os três primeiros intervalos iguais).
- **`base_aura` recalculado** de 1.0 para 38.0, a partir da duração pretendida do duelo (~75 s) e de um teto "sem burst, jogador sustido" — ver o comentário com a conta completa junto ao `@export` em `duel.gd`. Garante que o primeiro round exige burst, sem o tornar impossível sem ele. Este cálculo continua válido: o primeiro limiar do primeiro cenário manteve-se em 30.000 (ver bloco seguinte).
- **`scripts/countdown_timer.gd`** (`CountdownTimer`, extends `Label`) — só modo história, contador pequeno no canto superior direito. `default_duel_duration` (90 s) expõe o fallback. Sinais `time_updated(seconds_left)` / `time_expired()`. Continua em uso, inalterado.
- UNUSED desde a reestruturação em cenários (ver bloco seguinte): `scripts/opponent.gd` e as suas três instâncias `.tres` mantêm-se no repositório, sem ser referenciados por código novo.

**Reestruturação em cenários de 10 rounds com chefe final** (ponto 63 — substitui o modelo de 3 adversários acima)
- `scripts/scenario.gd` (`Scenario`, `Resource`) — `id`, `display_name`, `scene_id`, `boss_name`, `boss_cosmetic_id`, `round_thresholds: Array[float]` (10 entradas), `round_taunts: Array[String]` (9 entradas, rounds 1-9), `ego_per_round`, `coin_per_round`, `round_duration`. Uma instância em `assets/data/scenarios/scenario_01.tres`, com os limiares 30.000/60.000/90.000 dos três adversários antigos como os primeiros 3 dos 10 (depois 120.000 até 300.000, mesmo passo de 30.000).
- `duel.gd` trocou `story_opponents`/`current_opponent` por `story_scenarios: Array[Scenario]` e `current_scenario` + `current_round_index` (0-9), escolhidos em `_setup_story_round()` por `GameState.completed_scenarios.size()` + `GameState.current_round_index` — sem enum de estado, só dois índices. `_check_victory()` decide entre `round_won(final_aura, round_index)` (rounds 1-9) e `duel_won(final_aura)` (round 10, o chefe).
- **Tap/streak/aura/intensity/burst não foram tocados** nesta reestruturação — só a bookkeeping de progressão da história por cima.
- **Aura contínua** (ponto 62): `GameState.current_aura`, `GameState.current_round_index` e `GameState.completed_scenarios` (novos campos persistidos, substituindo `defeated_opponents` para o novo modelo — esse campo antigo fica por usar, ver acima). Cada round arranca no posto de controlo anterior e só avança quando `ResultScreen`/`BossDefeatScreen` comitam a vitória — nunca durante o farming.
- **`scripts/boss_card.gd`** (`BossCard`, substitui `opponent_card.gd`/`OpponentCard`) — mesmo cartão no canto superior direito, agora a mostrar o CHEFE do cenário (nome, limiar final) desde o round 1, não um adversário por duelo. Duck-typed a `duel_won` (só o chefe o faz partir-se), nunca a `round_won`.
- **`scripts/result_screen.gd`** (`ResultScreen`) — agora reage a `round_won` (rounds 1-9), não a `duel_won`. Comita `GameState` (aura, `current_round_index + 1`, moedas, ego) assim que `round_won` dispara, anima a revelação (aura, bónus de tempo → ego, ego, barra de ego, moedas), e termina com a fala de provocação do round (`Scenario.round_taunts[round_index]`, via `Announcer.say_line()` — novo método, não passa pelas pools de `announce()`) em vez da linha genérica de vitória do locutor. O botão "Continuar" já NÃO recarrega a cena: chama `duel.advance_round()`, que reaproveita a bookkeeping já comitada e volta a armar o próximo limiar — o duelo continua sem interrupção (ponto 63).
- **`scripts/boss_defeat_screen.gd`** (`BossDefeatScreen`, novo) — reage a `duel_won` (só o round 10). Mesmo padrão de comita-antes-de-animar do `ResultScreen`, mas com cerimónia própria: confetti dourado (partículas próprias, não as do burst), cosmético do chefe, "%s derrotado!" e troféu. "Continuar" recarrega a cena — ainda o substituto provisório para mapa/casa (ponto 64, passo 4) — e é essa recarga que reativa o loop-back de teste em `_setup_story_round()` quando `story_scenarios` se esgota (ver ponto 67).
- **`scripts/game_over_screen.gd`** (`GameOverScreen`) — inalterado. "Aceitar derrota" continua a recarregar a cena; como cada round agora tem o seu próprio checkpoint (`GameState.current_aura` avança a cada round, não só no chefe), isto já significa "voltar ao início do round atual", não do cenário inteiro — sem precisar de código novo.
- **`GameState`**: `rank`/`rank_points` renomeados para `ego`/`ego_points` (`add_rank` → `add_ego`), mais `current_round_index` e `completed_scenarios` (novos, persistidos). `defeated_opponents`/`add_defeated_opponent` ficam por usar, ao lado de `Opponent`.
- Novas chaves de tradução em `announcer_lines.csv`: nome do cenário, provocações dos 9 rounds, "%s derrotado!", e `result_victory_rank_label`/`result_rank_level_label` renomeadas para `result_victory_ego_label`/`result_ego_level_label` — nas seis línguas suportadas.

**Ecrãs de Casa, Quarto e Definições (esqueleto, pontos 6 e 7)**
- `scenes/home.tscn` / `scripts/home.gd` — agora a **cena principal do projeto** (substituiu `duel.tscn` em `project.godot`). Nome do jogador (ou título do jogo, se vazio) sobre uma barra de rank fina, avatar placeholder (`ColorRect`), botões História/Arcade lado a lado e O Quarto por baixo, ícone de definições no canto. `home.gd` não tem `class_name`, pela mesma razão documentada em `duel.gd`: é o script raiz da cena principal, analisado antes de o cache global de classes estar garantidamente completo.
- História e Arcade apontam ambos para `scenes/duel.tscn` — placeholder deliberado até existirem o mapa de progressão (ponto 40) e o comportamento real de arcade (ponto 18).
- `scenes/the_room.tscn` / `scripts/the_room.gd` — três abas (Vestir/Loja/Troféus) que só trocam a visibilidade de três painéis placeholder ("Em breve"). "Pronto" e o botão de retrocesso fazem ambos o mesmo, por agora: voltam à Casa.
- `scenes/settings.tscn` / `scripts/settings.gd` — **funcionalmente ligado**, não fingido: sliders de volume (Music/Announcer/SFX) e o interruptor de hápticos ligam-se em direto a `SettingsManager`; o seletor de idioma lista `LocaleManager.SUPPORTED_LOCALES` e chama `LocaleManager.set_locale()`; o campo de nome chama `GameState.set_player_name()` (ponto 51). Bandeira e género do avatar são entradas visíveis mas desativadas (`disabled = true`), rotuladas "Em breve" — esses sistemas ainda não existem.
- `scenes/back_button.tscn` / `scripts/back_button.gd` (`BackHomeButton`) — botão partilhado de retrocesso, instanciado em O Quarto e Definições, para não duplicar a chamada `change_scene_to_file` três vezes.
- **`scripts/duel.gd` e todos os seus componentes de suporte não foram tocados** neste trabalho — só ganharam um novo ponto de entrada (Casa → duelo).

## Verificado

Fundação (tap/streak/aura/burst) confirmada em headless na sessão anterior — ver git log. **Nem o bloco adversário/resultado original nem a reestruturação em cenários/rounds/chefe foram executados em headless**, por pedido explícito do autor; fica para teste manual no editor.

## Problemas conhecidos

- **Ecrã de preparação e demonstração dos lados** (pontos 54 e 55) foram tentados e revertidos: dependem de ecrãs que ainda não existem (casa, onboarding), e o enxerto no duelo congelou a cena. Adiados para a fase dos ecrãs.
- **O gesto SIX SEVEN não é testável no computador** — exige telemóvel físico, via exportação Android ou remote deploy.
- **Ainda sem mapa**: o "Continuar" do `BossDefeatScreen` (round 10) e o "Aceitar derrota" do game over continuam a recarregar a própria cena do duelo (`reload_current_scene`), em vez de navegar para a Casa ou um mapa — provisório até existir o mapa de progressão (ponto 40). `ResultScreen` (rounds 1-9) já não recarrega: chama `duel.advance_round()` e continua o mesmo duelo.
- **`scene_id` do `Scenario` ainda não alimenta nada visual** — reutiliza `"street"` do antigo `opponent_01`; sem mapa (ponto 40) não há onde mostrar o local.

## Próximos passos, por ordem

1. **Gesto SIX SEVEN** (ponto 11). Requer telemóvel físico para testar.
2. **Avatar em camadas** (pontos 21, 23, 29). Placeholders geométricos primeiro — Casa e O Quarto já têm onde os encaixar.
3. **Mapa de progressão e onboarding/criação de personagem** (pontos 5, 40) — Casa, O Quarto e Definições já existem em esqueleto (pontos 6, 7).
4. **Get ready e demonstração dos lados** (pontos 54, 55), agora que há de onde vir.
5. **AchievementManager** (ponto 53).
6. **Ligar o fim do cenário (`BossDefeatScreen`) e o game over à Casa** (em vez de `reload_current_scene`), quando o mapa existir.

## Modo de trabalho preferido pelo autor

- Um passo de cada vez, respostas breves, sem monólogos.
- Pensar e decidir ANTES de gerar código.
- Prompts entregues como bloco pronto a colar no Claude Code, sem explicação à volta.
- Grande parte da conversa é por voz — respostas devem ser fáceis de ouvir.
- O progresso é guiado por inspiração, não por calendário rígido.
