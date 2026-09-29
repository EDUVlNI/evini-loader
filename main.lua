-- EVINI 1.0: fonte independente. Nao carrega o Nitrogen.
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
local state = {enabled=false, size=8, transparent=false, teamCheck=false}
local connections, originals = {}, {}
local alive = true
local green, dark = Color3.fromRGB(176,239,179), Color3.fromRGB(22,38,29)
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
    return create('TextLabel',{Text=value,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=dark,Font=Enum.Font.Gotham,TextSize=fontSize or 14,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent)
end
local function button(parent,value,pos,size)
    local b = create('TextButton',{Text=value,Position=pos,Size=size,BackgroundColor3=green,TextColor3=dark,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=13},parent)
    round(b,9)
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
local function apply()
    if not state.enabled then restoreAll(); return end
    local active={}
    for _,target in ipairs(Players:GetPlayers()) do
        local teammate=not player.Neutral and not target.Neutral and player.Team~=nil and player.Team==target.Team
        if target~=player and not (state.teamCheck and teammate) then
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
local panel=create('Frame',{Name='Hub',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(360,380),BackgroundColor3=Color3.fromRGB(235,249,235),BorderSizePixel=0,Visible=false},gui)
round(panel,18)
create('UIStroke',{Color=green,Thickness=2},panel)
local header=create('Frame',{Size=UDim2.new(1,0,0,64),BackgroundTransparency=1,Active=true},panel)
local title=text(header,'EVINI',UDim2.fromOffset(20,10),UDim2.fromOffset(220,28),25)
title.Font=Enum.Font.GothamBold
text(header,'HITBOX  /  L para mostrar ou ocultar',UDim2.fromOffset(20,39),UDim2.fromOffset(295,18),11)
local hide=button(header,'–',UDim2.new(1,-76,0,16),UDim2.fromOffset(28,28))
local close=button(header,'×',UDim2.new(1,-42,0,16),UDim2.fromOffset(28,28))
local function toggle(label,y,key)
    text(panel,label,UDim2.fromOffset(20,y),UDim2.fromOffset(222,34),14)
    local b=button(panel,'',UDim2.new(1,-99,0,y),UDim2.fromOffset(79,34))
    local function refresh()
        b.Text=state[key] and 'LIGADO' or 'DESLIG.'
        b.BackgroundColor3=state[key] and green or Color3.fromRGB(212,224,214)
    end
    connect(b.Activated,function() state[key]=not state[key]; refresh(); apply() end)
    refresh()
end
toggle('Hitbox expander',78,'enabled')
toggle('Box totalmente transparente',123,'transparent')
toggle('Ignorar meu time',168,'teamCheck')
text(panel,'Tamanho da box',UDim2.fromOffset(20,221),UDim2.fromOffset(215,28),14)
local input=create('TextBox',{Position=UDim2.new(1,-90,0,216),Size=UDim2.fromOffset(70,34),BackgroundColor3=Color3.new(1,1,1),TextColor3=dark,BorderSizePixel=0,Text='8',ClearTextOnFocus=false,Font=Enum.Font.GothamBold,TextSize=15},panel)
round(input,8)
local slider=create('TextButton',{Text='',AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.fromOffset(20,258),Size=UDim2.new(1,-40,0,30)},panel)
local track=create('Frame',{Position=UDim2.fromOffset(0,12),Size=UDim2.new(1,0,0,6),BackgroundColor3=Color3.fromRGB(205,221,208),BorderSizePixel=0},slider)
round(track,3)
local fill=create('Frame',{Size=UDim2.fromScale(0,1),BackgroundColor3=green,BorderSizePixel=0},track)
round(fill,3)
local knob=create('Frame',{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(18,18),BackgroundColor3=Color3.fromRGB(89,161,105),BorderSizePixel=0},track)
round(knob,9)
local function setSize(value)
    if not value or value~=value then value=state.size end
    state.size=math.floor(math.clamp(value,2,30)*10+0.5)/10
    input.Text=tostring(state.size)
    local ratio=(state.size-2)/28
    fill.Size=UDim2.fromScale(ratio,1); knob.Position=UDim2.fromScale(ratio,0.5)
    apply()
end
setSize(state.size)
text(panel,'2 studs',UDim2.fromOffset(20,289),UDim2.fromOffset(100,16),11)
local maxLabel=text(panel,'30 studs',UDim2.new(1,-100,0,289),UDim2.fromOffset(80,16),11)
maxLabel.TextXAlignment=Enum.TextXAlignment.Right
text(panel,'Alteração local: o efeito nos acertos depende do jogo.\nFechar restaura as partes alteradas.',UDim2.fromOffset(20,321),UDim2.new(1,-40,0,42),12)
local launcher=button(gui,'EVINI',UDim2.fromOffset(14,130),UDim2.fromOffset(78,34))
launcher.Visible=false
connect(launcher.Activated,function() panel.Visible=not panel.Visible end)
connect(hide.Activated,function() panel.Visible=false end)
connect(input.FocusLost,function() setSize(tonumber(input.Text)) end)
connect(UIS.InputBegan,function(event,processed)
    if not processed and not UIS:GetFocusedTextBox() and event.KeyCode==Enum.KeyCode.L then panel.Visible=not panel.Visible end
end)
local sliding,dragging,dragStart,panelStart
local function slide(position)
    if track.AbsoluteSize.X>0 then setSize(2+math.clamp((position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*28) end
end
connect(slider.InputBegan,function(event)
    if event.UserInputType==Enum.UserInputType.MouseButton1 or event.UserInputType==Enum.UserInputType.Touch then sliding=event; slide(event.Position) end
end)
connect(header.InputBegan,function(event)
    if event.UserInputType==Enum.UserInputType.MouseButton1 or event.UserInputType==Enum.UserInputType.Touch then dragging=event; dragStart=event.Position; panelStart=panel.Position end
end)
connect(UIS.InputChanged,function(event)
    local mouse=event.UserInputType==Enum.UserInputType.MouseMovement
    if sliding and (event==sliding or (mouse and sliding.UserInputType==Enum.UserInputType.MouseButton1)) then slide(event.Position) end
    if dragging and (event==dragging or (mouse and dragging.UserInputType==Enum.UserInputType.MouseButton1)) then
        local d=event.Position-dragStart
        panel.Position=UDim2.new(panelStart.X.Scale,panelStart.X.Offset+d.X,panelStart.Y.Scale,panelStart.Y.Offset+d.Y)
    end
end)
connect(UIS.InputEnded,function(event)
    if event==sliding or event.UserInputType==Enum.UserInputType.MouseButton1 then sliding=nil end
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
-- Foto do usuario; suporte a assets locais e necessario para exibi-la.
local splash=create('Frame',{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(230,264),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},gui)
splash.Visible=false
round(splash,20)
create('UIStroke',{Color=green,Thickness=3},splash)
local scale=create('UIScale',{Scale=0.1},splash)
local fallback=text(splash,'🐶',UDim2.fromOffset(10,10),UDim2.fromOffset(210,206),92)
fallback.TextXAlignment=Enum.TextXAlignment.Center
local photo=create('ImageLabel',{Position=UDim2.fromOffset(10,10),Size=UDim2.fromOffset(210,206),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Image='',Visible=false},splash)
local splashTitle=text(splash,'EVINI',UDim2.fromOffset(10,222),UDim2.fromOffset(210,30),22)
splashTitle.TextXAlignment=Enum.TextXAlignment.Center; splashTitle.Font=Enum.Font.GothamBold
local photoReady=false
task.spawn(function()
    local assetLoader=getcustomasset or getsynasset
    if type(assetLoader)~='function' or type(writefile)~='function' then photoReady=true; return end
    pcall(function()
        local file='evini-dog-v1.jpg'
        if type(isfile)~='function' or not isfile(file) then
            local bytes=game:HttpGet('https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/assets/dog.jpg',true)
            if not alive or not splash.Parent then return end
            writefile(file,bytes)
        end
        if not alive or not splash.Parent then return end
        photo.Image=assetLoader(file)
        ContentProvider:PreloadAsync({photo})
        if alive and splash.Parent and photo.IsLoaded then photo.Visible=true; fallback.Visible=false end
    end)
    photoReady=true
end)
task.spawn(function()
    local deadline=os.clock()+3
    while alive and not photoReady and os.clock()<deadline do task.wait(0.05) end
    if not alive then return end
    splash.Visible=true
    TweenService:Create(scale,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    task.wait(1.8)
    if not alive then return end
    local out=TweenService:Create(scale,TweenInfo.new(0.18,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Scale=0})
    out:Play(); out.Completed:Wait()
    if not alive then return end
    splash:Destroy(); panel.Visible=true; launcher.Visible=true
end)
return api
