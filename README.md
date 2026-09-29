# EVINI 2.3

Hub independente e legivel para Roblox, direcionado ao Da Hood original. A versao aparece no cabecalho. Veja [a revisao completa dos pedidos e limites](REVISAO.md).

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua", true))()
```

Links antigos contendo um hash de commit continuam executando a versao antiga. Use a linha atualizada entregue na conversa para garantir a 2.3.

## Controles

- **L:** abrir/ocultar hub.
- **Q:** capturar/soltar cam lock, depois de ativar. Nao prende sozinho.
- **R:** capturar/soltar silent lock em modo Alvo fixo por tecla, depois de ativar silent.
- **Esc:** soltar os locks; tambem desliga silent automatico por FOV.
- **X da janela:** encerrar, restaurar hitboxes e remover efeitos.

As tres teclas podem ser trocadas, sem conflitos. Captura de alvo precisa ocorrer com o hub oculto. Abrir o hub ou perder foco libera os locks fixos. Silent e camera compartilham parte do corpo, Air Part, previsao, parede, equipe e filtro por nick, mas possuem raios FOV e desenhos independentes.

## Mira

**Silent:** escolha Proximo no FOV ou Alvo fixo por tecla. Confira o status do adaptador. Requer `hookmetamethod` e `getnamecallmethod` no executor e o formato de `MainEvent` explicado na revisao. Ele nao dispara automaticamente e nao garante acertos: o servidor pode rejeitar a alteracao. Outros FPS precisam de adaptadores proprios.

**Cam lock:** seleciona dentro do circulo somente no instante da tecla; a mesma tecla solta. Nenhum retarget automatico. Morreu, ficou KO ou deixou de ser valido: exige nova captura.

**Calibracao avancada:** formula propria `base + ping(s) * 250 / Math`, limitada a 0–0,5 s. Botao 80–120 ms usa Math 250 e base 0,040, estimando 0,120–0,160 s. Aumentar Math reduz antecipacao. Sem ping, usa manual. Air Part usa estado Jumping/Freefall e estimativa por velocidade/gravidade. Isso nao melhora Wi-Fi nem conhece a compensacao de cada servidor/arma.

**Hitbox e filtros:** campo numerico 2–30, invisibilidade, Knock Check, Todos/Ignorar nick/So este nick. Confirmar nick com Enter ou saindo do campo. Usuario exato tem prioridade; nomes repetidos exigem @usuario. Mortes sempre sao excluidas; K.O segue o interruptor.

## Visual

ESP de nomes somente. Jogadores/NPCs separados, sem caixas, distancia ou barras.

Aim Viewer le `BodyEffects.MousePos` quando for um Vector3Value replicado. Se indisponivel, nao inventa uma mira. A opcao de estimativa usa a direcao da arma e identifica a linha como **estimativa**. A contagem informa quando nao ha dados.

FOV, marcador e linha de cam lock e silent possuem interruptores independentes. Ocultar todos os desenhos preserva a funcionalidade de mira e tambem oculta ESP, Aim Viewer e notificacoes.

## Ajustes e persistencia

Cor de destaque, transparencia, tamanho, blur, movimento reduzido e notificacoes. Preferencias salvas em `evini-settings-<GameId>.json` no executor apos 0,35 s sem novas alteracoes e ao fechar/reexecutar. Exige `readfile`/`writefile`; indisponibilidade/falha aparece no painel. JSON validado; arquivo corrompido usa padroes. Nao salva alvo capturado nem sincroniza dispositivos.

## Verificacao

Testes simulados de inicializacao, hitbox, filtros, camera por tecla, pred/KO, nomes, abas, visibilidade, armazenamento e limpeza. Testes adicionais do adaptador: fixed/FOV, soltura, guardas de remote/acao/tipo, argumentos preservados, camera imovel, Aim Viewer real/estimado/ausente e ponte unica em reexecucao.

Ainda precisa de verificacao no Da Hood com o executor do usuario. Contador de redirecionamento prova apenas alteracao local de chamada, nao acerto aceito pelo servidor. Nenhum fonte ofuscado do Nitrogen/Azure e carregado.

Validacao adicional: compilacao concluida com Luau 0.740; diagnosticos de executor sem hooks e jogo sem MainEvent tambem testados.
