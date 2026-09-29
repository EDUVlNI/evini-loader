-- EVINI 2.0: fonte independente. Nao carrega o Nitrogen.
-- Alteracoes de hitbox sao locais; o servidor pode ignora-las.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local ContentProvider = game:GetService('ContentProvider')
local Workspace=game:GetService('Workspace')
local Lighting=game:GetService('Lighting')
local GuiService=game:GetService('GuiService')
local player = Players.LocalPlayer
assert(player, '[EVINI] Execute em um cliente com LocalPlayer.')
local env = (type(getgenv) == 'function' and getgenv()) or _G
if type(env.EVINI) == 'table' and type(env.EVINI.Destroy) == 'function' then pcall(env.EVINI.Destroy) end
local state = {enabled=false, size=8, transparent=false, knockCheck=true, mode='all', query=''}
state.espPlayers=false; state.espEntities=false; state.espNames=true; state.espHealth=true
state.camEnabled=false; state.camNPC=false; state.wallCheck=true; state.camTeam=false
state.fov=140; state.showFov=true; state.lockMode='hold'; state.hitPart='Head'
state.airEnabled=true; state.airPart='HumanoidRootPart'; state.prediction=0.12; state.airPrediction=0.12
state.autoPrediction=false; state.pingGain=1; state.smoothing=0.22
state.blur=true
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
    return create('TextLabel',{Text=value,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=Color3.fromRGB(226,234,228),Font=Enum.Font.Arcade,TextSize=fontSize or 14,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent)
end
local function button(parent,value,pos,size,radius)
    local b = create('TextButton',{Text=value,Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(19,20,20),TextColor3=Color3.fromRGB(170,185,176),BorderSizePixel=0,Font=Enum.Font.Arcade,TextSize=13},parent)
    round(b,radius or 2)
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
-- Da Hood pode marcar K.O mesmo quando o Humanoid ainda tem vida.
local function flagOn(parent,name)
    local value=parent and parent:FindFirstChild(name)
    return value~=nil and value:IsA('BoolValue') and value.Value==true
end
local function unavailable(character,humanoid)
    if humanoid.Health<=0 or humanoid:GetState()==Enum.HumanoidStateType.Dead then return true end
    local effects=character:FindFirstChild('BodyEffects')
    -- Mortos sempre sao excluidos; K.O e controlado pelo Knock Check.
    if flagOn(effects,'Dead') then return true end
    return state.knockCheck and flagOn(effects,'K.O')
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
            if humanoid and not unavailable(character,humanoid) and part and part:IsA('BasePart') then
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
-- ESP / camera: APIs nativas, sem alterar remotes de armas ou baixar codigo externo.
local candidates,npcModels,espObjects={},{},{}
local cameraTarget=nil
local held,latched=false,false
local pingSeconds=nil
local cameraStatus=function() end
local overlays=create('ScreenGui',{Name='EVINI_Overlays',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=79,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player:WaitForChild('PlayerGui'))
local ring=create('Frame',{Name='FOV',AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Size=UDim2.fromOffset(280,280),Visible=false},overlays)
create('UICorner',{CornerRadius=UDim.new(1,0)},ring)
create('UIStroke',{Color=green,Thickness=1,Transparency=0.22},ring)
local function addHumanoid(obj)
    if obj:IsA('Humanoid') and obj.Parent and obj.Parent:IsA('Model') then npcModels[obj.Parent]=true end
end
connect(Workspace.DescendantAdded,addHumanoid)
connect(Workspace.DescendantRemoving,function(obj)
    if obj:IsA('Humanoid') and obj.Parent then npcModels[obj.Parent]=nil end
end)
task.spawn(function()
    for index,obj in ipairs(Workspace:GetDescendants()) do
        if not alive then return end
        addHumanoid(obj)
        if index%250==0 then task.wait() end
    end
end)
local function collectCandidates()
    local list,seen={},{}
    for _,p in ipairs(Players:GetPlayers()) do
        local model=p.Character
        if model then
            seen[model]=true
            if p~=player then table.insert(list,{model=model,player=p,name=p.DisplayName..' (@'..p.Name..')'}) end
        end
    end
    for model in pairs(npcModels) do
        if not model.Parent then npcModels[model]=nil
        elseif not seen[model] and not Players:GetPlayerFromCharacter(model) then
            table.insert(list,{model=model,name=model.Name})
        end
    end
    candidates=list
end
local function targetPart(model,name)
    local found=model:FindFirstChild(name)
    if found and found:IsA('BasePart') then return found end
    local alternate=(name=='UpperTorso' or name=='LowerTorso') and 'Torso' or 'HumanoidRootPart'
    found=model:FindFirstChild(alternate) or model.PrimaryPart
    return found and found:IsA('BasePart') and found or nil
end
local function targetInfo(entry)
    if not entry.model.Parent then return nil end
    local hum=entry.model:FindFirstChildOfClass('Humanoid')
    if not hum or unavailable(entry.model,hum) then return nil end
    local part=targetPart(entry.model,'HumanoidRootPart')
    return part,hum
end
local function filterCamera(entry,selected)
    if not entry.player then return state.camNPC and state.mode~='only' end
    if state.mode=='exclude' and entry.player==selected then return false end
    if state.mode=='only' and entry.player~=selected then return false end
    if state.camTeam and not player.Neutral and not entry.player.Neutral and player.Team and player.Team==entry.player.Team then return false end
    return true
end
local function aimPart(entry,hum)
    local air=hum:GetState()==Enum.HumanoidStateType.Freefall or hum:GetState()==Enum.HumanoidStateType.Jumping
    return targetPart(entry.model,(state.airEnabled and air) and state.airPart or state.hitPart),air
end
local function visibleToCamera(entry,part,camera)
    if not state.wallCheck then return true end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances=player.Character and {player.Character} or {}
    local hit=Workspace:Raycast(camera.CFrame.Position,part.Position-camera.CFrame.Position,params)
    return not hit or hit.Instance:IsDescendantOf(entry.model)
end
local function acquire(camera,mouse)
    local selected=resolveTarget()
    local best,distance=nil,state.fov
    for _,entry in ipairs(candidates) do
        local root,hum=targetInfo(entry)
        if root and filterCamera(entry,selected) then
            local part=aimPart(entry,hum)
            if part then
                local point,onScreen=camera:WorldToViewportPoint(part.Position)
                local delta=Vector2.new(point.X,point.Y)-mouse
                if onScreen and point.Z>0 and delta.Magnitude<distance and visibleToCamera(entry,part,camera) then
                    best=entry; distance=delta.Magnitude
                end
            end
        end
    end
    return best
end
local function predictionTime(air)
    local base=(state.airEnabled and air) and state.airPrediction or state.prediction
    -- Ajuste estimado: RTT/2 como ponto de partida; nao promete eliminar latencia.
    if state.autoPrediction and pingSeconds then return math.clamp(pingSeconds*0.5*state.pingGain,0,0.5) end
    return base
end
local function predictedPosition(part,hum,air)
    local velocity=part.AssemblyLinearVelocity
    if velocity.Magnitude>250 then velocity=velocity.Unit*250 end
    local t=predictionTime(air)
    local offset=velocity*t
    if state.airEnabled and air then offset=offset+Vector3.new(0,-0.5*Workspace.Gravity*t*t,0) end
    return part.Position+offset
end
local function destroyESP(model)
    local item=espObjects[model]
    if item then item.frame:Destroy(); espObjects[model]=nil end
end
local function ensureESP(entry)
    local item=espObjects[entry.model]
    if item then return item end
    local frame=create('Frame',{Name='ESPBox',BackgroundTransparency=1,BorderSizePixel=0,Visible=false},overlays)
    create('UIStroke',{Color=entry.player and green or Color3.fromRGB(230,183,100),Thickness=1},frame)
    local label=text(frame,'',UDim2.new(0.5,-110,0,-29),UDim2.fromOffset(220,26),11)
    label.Font=Enum.Font.RobotoMono; label.TextXAlignment=Enum.TextXAlignment.Center
    label.TextStrokeTransparency=0.35
    local bar=create('Frame',{Position=UDim2.fromOffset(-5,0),Size=UDim2.new(0,2,1,0),BackgroundColor3=green,BorderSizePixel=0},frame)
    item={frame=frame,label=label,bar=bar}; espObjects[entry.model]=item
    return item
end
local function updateESP(camera)
    local seen={}
    for _,entry in ipairs(candidates) do
        local wanted=entry.player and state.espPlayers or (not entry.player and state.espEntities)
        local root,hum=targetInfo(entry)
        if wanted and root then
            local item=ensureESP(entry); seen[entry.model]=true
            local head=targetPart(entry.model,'Head') or root
            local top,onScreen=camera:WorldToViewportPoint(head.Position+Vector3.new(0,1,0))
            local bottom=camera:WorldToViewportPoint(root.Position-Vector3.new(0,3,0))
            local height=math.abs(bottom.Y-top.Y)
            item.frame.Visible=onScreen and top.Z>0 and bottom.Z>0 and height>1
            if item.frame.Visible then
                local width=math.max(12,height*0.52)
                item.frame.Position=UDim2.fromOffset(top.X-width/2,math.min(top.Y,bottom.Y))
                item.frame.Size=UDim2.fromOffset(width,height)
                item.label.Visible=state.espNames
                item.label.Text=entry.name..' · '..math.floor((root.Position-camera.CFrame.Position).Magnitude)..' st'
                item.bar.Visible=state.espHealth
                item.bar.Size=UDim2.new(0,2,math.clamp(hum.Health/math.max(1,hum.MaxHealth),0,1),0)
            end
        end
    end
    local stale={}
    for model in pairs(espObjects) do if not seen[model] then table.insert(stale,model) end end
    for _,model in ipairs(stale) do destroyESP(model) end
end
local camBind=Enum.KeyCode.Q
local capturing=nil
local uiOpen=false
local uiBusy=false
local function cameraActive()
    if not state.camEnabled or uiOpen or uiBusy or capturing or UIS:GetFocusedTextBox() then return false end
    return state.lockMode=='auto' or (state.lockMode=='hold' and held) or (state.lockMode=='toggle' and latched)
end
local function resetCamera() held=false; latched=false; cameraTarget=nil end
local espElapsed,statusElapsed=0,0
local function render(dt)
    local camera=Workspace.CurrentCamera
    if not camera then return end
    local mouse=UIS:GetMouseLocation()
    ring.Position=UDim2.fromOffset(mouse.X,mouse.Y)
    ring.Size=UDim2.fromOffset(state.fov*2,state.fov*2)
    ring.Visible=state.camEnabled and state.showFov and not uiOpen and not uiBusy
    espElapsed=espElapsed+dt; statusElapsed=statusElapsed+dt
    if espElapsed>=0.05 then espElapsed=0; updateESP(camera) end
    if cameraActive() then
        -- Manter alvo enquanto valido, dentro do FOV e sem obstaculo.
        local entry=cameraTarget
        if entry then
            local root,hum=targetInfo(entry)
            local part=hum and aimPart(entry,hum)
            local point,onScreen
            if part then point,onScreen=camera:WorldToViewportPoint(part.Position) end
            if not root or not part or not filterCamera(entry,resolveTarget()) or not onScreen or point.Z<=0
                or (Vector2.new(point.X,point.Y)-mouse).Magnitude>state.fov or not visibleToCamera(entry,part,camera) then entry=nil end
        end
        cameraTarget=entry or acquire(camera,mouse)
        if cameraTarget then
            local _,hum=targetInfo(cameraTarget)
            local part,air=aimPart(cameraTarget,hum)
            local destination=predictedPosition(part,hum,air)
            if (destination-camera.CFrame.Position).Magnitude>0.01 then
                local alpha=state.smoothing<=0 and 1 or 1-math.exp(-dt*6/state.smoothing)
                camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position,destination),alpha)
            end
        end
    else cameraTarget=nil end
    if statusElapsed>=0.2 then
        statusElapsed=0
        cameraStatus(cameraTarget and cameraTarget.name or 'Sem alvo',pingSeconds,predictionTime(false))
    end
end
local palette={bg=Color3.fromRGB(17,20,19),panel=Color3.fromRGB(24,28,26),edge=Color3.fromRGB(49,60,53),muted=Color3.fromRGB(135,153,141),white=Color3.fromRGB(220,232,223)}
local rootUI=create('Frame',{Name='Hub',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(620,546),BackgroundTransparency=1,Visible=false},gui)
local uiScale=create('UIScale',{Scale=1},rootUI)
local function fitUI()
    local camera=Workspace.CurrentCamera
    if camera then uiScale.Scale=math.min(1,math.max(0.35,math.min((camera.ViewportSize.X-28)/620,(camera.ViewportSize.Y-60)/546))) end
end
local pieces={}
local function piece(name,x,y,w,h,dx,dy)
    local obj=create('CanvasGroup',{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=palette.bg,BorderSizePixel=0,GroupTransparency=0},rootUI)
    round(obj,4); create('UIStroke',{Color=palette.edge,Thickness=1},obj)
    table.insert(pieces,{obj=obj,home=UDim2.fromOffset(x,y),away=UDim2.fromOffset(x+dx,y+dy)})
    return obj
end
local header=piece('Header',0,0,620,58,0,-45)
local sidebar=piece('Navigation',0,66,138,430,-55,0)
local body=piece('Content',146,66,474,430,55,0)
local footer=piece('Footer',0,504,620,42,0,42)
local title=text(header,'EVINI',UDim2.fromOffset(18,10),UDim2.fromOffset(175,23),21); title.Font=Enum.Font.Arcade; title.TextColor3=green
local sub=text(header,'CONTROL ROOM  /  2.0',UDim2.fromOffset(19,34),UDim2.fromOffset(300,14),10); sub.Font=Enum.Font.RobotoMono; sub.TextColor3=palette.muted
local hide=button(header,'−',UDim2.new(1,-74,0,15),UDim2.fromOffset(26,26)); hide.Name='Hide'
local close=button(header,'×',UDim2.new(1,-40,0,15),UDim2.fromOffset(26,26)); close.Name='Close'
local blur=create('BlurEffect',{Name='EVINI_Blur',Size=0},Lighting)
local animationVersion=0
local activeTweens={}
local destroyed=false
local function tween(obj,duration,props)
    local t=TweenService:Create(obj,TweenInfo.new(duration,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props)
    t:Play(); table.insert(activeTweens,t); return t
end
local function showUI(open,after)
    if not alive then return end
    animationVersion=animationVersion+1
    local version=animationVersion
    for _,t in ipairs(activeTweens) do t:Cancel() end
    activeTweens={}; uiBusy=true; uiOpen=open; resetCamera()
    rootUI.Visible=true; fitUI()
    tween(blur,0.28,{Size=open and state.blur and 5 or 0})
    for i,item in ipairs(pieces) do
        if open and item.obj.GroupTransparency>=0.99 then item.obj.Position=item.away end
        task.delay((open and i-1 or #pieces-i)*0.045,function()
            if not alive or version~=animationVersion then return end
            tween(item.obj,0.26,{Position=open and item.home or item.away,GroupTransparency=open and 0 or 1})
        end)
    end
    task.delay(0.43,function()
        if not alive or version~=animationVersion then return end
        uiBusy=false; rootUI.Visible=open
        if after then after() end
    end)
end
for _,item in ipairs(pieces) do item.obj.GroupTransparency=1; item.obj.Position=item.away end
local pages,tabs={},{}
local currentPage='HITBOX'
local function page(name,index)
    local frame=create('ScrollingFrame',{Name=name,Position=UDim2.fromOffset(14,12),Size=UDim2.new(1,-28,1,-24),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=green,CanvasSize=UDim2.fromOffset(0,0),Visible=index==1},body)
    pages[name]={frame=frame,y=0}
    local b=button(sidebar,name,UDim2.fromOffset(10,14+(index-1)*42),UDim2.new(1,-20,0,32)); b.Name='Tab_'..name; b.Font=Enum.Font.RobotoMono
    tabs[name]=b
    connect(b.Activated,function()
        currentPage=name
        for key,p in pairs(pages) do p.frame.Visible=key==name; tabs[key].TextColor3=key==name and green or palette.muted end
    end)
    b.TextColor3=index==1 and green or palette.muted
    return pages[name]
end
local hitPage=page('HITBOX',1)
local espPage=page('ESP',2)
local camPage=page('CAM LOCK',3)
local predPage=page('PREDICT',4)
local settingsPage=page('INTERFACE',5)
local branding=text(sidebar,'# DEATH\n8440749',UDim2.new(0,13,1,-48),UDim2.new(1,-26,0,36),10); branding.Font=Enum.Font.RobotoMono; branding.TextColor3=palette.muted
local function slot(p,h)
    local y=p.y; p.y=y+h; p.frame.CanvasSize=UDim2.fromOffset(0,p.y+8); return y
end
local function label(p,value,description)
    local y=slot(p,description and 57 or 32)
    local t=text(p.frame,value,UDim2.fromOffset(0,y),UDim2.new(1,0,0,20),15); t.Font=Enum.Font.RobotoMono; t.TextColor3=green
    if description then local d=text(p.frame,description,UDim2.fromOffset(0,y+23),UDim2.new(1,-4,0,30),11); d.Font=Enum.Font.BuilderSans; d.TextColor3=palette.muted end
end
local function rowText(p,value,y)
    local t=text(p.frame,value,UDim2.fromOffset(0,y+5),UDim2.new(1,-132,0,24),13); t.Font=Enum.Font.BuilderSans; return t
end
local function switch(p,value,key,onChange)
    local y=slot(p,42); rowText(p,value,y)
    local b=button(p.frame,'',UDim2.new(1,-46,0,y+6),UDim2.fromOffset(46,22)); b.Name=key
    local dot=create('Frame',{Size=UDim2.fromOffset(14,14),BorderSizePixel=0},b); round(dot,2)
    local function refresh()
        b.BackgroundColor3=state[key] and green or palette.edge
        dot.BackgroundColor3=state[key] and palette.bg or palette.muted
        dot.Position=UDim2.fromOffset(state[key] and 28 or 4,4)
    end
    connect(b.Activated,function() state[key]=not state[key]; refresh(); if onChange then onChange() end end)
    refresh(); return b
end
local function field(p,value,key,min,max,step,onChange)
    local y=slot(p,46); rowText(p,value,y)
    local box=create('TextBox',{Name=key=='size' and 'SizeInput' or key,Position=UDim2.new(1,-106,0,y),Size=UDim2.fromOffset(106,32),BackgroundColor3=palette.panel,BorderSizePixel=0,Text=tostring(state[key]),TextColor3=palette.white,ClearTextOnFocus=false,Font=Enum.Font.RobotoMono,TextSize=13},p.frame)
    round(box,3); create('UIStroke',{Color=palette.edge,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},box)
    local function set(v)
        if v and v==v then state[key]=math.floor(math.clamp(v,min,max)/step+0.5)*step end
        box.Text=string.format(step<1 and '%.3f' or '%.0f',state[key])
        if onChange then onChange() end
    end
    connect(box.FocusLost,function() set(tonumber((box.Text:gsub(',','.')))) end)
    return box,set
end
local sliderDrag=nil
local function slider(p,value,key,min,max,step)
    local box,set=field(p,value,key,min,max,step)
    local y=slot(p,24)-7
    local hit=create('TextButton',{Name=key..'_Slider',Text='',BackgroundTransparency=1,Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,22)},p.frame)
    local track=create('Frame',{Position=UDim2.fromOffset(0,8),Size=UDim2.new(1,0,0,3),BackgroundColor3=palette.edge,BorderSizePixel=0},hit)
    local fill=create('Frame',{Size=UDim2.fromScale((state[key]-min)/(max-min),1),BackgroundColor3=green,BorderSizePixel=0},track)
    local knob=create('Frame',{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale((state[key]-min)/(max-min),0.5),Size=UDim2.fromOffset(7,11),BackgroundColor3=green,BorderSizePixel=0},track)
    local function refresh() local r=(state[key]-min)/(max-min); fill.Size=UDim2.fromScale(r,1); knob.Position=UDim2.fromScale(r,0.5) end
    connect(box.FocusLost,refresh)
    local function move(position)
        if track.AbsoluteSize.X<=0 then return end
        set(min+math.clamp((position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(max-min)); refresh()
    end
    connect(hit.InputBegan,function(event)
        if event.UserInputType==Enum.UserInputType.MouseButton1 or event.UserInputType==Enum.UserInputType.Touch then sliderDrag={input=event,move=move}; move(event.Position) end
    end)
end
local function choice(p,value,key,options,onChange)
    local y=slot(p,46); local caption=rowText(p,value,y); caption.Size=UDim2.new(1,-166,0,24)
    local b=button(p.frame,'',UDim2.new(1,-154,0,y),UDim2.fromOffset(154,32)); b.Name=key; b.Font=Enum.Font.RobotoMono; b.TextSize=11
    local function refresh()
        for _,o in ipairs(options) do if o[1]==state[key] then b.Text=o[2]..'  >' end end
    end
    connect(b.Activated,function()
        for i,o in ipairs(options) do if o[1]==state[key] then state[key]=options[i%#options+1][1]; break end end
        refresh(); if onChange then onChange() end
    end)
    refresh(); return b
end
label(hitPage,'HITBOX','Controles locais. Os filtros por nick também valem para o cam lock de jogadores.')
switch(hitPage,'Ativar expansão','enabled',apply)
switch(hitPage,'Box invisível','transparent',apply)
switch(hitPage,'Knock Check','knockCheck',function() apply(); cameraTarget=nil end)
field(hitPage,'Tamanho · 2–30 studs','size',2,30,0.1,apply)
choice(hitPage,'Filtro de jogadores','mode',{{'all','Todos'},{'exclude','Ignorar nick'},{'only','Só este nick'}},function() apply(); cameraTarget=nil end)
local nickY=slot(hitPage,42)
local nick=create('TextBox',{Name='NickInput',Position=UDim2.fromOffset(0,nickY),Size=UDim2.new(1,0,0,32),BackgroundColor3=palette.panel,TextColor3=palette.white,BorderSizePixel=0,PlaceholderText='@usuario ou nome de exibição exato',PlaceholderColor3=palette.muted,Text='',ClearTextOnFocus=false,Font=Enum.Font.BuilderSans,TextSize=13},hitPage.frame); round(nick,3)
local result=text(hitPage.frame,'',UDim2.fromOffset(0,slot(hitPage,36)),UDim2.new(1,0,0,32),11); result.Font=Enum.Font.BuilderSans; result.TextColor3=palette.muted
reportTarget=function(target,message)
    result.Text=state.mode=='all' and 'Todos os outros jogadores.' or (target and ((state.mode=='exclude' and 'Normal para @' or 'Somente @')..target.Name) or message)
end
connect(nick.FocusLost,function() state.query=nick.Text:match('^%s*(.-)%s*$'):gsub('^@',''); nick.Text=state.query; apply(); cameraTarget=nil end)
label(espPage,'ESP','Jogadores e entidades com Humanoid. Caixas, nome, distância e barra de vida.')
switch(espPage,'Jogadores','espPlayers')
switch(espPage,'NPCs / entidades','espEntities')
switch(espPage,'Nomes e distância','espNames')
switch(espPage,'Barra de vida','espHealth')
label(espPage,'LEITURA','Verde: jogador. Âmbar: entidade. Mortos e K.O. seguem o Knock Check. Objetos sem Humanoid não são identificados automaticamente.')
label(camPage,'CAM LOCK','Alvo dentro do círculo do mouse. A câmera fica livre enquanto o hub está aberto.')
switch(camPage,'Ativar cam lock','camEnabled',resetCamera)
choice(camPage,'Ativação','lockMode',{{'hold','Segurar tecla'},{'toggle','Alternar tecla'},{'auto','Automático'}},resetCamera)
switch(camPage,'Mostrar círculo FOV','showFov')
slider(camPage,'Raio do FOV · pixels','fov',30,500,1)
choice(camPage,'Parte do corpo','hitPart',{{'Head','Cabeça'},{'UpperTorso','Tronco'},{'LowerTorso','Tronco baixo'},{'HumanoidRootPart','Centro'}},function() cameraTarget=nil end)
switch(camPage,'Verificar paredes','wallCheck')
switch(camPage,'Ignorar meu time','camTeam',function() cameraTarget=nil end)
switch(camPage,'Incluir NPCs no lock','camNPC',function() cameraTarget=nil end)
slider(camPage,'Suavização · 0 = instantâneo','smoothing',0,1,0.01)
local targetReadout=text(camPage.frame,'Sem alvo',UDim2.fromOffset(0,slot(camPage,32)),UDim2.new(1,0,0,28),11); targetReadout.Font=Enum.Font.RobotoMono; targetReadout.TextColor3=green
label(predPage,'PREDICT','Estimativa de movimento, não correção de conexão. Ajuste aos poucos e teste no jogo.')
switch(predPage,'Estimativa pelo ping','autoPrediction')
slider(predPage,'Ganho do ping automático','pingGain',0.25,3,0.05)
slider(predPage,'Previsão manual · segundos','prediction',0,0.5,0.001)
switch(predPage,'Usar Air Part','airEnabled')
choice(predPage,'Parte no ar','airPart',{{'HumanoidRootPart','Centro'},{'Head','Cabeça'},{'UpperTorso','Tronco'},{'LowerTorso','Tronco baixo'}})
slider(predPage,'Previsão no ar · segundos','airPrediction',0,0.5,0.001)
label(predPage,'NO AR','Air Part usa o estado de salto/queda e antecipa velocidade + gravidade. No automático, o ping define o tempo nos dois casos.')
label(settingsPage,'INTERFACE','Clique na tecla para trocar. Esc cancela. Abrir o hub pausa o cam lock.')
local hideKey=Enum.KeyCode.L
local captureVersion=0
local keyButtons={}
local function refreshKeys()
    if keyButtons.hide then keyButtons.hide.Text=hideKey.Name end
    if keyButtons.cam then keyButtons.cam.Text=camBind.Name end
end
local function stopCapture() capturing=nil; captureVersion=captureVersion+1; refreshKeys() end
local function keyField(value,which)
    local y=slot(settingsPage,46); rowText(settingsPage,value,y)
    local b=button(settingsPage.frame,'',UDim2.new(1,-106,0,y),UDim2.fromOffset(106,32)); b.Name=which=='hide' and 'Keybind' or 'CamKeybind'; keyButtons[which]=b
    connect(b.Activated,function()
        if capturing==which then stopCapture(); return end
        stopCapture(); capturing=which; resetCamera(); b.Text='Tecla?'; local version=captureVersion
        task.delay(8,function() if alive and version==captureVersion then stopCapture() end end)
    end)
end
keyField('Ocultar / abrir hub','hide'); keyField('Tecla do cam lock','cam'); refreshKeys()
switch(settingsPage,'Blur ao abrir','blur',function() tween(blur,0.2,{Size=uiOpen and state.blur and 5 or 0}) end)
label(settingsPage,'COMPATIBILIDADE','Base R6 / R15 com Humanoid. Câmeras e personagens personalizados podem exigir adaptação. Fechar remove efeitos e restaura hitboxes.')
local foot=text(footer,'L · HUB     Q · CAM LOCK',UDim2.fromOffset(14,12),UDim2.fromOffset(250,18),10); foot.Font=Enum.Font.RobotoMono; foot.TextColor3=palette.muted
local stats=text(footer,'PING —',UDim2.new(1,-332,0,12),UDim2.fromOffset(318,18),10); stats.Font=Enum.Font.RobotoMono; stats.TextXAlignment=Enum.TextXAlignment.Right; stats.TextColor3=green
cameraStatus=function(name,ping,pred)
    targetReadout.Text='ALVO: '..name
    stats.Text=(ping and math.floor(ping*1000)..' ms' or 'ping indisponível')..' / '..string.format('%.3f s',pred)
    foot.Text=hideKey.Name..' · HUB   '..camBind.Name..' · '..(cameraTarget and 'LOCK' or 'CAM')
end
connect(UIS.InputBegan,function(event,processed)
    if UIS:GetFocusedTextBox() then return end
    if capturing then
        if event.UserInputType~=Enum.UserInputType.Keyboard then return end
        if event.KeyCode==Enum.KeyCode.Escape then stopCapture(); return end
        if processed or event.KeyCode==Enum.KeyCode.Unknown then return end
        if (capturing=='hide' and event.KeyCode==camBind) or (capturing=='cam' and event.KeyCode==hideKey) then keyButtons[capturing].Text='Em uso'; return end
        if capturing=='hide' then hideKey=event.KeyCode else camBind=event.KeyCode end
        stopCapture(); return
    end
    if processed then return end
    if event.KeyCode==hideKey then showUI(not uiOpen)
    elseif event.KeyCode==camBind and not uiOpen and not uiBusy then
        held=true; if state.lockMode=='toggle' then latched=not latched end
    end
end)
connect(UIS.InputEnded,function(event)
    if event.KeyCode==camBind then held=false end
    if sliderDrag and (event==sliderDrag.input or event.UserInputType==Enum.UserInputType.MouseButton1) then sliderDrag=nil end
end)
connect(UIS.WindowFocusReleased,function() resetCamera(); sliderDrag=nil end)
local dragging,dragStart,panelStart
connect(header.InputBegan,function(event)
    if not uiBusy and (event.UserInputType==Enum.UserInputType.MouseButton1 or event.UserInputType==Enum.UserInputType.Touch) then dragging=event; dragStart=event.Position; panelStart=rootUI.Position end
end)
connect(UIS.InputChanged,function(event)
    local mouse=event.UserInputType==Enum.UserInputType.MouseMovement
    if sliderDrag and (event==sliderDrag.input or (mouse and sliderDrag.input.UserInputType==Enum.UserInputType.MouseButton1)) then sliderDrag.move(event.Position) end
    if dragging and (event==dragging or (mouse and dragging.UserInputType==Enum.UserInputType.MouseButton1)) then
        local d=event.Position-dragStart
        rootUI.Position=UDim2.new(panelStart.X.Scale,panelStart.X.Offset+d.X,panelStart.Y.Scale,panelStart.Y.Offset+d.Y)
    end
end)
connect(UIS.InputEnded,function(event) if event==dragging or event.UserInputType==Enum.UserInputType.MouseButton1 then dragging=nil end end)
connect(hide.Activated,function() stopCapture(); showUI(false) end)
local api={Settings=state}
function api.Destroy()
    if not alive then return end
    alive=false; animationVersion=animationVersion+1; resetCamera()
    for _,c in ipairs(connections) do c:Disconnect() end
    for _,t in ipairs(activeTweens) do t:Cancel() end
    RunService:UnbindFromRenderStep('EVINI_Camera')
    restoreAll(); blur:Destroy(); overlays:Destroy(); gui:Destroy()
    espObjects={}; candidates={}; npcModels={}
    if env.EVINI==api then env.EVINI=nil end
end
env.EVINI=api
connect(close.Activated,function()
    if destroyed then return end
    destroyed=true; state.camEnabled=false; state.enabled=false; apply(); resetCamera()
    showUI(false,api.Destroy)
    -- Fechamento nao pode ficar preso se outra tecla interromper a animacao.
    task.delay(0.6,function() if alive then api.Destroy() end end)
end)
local elapsed,collectElapsed,pingElapsed=0,0,0
connect(RunService.Heartbeat,function(dt)
    elapsed=elapsed+dt; collectElapsed=collectElapsed+dt; pingElapsed=pingElapsed+dt
    if elapsed>=0.05 then elapsed=0; apply() end
    if collectElapsed>=0.3 then collectElapsed=0; collectCandidates(); fitUI() end
    if pingElapsed>=1 then
        pingElapsed=0
        local ok,value=pcall(function() return player:GetNetworkPing() end)
        if ok and type(value)=='number' and value==value and value>=0 and value<5 then
            pingSeconds=pingSeconds and pingSeconds*0.8+value*0.2 or value
        else pingSeconds=nil end
    end
end)
collectCandidates()
RunService:BindToRenderStep('EVINI_Camera',Enum.RenderPriority.Camera.Value+1,render)
apply()
-- Emblema da crew antes da montagem do hub.
local splash=create('ImageLabel',{Name='CrewIntro',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(140,140),BackgroundTransparency=1,Image='rbxthumb://type=GroupIcon&id=8440749&w=420&h=420',ImageTransparency=1,ScaleType=Enum.ScaleType.Fit},gui)
local introDone=false
local function endIntro()
    if not alive or introDone then return end
    introDone=true; splash:Destroy(); if not destroyed then showUI(true) end
end
task.delay(3,endIntro)
task.spawn(function()
    pcall(function() ContentProvider:PreloadAsync({splash}) end)
    if not alive or introDone then return end
    if splash.IsLoaded then
        TweenService:Create(splash,TweenInfo.new(0.18),{ImageTransparency=0}):Play()
        task.wait(0.65)
        if not alive or introDone then return end
        TweenService:Create(splash,TweenInfo.new(0.16),{ImageTransparency=1}):Play(); task.wait(0.17)
    end
    endIntro()
end)
return api
