# EVINI 2.6

Hub preto e branco com cam lock, hitbox e configurações visuais. Silent aim e silent lock removidos por completo, incluindo atalhos, círculos e interceptação de chamadas.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua"))()
```

- **L:** abrir ou ocultar o hub.
- **Q:** prender ou soltar o cam lock, com o hub oculto.
- **Esc:** soltar o cam lock.
- **X:** encerrar e restaurar hitboxes.

Atalhos personalizados salvos continuam valendo. Mantidos: tamanho numérico e transparência da hitbox, filtros por nick, Knock Check, FOV, predict, Air Part, ESP somente nomes, Aim Viewer, animações, aparência e salvamento local quando disponível. Configurações antigas de silent são ignoradas.

Compilação e testes simulados verificam o código; o comportamento no jogo precisa de validação no Roblox. O servidor pode ignorar alterações locais de hitbox. Aim Viewer depende dos dados replicados; a estimativa opcional é identificada como estimativa.

Em Mira, desligue **Mostrar círculo do FOV** para deixá-lo invisível sem desativar o cam lock. A captura mostra **EVINI / locked in @username**, usando o nome de usuário real. Notificações respeitam os controles de visibilidade existentes.
