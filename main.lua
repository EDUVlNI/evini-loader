-- EVINI 3.6: fonte independente. Nao carrega o Nitrogen.
-- Alteracoes de hitbox sao locais; o servidor pode ignora-las.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local ContentProvider = game:GetService('ContentProvider')
local Workspace=game:GetService('Workspace')
local GuiService=game:GetService('GuiService')
local player = Players.LocalPlayer
assert(player, '[EVINI] Execute em um cliente com LocalPlayer.')
local env = (type(getgenv) == 'function' and getgenv()) or _G
if type(env.EVINI) == 'table' and type(env.EVINI.Destroy) == 'function' then pcall(env.EVINI.Destroy) end
local state = {enabled=false, size=8, transparent=false, knockCheck=true, playerSelection={}, newPlayersSelected=true}
state.serverNotices=true; state.espPlayers=false; state.espEntities=false
state.camEnabled=false; state.camNPC=false; state.wallCheck=true; state.camTeam=false
state.fovTransparency=0.22;state.cycleParts=false;state.cycleInterval=0.8;state.fov=140; state.showFov=true; state.hitPart='Head'
state.airEnabled=true; state.airPart='HumanoidRootPart'; state.prediction=0.12; state.airPrediction=0.12
state.autoPrediction=false; state.autoPredMath=250; state.autoBase=0.04; state.smoothing=0.22
state.smokeTheme=true;state.uiSounds=true;state.soundVolume=0.2;state.accent='Branco';state.uiOpacity=0.28;state.uiSize=1;state.reduceMotion=false;state.notifications=true
state.camMarker=false;state.camTracer=false;state.hideVisuals=false
state.aimViewer=false;state.aimEstimate=false;state.aimLength=120
state.hideKeyName='L'; state.camKeyName='Q'
local closing=false
local alive=true
-- Preferencias locais por experiencia. JSON validado, nunca executado.
local HttpService=game:GetService('HttpService')
local settingsFile='evini-settings-'..tostring((game.GameId and game.GameId>0) and game.GameId or game.PlaceId or 0)..'.json'
local defaults={}
for k,v in pairs(state) do defaults[k]=v end
local bounds={fovTransparency={0,1},cycleInterval={0.3,3},aimLength={10,500},uiOpacity={0,0.45},soundVolume={0,0.6},uiSize={0.45,1.5},size={2,30},fov={30,500},prediction={0,0.5},airPrediction={0,0.5},autoPredMath={100,1000},autoBase={0,0.2},smoothing={0,1}}
local options={accent={Branco=true,Cinza=true},hitPart={Head=true,UpperTorso=true,LowerTorso=true,HumanoidRootPart=true},airPart={Head=true,UpperTorso=true,LowerTorso=true,HumanoidRootPart=true}}
local persistenceStatus='Salvamento indisponível neste executor'
local persistenceReport=function() end
local canSave=type(writefile)=='function' and type(readfile)=='function'
local function loadSettings()
    if not canSave then return end
    persistenceStatus='Salvamento automático ativo'
    local ok,data=pcall(function() return HttpService:JSONDecode(readfile(settingsFile)) end)
    if not ok or type(data)~='table' or data.version~=1 or type(data.settings)~='table' then return end
    if data.settings.smokeTheme~=true then data.settings.uiOpacity=0.28 end
    for key,default in pairs(defaults) do
        local value=data.settings[key]
        if type(value)==type(default) then
            if type(value)=='boolean' then state[key]=value
            elseif bounds[key] and value==value then state[key]=math.clamp(value,bounds[key][1],bounds[key][2])
            elseif options[key] and options[key][value] then state[key]=value
            elseif key=='playerSelection' then
                local count=0
                for id,enabled in pairs(value) do
                    if type(id)=='string' and #id<=20 and id:match('^%d+$') and type(enabled)=='boolean' and count<500 then
                        state.playerSelection[id]=enabled;count=count+1
                    end
                end
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
local departing=setmetatable({}, {__mode='k'})
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
    return create('TextLabel',{Text=value,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=Color3.fromRGB(235,235,235),Font=Enum.Font.Gotham,TextSize=fontSize or 14,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent)
end
local clickSound=create('Sound',{Name='UIClick',SoundId='rbxasset://sounds/electronicpingshort.wav',Volume=state.soundVolume,PlaybackSpeed=1.6},gui)
local function playClick()
    if not alive or not state.uiSounds then return end
    clickSound.Volume=state.soundVolume
    pcall(function() clickSound.TimePosition=0;clickSound:Play() end)
end
local function button(parent,value,pos,size,radius)
    local b = create('TextButton',{Text=value,Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(48,48,48),TextColor3=Color3.fromRGB(200,200,200),BorderSizePixel=0,Font=Enum.Font.Gotham,TextSize=13},parent)
    round(b,radius or 1)
    create('UIGradient',{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(94,94,94))},b)
    create('UIStroke',{Color=Color3.fromRGB(0,0,0),Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b)
    -- Instance-owned event is released with the button, including roster rows.
    b.Activated:Connect(playClick)
    b.AutoButtonColor=false
    create('Frame',{Position=UDim2.fromOffset(1,1),Size=UDim2.new(1,-2,0,1),BackgroundColor3=Color3.fromRGB(118,118,118),BorderSizePixel=0},b)
    create('Frame',{Position=UDim2.fromOffset(1,1),Size=UDim2.new(0,1,1,-2),BackgroundColor3=Color3.fromRGB(74,74,74),BorderSizePixel=0},b)
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
local function selectedPlayer(target)
    local value=state.playerSelection[tostring(target.UserId)]
    if value==nil then return state.newPlayersSelected end
    return value
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
    if closing or not state.enabled then restoreAll(); return end
    local active={}
    for _,target in ipairs(Players:GetPlayers()) do
        local eligible=selectedPlayer(target)
        if target~=player and not departing[target] and eligible then
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
            if p~=player and not departing[p] then table.insert(list,{model=model,player=p,name=p.DisplayName..' (@'..p.Name..')'}) end
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
    if entry.player and departing[entry.player] then return nil end
    if not entry.model.Parent then return nil end
    local hum=entry.model:FindFirstChildOfClass('Humanoid')
    if not hum or unavailable(entry.model,hum) then return nil end
    local part=targetPart(entry.model,'HumanoidRootPart')
    return part,hum
end
local function filterCamera(entry)
    if not entry.player then return state.camNPC end
    if not selectedPlayer(entry.player) then return false end
    if state.camTeam and not player.Neutral and not entry.player.Neutral and player.Team and player.Team==entry.player.Team then return false end
    return true
end
local aimClock=0
local function aimPart(entry,hum)
    local air=hum:GetState()==Enum.HumanoidStateType.Freefall or hum:GetState()==Enum.HumanoidStateType.Jumping
    local name=state.hitPart
    if state.cycleParts then
        local sequence={'UpperTorso','LowerTorso','Head'}
        name=sequence[math.floor(aimClock/state.cycleInterval)%#sequence+1]
    end
    return targetPart(entry.model,(state.airEnabled and air) and state.airPart or name),air
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
    local best,distance=nil,radius or state.fov
    for _,entry in ipairs(candidates) do
        local root,hum=targetInfo(entry)
        if root and filterCamera(entry) then
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
    local frame=create('BillboardGui',{Name='ESPName',Size=UDim2.fromOffset(220,24),StudsOffsetWorldSpace=Vector3.new(0,2,0),AlwaysOnTop=true,MaxDistance=1200,Enabled=false},gui)
    local name=text(frame,entry.player and entry.player.DisplayName or entry.model.Name,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),13)
    name.Font=Enum.Font.GothamMedium;name.TextXAlignment=Enum.TextXAlignment.Center;name.TextStrokeTransparency=0.3
    item={frame=frame,label=name};espObjects[entry.model]=item
    return item
end
local function updateESP()
    local seen={}
    if not state.hideVisuals and (state.espPlayers or state.espEntities) then
        for _,entry in ipairs(candidates) do
            local wanted=entry.player and state.espPlayers or (not entry.player and state.espEntities)
            if wanted then
                local root=targetInfo(entry)
                if root then
                    local item=ensureESP(entry)
                    local head=targetPart(entry.model,'Head') or root
                    if item.frame.Adornee~=head then item.frame.Adornee=head end
                    if not item.frame.Enabled then item.frame.Enabled=true end
                    if item.label.TextColor3~=green then item.label.TextColor3=green end
                    seen[entry.model]=true
                end
            end
        end
    end
    for model,item in pairs(espObjects) do
        if not model.Parent then destroyESP(model)
        elseif not seen[model] and item.frame.Enabled then item.frame.Enabled=false end
    end
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
local aimFolder=create('Folder',{Name='EVINI_AimEffects'},Workspace)
local aimRed=Color3.fromRGB(255,48,48)
local function destroyAim(model)
    local item=aimItems[model]
    if not item then return end
    item.start:Destroy();item.finish:Destroy();item.beam:Destroy();item.label:Destroy()
    aimItems[model]=nil
end
local function ensureAim(entry)
    local item=aimItems[entry.model]
    if item then return item end
    local props={Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1,Size=Vector3.new(0.08,0.08,0.08)}
    local start=create('Part',props,aimFolder);start.Name='AimStart'
    local finish=create('Part',props,aimFolder);finish.Name='AimPoint';finish.Color=aimRed;finish.Material=Enum.Material.Neon;finish.Shape=Enum.PartType.Ball;finish.Size=Vector3.new(0.18,0.18,0.18)
    local a=create('Attachment',{},start);local b=create('Attachment',{},finish)
    local beam=create('Beam',{Name='AimRay',Attachment0=a,Attachment1=b,Color=ColorSequence.new(aimRed),Transparency=NumberSequence.new(0.15),Width0=0.035,Width1=0.025,FaceCamera=true,LightEmission=1,LightInfluence=0,Segments=1,Enabled=false},aimFolder)
    local tag=create('BillboardGui',{Name='AimViewerLabel',Adornee=finish,Size=UDim2.fromOffset(210,22),StudsOffsetWorldSpace=Vector3.new(0,0.35,0),AlwaysOnTop=true,Enabled=false},gui)
    local caption=text(tag,'',UDim2.fromScale(0,0),UDim2.fromScale(1,1),11);caption.TextColor3=aimRed;caption.TextStrokeTransparency=0.2;caption.TextXAlignment=Enum.TextXAlignment.Center
    item={start=start,finish=finish,beam=beam,label=tag,caption=caption};aimItems[entry.model]=item
    return item
end
local function updateAimViewer()
    local exact,estimated=0,0
    local seen={}
    if state.aimViewer and not state.hideVisuals then
        for _,entry in ipairs(candidates) do
            if entry.player then
                local root=targetInfo(entry)
                if root then
                    local head=targetPart(entry.model,'Head') or root
                    local tool=entry.model:FindFirstChildOfClass('Tool')
                    local handle=tool and tool:FindFirstChild('Handle')
                    local origin=handle and handle:IsA('BasePart') and handle or head
                    local effects=entry.model:FindFirstChild('BodyEffects')
                    local value=effects and effects:FindFirstChild('MousePos')
                    local destination,approx=nil,false
                    if value and value:IsA('Vector3Value') then destination=value.Value
                    elseif state.aimEstimate then destination=origin.Position+origin.CFrame.LookVector*state.aimLength;approx=true end
                    if destination and typeof(destination)=='Vector3' then
                        local delta=destination-origin.Position
                        local length=delta.Magnitude
                        if length==length and length>0.01 and length<1e7 then
                            local item=ensureAim(entry)
                            seen[entry.model]=true
                            item.start.Position=origin.Position
                            item.finish.Position=origin.Position+delta.Unit*math.min(length,state.aimLength)
                            item.beam.Enabled=true;item.finish.Transparency=0;item.label.Enabled=true
                            item.caption.Text='@'..entry.player.Name..(approx and ' · direção estimada' or ' · mira replicada')
                            if approx then estimated=estimated+1 else exact=exact+1 end
                        end
                    end
                end
            end
        end
    end
    for model,item in pairs(aimItems) do
        if not model.Parent then destroyAim(model)
        elseif not seen[model] then item.beam.Enabled=false;item.finish.Transparency=1;item.label.Enabled=false end
    end
    aimReport(exact,estimated)
end

local espElapsed,aimElapsed,statusElapsed=0,0,0
local function render(dt)
    aimClock=aimClock+dt
    ringStroke.Transparency=state.fovTransparency
    local camera=Workspace.CurrentCamera
    if not camera then return end
    local mouse=UIS:GetMouseLocation()
    ring.Position=UDim2.fromOffset(mouse.X,mouse.Y)
    ring.Size=UDim2.fromOffset(state.fov*2,state.fov*2)
    ring.Visible=not state.hideVisuals and state.camEnabled and state.showFov and not uiOpen and not uiBusy
    espElapsed=espElapsed+dt; statusElapsed=statusElapsed+dt
    if espElapsed>=0.15 then espElapsed=0;updateESP() end
    aimElapsed=aimElapsed+dt
    if aimElapsed>=1/30 then aimElapsed=0;updateAimViewer() end
    if cameraActive() then
        -- FOV somente na captura por tecla. Nunca adquirir outro alvo por frame.
        local entry=cameraTarget
        if entry then
            local root,hum=targetInfo(entry)
            local part=hum and aimPart(entry,hum)
            local point,onScreen
            if part then point,onScreen=camera:WorldToViewportPoint(part.Position) end
            if not root or not part or not filterCamera(entry) then entry=nil end
        end
        if not entry then resetCamera() else cameraTarget=entry end
        if cameraTarget then
            local _,hum=targetInfo(cameraTarget)
            local part,air=aimPart(cameraTarget,hum)
            local point,onScreen=camera:WorldToViewportPoint(part.Position)
            local destination=predictedPosition(part,hum,air)
            if onScreen and point.Z>0 and visibleToCamera(cameraTarget,part,camera) and (destination-camera.CFrame.Position).Magnitude>0.01 then
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
local palette={bg=Color3.fromRGB(8,8,8),panel=Color3.fromRGB(18,18,18),edge=Color3.fromRGB(78,78,78),muted=Color3.fromRGB(198,198,193),white=Color3.fromRGB(235,235,235)}
local rootUI=create('Frame',{Name='Hub',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(620,650),BackgroundTransparency=1,Visible=false},gui)
local uiScale=create('UIScale',{Name='UserScale',Scale=1},rootUI)
local panel=create('CanvasGroup',{Name='UnifiedPanel',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,-22),Size=UDim2.new(1,0,1,44),BackgroundTransparency=1,GroupTransparency=1},rootUI)
local surface=create('Frame',{Name='PanelSurface',Position=UDim2.fromOffset(0,44),Size=UDim2.new(1,0,1,-44),BackgroundTransparency=1},panel)
local motionScale=create('UIScale',{Name='MotionScale',Scale=0.94},panel)
local fitReadout=function() end
local function fitUI()
    local camera=Workspace.CurrentCamera
    if camera then
        local width=math.floor(math.clamp(580*state.uiSize,420,820)+0.5)
        local height=math.floor(math.clamp(610*state.uiSize,450,820)+0.5)
        local scale=math.min(1,(camera.ViewportSize.X-28)/width,(camera.ViewportSize.Y-100)/height)
        uiScale.Scale=math.max(0.1,scale)
        rootUI.Size=UDim2.fromOffset(width,height)
        fitReadout(state.uiSize)
    end
end
-- Clip the lower half of a rounded rectangle, then continue with a straight body.
-- No overlapping translucent fills: only the two upper corners are rounded.
local topClip=create('Frame',{Name='TopCurveClip',Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,ClipsDescendants=true},surface)
local topFill=create('Frame',{Name='TopCurve',Size=UDim2.new(1,0,0,80),BackgroundColor3=palette.bg,BackgroundTransparency=state.uiOpacity,BorderSizePixel=0},topClip)
round(topFill,38);create('UIStroke',{Color=palette.edge,Thickness=1},topFill)
local lowerFill=create('Frame',{Name='StraightBody',Position=UDim2.fromOffset(0,40),Size=UDim2.new(1,0,1,-40),BackgroundColor3=palette.bg,BackgroundTransparency=state.uiOpacity,BorderSizePixel=0},surface)
for _,x in ipairs({0,1}) do create('Frame',{Position=UDim2.new(x,-x,0,40),Size=UDim2.new(0,1,1,-40),BackgroundColor3=palette.edge,BorderSizePixel=0},surface) end
create('Frame',{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=palette.edge,BorderSizePixel=0},surface)
local function region(name,x,y,w,h)
    return create('Frame',{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,BorderSizePixel=0},surface)
end
local header=region('Header',0,0,620,92)
local sidebar=region('Navigation',10,94,600,46)
local body=region('Content',10,142,600,462)
local footer=region('Footer',10,610,600,34)
header.Size=UDim2.new(1,0,0,76)
sidebar.Position=UDim2.fromOffset(10,68);sidebar.Size=UDim2.new(1,-20,0,46)
body.Position=UDim2.fromOffset(10,116);body.Size=UDim2.new(1,-20,1,-158)
footer.Position=UDim2.new(0,10,1,-38);footer.Size=UDim2.new(1,-20,0,34)
local title=text(header,'EVINI',UDim2.fromOffset(100,-42),UDim2.new(1,-200,0,84),60)
title.Name='HubTitle';title.Font=Enum.Font.GothamBlack;title.TextXAlignment=Enum.TextXAlignment.Center;title.TextStrokeTransparency=0;title.TextStrokeColor3=Color3.new(0,0,0)
create('UIStroke',{Color=Color3.new(0,0,0),Thickness=3},title)
local titleGlyphs=create('Frame',{Name='BevanTitle',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0,0),Size=UDim2.new(0.42,0,0,78),BackgroundTransparency=1},header)
create('UISizeConstraint',{MaxSize=Vector2.new(260,79)},titleGlyphs)
create('UIAspectRatioConstraint',{AspectRatio=3.309090909090909,DominantAxis=Enum.DominantAxis.Width},titleGlyphs)
local glyphData='0,19,10,69,1;0,90,10,45,1;0,139,10,114,1;0,267,10,78,1;0,17,11,239,1;0,265,11,82,1;0,16,12,241,1;0,263,12,86,1;0,15,13,243,1;0,262,13,88,2;0,14,14,245,2;0,13,16,247,1;0,261,15,90,2;0,13,17,338,1;0,171,18,3,1;0,213,18,6,1;0,251,18,18,1;0,298,18,6,1;0,252,19,17,1;0,299,19,4,1;0,253,20,16,2;0,254,22,15,1;0,255,23,14,2;0,256,25,13,2;0,257,27,12,1;0,258,28,11,2;0,259,30,10,2;0,260,32,9,1;0,299,20,5,13;0,299,33,4,1;0,13,18,8,17;0,86,18,6,17;0,133,18,8,17;0,172,19,2,16;0,214,19,4,16;0,261,33,8,2;0,299,34,5,1;0,343,18,8,17;0,13,35,16,1;0,335,35,16,1;0,13,36,15,1;0,126,35,22,2;0,165,35,17,2;0,262,35,14,2;0,86,35,13,3;0,263,37,13,1;0,336,36,15,2;0,14,37,14,2;0,52,35,17,5;0,127,37,20,3;0,164,37,18,3;0,264,38,12,2;0,336,38,14,2;0,15,39,13,2;0,127,40,19,1;0,336,40,13,1;0,17,41,11,1;0,86,38,14,4;0,265,40,11,2;0,336,41,12,1;0,19,42,9,1;0,163,40,19,3;0,206,35,20,8;0,266,42,10,1;0,291,35,20,8;0,336,42,10,1;0,128,41,18,3;0,162,43,9,1;0,86,42,15,3;0,267,43,9,2;0,52,40,18,6;0,162,44,8,2;0,64,46,6,1;0,129,44,16,3;0,161,46,9,1;0,268,45,8,2;0,65,47,6,1;0,86,45,16,3;0,130,47,15,1;0,269,47,7,1;0,161,47,8,2;0,65,48,38,2;0,270,48,6,2;0,65,50,29,1;0,95,50,8,1;0,130,48,14,3;0,160,49,9,2;0,95,51,9,1;0,131,51,13,1;0,160,51,8,1;0,271,50,5,2;0,65,51,28,2;0,272,52,4,1;0,96,52,8,2;0,159,52,9,2;0,241,52,1,2;0,65,53,27,2;0,131,52,12,3;0,241,54,2,1;0,273,53,3,2;0,96,54,9,2;0,159,54,8,2;0,65,55,28,2;0,97,56,8,1;0,158,56,9,1;0,241,55,3,2;0,274,55,2,2;0,132,55,10,3;0,275,57,1,1;0,97,57,9,2;0,158,57,8,2;0,241,57,4,2;0,65,57,29,3;0,157,59,9,1;0,241,59,5,1;0,65,60,6,1;0,98,59,8,2;0,133,58,8,3;0,65,61,5,1;0,98,61,9,1;0,133,61,7,1;0,157,60,8,2;0,241,60,6,2;0,156,62,9,1;0,99,62,8,2;0,241,62,7,2;0,99,64,9,1;0,134,62,6,3;0,156,63,8,2;0,241,64,8,1;0,155,65,9,1;0,20,43,8,24;0,100,65,8,2;0,174,43,8,24;0,206,43,8,24;0,218,43,8,24;0,241,65,9,2;0,303,43,8,24;0,336,43,8,24;0,19,67,9,1;0,100,67,9,1;0,135,65,4,3;0,155,66,8,2;0,171,67,11,1;0,291,43,9,25;0,301,67,10,1;0,336,67,10,1;0,17,68,11,1;0,52,62,18,7;0,136,68,3,1;0,169,68,13,1;0,241,67,10,2;0,336,68,12,1;0,16,69,12,1;0,101,68,8,2;0,154,68,9,2;0,168,69,14,1;0,241,69,11,1;0,336,69,13,1;0,15,70,13,1;0,101,70,9,1;0,136,69,2,3;0,154,70,8,2;0,167,70,15,2;0,241,70,12,2;0,336,70,14,2;0,14,71,14,2;0,102,71,8,2;0,137,72,1,1;0,153,72,9,1;0,241,72,13,1;0,13,73,15,1;0,336,72,15,2;0,13,74,16,1;0,52,69,17,6;0,102,73,9,2;0,153,73,8,2;0,166,72,16,3;0,206,67,20,8;0,241,73,14,2;0,291,68,20,7;0,335,74,16,1;0,152,75,9,1;0,291,75,13,1;0,103,75,8,2;0,248,75,8,2;0,291,76,12,1;0,103,77,9,1;0,152,76,8,2;0,151,78,9,1;0,248,77,9,2;0,104,78,8,2;0,248,79,10,1;0,104,80,9,1;0,151,79,8,2;0,150,81,9,1;0,248,80,11,2;0,105,81,8,2;0,248,82,12,1;0,105,83,9,1;0,150,82,8,2;0,248,83,13,2;0,106,84,8,2;0,149,84,9,2;0,106,86,9,1;0,149,86,8,1;0,248,85,14,2;0,248,87,15,1;0,107,87,8,2;0,148,87,9,2;0,107,89,9,1;0,248,88,16,2;0,291,77,13,13;0,148,89,8,2;0,214,75,4,16;0,248,90,17,1;0,291,90,12,1;0,13,75,8,17;0,86,60,8,32;0,108,90,8,2;0,147,91,9,1;0,166,75,8,17;0,213,91,6,1;0,248,91,18,1;0,291,91,13,1;0,343,75,8,17;0,166,92,185,1;0,13,92,81,2;0,108,92,47,2;0,166,93,90,1;0,257,93,94,1;0,14,94,80,1;0,109,94,46,1;0,167,94,89,1;0,258,94,93,1;0,14,95,79,1;0,109,95,45,1;0,167,95,88,1;0,258,95,92,1;0,15,96,78,1;0,110,96,43,1;0,168,96,87,1;0,259,96,91,1;0,16,97,76,1;0,111,97,41,1;0,169,97,85,1;0,260,97,37,1;0,298,97,51,1;0,17,98,73,1;0,112,98,39,1;0,170,98,83,1;0,261,98,34,1;0,299,98,48,1;0,19,99,69,1;0,114,99,35,1;0,172,99,78,1;0,264,99,29,1;0,302,99,43,1;1,219,19,32,1;1,219,20,33,1;1,219,21,34,2;1,219,23,35,1;1,219,24,36,2;1,219,26,37,2;1,219,28,38,2;1,219,30,39,1;1,219,31,40,2;1,22,19,64,15;1,92,19,41,15;1,141,19,30,15;1,175,19,38,15;1,219,33,41,1;1,269,19,29,15;1,304,19,39,15;1,28,34,25,1;1,69,34,17,1;1,98,34,28,1;1,148,34,17,1;1,182,34,24,1;1,226,34,34,1;1,276,34,16,1;1,311,34,25,1;1,99,35,26,1;1,149,35,15,1;1,226,35,35,1;1,99,36,27,1;1,148,36,16,2;1,226,36,36,2;1,100,37,26,2;1,100,39,27,1;1,148,38,15,2;1,226,38,37,2;1,147,40,16,1;1,226,40,38,1;1,70,35,16,7;1,101,40,26,3;1,147,41,15,2;1,226,41,39,2;1,146,43,16,1;1,226,43,40,2;1,102,43,26,3;1,226,45,41,1;1,29,35,23,12;1,71,42,15,5;1,103,46,25,1;1,146,44,15,3;1,226,46,42,2;1,103,47,26,2;1,104,49,25,1;1,145,47,15,3;1,226,48,43,2;1,144,50,16,1;1,226,50,44,1;1,104,50,26,2;1,226,51,14,1;1,242,51,29,1;1,243,52,28,1;1,105,52,25,2;1,144,51,15,3;1,243,53,29,1;1,105,54,26,1;1,244,54,28,1;1,244,55,29,1;1,106,55,25,2;1,143,54,15,3;1,245,56,29,1;1,106,57,26,1;1,246,57,28,1;1,246,58,29,1;1,107,58,25,2;1,142,57,15,3;1,247,59,28,1;1,277,35,14,25;1,71,60,14,1;1,142,60,14,1;1,247,60,44,1;1,29,47,35,15;1,107,60,26,2;1,248,61,43,1;1,141,61,15,2;1,108,62,25,2;1,249,62,42,2;1,108,64,26,1;1,141,63,14,2;1,71,61,15,5;1,250,64,41,2;1,140,65,15,2;1,251,66,40,1;1,109,65,25,3;1,140,67,14,1;1,252,67,39,2;1,139,68,15,2;1,110,68,25,3;1,139,70,14,1;1,253,69,38,2;1,138,71,15,1;1,254,71,37,1;1,111,71,25,3;1,138,72,14,2;1,226,52,15,22;1,255,72,36,2;1,29,62,23,13;1,70,66,16,9;1,112,74,24,1;1,137,74,15,1;1,182,35,23,40;1,226,74,14,1;1,312,35,23,40;1,28,75,25,1;1,69,75,17,1;1,112,75,40,1;1,182,75,24,1;1,226,75,15,1;1,256,74,35,2;1,311,75,25,1;1,112,76,39,1;1,257,76,34,1;1,113,77,38,2;1,258,77,33,2;1,113,79,37,2;1,259,79,32,2;1,114,81,36,1;1,260,81,31,1;1,114,82,35,2;1,261,82,30,2;1,115,84,34,1;1,262,84,29,1;1,115,85,33,2;1,263,85,28,2;1,116,87,32,1;1,264,87,27,2;1,116,88,31,2;1,22,76,64,15;1,117,90,30,1;1,175,76,38,15;1,219,76,29,15;1,265,89,26,2;1,304,76,39,15'
for color,x,y,w,h in glyphData:gmatch('(%d+),(%d+),(%d+),(%d+),(%d+)') do
    create('Frame',{Position=UDim2.fromScale(tonumber(x)/364,tonumber(y)/110),Size=UDim2.fromScale(tonumber(w)/364,tonumber(h)/110),BackgroundColor3=color=='1' and Color3.new(1,1,1) or Color3.new(0,0,0),BorderSizePixel=0},titleGlyphs)
end
title.Visible=false
local hide=button(header,'−',UDim2.new(1,-90,0,28),UDim2.fromOffset(30,30));hide.Name='Hide';hide.TextSize=22
local close=button(header,'×',UDim2.new(1,-52,0,28),UDim2.fromOffset(30,30));close.Name='Close';close.TextSize=22;close.BackgroundColor3=Color3.fromRGB(99,33,29)
local smaller=button(header,'−',UDim2.fromOffset(22,30),UDim2.fromOffset(24,26));smaller.Name='SmallerUI'
local scaleReadout=button(header,'100%',UDim2.fromOffset(50,30),UDim2.fromOffset(50,26));scaleReadout.Name='ResetUISize';scaleReadout.TextSize=11
local larger=button(header,'+',UDim2.fromOffset(104,30),UDim2.fromOffset(24,26));larger.Name='LargerUI'
-- Simple geometric icons stay crisp instead of scaling Unicode glyphs.
local function lineIcon(b,kind)
    b.Text=''
    local rotations=kind=='close' and {45,-45} or (kind=='plus' and {0,90} or {0})
    for _,rotation in ipairs(rotations) do
        create('Frame',{Name='IconLine',AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(kind=='close' and 13 or 10,2),Rotation=rotation,BackgroundColor3=Color3.fromRGB(230,230,226),BorderSizePixel=0},b)
    end
end
lineIcon(hide,'minus');lineIcon(close,'close');lineIcon(smaller,'minus');lineIcon(larger,'plus')
fitReadout=function(scale) scaleReadout.Text=tostring(math.floor(scale*100+0.5))..'%' end
local refreshSizeControls=function() end
local function setUISize(value)
    state.uiSize=math.clamp(value,0.45,1.5);fitUI();refreshSizeControls();queueSave()
end
connect(smaller.Activated,function() setUISize(state.uiSize-0.05) end)
connect(larger.Activated,function() setUISize(state.uiSize+0.05) end)
connect(scaleReadout.Activated,function() setUISize(1) end)
local animationVersion=0
local activeTweens={}
local destroyed=false
local function showUI(open,after)
    if not alive then return end
    animationVersion=animationVersion+1
    for _,t in ipairs(activeTweens) do t:Cancel() end
    activeTweens={};uiBusy=false;uiOpen=open;resetCamera();fitUI()
    panel.GroupTransparency=0;panel.Position=UDim2.new(0.5,0,0.5,-22);motionScale.Scale=1
    rootUI.Visible=open
    if after then after() end
end
local pages,tabs={},{}
local currentPage='Mira'
local function refreshTabs()
    for name,b in pairs(tabs) do
        local active=name==currentPage
        b.TextColor3=active and Color3.fromRGB(250,250,246) or palette.muted
        b.BackgroundColor3=active and Color3.fromRGB(88,88,84) or Color3.fromRGB(40,40,38)
        local highlight=b:FindFirstChild('SelectedTabHighlight')
        if highlight then highlight.Visible=active end
    end
end
local function page(name,index)
    local frame=create('ScrollingFrame',{Name=name,Position=UDim2.fromOffset(8,12),Size=UDim2.new(1,-16,1,-24),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=green,CanvasSize=UDim2.fromOffset(0,0),Visible=index==1},body)
    frame.ScrollingDirection=Enum.ScrollingDirection.Y
    frame.VerticalScrollBarInset=Enum.ScrollBarInset.Always
    local content=create('Frame',{Name=name..'Content',Position=UDim2.fromOffset(3,2),Size=UDim2.new(1,-9,0,0),BackgroundTransparency=1,BorderSizePixel=0},frame)
    pages[name]={frame=content,scroll=frame,y=0};accent(frame,'ScrollBarImageColor3')
    local b=button(sidebar,name,UDim2.new((index-1)/5,3,0,5),UDim2.new(0.2,-6,0,34)); b.Name='Tab_'..name; b.Font=Enum.Font.GothamMedium;b.TextSize=14
    tabs[name]=b
    create('Frame',{Name='SelectedTabHighlight',Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-4,0,2),BackgroundColor3=Color3.fromRGB(170,170,164),BorderSizePixel=0,Visible=false},b)
    connect(b.Activated,function()
        currentPage=name;refreshTabs()
        for key,p in pairs(pages) do
            if p.tabTween then p.tabTween:Cancel() end
            p.scroll.Visible=key==name
            if key==name then p.scroll.Position=UDim2.fromOffset(8,12)
            end
        end
    end)
    refreshTabs()
    return pages[name]
end
local camPage=page('Mira',1)
local hitPage=page('Hitbox',2)
local espPage=page('Visual',3)
local playersPage=page('Jogadores',4)
local settingsPage=page('Ajustes',5)
local function subPage() return {frame=create('Frame',{BackgroundTransparency=1,Visible=false,Size=UDim2.new(1,0,0,0)},camPage.frame),y=0} end
local predPage=subPage()
local function slot(p,h)
    local y=p.y;p.y=y+h
    p.frame.Size=UDim2.new(1,p.scroll and -9 or 0,0,p.y+8)
    if p.scroll then p.scroll.CanvasSize=UDim2.fromOffset(0,p.y+12) end
    return y
end
local function label(p,value,description)
    local y=slot(p,description and 57 or 32)
    local t=text(p.frame,value,UDim2.fromOffset(0,y),UDim2.new(1,0,0,20),15); t.Font=Enum.Font.Gotham; accent(t,'TextColor3')
    if description then local d=text(p.frame,description,UDim2.fromOffset(0,y+23),UDim2.new(1,-4,0,30),11); d.Font=Enum.Font.Gotham; d.TextColor3=palette.muted end
end
local function rowText(p,value,y)
    local backdrop=create('Frame',{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,38),BackgroundColor3=palette.panel,BackgroundTransparency=0.45,BorderSizePixel=1,BorderColor3=Color3.fromRGB(5,5,5)},p.frame)
    local t=text(p.frame,value,UDim2.fromOffset(10,y+7),UDim2.new(1,-132,0,24),13); t.Font=Enum.Font.Gotham; return t
end
local controlRefresh={}
local function switch(p,value,key,onChange)
    local y=slot(p,42); rowText(p,value,y)
    local b=button(p.frame,'',UDim2.new(1,-56,0,y+8),UDim2.fromOffset(46,22)); b.Name=key
    local dot=create('Frame',{Size=UDim2.fromOffset(14,14),BorderSizePixel=0},b); round(dot,2)
    local function refresh()
        b.BackgroundColor3=state[key] and Color3.fromRGB(27,79,43) or palette.edge
        dot.BackgroundColor3=palette.white
        dot.Position=UDim2.fromOffset(state[key] and 28 or 4,4)
    end
    connect(b.Activated,function() state[key]=not state[key]; refresh(); if onChange then onChange() end;queueSave() end)
    refresh();controlRefresh[key]=refresh; return b
end
local function field(p,value,key,min,max,step,onChange)
    local y=slot(p,46); rowText(p,value,y)
    local box=create('TextBox',{Name=key=='size' and 'SizeInput' or key,Position=UDim2.new(1,-116,0,y+3),Size=UDim2.fromOffset(106,32),BackgroundColor3=palette.panel,BorderSizePixel=0,Text=tostring(state[key]),TextColor3=palette.white,ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=13},p.frame)
    round(box,3); create('UIStroke',{Color=palette.edge,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},box)
    local function set(v)
        if v and v==v then state[key]=math.floor(math.clamp(v,min,max)/step+0.5)*step end
        box.Text=string.format(step<1 and '%.3f' or '%.0f',state[key])
        if key=='uiSize' then fitUI() end
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
    local hit=create('TextButton',{Name=key..'_Slider',Text='',BackgroundTransparency=1,Position=UDim2.fromOffset(12,y),Size=UDim2.new(1,-24,0,22)},p.frame)
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
    local y=slot(p,46); local caption=rowText(p,value,y); caption.Size=UDim2.new(1,-184,0,24)
    local b=button(p.frame,'',UDim2.new(1,-164,0,y+3),UDim2.fromOffset(154,32)); b.Name=key; b.Font=Enum.Font.Gotham; b.TextSize=11
    local function refresh()
        for _,o in ipairs(options) do if o[1]==state[key] then b.Text=o[2]..'  >' end end
    end
    connect(b.Activated,function()
        for i,o in ipairs(options) do if o[1]==state[key] then state[key]=options[i%#options+1][1]; break end end
        refresh(); if onChange then onChange() end;queueSave()
    end)
    refresh(); return b
end
label(hitPage,'HITBOX','Escolha quem pode ser alvo na aba Jogadores. A mesma seleção vale para hitbox e cam lock.')
switch(hitPage,'Ativar expansão','enabled',apply)
switch(hitPage,'Box invisível','transparent',apply)
switch(hitPage,'Knock Check','knockCheck',function() apply(); cameraTarget=nil end)
field(hitPage,'Tamanho · 2–30 studs','size',2,30,0.1,apply)
label(playersPage,'JOGADORES','✓ permite hitbox e cam lock. Desmarque para proteger a pessoa. A seleção fica salva pelo usuário.')
switch(playersPage,'Selecionar novos jogadores','newPlayersSelected')
local actionsY=slot(playersPage,44)
local selectAll=button(playersPage.frame,'Marcar todos',UDim2.fromOffset(0,actionsY),UDim2.new(0.5,-5,0,32));selectAll.Name='SelectAll'
local deselectAll=button(playersPage.frame,'Desmarcar todos',UDim2.new(0.5,5,0,actionsY),UDim2.new(0.5,-5,0,32));deselectAll.Name='DeselectAll'
local searchY=slot(playersPage,44)
local rosterSearch=create('TextBox',{Name='PlayerSearch',Position=UDim2.fromOffset(0,searchY),Size=UDim2.new(1,0,0,32),BackgroundColor3=palette.panel,TextColor3=palette.white,BorderSizePixel=1,PlaceholderText='Pesquisar @nick ou nome',Text='',ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=14},playersPage.frame)
local rosterTop=playersPage.y
local roster={}
local rosterFilter=''
local function layoutRoster()
    local list={}
    for _,item in pairs(roster) do table.insert(list,item) end
    table.sort(list,function(a,b) return a.player.Name:lower()<b.player.Name:lower() end)
    local y=rosterTop
    for _,item in ipairs(list) do
        local p=item.player
        local visible=rosterFilter=='' or p.Name:lower():find(rosterFilter,1,true) or p.DisplayName:lower():find(rosterFilter,1,true)
        item.row.Visible=not not visible
        item.check.Text=selectedPlayer(p) and '✓' or ''
        item.check.BackgroundColor3=selectedPlayer(p) and Color3.fromRGB(27,79,43) or palette.panel
        if visible then item.row.Position=UDim2.fromOffset(0,y);y=y+62 end
    end
    playersPage.frame.Size=UDim2.new(1,-9,0,y+8)
    playersPage.scroll.CanvasSize=UDim2.fromOffset(0,y+12)
end
local function selectionChanged()
    if cameraTarget and cameraTarget.player and not selectedPlayer(cameraTarget.player) then resetCamera() end
    apply();layoutRoster();queueSave()
end
local function addRoster(p)
    departing[p]=nil
    if p==player or roster[p.UserId] then return end
    local id=tostring(p.UserId)
    if state.playerSelection[id]==nil then state.playerSelection[id]=state.newPlayersSelected end
    local row=create('Frame',{Name='Player_'..id,Size=UDim2.new(1,-2,0,54),BackgroundColor3=palette.panel,BackgroundTransparency=0.25,BorderSizePixel=1,BorderColor3=palette.edge},playersPage.frame)
    create('ImageLabel',{Size=UDim2.fromOffset(40,40),Position=UDim2.fromOffset(7,7),BackgroundTransparency=1,Image='rbxthumb://type=AvatarHeadShot&id='..id..'&w=150&h=150'},row)
    local name=text(row,p.DisplayName,UDim2.fromOffset(58,6),UDim2.new(1,-118,0,21),15);name.Font=Enum.Font.GothamBold
    text(row,'@'..p.Name,UDim2.fromOffset(58,29),UDim2.new(1,-118,0,18),12).TextColor3=palette.muted
    local check=button(row,'',UDim2.new(1,-43,0,11),UDim2.fromOffset(32,32));check.Name='Select_'..id;check.TextSize=22
    local item={player=p,row=row,check=check};roster[p.UserId]=item
    item.connection=check.Activated:Connect(function() state.playerSelection[id]=not selectedPlayer(p);selectionChanged() end)
    layoutRoster()
end
local function removeRoster(p)
    departing[p]=true
    local item=roster[p.UserId]
    if item then item.connection:Disconnect();item.row:Destroy();roster[p.UserId]=nil end
    if cameraTarget and cameraTarget.player==p then resetCamera() end
    if p.Character then
        local root=p.Character:FindFirstChild('HumanoidRootPart');if root then restore(root) end
        destroyESP(p.Character);destroyAim(p.Character)
    end
    layoutRoster()
end
local function setRoster(value)
    for _,item in pairs(roster) do state.playerSelection[tostring(item.player.UserId)]=value end
    selectionChanged()
end
connect(selectAll.Activated,function() setRoster(true) end)
connect(deselectAll.Activated,function() setRoster(false) end)
connect(rosterSearch:GetPropertyChangedSignal('Text'),function() rosterFilter=rosterSearch.Text:lower():gsub('^@','');layoutRoster() end)
for _,p in ipairs(Players:GetPlayers()) do addRoster(p) end
local notices={}
local noticeClock=0
local function arrangeNotices()
    for i,item in ipairs(notices) do item.frame.Position=UDim2.fromOffset(18,70+(i-1)*46) end
end
local function serverNotice(p,joined)
    if p==player or not state.serverNotices or not alive then return end
    if #notices>=4 then local old=table.remove(notices,1);old.frame:Destroy() end
    local frame=create('Frame',{Name='ServerNotice',Size=UDim2.fromOffset(310,40),BackgroundColor3=palette.bg,BackgroundTransparency=0.12,BorderSizePixel=1,BorderColor3=palette.edge},overlays)
    local caption=text(frame,(joined and '+ ' or '− ')..'@'..p.Name..(joined and ' entrou no servidor' or ' saiu do servidor'),UDim2.fromOffset(10,4),UDim2.new(1,-20,1,-8),13)
    caption.TextColor3=joined and Color3.fromRGB(160,222,174) or Color3.fromRGB(235,165,157)
    table.insert(notices,{frame=frame,expires=noticeClock+4});arrangeNotices()
end
connect(Players.PlayerAdded,function(p) addRoster(p);serverNotice(p,true);collectCandidates();queueSave() end)
connect(Players.PlayerRemoving,function(p) removeRoster(p);serverNotice(p,false) end)
connect(RunService.Heartbeat,function(dt)
    noticeClock=noticeClock+dt
    local changed=false
    for i=#notices,1,-1 do
        if notices[i].expires<=noticeClock or not state.serverNotices then notices[i].frame:Destroy();table.remove(notices,i);changed=true end
    end
    if changed then arrangeNotices() end
end)
label(espPage,'Nomes no jogo','Identifique jogadores e NPCs sem cobrir a cena.')
switch(espPage,'Jogadores','espPlayers')
switch(espPage,'NPCs / entidades','espEntities')

label(espPage,'Aim Viewer','Raio e ponto vermelhos em 3D. Usa mira replicada mesmo sem arma, quando disponível.')
switch(espPage,'Ativar Aim Viewer','aimViewer')
switch(espPage,'Estimar direção sem dados de mira','aimEstimate')
field(espPage,'Comprimento da linha','aimLength',10,500,1)
local aimStatus=text(espPage.frame,'Aim Viewer desligado',UDim2.fromOffset(0,slot(espPage,38)),UDim2.new(1,0,0,34),11);aimStatus.Name='AimViewerStatus'
aimReport=function(exact,estimated)
    aimStatus.Text=state.aimViewer and ('Replicadas: '..exact..' · estimadas: '..estimated..(exact+estimated==0 and ' · sem dados disponíveis' or '')) or 'Aim Viewer desligado'
end
label(espPage,'Visibilidade','Ocultar estes desenhos não desliga o recurso de mira.')
switch(espPage,'Ocultar todos os desenhos','hideVisuals')
switch(espPage,'Marcador do cam lock','camMarker')
switch(espPage,'Linha do cam lock','camTracer')
label(espPage,'Só nomes','Etiquetas nativas acompanham os personagens. Sem caixas ou distância; mortos e K.O. ficam ocultos.')
label(camPage,'CAM LOCK + PREDICT','Clique na tecla para capturar no FOV. Clique de novo para soltar. Esc também solta.')
local camKeyY=slot(camPage,46)
switch(camPage,'Ativar cam lock','camEnabled',resetCamera)
local preset=button(camPage.frame,'Começar com ping de 80–120 ms',UDim2.fromOffset(0,slot(camPage,40)),UDim2.new(1,0,0,30));preset.Name='PingPreset';preset.Font=Enum.Font.Gotham;preset.TextSize=11
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
slider(camPage,'Transparência do FOV · 0–1','fovTransparency',0,1,0.05)
slider(camPage,'Raio do FOV · pixels','fov',30,500,1)
choice(camPage,'Parte do corpo','hitPart',{{'Head','Cabeça'},{'UpperTorso','Tronco'},{'LowerTorso','Tronco baixo'},{'HumanoidRootPart','Centro'}},function() cameraTarget=nil end)
switch(camPage,'Pausar mira atrás de paredes','wallCheck')
label(camPage,'Alvo mantido','Atrás de paredes ou fora da tela, a câmera pausa. Ao reaparecer, retoma o mesmo alvo. A tecla e Esc soltam.')
switch(camPage,'Alternar cabeça e tronco','cycleParts')
slider(camPage,'Intervalo da alternância · s','cycleInterval',0.3,3,0.1)
switch(camPage,'Ignorar meu time','camTeam',function() cameraTarget=nil end)
switch(camPage,'Incluir NPCs no lock','camNPC',function() cameraTarget=nil end)
slider(camPage,'Suavização · 0 = instantâneo','smoothing',0,1,0.01)
switch(predPage,'Usar Air Part','airEnabled')
choice(predPage,'Parte no ar','airPart',{{'HumanoidRootPart','Centro'},{'Head','Cabeça'},{'UpperTorso','Tronco'},{'LowerTorso','Tronco baixo'}})
slider(predPage,'Previsão no ar · segundos','airPrediction',0,0.5,0.001)
label(predPage,'NO AR','Air Part usa o estado de salto/queda e antecipa velocidade + gravidade. No automático, o ping define o tempo nos dois casos.')
local targetReadout=text(camPage.frame,'Sem alvo',UDim2.fromOffset(0,slot(camPage,32)),UDim2.new(1,0,0,28),11); targetReadout.Font=Enum.Font.Gotham; accent(targetReadout,'TextColor3')
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
    local b=button(p.frame,'',UDim2.new(1,-116,0,y+3),UDim2.fromOffset(106,32)); b.Name=which=='hide' and 'Keybind' or 'CamKeybind'; keyButtons[which]=b
    connect(b.Activated,function()
        if capturing==which then stopCapture(); return end
        stopCapture(); capturing=which; resetCamera(); b.Text='Tecla?'; local version=captureVersion
        task.delay(8,function() if alive and version==captureVersion then stopCapture() end end)
    end)
end
keyField('Ocultar / abrir hub','hide'); keyField('Tecla do cam lock','cam'); refreshKeys()
local saveText=text(settingsPage.frame,persistenceStatus,UDim2.fromOffset(0,slot(settingsPage,38)),UDim2.new(1,0,0,32),11); saveText.Font=Enum.Font.Gotham;saveText.TextColor3=palette.muted
persistenceReport=function(message) if alive then saveText.Text=message end end
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
    camPage.frame.Size=UDim2.new(1,-9,0,y+10)
    camPage.scroll.CanvasSize=UDim2.fromOffset(0,y+14)
end
for _,definition in ipairs({{'Calibração avançada',predPage}}) do
    local f={name=definition[1],page=definition[2],open=false}
    f.button=button(camPage.frame,'',UDim2.fromOffset(0,0),UDim2.new(1,0,0,32));f.button.Name=definition[1]
    table.insert(folds,f)
    connect(f.button.Activated,function() f.open=not f.open;arrangeFolds() end)
end
arrangeFolds()
local function refreshAppearance()
    green=accents[state.accent]
    for _,binding in ipairs(accentBindings) do if binding[1].Parent then binding[1][binding[2]]=green end end
    topFill.BackgroundTransparency=state.uiOpacity;lowerFill.BackgroundTransparency=state.uiOpacity
    for _,refresh in pairs(controlRefresh) do refresh() end
    refreshTabs()
    fitUI()
end
label(settingsPage,'Aparência')
choice(settingsPage,'Contraste','accent',{{'Branco','Branco'},{'Cinza','Cinza claro'}},refreshAppearance)
field(settingsPage,'Transparência · 0–0,45','uiOpacity',0,0.45,0.01,refreshAppearance)
slider(settingsPage,'Tamanho da interface · 0,45–1,50','uiSize',0.45,1.5,0.05)
local refreshSize=controlRefresh.uiSize
controlRefresh.uiSize=function() refreshSize();fitUI() end
refreshSizeControls=controlRefresh.uiSize
switch(settingsPage,'Sons dos botões','uiSounds')
slider(settingsPage,'Volume dos botões','soundVolume',0,0.6,0.05)

switch(settingsPage,'Notificações de alvo','notifications')
switch(settingsPage,'Avisar entradas e saídas','serverNotices')
local foot=text(footer,'L · HUB     Q · CAM LOCK',UDim2.fromOffset(12,8),UDim2.new(0.45,-12,0,18),10); foot.Font=Enum.Font.Gotham; foot.TextColor3=palette.muted
local stats=text(footer,'PING —',UDim2.new(0.45,0,0,8),UDim2.new(0.55,-12,0,18),10); stats.Font=Enum.Font.Gotham; stats.TextXAlignment=Enum.TextXAlignment.Right; stats.TextColor3=palette.muted
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
    for _,item in pairs(roster) do item.connection:Disconnect() end
    aimFolder:Destroy()
    restoreAll(); overlays:Destroy(); gui:Destroy()
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
local lastViewport=nil
fitUI()
connect(RunService.Heartbeat,function(dt)
    local cam=Workspace.CurrentCamera
    if cam and cam.ViewportSize~=lastViewport then lastViewport=cam.ViewportSize;fitUI() end
    elapsed=elapsed+dt; collectElapsed=collectElapsed+dt; pingElapsed=pingElapsed+dt
    if elapsed>=0.1 then elapsed=0; apply() end
    if collectElapsed>=0.3 then collectElapsed=0; collectCandidates() end
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
    endIntro()
end)
return api
