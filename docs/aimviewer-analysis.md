# Correções 5.4 — estado atual

- Causa da câmera presa: `CFrame.lookAt` era calculado por frame com a direção da cabeça/raiz ou ponto de mira. Agora apenas a posição é acompanhada; yaw/pitch pertencem ao observador e usam GetMouseDelta. Scriptable é mantido por um único controlador; CameraSubject não é alterado para o alvo. Snapshot inclui MouseBehavior e MouseIconEnabled.
- Causa da linha ausente: a implementação 5.2/5.3 só criava um ponto vermelho. Agora há Beam branco de largura 0,035 com duas âncoras locais não colidíveis/não consultáveis. Oculta imediatamente ao desligar ou trocar de alvo e é destruído no encerramento.
- Fonte aceita: MousePos/MousePosition Vector3Value ou CFrameValue no personagem/BodyEffects. Só depois de alteração observada e por até 0,75 s, rejeitando vetores inválidos e distância acima de 5.000 studs. A existência desse campo não prova que corresponda ao cursor ou resultado balístico: a semântica e disponibilidade precisam de validação no servidor alvo. Sem dado, não há linha substituta.
- Anti-Aim removido do código, configurações e inputs.
- Hover agora usa MouseEnter/MouseLeave do hit target estático, com um único item ativo. O conteúdo visual se move, sem deslocar a área de clique.
- Inicialização usa marcos reais de montagem, com yields para renderizar a barra; não representa download. Fade da barra precede o fade do degradê e menu fica fechado. Camadas de carregamento são destruídas.

Validação: testes simulados de mouse independente, acompanhamento de posição, seleção/ambiguidade, fontes válidas/inválidas/expiradas, mudança de jogador, morte/respawn/saída, substituição/restauração da câmera e mouse, hover isolado, carregamento, K e limpeza. Compilação Luau. Não houve sessão de Roblox conectada: fluidez, oclusão/visibilidade do Beam, input do executor e dados reais do Da Hood permanecem sem validação em jogo.

A referência foi baixada novamente em 2026-10-28: mesmo hash e resultado de análise estática abaixo, sem execução. Não foi possível recuperar sua lógica de AimViewer da camada virtualizada.

Em experiência própria, um LocalScript precisa publicar direção/ponto de mira explicitamente por RemoteEvent; o servidor deve validar identidade, vetores, origem, distância, frequência e permissões dos espectadores e enviar atualizações com timestamp/heartbeat. Isso requer acesso ao projeto/servidor e não foi instalado no Da Hood. Não enviamos remotes desconhecidos para tentar obter dados privados.

---

# Registro histórico da análise 5.2 (substituído pelos comportamentos acima)

# EVINI 5.2 — análise e correção de Spectate / AimViewer

Data: 28/10/2026. Base analisada: `4f7b0b61ea9445382a518b5956539bd4405595ff` (5.1); implementação anterior consultada no commit `f3db8869b5cab1d521d725e46af899ec05f6a02a` (4.8).

## Causa confirmada no EVINI

Na 4.8, `updateAimViewer()` percorria os candidatos já coletados, procurava `BodyEffects.MousePos`/`MousePosition` e alguns valores no personagem e desenhava um Beam vermelho entre a cabeça e o destino. Opcionalmente, usava `Head.CFrame.LookVector` como estimativa. O cache `aimItems` evitava recriar os objetos a cada quadro.

Isso era um visualizador de linhas, não Spectate. Não existiam um jogador observado por UserId, estado de observação, captura da câmera anterior nem mudanças de `CameraSubject`/`CameraType` para seguir outro personagem. A presença de uma linha vermelha não fornecia a perspectiva do jogador. Além disso, um valor de mira que parasse de atualizar podia continuar sendo exibido como se fosse atual.

Na 5.1, esse visualizador havia sido removido por solicitação anterior e substituído por um recurso separado de Anti-Aim, que altera temporariamente `AssemblyLinearVelocity` do próprio personagem. Portanto, não havia um AimViewer de perspectiva funcionando a ser apenas ajustado: foi necessário reinstalar uma implementação independente de observação e leitura de mira. O Anti-Aim foi preservado separadamente.

## Referência externa: análise estática e limites

Fonte: [Nosssa/NossLock/VinGUI](https://raw.githubusercontent.com/Nosssa/NossLock/main/VinGUI).

O arquivo completo foi baixado como texto, sem execução. Tem 161.528 bytes e SHA-256 `cf2e7d61fe69f64a3f2ff42223cd63b8e1acf27e3ab60f7c04c36572b2138af6`.

A camada externa contém um programa virtualizado: nomes indiretos, controle de fluxo achatado, acesso ao ambiente por `getfenv`/`_ENV`, funções de leitura/deserialização e um despachante. Há um literal com prefixo `LPH>`. Foi reconstruída estaticamente a transformação da camada de transporte: pares hexadecimais produzem bytes e `nH` repete o próximo byte `n` vezes. Isso produziu 73.226 bytes; hash e contagens estão em `reference-analysis.json`.

Nem o texto externo nem os bytes dessa primeira camada expõem os identificadores pesquisados (`Spectate`, `AimViewer`, `CameraSubject`, `MousePos`, `UserId`, etc.). O conteúdo permanece virtualizado/codificado. Ausência desses textos **não demonstra ausência de uma funcionalidade**. Não foi recuperada a semântica completa da máquina virtual; não é possível afirmar, com essa análise, que VinGUI contém Spectate/AimViewer nem como implementaria seleção, câmera ou desenho da mira.

O procedimento reproduzível está em `tools/inspect_reference.py`. Ele apenas lê bytes, calcula hashes, reconstrói essa codificação e pesquisa textos. Não usa execução Lua, `eval`, hooks, carregadores, emulação dos opcodes ou acesso ao Roblox. O código externo não foi incorporado ao produto.

O invólucro fornecido na mensagem também não implementa um visualizador: ele injeta uma velocidade no próprio `HumanoidRootPart`, restaura-a após um quadro, troca um booleano pela tecla C, altera `IsInGroup` e chama o carregador remoto. Isso não dá acesso à câmera de outro cliente. A implementação nova não inclui esse hook nem o carregador.

## Limite fundamental de perspectiva

A classe [Camera é Not Replicated](https://create.roblox.com/docs/reference/engine/classes/Camera). A câmera local não fornece o CFrame, FOV, zoom, deslocamento do mouse ou efeitos visuais da câmera de outro cliente. Um ponto de mira exposto pelo jogo também não codifica todos esses dados.

A nova UI sempre identifica a câmera como **aproximada**. Há dois modos:

- **Personagem:** câmera virtual atrás/acima da cabeça, seguindo posição e orientação replicadas do personagem. Não representa os movimentos livres de câmera do usuário observado.
- **Direção da mira:** câmera virtual próxima à cabeça, voltada para o ponto de mira exposto quando utilizável; caso contrário, segue a orientação da cabeça, identificada como direção estimada.

Não há tentativa de ler o mouse remoto, inventar a câmera de outro cliente ou acionar remotes para obtê-la.

## Seleção e integração

A categoria Visual ganhou um bloco Spectate / Aim Viewer com pesquisa, iniciar/parar, modo e diagnóstico. A categoria Jogadores existente ganhou `Observar` em cada linha, conservando sua seleção para hitbox/cam lock. Não foi criada outra ScreenGui ou lista duplicada.

A pesquisa remove espaços nas extremidades, aceita `@username`, compara Username e DisplayName e aceita trechos de ambos. Um Username exato tem prioridade; se não houver, vêm DisplayNames exatos e depois correspondências parciais. Uma busca ambígua não escolhe arbitrariamente e não interrompe o jogador já observado: mostra o número de resultados e orienta a usar a lista. As comparações usam `string.lower`; não há normalização Unicode completa.

A identidade observada é a instância de Player associada ao **UserId**, não o DisplayName. Nome e username permanecem no aviso de observação, incluindo ID. A troca de alvo reutiliza os componentes. A pesquisa não depende dos jogadores marcados para hitbox/cam lock.

## Dados de mira e atualidade

O adaptador procura apenas `MousePos`/`MousePosition` em `BodyEffects` ou diretamente no personagem, como `Vector3Value` ou `CFrameValue`. São candidatos de dados expostos pelo jogo; presença não prova fidelidade à câmera ou ao alvo final da arma. Jogos que usem outra estrutura precisam de um adaptador verificado.

- No primeiro contato: o ponto pode ser usado, mas a UI informa **idade não confirmada**.
- Após alteração localmente observada do valor: informa **mira replicada do jogo**, sempre com **câmera aproximada**.
- Sem alteração por 0,75 s: não presume que o valor permaneça atual; usa a direção estimada e remove o ponto vermelho. Um jogador mirando no mesmo lugar pode também cair nesse caso conservador, pois não há timestamp/heartbeat de mira fornecido pelo jogo.
- NaN, infinito, vetor degenerado e distância maior que 5.000 studs são rejeitados.

A busca por uma fonte ausente ocorre no máximo a cada 0,2 s. Depois de localizada, há uma conexão de mudança de valor e atualização visual por quadro. Quando a fonte some, é substituída ou o personagem muda, a conexão antiga é desconectada.

## Câmera, ciclo de vida e recursos

A observação salva por instância de Camera: `CameraType`, `CameraSubject`, `CFrame`, `Focus` e `FieldOfView`. Em seguida controla a câmera local como Scriptable. Trocar o jogador não substitui o snapshot original. Se `CurrentCamera` mudar, restaura a anterior e captura separadamente a nova.

Parar pela opção, pelo aviso, por Esc, pela saída do alvo ou por `EVINI.Destroy()` restaura a câmera. Se o sujeito anterior tiver sido removido ou morrido, tenta usar o Humanoid atual do jogador local com câmera Custom. Se o próprio personagem local ainda não existir, a retomada final depende também do controlador de câmera/respawn do jogo.

Na morte do observado, a câmera local é restaurada e a seleção fica aguardando seu renascimento. O novo Character é identificado por troca de instância, sem conexões extras por respawn. Partes indisponíveis por streaming suspendem a câmera aproximada. Ao sair do servidor, a seleção é limpa e a linha existente é removida.

Durante Spectate, cam lock não disputa o CFrame, trigger não dispara e o pulso Anti-Aim fica pausado. As preferências desses recursos não são apagadas; o trigger é desarmado explicitamente ao iniciar a observação. O início de Spectate nunca é restaurado automaticamente ao recarregar preferências.

O visualizador reutiliza o loop de câmera, a lista e os helpers da UI, com apenas um aviso e um marcador reaproveitados. Não cria objetos por quadro. As conexões adicionais de linhas são desconectadas na saída e no encerramento. Não há polling de todos os descendentes do Workspace para o visualizador.

## Validação realizada

Compilação com `luau-compile --null` e testes simulados locais:

- `tests/spectate.py`: Username, DisplayName, pesquisa parcial, duplicidade, UserId, controles da UI, troca sem reinício, câmera aproximada, fontes Vector3/CFrame, fonte substituída/removida, falta de atualizações, valores inválidos, reutilização de objetos e desconexão após 20 trocas.
- Também cobre morte/renascimento/saída, substituição de CurrentCamera, restauração de tipo/sujeito/transformação/foco/FOV, fallback ao novo Humanoid local, botão Parar, Esc, Destroy e recarga sem iniciar observação.
- Suites de regressão, UI, Anti-Aim, trigger e corpo inteiro passaram, preservando seus comportamentos existentes.

Estes testes simulam objetos, eventos e matemática básica da API. **Não são uma sessão real do Roblox**, não medem latência de rede nem comprovam quais campos Da Hood/Painhood replicam hoje. A conferência visual no jogo e a disponibilidade real do ponto de mira continuam pendentes.
