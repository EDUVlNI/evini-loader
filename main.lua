-- EVINI 2.6: fonte independente. Nao carrega o Nitrogen.
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
state.espPlayers=false; state.espEntities=false
state.camEnabled=false; state.camNPC=false; state.wallCheck=true; state.camTeam=false
state.fov=140; state.showFov=true; state.hitPart='Head'
state.airEnabled=true; state.airPart='HumanoidRootPart'; state.prediction=0.12; state.airPrediction=0.12
state.autoPrediction=false; state.autoPredMath=250; state.autoBase=0.04; state.smoothing=0.22
state.accent='Branco';state.uiOpacity=0.06;state.uiSize=1;state.blurSize=5;state.reduceMotion=false;state.notifications=true
state.camMarker=false;state.camTracer=false;state.hideVisuals=false
state.aimViewer=false;state.aimEstimate=false;state.aimLength=120
state.blur=true; state.hideKeyName='L'; state.camKeyName='Q'
local closing=false
local alive=true
-- Preferencias locais por experiencia. JSON validado, nunca executado.
local HttpService=game:GetService('HttpService')
local settingsFile='evini-settings-'..tostring((game.GameId and game.GameId>0) and game.GameId or game.PlaceId or 0)..'.json'
local defaults={}
for k,v in pairs(state) do defaults[k]=v end
local bounds={aimLength={10,500},uiOpacity={0,0.45},uiSize={0.65,1.3},blurSize={0,12},size={2,30},fov={30,500},prediction={0,0.5},airPrediction={0,0.5},autoPredMath={100,1000},autoBase={0,0.2},smoothing={0,1}}
local options={accent={Branco=true,Cinza=true},mode={all=true,exclude=true,only=true},hitPart={Head=true,UpperTorso=true,LowerTorso=true,HumanoidRootPart=true},airPart={Head=true,UpperTorso=true,LowerTorso=true,HumanoidRootPart=true}}
local persistenceStatus='Salvamento indisponível neste executor'
local persistenceReport=function() end
local canSave=type(writefile)=='function' and type(readfile)=='function'
local function loadSettings()
    if not canSave then return end
    persistenceStatus='Salvamento automático ativo'
    local ok,data=pcall(function() return HttpService:JSONDecode(readfile(settingsFile)) end)
    if not ok or type(data)~='table' or data.version~=1 or type(data.settings)~='table' then return end
    for key,default in pairs(defaults) do
        local value=data.settings[key]
        if type(value)==type(default) then
            if type(value)=='boolean' then state[key]=value
            elseif bounds[key] and value==value then state[key]=math.clamp(value,bounds[key][1],bounds[key][2])
            elseif options[key] and options[key][value] then state[key]=value
            elseif key=='query' and #value<=100 then state[key]=value
            elseif key=='hideKeyName' or key=='camKeyName' then
                local valid,code=pcall(function() return Enum.KeyCode[value] end)
                if valid and code and code~=Enum.KeyCode.Unknown and code~=Enum.KeyCode.Escape then state[key]=value end
            end
        end
    end
    if state.hideKeyName==state.camKeyName then state.hideKeyName='L';state.camKeyName='Q' end
    persistenceStatus='Configurações restauradas'
end
loadSettings()
local saveVersion=0
local function saveSettings()
    if not canSave then return false end
    local values={}
    for key in pairs(defaults) do values[key]=state[key] end
    local ok=pcall(function() writefile(settingsFile,HttpService:JSONEncode({version=1,settings=values})) end)
    persistenceStatus=ok and 'Configurações salvas neste dispositivo' or 'Falha ao salvar; confira o executor'
    persistenceReport(persistenceStatus)
    return ok
end
local function queueSave()
    saveVersion=saveVersion+1;local version=saveVersion
    task.delay(0.35,function() if alive and version==saveVersion then saveSettings() end end)
end

local connections, originals = {}, {}
local accents={Branco=Color3.fromRGB(238,238,238),Cinza=Color3.fromRGB(185,185,185)}
local green=accents[state.accent]
local accentBindings={}
local function accent(obj,property) table.insert(accentBindings,{obj,property});obj[property]=green end
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
    return create('TextLabel',{Text=value,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=Color3.fromRGB(235,235,235),Font=Enum.Font.BuilderSans,TextSize=fontSize or 14,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent)
end
local function button(parent,value,pos,size,radius)
    local b = create('TextButton',{Text=value,Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(24,24,24),TextColor3=Color3.fromRGB(200,200,200),BorderSizePixel=0,Font=Enum.Font.BuilderSans,TextSize=13},parent)
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
    if closing or not state.enabled then restoreAll(); return end
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
local notifyTarget=function() end
local hideNotice=function() end
local latched=false
local pingSeconds=nil
local cameraStatus=function() end
local overlays=create('ScreenGui',{Name='EVINI_Overlays',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=79,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player:WaitForChild('PlayerGui'))
local ring=create('Frame',{Name='FOV',AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Size=UDim2.fromOffset(280,280),Visible=false},overlays)
create('UICorner',{CornerRadius=UDim.new(1,0)},ring)
local ringStroke=create('UIStroke',{Color=green,Thickness=1,Transparency=0.22},ring);accent(ringStroke,'Color')
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
local function acquire(camera,mouse,radius)
    local selected=resolveTarget()
    local best,distance=nil,radius or state.fov
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
    -- Formula propria EVINI: base + RTT em segundos * (250 / Auto Pred Math).
    if state.autoPrediction and pingSeconds then return math.clamp(state.autoBase+pingSeconds*(250/state.autoPredMath),0,0.5) end
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
    local frame=create('Frame',{Name='ESPName',BackgroundTransparency=1,Size=UDim2.fromOffset(220,22),Visible=false},overlays)
    local label=text(frame,'',UDim2.fromOffset(0,0),UDim2.fromScale(1,1),13)
    label.Font=Enum.Font.BuilderSansMedium;label.TextXAlignment=Enum.TextXAlignment.Center;label.TextStrokeTransparency=0.35
    item={frame=frame,label=label};espObjects[entry.model]=item
    return item
end
local function updateESP(camera)
    local seen={}
    for _,entry in ipairs(candidates) do
        local wanted=not state.hideVisuals and (entry.player and state.espPlayers or (not entry.player and state.espEntities))
        local root,hum=targetInfo(entry)
        if wanted and root then
            local item=ensureESP(entry);seen[entry.model]=true
            local head=targetPart(entry.model,'Head') or root
            local point,onScreen=camera:WorldToViewportPoint(head.Position+Vector3.new(0,1,0))
            item.frame.Visible=onScreen and point.Z>0
            item.frame.Position=UDim2.fromOffset(point.X-110,point.Y-24)
            item.label.Text=entry.player and entry.player.DisplayName or entry.model.Name
            item.label.TextColor3=entry.player and green or Color3.fromRGB(185,185,185)
        end
    end
    local stale={}
    for model in pairs(espObjects) do if not seen[model] then table.insert(stale,model) end end
    for _,model in ipairs(stale) do destroyESP(model) end
end
local camBind=Enum.KeyCode[state.camKeyName]
local capturing=nil
local uiOpen=false
local uiBusy=false
local function cameraActive()
    if closing or not state.camEnabled or uiOpen or uiBusy or capturing or UIS:GetFocusedTextBox() then return false end
    return latched and cameraTarget~=nil
end
local function resetCamera() local had=cameraTarget;latched=false;cameraTarget=nil;if had then notifyTarget('Alvo liberado') end end
local function screenLine(name)
    return create('Frame',{Name=name,AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,BackgroundColor3=green,Visible=false},overlays)
end
local function drawLine(line,a,b)
    local d=b-a;line.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
    line.Size=UDim2.fromOffset(d.Magnitude,1);line.Rotation=math.deg(math.atan2(d.Y,d.X));line.Visible=true
end
local camDot=create('Frame',{Name='CamTargetDot',AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(6,6),BackgroundColor3=green,BorderSizePixel=0,Visible=false},overlays);round(camDot,3)
local camLine=screenLine('CamTracer')
for _,obj in ipairs({camDot,camLine}) do accent(obj,'BackgroundColor3') end
local function drawTarget(camera,point,dot,line,showDot,showLine)
    dot.Visible=false;line.Visible=false
    if not point or state.hideVisuals then return end
    local p,onScreen=camera:WorldToViewportPoint(point)
    if not onScreen or p.Z<=0 then return end
    local position=Vector2.new(p.X,p.Y)
    dot.Position=UDim2.fromOffset(p.X,p.Y);dot.Visible=showDot
    if showLine then drawLine(line,UIS:GetMouseLocation(),position) end
end
local function updateCameraVisuals(camera)
    if state.hideVisuals or not state.notifications then hideNotice() end
    local camPoint=nil
    if cameraTarget then local _,hum=targetInfo(cameraTarget);if hum then local part=aimPart(cameraTarget,hum);if part then camPoint=part.Position end end end
    drawTarget(camera,camPoint,camDot,camLine,state.camMarker,state.camTracer)
end
local aimItems={}
local aimReport=function() end
local function updateAimViewer(camera)
    local seen,exact,estimated={ },0,0
    if state.aimViewer and not state.hideVisuals then
        for _,entry in ipairs(candidates) do
            local root,hum=targetInfo(entry)
            if entry.player and root then
                local tool=entry.model:FindFirstChildOfClass('Tool')
                local handle=tool and tool:FindFirstChild('Handle')
                local effects=entry.model:FindFirstChild('BodyEffects')
                local value=effects and effects:FindFirstChild('MousePos')
                local origin=handle and handle:IsA('BasePart') and handle or targetPart(entry.model,'Head')
                local destination,approx=nil,false
                if origin and value and value:IsA('Vector3Value') then destination=value.Value
                elseif origin and state.aimEstimate and handle then destination=origin.Position+origin.CFrame.LookVector*state.aimLength;approx=true end
                if origin and destination and typeof(destination)=='Vector3' then
                    local direction=destination-origin.Position
                    if direction.Magnitude>0.01 then
                        local endpoint=origin.Position+direction.Unit*math.min(direction.Magnitude,state.aimLength)
                        local a,aOn=camera:WorldToViewportPoint(origin.Position)
                        local b,bOn=camera:WorldToViewportPoint(endpoint)
                        local item=aimItems[entry.model]
                        if not item then
                            item={line=screenLine('AimViewerLine'),label=text(overlays,'',UDim2.fromOffset(0,0),UDim2.fromOffset(200,20),11)}
                            item.label.Name='AimViewerLabel';item.label.TextStrokeTransparency=0.35;aimItems[entry.model]=item
                        end
                        seen[entry.model]=true;item.line.Visible=false;item.label.Visible=false
                        if approx then estimated=estimated+1 else exact=exact+1 end
                        if aOn and bOn and a.Z>0 and b.Z>0 then
                            drawLine(item.line,Vector2.new(a.X,a.Y),Vector2.new(b.X,b.Y))
                            item.line.BackgroundColor3=approx and Color3.fromRGB(150,150,150) or green
                            item.label.Position=UDim2.fromOffset(b.X+5,b.Y);item.label.Text=entry.player.DisplayName..(approx and ' · estimativa' or ' · replicada');item.label.Visible=true
                        end
                    end
                end
            end
        end
    end
    local stale={};for model in pairs(aimItems) do if not seen[model] then table.insert(stale,model) end end
    for _,model in ipairs(stale) do local item=aimItems[model];item.line:Destroy();item.label:Destroy();aimItems[model]=nil end
    aimReport(exact,estimated)
end

local espElapsed,statusElapsed=0,0
local function render(dt)
    local camera=Workspace.CurrentCamera
    if not camera then return end
    local mouse=UIS:GetMouseLocation()
    ring.Position=UDim2.fromOffset(mouse.X,mouse.Y)
    ring.Size=UDim2.fromOffset(state.fov*2,state.fov*2)
    ring.Visible=not state.hideVisuals and state.camEnabled and state.showFov and not uiOpen and not uiBusy
    espElapsed=espElapsed+dt; statusElapsed=statusElapsed+dt
    if espElapsed>=0.05 then espElapsed=0; updateESP(camera);updateAimViewer(camera) end
    if cameraActive() then
        -- FOV somente na captura por tecla. Nunca adquirir outro alvo por frame.
        local entry=cameraTarget
        if entry then
            local root,hum=targetInfo(entry)
            local part=hum and aimPart(entry,hum)
            local point,onScreen
            if part then point,onScreen=camera:WorldToViewportPoint(part.Position) end
            if not root or not part or not filterCamera(entry,resolveTarget()) or not onScreen or point.Z<=0
                or not visibleToCamera(entry,part,camera) then entry=nil end
        end
        if not entry then resetCamera() else cameraTarget=entry end
        if cameraTarget then
            local _,hum=targetInfo(cameraTarget)
            local part,air=aimPart(cameraTarget,hum)
            local destination=predictedPosition(part,hum,air)
            if (destination-camera.CFrame.Position).Magnitude>0.01 then
                local alpha=state.smoothing<=0 and 1 or 1-math.exp(-dt*6/state.smoothing)
                camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position,destination),alpha)
            end
        end
    else resetCamera() end
    updateCameraVisuals(camera)
    if statusElapsed>=0.2 then
        statusElapsed=0
        cameraStatus(cameraTarget and cameraTarget.name or 'Sem alvo',pingSeconds,predictionTime(false))
    end
end
local palette={bg=Color3.fromRGB(14,14,14),panel=Color3.fromRGB(25,25,25),edge=Color3.fromRGB(59,59,59),muted=Color3.fromRGB(158,158,158),white=Color3.fromRGB(235,235,235)}
local rootUI=create('Frame',{Name='Hub',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(620,546),BackgroundTransparency=1,Visible=false},gui)
local uiScale=create('UIScale',{Scale=1},rootUI)
local function fitUI()
    local camera=Workspace.CurrentCamera
    if camera then uiScale.Scale=math.min(state.uiSize,math.max(0.35,math.min((camera.ViewportSize.X-28)/620,(camera.ViewportSize.Y-60)/546))) end
end
local pieces={}
local function piece(name,x,y,w,h,dx,dy)
    local obj=create('CanvasGroup',{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=palette.bg,BorderSizePixel=0,GroupTransparency=0},rootUI)
    round(obj,7); obj.BackgroundTransparency=state.uiOpacity;create('UIStroke',{Color=palette.edge,Thickness=1},obj)
    table.insert(pieces,{obj=obj,home=UDim2.fromOffset(x,y),away=UDim2.fromOffset(x+dx,y+dy)})
    return obj
end
local header=piece('Header',0,0,620,58,0,-24)
local sidebar=piece('Navigation',0,66,138,430,-30,0)
local body=piece('Content',146,66,474,430,30,0)
local footer=piece('Footer',0,504,620,42,0,22)
local title=text(header,'EVINI',UDim2.fromOffset(18,10),UDim2.fromOffset(175,23),21); title.Font=Enum.Font.BuilderSansBold;accent(title,'TextColor3')
local sub=text(header,'v2.6 · #death · Cam lock, Hitbox e Visual',UDim2.fromOffset(19,34),UDim2.fromOffset(300,14),10); sub.Font=Enum.Font.BuilderSans; sub.TextColor3=palette.muted
local hide=button(header,'−',UDim2.new(1,-74,0,15),UDim2.fromOffset(26,26)); hide.Name='Hide'
local close=button(header,'×',UDim2.new(1,-40,0,15),UDim2.fromOffset(26,26)); close.Name='Close'
local blur=create('BlurEffect',{Name='EVINI_Blur',Size=0},Lighting)
local animationVersion=0
local activeTweens={}
local destroyed=false
local function tween(obj,duration,props)
    local t=TweenService:Create(obj,TweenInfo.new(state.reduceMotion and 0 or duration,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props)
    t:Play(); table.insert(activeTweens,t); return t
end
local function showUI(open,after)
    if not alive then return end
    animationVersion=animationVersion+1
    local version=animationVersion
    for _,t in ipairs(activeTweens) do t:Cancel() end
    activeTweens={}; uiBusy=true; uiOpen=open; resetCamera()
    rootUI.Visible=true; fitUI()
    tween(blur,0.28,{Size=open and state.blur and state.blurSize or 0})
    for i,item in ipairs(pieces) do
        if open and item.obj.GroupTransparency>=0.99 then item.obj.Position=state.reduceMotion and item.home or item.away end
        task.delay(state.reduceMotion and 0 or (open and i-1 or #pieces-i)*0.035,function()
            if not alive or version~=animationVersion then return end
            tween(item.obj,0.30,{Position=(open or state.reduceMotion) and item.home or item.away,GroupTransparency=open and 0 or 1})
        end)
    end
    task.delay(state.reduceMotion and 0 or 0.43,function()
        if not alive or version~=animationVersion then return end
        uiBusy=false; rootUI.Visible=open
        if after then after() end
    end)
end
for _,item in ipairs(pieces) do item.obj.GroupTransparency=1; item.obj.Position=item.away end
local pages,tabs={},{}
local currentPage='Mira'
local function page(name,index)
    local frame=create('ScrollingFrame',{Name=name,Position=UDim2.fromOffset(14,12),Size=UDim2.new(1,-28,1,-24),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=green,CanvasSize=UDim2.fromOffset(0,0),Visible=index==1},body)
    pages[name]={frame=frame,y=0};accent(frame,'ScrollBarImageColor3')
    local b=button(sidebar,name,UDim2.fromOffset(10,14+(index-1)*42),UDim2.new(1,-20,0,32)); b.Name='Tab_'..name; b.Font=Enum.Font.BuilderSans
    tabs[name]=b
    connect(b.Activated,function()
        currentPage=name
        for key,p in pairs(pages) do
            if p.tabTween then p.tabTween:Cancel() end
            p.frame.Visible=key==name;tabs[key].TextColor3=key==name and green or palette.muted
            if key==name then
                p.frame.Position=UDim2.fromOffset(14,state.reduceMotion and 12 or 17)
                p.tabTween=TweenService:Create(p.frame,TweenInfo.new(state.reduceMotion and 0 or 0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(14,12)})
                p.tabTween:Play()
            end
        end
    end)
    b.TextColor3=index==1 and green or palette.muted
    return pages[name]
end
local camPage=page('Mira',1)
local espPage=page('Visual',2)
local settingsPage=page('Ajustes',3)
local function subPage() return {frame=create('Frame',{BackgroundTransparency=1,Visible=false,Size=UDim2.new(1,0,0,0)},camPage.frame),y=0} end
local hitPage=subPage()
local predPage=subPage()
local branding=text(sidebar,'# DEATH\n8440749',UDim2.new(0,13,1,-48),UDim2.new(1,-26,0,36),10); branding.Font=Enum.Font.BuilderSans; branding.TextColor3=palette.muted
local function slot(p,h)
    local y=p.y; p.y=y+h; if p.frame:IsA('ScrollingFrame') then p.frame.CanvasSize=UDim2.fromOffset(0,p.y+8) else p.frame.Size=UDim2.new(1,0,0,p.y+8) end; return y
end
local function label(p,value,description)
    local y=slot(p,description and 57 or 32)
    local t=text(p.frame,value,UDim2.fromOffset(0,y),UDim2.new(1,0,0,20),15); t.Font=Enum.Font.BuilderSans; accent(t,'TextColor3')
    if description then local d=text(p.frame,description,UDim2.fromOffset(0,y+23),UDim2.new(1,-4,0,30),11); d.Font=Enum.Font.BuilderSans; d.TextColor3=palette.muted end
end
local function rowText(p,value,y)
    local t=text(p.frame,value,UDim2.fromOffset(0,y+5),UDim2.new(1,-132,0,24),13); t.Font=Enum.Font.BuilderSans; return t
end
local controlRefresh={}
local function switch(p,value,key,onChange)
    local y=slot(p,42); rowText(p,value,y)
    local b=button(p.frame,'',UDim2.new(1,-46,0,y+6),UDim2.fromOffset(46,22)); b.Name=key
    local dot=create('Frame',{Size=UDim2.fromOffset(14,14),BorderSizePixel=0},b); round(dot,2)
    local function refresh()
        b.BackgroundColor3=state[key] and green or palette.edge
        dot.BackgroundColor3=state[key] and palette.bg or palette.muted
        dot.Position=UDim2.fromOffset(state[key] and 28 or 4,4)
    end
    connect(b.Activated,function() state[key]=not state[key]; refresh(); if onChange then onChange() end;queueSave() end)
    refresh();controlRefresh[key]=refresh; return b
end
local function field(p,value,key,min,max,step,onChange)
    local y=slot(p,46); rowText(p,value,y)
    local box=create('TextBox',{Name=key=='size' and 'SizeInput' or key,Position=UDim2.new(1,-106,0,y),Size=UDim2.fromOffset(106,32),BackgroundColor3=palette.panel,BorderSizePixel=0,Text=tostring(state[key]),TextColor3=palette.white,ClearTextOnFocus=false,Font=Enum.Font.BuilderSans,TextSize=13},p.frame)
    round(box,3); create('UIStroke',{Color=palette.edge,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},box)
    local function set(v)
        if v and v==v then state[key]=math.floor(math.clamp(v,min,max)/step+0.5)*step end
        box.Text=string.format(step<1 and '%.3f' or '%.0f',state[key])
        if onChange then onChange() end;queueSave()
    end
    connect(box.FocusLost,function() set(tonumber((box.Text:gsub(',','.')))) end)
    controlRefresh[key]=function() box.Text=string.format(step<1 and '%.3f' or '%.0f',state[key]) end
    return box,set
end
local sliderDrag=nil
local function slider(p,value,key,min,max,step)
    local box,set=field(p,value,key,min,max,step)
    local y=slot(p,24)-7
    local hit=create('TextButton',{Name=key..'_Slider',Text='',BackgroundTransparency=1,Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,22)},p.frame)
    local track=create('Frame',{Position=UDim2.fromOffset(0,8),Size=UDim2.new(1,0,0,3),BackgroundColor3=palette.edge,BorderSizePixel=0},hit)
    local fill=create('Frame',{Size=UDim2.fromScale((state[key]-min)/(max-min),1),BackgroundColor3=green,BorderSizePixel=0},track)
    accent(fill,'BackgroundColor3')
    local knob=create('Frame',{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale((state[key]-min)/(max-min),0.5),Size=UDim2.fromOffset(7,11),BackgroundColor3=green,BorderSizePixel=0},track)
    accent(knob,'BackgroundColor3')
    local function refresh() local r=(state[key]-min)/(max-min); fill.Size=UDim2.fromScale(r,1); knob.Position=UDim2.fromScale(r,0.5) end
    local refreshBox=controlRefresh[key]
    controlRefresh[key]=function() refreshBox();refresh() end
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
    local b=button(p.frame,'',UDim2.new(1,-154,0,y),UDim2.fromOffset(154,32)); b.Name=key; b.Font=Enum.Font.BuilderSans; b.TextSize=11
    local function refresh()
        for _,o in ipairs(options) do if o[1]==state[key] then b.Text=o[2]..'  >' end end
    end
    connect(b.Activated,function()
        for i,o in ipairs(options) do if o[1]==state[key] then state[key]=options[i%#options+1][1]; break end end
        refresh(); if onChange then onChange() end;queueSave()
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
local nick=create('TextBox',{Name='NickInput',Position=UDim2.fromOffset(0,nickY),Size=UDim2.new(1,0,0,32),BackgroundColor3=palette.panel,TextColor3=palette.white,BorderSizePixel=0,PlaceholderText='@usuario ou nome de exibição exato',PlaceholderColor3=palette.muted,Text=state.query,ClearTextOnFocus=false,Font=Enum.Font.BuilderSans,TextSize=13},hitPage.frame); round(nick,3)
local result=text(hitPage.frame,'',UDim2.fromOffset(0,slot(hitPage,36)),UDim2.new(1,0,0,32),11); result.Font=Enum.Font.BuilderSans; result.TextColor3=palette.muted
reportTarget=function(target,message)
    result.Text=state.mode=='all' and 'Todos os outros jogadores.' or (target and ((state.mode=='exclude' and 'Normal para @' or 'Somente @')..target.Name) or message)
end
connect(nick.FocusLost,function() state.query=nick.Text:match('^%s*(.-)%s*$'):gsub('^@',''); nick.Text=state.query; apply(); resetCamera();queueSave() end)
label(espPage,'Nomes no jogo','Identifique jogadores e NPCs sem cobrir a cena.')
switch(espPage,'Jogadores','espPlayers')
switch(espPage,'NPCs / entidades','espEntities')

label(espPage,'Aim Viewer','Linha da mira replicada. Estimativa opcional é rotulada e não representa a mira real.')
switch(espPage,'Ativar Aim Viewer','aimViewer')
switch(espPage,'Permitir estimativa da arma','aimEstimate')
field(espPage,'Comprimento da linha','aimLength',10,500,1)
local aimStatus=text(espPage.frame,'Aim Viewer desligado',UDim2.fromOffset(0,slot(espPage,38)),UDim2.new(1,0,0,34),11);aimStatus.Name='AimViewerStatus'
aimReport=function(exact,estimated)
    aimStatus.Text=state.aimViewer and ('Replicadas: '..exact..' · estimadas: '..estimated..(exact+estimated==0 and ' · sem dados disponíveis' or '')) or 'Aim Viewer desligado'
end
label(espPage,'Visibilidade','Ocultar estes desenhos não desliga o recurso de mira.')
switch(espPage,'Ocultar todos os desenhos','hideVisuals')
switch(espPage,'Marcador do cam lock','camMarker')
switch(espPage,'Linha do cam lock','camTracer')
label(espPage,'Só o essencial','Apenas o nome de exibição, sem caixa, distância ou vida. Mortos e K.O. ficam ocultos.')
label(camPage,'CAM LOCK + PREDICT','Clique na tecla para capturar no FOV. Clique de novo para soltar. Esc também solta.')
local camKeyY=slot(camPage,46)
switch(camPage,'Ativar cam lock','camEnabled',resetCamera)
local preset=button(camPage.frame,'Começar com ping de 80–120 ms',UDim2.fromOffset(0,slot(camPage,40)),UDim2.new(1,0,0,30));preset.Name='PingPreset';preset.Font=Enum.Font.BuilderSans;preset.TextSize=11
connect(preset.Activated,function()
    state.autoPrediction=true;state.autoPredMath=250;state.autoBase=0.04;state.smoothing=0.22
    for _,key in ipairs({'autoPrediction','autoPredMath','autoBase','smoothing'}) do if controlRefresh[key] then controlRefresh[key]() end end
    queueSave()
end)
label(predPage,'CALIBRAÇÃO','Comece com Auto Pred Math 250 e base 0,040. Em 80–120 ms, esta fórmula estima 0,120–0,160 s; não garante acertos.')
switch(predPage,'Estimativa pelo ping','autoPrediction')
slider(predPage,'Auto Pred Math','autoPredMath',100,1000,1)
field(predPage,'Base automática · segundos','autoBase',0,0.2,0.005)
slider(predPage,'Previsão manual · segundos','prediction',0,0.5,0.001)

switch(camPage,'Mostrar círculo do FOV','showFov')
slider(camPage,'Raio do FOV · pixels','fov',30,500,1)
choice(camPage,'Parte do corpo','hitPart',{{'Head','Cabeça'},{'UpperTorso','Tronco'},{'LowerTorso','Tronco baixo'},{'HumanoidRootPart','Centro'}},function() cameraTarget=nil end)
switch(camPage,'Verificar paredes','wallCheck')
switch(camPage,'Ignorar meu time','camTeam',function() cameraTarget=nil end)
switch(camPage,'Incluir NPCs no lock','camNPC',function() cameraTarget=nil end)
slider(camPage,'Suavização · 0 = instantâneo','smoothing',0,1,0.01)
switch(predPage,'Usar Air Part','airEnabled')
choice(predPage,'Parte no ar','airPart',{{'HumanoidRootPart','Centro'},{'Head','Cabeça'},{'UpperTorso','Tronco'},{'LowerTorso','Tronco baixo'}})
slider(predPage,'Previsão no ar · segundos','airPrediction',0,0.5,0.001)
label(predPage,'NO AR','Air Part usa o estado de salto/queda e antecipa velocidade + gravidade. No automático, o ping define o tempo nos dois casos.')
local targetReadout=text(camPage.frame,'Sem alvo',UDim2.fromOffset(0,slot(camPage,32)),UDim2.new(1,0,0,28),11); targetReadout.Font=Enum.Font.BuilderSans; accent(targetReadout,'TextColor3')
label(settingsPage,'Do seu jeito','Ajuste a aparência e os atalhos. Suas escolhas ficam salvas neste dispositivo.')
local hideKey=Enum.KeyCode[state.hideKeyName]
local captureVersion=0
local keyButtons={}
local function refreshKeys()
    if keyButtons.hide then keyButtons.hide.Text=hideKey.Name end
    if keyButtons.cam then keyButtons.cam.Text=camBind.Name end
end
local function stopCapture() capturing=nil; captureVersion=captureVersion+1; refreshKeys() end
local function keyField(value,which)
    local p=which~='hide' and camPage or settingsPage
    local y=which=='cam' and camKeyY or slot(p,46); rowText(p,value,y)
    local b=button(p.frame,'',UDim2.new(1,-106,0,y),UDim2.fromOffset(106,32)); b.Name=which=='hide' and 'Keybind' or 'CamKeybind'; keyButtons[which]=b
    connect(b.Activated,function()
        if capturing==which then stopCapture(); return end
        stopCapture(); capturing=which; resetCamera(); b.Text='Tecla?'; local version=captureVersion
        task.delay(8,function() if alive and version==captureVersion then stopCapture() end end)
    end)
end
keyField('Ocultar / abrir hub','hide'); keyField('Tecla do cam lock','cam'); refreshKeys()
local saveText=text(settingsPage.frame,persistenceStatus,UDim2.fromOffset(0,slot(settingsPage,38)),UDim2.new(1,0,0,32),11); saveText.Font=Enum.Font.BuilderSans;saveText.TextColor3=palette.muted
persistenceReport=function(message) if alive then saveText.Text=message end end
switch(settingsPage,'Blur ao abrir','blur',function() tween(blur,0.2,{Size=uiOpen and state.blur and state.blurSize or 0}) end)
label(settingsPage,'COMPATIBILIDADE','Base R6 / R15 com Humanoid. Câmeras e personagens personalizados podem exigir adaptação. Fechar remove efeitos e restaura hitboxes.')
local folds={}
local baseHeight=camPage.y
local function arrangeFolds()
    local y=baseHeight
    for _,f in ipairs(folds) do
        f.button.Position=UDim2.fromOffset(0,y)
        f.button.Text=(f.open and '−  ' or '+  ')..f.name
        y=y+40;f.page.frame.Position=UDim2.fromOffset(0,y);f.page.frame.Visible=f.open
        if f.open then y=y+f.page.y+12 end
    end
    camPage.frame.CanvasSize=UDim2.fromOffset(0,y+10)
end
for _,definition in ipairs({{'Calibração avançada',predPage},{'Hitbox e filtros',hitPage}}) do
    local f={name=definition[1],page=definition[2],open=false}
    f.button=button(camPage.frame,'',UDim2.fromOffset(0,0),UDim2.new(1,0,0,32));f.button.Name=definition[1]
    table.insert(folds,f)
    connect(f.button.Activated,function() f.open=not f.open;arrangeFolds() end)
end
arrangeFolds()
local function refreshAppearance()
    green=accents[state.accent]
    for _,binding in ipairs(accentBindings) do if binding[1].Parent then binding[1][binding[2]]=green end end
    for _,item in ipairs(pieces) do item.obj.BackgroundTransparency=state.uiOpacity end
    for _,refresh in pairs(controlRefresh) do refresh() end
    for name,b in pairs(tabs) do b.TextColor3=name==currentPage and green or palette.muted end
    fitUI();tween(blur,0.2,{Size=uiOpen and state.blur and state.blurSize or 0})
end
label(settingsPage,'Aparência')
choice(settingsPage,'Contraste','accent',{{'Branco','Branco'},{'Cinza','Cinza claro'}},refreshAppearance)
field(settingsPage,'Transparência · 0–0,45','uiOpacity',0,0.45,0.01,refreshAppearance)
field(settingsPage,'Tamanho da interface','uiSize',0.65,1.3,0.05,refreshAppearance)
field(settingsPage,'Intensidade do blur','blurSize',0,12,1,refreshAppearance)
switch(settingsPage,'Reduzir animações','reduceMotion')
switch(settingsPage,'Notificações de alvo','notifications')
local foot=text(footer,'L · HUB     Q · CAM LOCK',UDim2.fromOffset(14,12),UDim2.fromOffset(250,18),10); foot.Font=Enum.Font.BuilderSans; foot.TextColor3=palette.muted
local stats=text(footer,'PING —',UDim2.new(1,-332,0,12),UDim2.fromOffset(318,18),10); stats.Font=Enum.Font.BuilderSans; stats.TextXAlignment=Enum.TextXAlignment.Right; stats.TextColor3=green
cameraStatus=function(name,ping,pred)
    targetReadout.Text='ALVO: '..name
    stats.Text=(ping and math.floor(ping*1000)..' ms' or 'ping indisponível')..' / '..string.format('%.3f s',pred)
    foot.Text=hideKey.Name..' · HUB   '..camBind.Name..' · '..(cameraTarget and 'LOCK' or 'CAM')
end
local toast=create('Frame',{Name='TargetNotice',AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-38),Size=UDim2.fromOffset(300,58),BackgroundColor3=palette.bg,BorderSizePixel=0,Visible=false},overlays)
round(toast,7)
local toastTitle=text(toast,'EVINI',UDim2.fromOffset(14,8),UDim2.fromOffset(272,18),12);accent(toastTitle,'TextColor3')
local toastBody=text(toast,'',UDim2.fromOffset(14,29),UDim2.fromOffset(272,19),12)
local toastVersion=0
hideNotice=function() toastVersion=toastVersion+1;toast.Visible=false end
notifyTarget=function(message)
    if not alive or closing or state.hideVisuals or not state.notifications then return end
    toastVersion=toastVersion+1;local version=toastVersion
    toastBody.Text=message;toast.Visible=true
    task.delay(2,function() if alive and version==toastVersion then toast.Visible=false end end)
end
connect(UIS.InputBegan,function(event,processed)
    if not capturing and event.KeyCode==Enum.KeyCode.Escape then
        resetCamera()
        return
    end
    if not capturing and latched and event.KeyCode==camBind then resetCamera();return end
    if UIS:GetFocusedTextBox() then return end
    if capturing then
        if event.UserInputType~=Enum.UserInputType.Keyboard then return end
        if event.KeyCode==Enum.KeyCode.Escape then stopCapture(); return end
        if processed or event.KeyCode==Enum.KeyCode.Unknown then return end
        local assigned={hide=hideKey,cam=camBind}
        for role,key in pairs(assigned) do if role~=capturing and event.KeyCode==key then keyButtons[capturing].Text='Em uso';return end end
        if event.KeyCode==Enum.KeyCode.Escape then stopCapture(); return end
        if capturing=='hide' then hideKey=event.KeyCode;state.hideKeyName=hideKey.Name else camBind=event.KeyCode;state.camKeyName=camBind.Name end
        queueSave();stopCapture(); return
    end
    if processed then return end
    if event.KeyCode==hideKey then showUI(not uiOpen)
    elseif event.KeyCode==camBind and not uiOpen and not uiBusy then
        resetCamera()
        local camera=Workspace.CurrentCamera
        if state.camEnabled and camera and not closing then
            cameraTarget=acquire(camera,UIS:GetMouseLocation())
            latched=cameraTarget~=nil
            if cameraTarget then notifyTarget('locked in '..(cameraTarget.player and ('@'..cameraTarget.player.Name) or cameraTarget.name)) end
        end
    end
end)
connect(UIS.InputEnded,function(event)
    if sliderDrag and (event==sliderDrag.input or event.UserInputType==Enum.UserInputType.MouseButton1) then sliderDrag=nil end
end)
connect(UIS.WindowFocusReleased,function() resetCamera();sliderDrag=nil end)
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
local api={Settings=state,Save=saveSettings}
function api.Destroy()
    if not alive then return end
    saveSettings();alive=false; animationVersion=animationVersion+1; resetCamera()
    for _,c in ipairs(connections) do c:Disconnect() end
    for _,t in ipairs(activeTweens) do t:Cancel() end
    RunService:UnbindFromRenderStep('EVINI_Camera')
    restoreAll(); blur:Destroy(); overlays:Destroy(); gui:Destroy()
    espObjects={}; candidates={}; npcModels={};aimItems={}
    if env.EVINI==api then env.EVINI=nil end
end
env.EVINI=api
connect(close.Activated,function()
    if destroyed then return end
    destroyed=true;closing=true;apply();resetCamera()
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
    if splash.IsLoaded and not state.reduceMotion then
        TweenService:Create(splash,TweenInfo.new(0.18),{ImageTransparency=0}):Play()
        task.wait(0.65)
        if not alive or introDone then return end
        TweenService:Create(splash,TweenInfo.new(0.16),{ImageTransparency=1}):Play(); task.wait(0.17)
    end
    endIntro()
end)
return api
