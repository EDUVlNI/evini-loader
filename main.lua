-- EVINI 1.2: fonte independente. Nao carrega o Nitrogen.
-- Alteracoes de hitbox sao locais; o servidor pode ignora-las.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local ContentProvider = game:GetService('ContentProvider')
local player = Players.LocalPlayer
assert(player, '[EVINI] Execute em um cliente com LocalPlayer.')
local env = (type(getgenv) == 'function' and getgenv()) or _G
if type(env.EVINI) == 'table' and type(env.EVINI.Destroy) == 'function' then pcall(env.EVINI.Destroy) end
local state = {enabled=false, size=8, transparent=false, mode='all', query=''}
local connections, originals = {}, {}
local alive = true
local green, dark = Color3.fromRGB(64,181,111), Color3.fromRGB(22,38,29)
local function create(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local gui = create('ScreenGui', {Name='EVINI', ResetOnSpawn=false, DisplayOrder=80, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, player:WaitForChild('PlayerGui'))
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections,c)
    return c
end
local function round(obj, r) create('UICorner',{CornerRadius=UDim.new(0,r or 12)},obj) end
local function text(parent, value, pos, size, fontSize)
    return create('TextLabel',{Text=value,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=Color3.fromRGB(226,234,228),Font=Enum.Font.BuilderSans,TextSize=fontSize or 14,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent)
end
local function button(parent,value,pos,size,radius)
    local b = create('TextButton',{Text=value,Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(29,34,32),TextColor3=Color3.fromRGB(170,185,176),BorderSizePixel=0,Font=Enum.Font.BuilderSansBold,TextSize=13},parent)
    round(b,radius or 4)
    return b
end
local function restore(part)
    local s = originals[part]
    if not s then return end
    pcall(function()
        part.Size=s.size; part.Transparency=s.transparency; part.Color=s.color
        part.Material=s.material; part.CanCollide=s.canCollide
    end)
    originals[part]=nil
end
local function restoreAll()
    local parts={}
    for part in pairs(originals) do table.insert(parts,part) end
    for _,part in ipairs(parts) do restore(part) end
end
local reportTarget=function() end
local function resolveTarget()
    local query=state.query:lower()
    if query=='' then return nil,'Digite o nick e pressione Enter.' end
    for _,target in ipairs(Players:GetPlayers()) do
        if target.Name:lower()==query then
            if target==player then return nil,'Escolha outro jogador.' end
            return target
        end
    end
    local found=nil
    for _,target in ipairs(Players:GetPlayers()) do
        if target~=player and target.DisplayName:lower()==query then
            if found then return nil,'Nome repetido. Use o @usuario exato.' end
            found=target
        end
    end
    if found then return found end
    return nil,'Jogador não encontrado neste servidor.'
end
local function apply()
    local selected,message=resolveTarget()
    reportTarget(selected,message)
    if not state.enabled then restoreAll(); return end
    local active={}
    for _,target in ipairs(Players:GetPlayers()) do
        local eligible=state.mode=='all' or (state.mode=='exclude' and target~=selected) or (state.mode=='only' and target==selected)
        if target~=player and eligible then
            local character=target.Character
            local humanoid=character and character:FindFirstChildOfClass('Humanoid')
            local part=character and character:FindFirstChild('HumanoidRootPart')
            if humanoid and humanoid.Health>0 and part and part:IsA('BasePart') then
                active[part]=true
                if not originals[part] then
                    originals[part]={size=part.Size,transparency=part.Transparency,color=part.Color,material=part.Material,canCollide=part.CanCollide}
                end
                pcall(function()
                    part.Size=Vector3.new(state.size,state.size,state.size)
                    part.Transparency=state.transparent and 1 or 0.65
                    part.Color=green; part.Material=Enum.Material.ForceField; part.CanCollide=false
                end)
            end
        end
    end
    local stale={}
    for part in pairs(originals) do if not active[part] then table.insert(stale,part) end end
    for _,part in ipairs(stale) do restore(part) end
end
local muted=Color3.fromRGB(133,144,140)
local surface=Color3.fromRGB(29,34,32)
local edge=Color3.fromRGB(49,58,53)
local crewImage='rbxthumb://type=GroupIcon&id=8440749&w=420&h=420'
local panel=create('Frame',{Name='Hub',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(400,496),BackgroundColor3=Color3.fromRGB(19,23,21),BorderSizePixel=0,Visible=false},gui)
round(panel,6)
create('UIStroke',{Color=edge,Thickness=1},panel)
local header=create('Frame',{Name='DragHandle',Size=UDim2.new(1,-90,0,72),BackgroundTransparency=1,Active=true},panel)
local title=text(header,'EVINI',UDim2.fromOffset(22,17),UDim2.fromOffset(180,25),21)
title.Font=Enum.Font.RobotoCondensed
title.TextSize=26
local subtitle=text(header,'DA HOOD  /  # DEATH',UDim2.fromOffset(23,44),UDim2.fromOffset(220,15),10)
subtitle.TextColor3=muted
local hide=button(panel,'−',UDim2.new(1,-80,0,21),UDim2.fromOffset(26,26)); hide.Name='Hide'
local close=button(panel,'×',UDim2.new(1,-46,0,21),UDim2.fromOffset(26,26)); close.Name='Close'
local function line(y)
    create('Frame',{Position=UDim2.fromOffset(22,y),Size=UDim2.new(1,-44,0,1),BackgroundColor3=edge,BorderSizePixel=0},panel)
end
line(74)
local status=text(panel,'HITBOX',UDim2.fromOffset(22,90),UDim2.fromOffset(180,16),10)
status.TextColor3=green; status.Font=Enum.Font.RobotoMono
local function toggle(label,description,y,key)
    text(panel,label,UDim2.fromOffset(22,y),UDim2.fromOffset(240,20),13)
    local detail=text(panel,description,UDim2.fromOffset(22,y+23),UDim2.fromOffset(265,16),11)
    detail.TextColor3=muted
    local b=button(panel,'',UDim2.new(1,-64,0,y+8),UDim2.fromOffset(42,22),11)
    b.Name=key; b.AutoButtonColor=false
    local dot=create('Frame',{Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(3,3),BackgroundColor3=muted,BorderSizePixel=0},b)
    round(dot,8)
    local function refresh(animated)
        local on=state[key]
        local bg=on and green or Color3.fromRGB(54,63,58)
        local position=UDim2.fromOffset(on and 23 or 3,3)
        local color=on and Color3.fromRGB(22,43,29) or Color3.fromRGB(162,174,166)
        if animated then
            TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=bg}):Play()
            TweenService:Create(dot,TweenInfo.new(0.12),{Position=position,BackgroundColor3=color}):Play()
        else b.BackgroundColor3=bg; dot.Position=position; dot.BackgroundColor3=color end
    end
    connect(b.Activated,function() state[key]=not state[key]; refresh(true); apply() end)
    refresh(false)
end
toggle('Ativar hitbox','Expansão dos outros jogadores',117,'enabled')
toggle('Box invisível','Oculta o preenchimento da box',174,'transparent')
text(panel,'Tamanho',UDim2.fromOffset(22,230),UDim2.fromOffset(135,20),13)
local range=text(panel,'2–30 studs',UDim2.fromOffset(22,252),UDim2.fromOffset(150,16),11)
range.TextColor3=muted
local input=create('TextBox',{Name='SizeInput',Position=UDim2.new(1,-108,0,230),Size=UDim2.fromOffset(86,34),BackgroundColor3=surface,TextColor3=Color3.fromRGB(226,234,228),BorderSizePixel=0,Text='8',ClearTextOnFocus=false,Font=Enum.Font.RobotoMono,TextSize=14},panel)
round(input,4)
create('UIStroke',{Color=edge,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},input)
local function setSize(value)
    if not value or value~=value then value=state.size end
    state.size=math.floor(math.clamp(value,2,30)*10+0.5)/10
    input.Text=tostring(state.size)
    apply()
end
connect(input.FocusLost,function() setSize(tonumber((input.Text:gsub(',','.')))) end)
line(279)
local targetTitle=text(panel,'JOGADORES',UDim2.fromOffset(22,291),UDim2.fromOffset(180,18),11)
targetTitle.Font=Enum.Font.RobotoMono; targetTitle.TextColor3=green
local modes={}
local function updateModes()
    for key,b in pairs(modes) do
        b.BackgroundColor3=state.mode==key and green or surface
        b.TextColor3=state.mode==key and Color3.fromRGB(10,28,18) or muted
    end
end
for i,entry in ipairs({{'all','Todos'},{'exclude','Ignorar nick'},{'only','Só este nick'}}) do
    local key=entry[1]
    local b=button(panel,entry[2],UDim2.fromOffset(22+(i-1)*120,318),UDim2.fromOffset(112,30),4)
    b.Name='Mode_'..key; modes[key]=b
    connect(b.Activated,function() state.mode=key; updateModes(); apply() end)
end
local nick=create('TextBox',{Name='NickInput',Position=UDim2.fromOffset(22,358),Size=UDim2.new(1,-44,0,34),BackgroundColor3=surface,TextColor3=Color3.fromRGB(226,234,228),PlaceholderText='@usuario ou nome de exibição exato',PlaceholderColor3=muted,BorderSizePixel=0,Text='',ClearTextOnFocus=false,Font=Enum.Font.BuilderSans,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},panel)
round(nick,4)
create('UIPadding',{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},nick)
create('UIStroke',{Color=edge,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},nick)
local result=text(panel,'',UDim2.fromOffset(22,398),UDim2.new(1,-44,0,34),11)
result.TextColor3=muted
reportTarget=function(target,message)
    if state.mode=='all' then result.Text='Aplicar a todos os outros jogadores.'
    elseif target then
        result.Text=(state.mode=='exclude' and 'Normal para @' or 'Expandir somente @')..target.Name
    else result.Text=message end
end
connect(nick.FocusLost,function()
    state.query=nick.Text:match('^%s*(.-)%s*$'):gsub('^@','')
    nick.Text=state.query
    apply()
end)
updateModes(); apply()
line(443)
local hint=text(panel,'Ocultar interface',UDim2.fromOffset(22,459),UDim2.fromOffset(215,20),11)
hint.TextColor3=muted
local keyButton=button(panel,'L',UDim2.new(1,-86,0,455),UDim2.fromOffset(64,28))
keyButton.Name='Keybind'
create('UIStroke',{Color=edge,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},keyButton)
local toggleKey=Enum.KeyCode.L
local capturing=false
local captureVersion=0
local function stopCapture()
    capturing=false; captureVersion=captureVersion+1
    keyButton.Text=toggleKey.Name
    hint.Text='Ocultar interface'
end
connect(keyButton.Activated,function()
    if capturing then stopCapture(); return end
    capturing=true; captureVersion=captureVersion+1
    local version=captureVersion
    keyButton.Text='…'; hint.Text='Pressione uma tecla · Esc cancela'
    task.delay(8,function() if alive and capturing and version==captureVersion then stopCapture() end end)
end)
connect(hide.Activated,function() stopCapture(); panel.Visible=false end)
connect(UIS.InputBegan,function(event,processed)
    if UIS:GetFocusedTextBox() then return end
    if capturing then
        if event.UserInputType~=Enum.UserInputType.Keyboard then return end
        if event.KeyCode==Enum.KeyCode.Escape then stopCapture(); return end
        if processed or event.KeyCode==Enum.KeyCode.Unknown then return end
        toggleKey=event.KeyCode; stopCapture(); return
    end
    if not processed and event.KeyCode==toggleKey then panel.Visible=not panel.Visible end
end)
local dragging,dragStart,panelStart
connect(header.InputBegan,function(event)
    if event.UserInputType==Enum.UserInputType.MouseButton1 or event.UserInputType==Enum.UserInputType.Touch then dragging=event; dragStart=event.Position; panelStart=panel.Position end
end)
connect(UIS.InputChanged,function(event)
    local mouse=event.UserInputType==Enum.UserInputType.MouseMovement
    if dragging and (event==dragging or (mouse and dragging.UserInputType==Enum.UserInputType.MouseButton1)) then
        local d=event.Position-dragStart
        panel.Position=UDim2.new(panelStart.X.Scale,panelStart.X.Offset+d.X,panelStart.Y.Scale,panelStart.Y.Offset+d.Y)
    end
end)
connect(UIS.InputEnded,function(event)
    if event==dragging or event.UserInputType==Enum.UserInputType.MouseButton1 then dragging=nil end
end)
local api={}
function api.Destroy()
    if not alive then return end
    alive=false
    for _,c in ipairs(connections) do c:Disconnect() end
    restoreAll(); gui:Destroy()
    if env.EVINI==api then env.EVINI=nil end
end
env.EVINI=api
connect(close.Activated,api.Destroy)
local elapsed=0
connect(RunService.Heartbeat,function(dt) elapsed=elapsed+dt; if elapsed>=0.15 then elapsed=0; apply() end end)
-- Apenas o emblema da crew: sem painel, blur ou arquivos do executor.
local splash=create('ImageLabel',{Name='CrewIntro',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(160,160),BackgroundTransparency=1,Image=crewImage,ScaleType=Enum.ScaleType.Fit,ImageTransparency=1,Visible=false},gui)
local scale=create('UIScale',{Scale=0.75},splash)
local photoReady=false
local introDone=false
local function revealHub()
    if not alive or introDone then return end
    introDone=true
    splash:Destroy(); panel.Visible=true
end
-- Watchdog tambem cobre eventual falha na animacao ou no preload.
task.delay(5,revealHub)
task.spawn(function()
    pcall(function() ContentProvider:PreloadAsync({splash}) end)
    photoReady=true
end)
task.spawn(function()
    local deadline=os.clock()+2.5
    while alive and not photoReady and os.clock()<deadline do task.wait(0.05) end
    if not alive or introDone then return end
    if not splash.IsLoaded then revealHub(); return end
    splash.Visible=true
    TweenService:Create(scale,TweenInfo.new(0.32,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    TweenService:Create(splash,TweenInfo.new(0.2),{ImageTransparency=0}):Play()
    task.wait(0.85)
    if not alive or introDone then return end
    TweenService:Create(scale,TweenInfo.new(0.2),{Scale=0.92}):Play()
    local fade=TweenService:Create(splash,TweenInfo.new(0.2),{ImageTransparency=1})
    fade:Play(); fade.Completed:Wait()
    revealHub()
end)
return api
