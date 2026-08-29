# AURAMAX 67 — LIVRO DE REGRAS

Ler ANTES de escrever ou pedir qualquer código. Isto não é design — é como não voltar a partir o que já funciona.

---

## REGRA 1 — Nunca tipar estaticamente contra uma classe nova

Se um script novo tem `class_name`, nenhum outro script pode referenciá-lo por tipo (`@onready var x: NovaClasse`) enquanto o Godot não o tiver registado na cache dele.

**Porquê:** o Godot só sabe destas classes depois de um `EditorFileSystem.scan()` — que só acontece dentro de uma instância real do editor (ao abrir o projeto, ao ganhar foco, ou num import headless). Um ficheiro escrito diretamente em disco por uma ferramenta nunca dispara isso. Se `duel.tscn` (ou qualquer cena) tiver UM script que tipa contra uma classe ainda não cacheada, a cena INTEIRA falha ao carregar — não só a parte nova.

**Como aplicar:**
- Todo `@onready var` referencia o tipo nativo do Godot (`Control`, `Node2D`, `Label`...), nunca o `class_name` customizado.
- Toda variável, parâmetro ou array que guarde uma instância de uma classe customizada usa `var x = ...` sem anotação de tipo, com um comentário a apontar para esta regra.
- Isto vale para TODOS os scripts da mesma cena, não só o script raiz. Um `ResultScreen` ou `BossCard` que tipe contra `Scenario` derruba a cena tanto quanto o `duel.gd` derrubaria.

**Verificação antes de terminar uma tarefa:**
1. `grep` a toda a pasta `scripts/` (e `.tres`/`.tscn` com exports tipados) por `: NomeDaClasse`, `-> NomeDaClasse`, `Array[NomeDaClasse]` — para CADA classe nova ou tocada na tarefa, em TODOS os ficheiros, não só no principal.
2. Qualquer ocorrência fora do próprio ficheiro que define a classe é violação. Converter para não tipado.
3. Confirmar contra `.godot/global_script_class_cache.cfg` — ler o ficheiro e ver se a classe nova lá consta. Se não constar, a regra 1-2 é obrigatória, sem exceções.
4. Só relaxar isto depois de confirmado que o projeto foi aberto no editor real (ou correu um import headless) — aí a classe aparece na cache e passa a ser segura.

**Sinal de que isto aconteceu:** o jogo "morre" por completo — sem inputs, sem erro visível, só os elementos que não dependem de script (como `ColorRect`) continuam lá. Tempo e ecrãs desaparecem juntos, mesmo sem terem sido tocados — porque a cena toda falhou ao fazer parse.

---

## REGRA 2 — "Remover" tem de dizer o que fica

Quando um prompt pede para remover um mecanismo, tem de listar explicitamente o que DEVE PERMANECER. Nunca dizer só "remove X".

**Porquê:** já aconteceu pedir a remoção do decaimento gradual do streak, e a IA removeu também o relógio que zerava o streak sem input — um bug já corrigido antes, reintroduzido por um "remove" vago.

---

## REGRA 3 — Nunca refatorar código validado

Preferir sempre ACRESCENTAR um componente novo que escuta sinais existentes, em vez de reestruturar um sistema que já funciona.

**Porquê:** refactors de sistemas validados são a principal fonte de regressões neste projeto. A tentativa de máquina de estados (`State` enum) no duelo causou regressão total e foi revertida — o burst acabou implementado como uma simples flag booleana (`is_bursting`) ao lado do código existente, sem tocar nele.

**Como aplicar:** todo prompt que adicione uma feature nova ao duelo deve dizer explicitamente "não tocar em `_handle_tap`, `_complete_pair`, `_grant_aura`, intensidade, streak" (ou o que for o núcleo já validado), e construir por cima via sinais.

---

## REGRA 4 — Não enxertar features que dependem de ecrãs inexistentes

Uma feature que precisa da Casa, do Onboarding ou de outro ecrã ainda não construído não deve ser forçada dentro do Duelo só porque é onde se testa mais fácil.

**Porquê:** o ecrã de "get ready" e a demonstração dos lados dependiam de saber se era a primeira abertura do jogo (Onboarding) e de navegação vinda da Casa. Enxertados no duelo sozinho, congelaram a cena. Foram revertidos e adiados até existirem os ecrãs de que dependem.

**Como aplicar:** antes de pedir uma feature, perguntar "isto depende logicamente de algo que ainda não construímos?". Se sim, a ordem de construção tem de mudar primeiro.

---

## REGRA 5 — Consultar o DESIGN.md antes de perguntar

Antes de fazer qualquer pergunta sobre decisão de design ao Julio, procurar primeiro no `DESIGN.md`. Só perguntar o que genuinamente não está lá.

---

## REGRA 6 — Todo código em inglês

Nomes de nós, variáveis, funções e comentários — sempre em inglês. Os documentos de design são em português; o código nunca.

## REGRA 7 — Nada hardcoded

Nenhum valor afinável hardcoded — usar `@export`. Nenhuma string visível hardcoded — usar `tr()` com chave de tradução.

## REGRA 8 — Áudio sempre pelo bus certo

Nunca tocar áudio diretamente no bus Master. Sempre pelo bus específico (Music, Announcer, SFX).

## REGRA 9 — Sinais, não acoplamento direto

A camada de lógica não manipula apresentação diretamente (exceto o tint mínimo, quando explicitamente decidido). Tudo o resto comunica via sinais, para que a apresentação seja substituível sem tocar na lógica.

## REGRA 10 — Comentários explicam o porquê

Não descrever o que uma linha faz — isso lê-se no código. Explicar a razão da decisão, especialmente quando contraria o óbvio (ex: "isto está assim por causa da Regra 1").

---

## REGRA 12 — Testes são permanentes, nunca descartáveis

Qualquer teste escrito para validar uma tarefa FICA no repositório, na pasta `tests/`, com nome descritivo do que verifica. É proibido criar um harness temporário e apagá-lo no fim da tarefa.

**Porquê esta regra existe:** ao longo deste projeto foram escritos harnesses de teste várias vezes — para validar o sistema de ritmo, o burst, o desacoplamento das zonas — e todos foram apagados no fim. Isso é o pior dos dois mundos: gastou-se tempo a escrevê-los e não ficou proteção nenhuma. Bugs em mecânica básica (aura por toque, martelar o mesmo lado, limiar das bolinhas) foram descobertos manualmente pelo Julio a jogar, semanas depois de terem sido introduzidos, quando um teste permanente os teria apanhado no mesmo dia.

**Como aplicar:**
- Toda regra do ponto 68 do `DESIGN.md` (especificação do input) tem de ter um teste correspondente em `tests/`.
- Ao adicionar uma regra nova de mecânica ao `DESIGN.md`, adicionar o teste correspondente no MESMO commit.
- Antes de qualquer commit que toque em `duel.gd`, `burst_core.gd`, `announcer.gd` ou em qualquer lógica de input, aura, streak ou burst: correr a suíte de testes e reportar o resultado na resposta.
- Se algum teste falhar, a tarefa NÃO está terminada, mesmo que o resto funcione.

**Armadilha técnica a evitar (já aconteceu neste projeto):** instanciar uma cena e chamar os seus métodos imediatamente NÃO dispara o `_ready()` do Godot, logo os sinais ainda não estão ligados e o teste pode passar por razões erradas. Um teste tem de esperar pelo menos um frame real (`await get_tree().process_frame`) depois de adicionar a cena à árvore, antes de qualquer asserção. Um teste que não faça isto está a mentir.

**Como correr a suíte:**
```
"J:\PASTA DE BACKUP TUDO\GODOT\auraGodot472\Godot_v4.7.2-stable_win64_console.exe" --headless --path "J:\PASTA DE BACKUP TUDO\GODOT\auraGodot472\auramax" res://tests/duel_input_test.tscn
```
Imprime uma linha PASS/FAIL por teste e sai com código 0 se tudo passar, ou 1 se alguma asserção falhar — verificar sempre o exit code, não só ler a última linha impressa.
