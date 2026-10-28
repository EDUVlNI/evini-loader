-- EVINI 5.2: fonte independente. Nao carrega o Nitrogen.
-- Alteracoes de hitbox sao locais; o servidor pode ignora-las.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
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
state.extraDarkTheme=true;state.adjustableSmoke=true;state.uiDarkness=1;state.deepBlackTheme=true;state.smokeTheme=true;state.uiSounds=true;state.soundVolume=0.2;state.accent='Branco';state.uiOpacity=0.10;state.uiSize=1;state.reduceMotion=false;state.notifications=true
state.camMarker=false;state.camTracer=false;state.hideVisuals=false
state.viewerEnabled=false;state.viewerMode='character'
state.antiEnabled=false;state.antiKeyName='C';state.antiX=68756;state.antiY=100;state.antiZ=-344
state.hideKeyName='K'; state.camKeyName='Q'
state.studioUIVersion=true;state.triggerSounds=true
state.triggerEnabled=false;state.triggerKeyName='T';state.triggerMode='auto';state.triggerSize=32
state.triggerWalls=true;state.triggerShow=true;state.triggerTeam=false;state.triggerKnock=true
state.triggerBodyVersion=true;state.triggerDetect='body';state.triggerRepeat=false
state.triggerDelay=0;state.triggerInterval=0.15;state.triggerMethod='click'
local closing=false
local alive=true
-- Preferencias locais por experiencia. JSON validado, nunca executado.
local HttpService=game:GetService('HttpService')
local settingsFile='evini-settings-'..tostring((game.GameId and game.GameId>0) and game.GameId or game.PlaceId or 0)..'.json'
local defaults={}
for k,v in pairs(state) do defaults[k]=v end
local bounds={triggerSize={4,300},triggerDelay={0,0.5},triggerInterval={0.05,1},fovTransparency={0,1},cycleInterval={0.3,3},antiX={-100000,100000},antiY={-100000,100000},antiZ={-100000,100000},uiDarkness={0,1},uiOpacity={0,0.8},soundVolume={0,0.6},uiSize={0.45,1.5},size={2,30},fov={30,500},prediction={0,0.5},airPrediction={0,0.5},autoPredMath={100,1000},autoBase={0,0.2},smoothing={0,1}}
local options={viewerMode={character=true,aim=true},triggerDetect={body=true,square=true},triggerMode={auto=true,hold=true,toggle=true},triggerMethod={click=true,tool=true},accent={Branco=true,Cinza=true},hitPart={Head=true,UpperTorso=true,LowerTorso=true,HumanoidRootPart=true},airPart={Head=true,UpperTorso=true,LowerTorso=true,HumanoidRootPart=true}}
local persistenceStatus='Salvamento indisponível neste executor'
local persistenceReport=function() end
local canSave=type(writefile)=='function' and type(readfile)=='function'
local function loadSettings()
    if not canSave then return end
    persistenceStatus='Salvamento automático ativo'
    local ok,data=pcall(function() return HttpService:JSONDecode(readfile(settingsFile)) end)
    if not ok or type(data)~='table' or data.version~=1 or type(data.settings)~='table' then return end
    if data.settings.extraDarkTheme~=true then data.settings.uiOpacity=0.10;data.settings.uiDarkness=1 end
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
            elseif key=='hideKeyName' or key=='camKeyName' or key=='triggerKeyName' or key=='antiKeyName' then
                local valid,code=pcall(function() return Enum.KeyCode[value] end)
                if valid and code and code~=Enum.KeyCode.Unknown and code~=Enum.KeyCode.Escape then state[key]=value end
            end
        end
    end
    if data.settings.studioUIVersion~=true then state.hideKeyName='K' end
    if state.hideKeyName==state.camKeyName then state.hideKeyName='K';state.camKeyName='Q' end
    if state.triggerKeyName==state.hideKeyName or state.triggerKeyName==state.camKeyName then
        for _,key in ipairs({'T','Y','U','P'}) do if key~=state.hideKeyName and key~=state.camKeyName then state.triggerKeyName=key;break end end
    end
    if data.settings.triggerBodyVersion~=true then
        state.triggerEnabled=false;state.triggerMode='auto';state.triggerDetect='body';state.triggerRepeat=false
        state.triggerDelay=0;state.triggerShow=true;state.triggerMethod='click'
    end
    state.antiEnabled=false -- never restore an armed velocity modifier
    if state.antiKeyName==state.hideKeyName or state.antiKeyName==state.camKeyName or state.antiKeyName==state.triggerKeyName then
        for _,key in ipairs({'C','V','B','N'}) do if key~=state.hideKeyName and key~=state.camKeyName and key~=state.triggerKeyName then state.antiKeyName=key;break end end
    end
    persistenceStatus='Configurações restauradas'
end
loadSettings()
state.viewerEnabled=false -- observation is session-only; never auto-start on reload
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
local clickSound=create('Sound',{Name='UIClick',SoundId='rbxasset://sounds/volume_slider.ogg',Volume=state.soundVolume},gui)
local soundStatus='Som do painel do Studio'
local soundReport=function() end
local function playClick()
    if not alive or not state.uiSounds then return end
    clickSound.Volume=state.soundVolume
    pcall(function() clickSound.TimePosition=0;clickSound:Play() end)
end
local function button(parent,value,pos,size,radius)
    local b=create('TextButton',{Text=value,Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(35,36,42),BackgroundTransparency=0.18,TextColor3=Color3.fromRGB(221,223,230),BorderSizePixel=0,Font=Enum.Font.GothamMedium,TextSize=15,AutoButtonColor=false},parent)
    round(b,radius or 7)
    b.Activated:Connect(playClick)
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
local viewer={active=false,userId=nil,target=nil,clock=0,source=nil,sourceConnection=nil,snapshot=nil,onState=function() end,onSelection=function() end,status="Selecione um jogador"}

local trigger={}
do
    local armed,autoPaused,focused=false,true,true
    local clock,lastShot,stableSince=0,-math.huge,0
    local pendingTarget,entryFired,fault=nil,false,nil
    local heldTool,heldMouse,heldVersion=nil,false,0
    local function releaseInput()
        heldVersion=heldVersion+1
        local tool=heldTool;heldTool=nil
        if tool then pcall(function() tool:Deactivate() end) end
        if heldMouse then heldMouse=false;pcall(mouse1release) end
    end
    local audible=false
    local onSound=create('Sound',{Name='TriggerOn',SoundId='rbxasset://sounds/electronicpingshort.wav',PlaybackSpeed=1.6,Volume=state.soundVolume},gui)
    local offSound=create('Sound',{Name='TriggerOff',SoundId='rbxasset://sounds/electronicpingshort.wav',PlaybackSpeed=0.75,Volume=state.soundVolume},gui)
    local function audioState(value)
        if value==audible then return end
        audible=value
        if not alive or not state.triggerSounds then return end
        onSound:Stop();offSound:Stop()
        local sound=value and onSound or offSound;sound.Volume=state.soundVolume
        pcall(function() sound.TimePosition=0;sound:Play() end)
    end
    local square=create('Frame',{Name='TriggerSquare',AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,BorderSizePixel=0,Visible=false},overlays)
    local outline=create('UIStroke',{Color=Color3.fromRGB(220,220,220),Thickness=2,Transparency=0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},square)
    local function status(value) trigger.lastStatus=value end
    function trigger.reset(suspend)
        audioState(false);releaseInput();armed=false;pendingTarget=nil;entryFired=false;stableSince=clock;square.Visible=false
        if suspend then autoPaused=true end
    end
    function trigger.configure() fault=nil;autoPaused=false;trigger.reset() end
    function trigger.press()
        if not state.triggerEnabled or uiOpen or uiBusy or capturing or not focused or UIS:GetFocusedTextBox() then return end
        fault=nil
        if state.triggerMode=='auto' then autoPaused=not autoPaused
        elseif state.triggerMode=='toggle' then armed=not armed else armed=true end
        pendingTarget=nil;entryFired=false;stableSince=clock
    end
    function trigger.release() if state.triggerMode=='hold' then trigger.reset() end end
    local function viable(character)
        local hum=character and character:FindFirstChildOfClass('Humanoid')
        local effects=character and character:FindFirstChild('BodyEffects')
        return character and character.Parent and hum and hum.Health>0 and hum:GetState()~=Enum.HumanoidStateType.Dead and not flagOn(effects,'Dead') and not (state.triggerKnock and flagOn(effects,'K.O'))
    end
    local function eligible(p)
        return p and p~=player and not departing[p] and selectedPlayer(p) and viable(p.Character) and not (state.triggerTeam and not player.Neutral and not p.Neutral and player.Team and player.Team==p.Team)
    end
    local function knifeEquipped()
        -- Only direct equipped Tools; a knife in Backpack must not pause firing.
        for _,tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA('Tool') then
                for word in tool.Name:lower():gmatch('%a+') do
                    if word=='knife' or word=='knives' or word=='faca' then return true end
                end
            end
        end
        return false
    end
    -- Ray versus each oriented limb box, independent of CanQuery/collision mesh.
    local function bodyBoxDistance(part,ray)
        local origin=part.CFrame:PointToObjectSpace(ray.Origin)
        local direction=part.CFrame:VectorToObjectSpace(ray.Direction)
        local half=part.Size*0.5
        local near,far=0,2000
        for _,axis in ipairs({'X','Y','Z'}) do
            local o,d,h=origin[axis],direction[axis],half[axis]
            if math.abs(d)<0.000001 then
                if o < -h or o > h then return end
            else
                local a,b=(-h-o)/d,(h-o)/d
                if a>b then a,b=b,a end
                near=math.max(near,a);far=math.min(far,b)
                if near>far then return end
            end
        end
        return near
    end
    local function wholeBodyTarget(ray)
        local best,distance=nil,2000
        for _,p in ipairs(Players:GetPlayers()) do
            if eligible(p) then
                for _,part in ipairs(p.Character:GetChildren()) do
                    if part:IsA('BasePart') and part.Name~='HumanoidRootPart' then
                        local depth=bodyBoxDistance(part,ray)
                        if depth and depth<distance then
                            local clear=true
                            if state.triggerWalls then
                                local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
                                params.FilterDescendantsInstances={player.Character,p.Character}
                                local hit=Workspace:Raycast(ray.Origin,ray.Direction*depth,params)
                                clear=not hit or hit.Instance:IsDescendantOf(p.Character)
                            end
                            if clear then best=p;distance=depth end
                        end
                    end
                end
            end
        end
        return best
    end
    local function bodyTarget(camera,mouse)
        local ray=camera:ViewportPointToRay(mouse.X,mouse.Y)
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={player.Character}
        if not state.triggerWalls then
            params.FilterType=Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances={}
            for _,p in ipairs(Players:GetPlayers()) do if eligible(p) then table.insert(params.FilterDescendantsInstances,p.Character) end end
        end
        local hit=Workspace:Raycast(ray.Origin,ray.Direction*2000,params)
        local node=hit and hit.Instance
        -- Cosmetics do not trigger themselves; check the body behind them.
        while node and node~=Workspace do
            if node:IsA('Tool') or node:IsA('Accessory') then break end
            if node:IsA('Model') then
                local p=Players:GetPlayerFromCharacter(node)
                if p then return eligible(p) and p or nil end
            end
            node=node.Parent
        end
        return wholeBodyTarget(ray)
    end
    local function squareTarget(camera,mouse)
        local best,distance=nil,math.huge
        for _,p in ipairs(Players:GetPlayers()) do
            if eligible(p) then
                for _,part in ipairs(p.Character:GetChildren()) do
                    if part:IsA('BasePart') then
                        local point,onScreen=camera:WorldToViewportPoint(part.Position)
                        local dx,dy=point.X-mouse.X,point.Y-mouse.Y
                        if onScreen and point.Z>0 and math.abs(dx)<=state.triggerSize/2 and math.abs(dy)<=state.triggerSize/2 and dx*dx+dy*dy<distance then
                            local clear=true
                            if state.triggerWalls then
                                local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={player.Character}
                                local hit=Workspace:Raycast(camera.CFrame.Position,part.Position-camera.CFrame.Position,params)
                                clear=not hit or hit.Instance:IsDescendantOf(p.Character)
                            end
                            if clear then best=p;distance=dx*dx+dy*dy end
                        end
                    end
                end
            end
        end
        return best
    end
    local function step(dt)
        clock=clock+dt
        if not alive or closing or not state.triggerEnabled then trigger.reset();status('Desligado');return end
        if viewer.active then trigger.reset(true);status('Pausado · Spectate ativo');return end
        if not focused or uiOpen or uiBusy or capturing or UIS:GetFocusedTextBox() then
            trigger.reset(not focused or (not uiOpen and UIS:GetFocusedTextBox()~=nil and UIS:GetFocusedTextBox()~=false))
            status('Pausado · interface, digitação ou foco');return
        end
        if not viable(player.Character) then trigger.reset(true);status('Pausado · personagem indisponível');return end
        local mouse=UIS:GetMouseLocation()
        local active=state.triggerMode=='auto' and not autoPaused or state.triggerMode~='auto' and armed
        square.Position=UDim2.fromOffset(mouse.X,mouse.Y)
        local side=state.triggerDetect=='body' and 10 or state.triggerSize
        square.Size=UDim2.fromOffset(side,side);square.Visible=state.triggerShow and not state.hideVisuals
        outline.Color=active and Color3.fromRGB(90,205,125) or Color3.fromRGB(220,220,220)
        if not active then audioState(false);pendingTarget=nil;status(fault or ((state.triggerMode=='hold' and 'Segure ' or 'Aperte ')..state.triggerKeyName..' para ativar'));return end
        if knifeEquipped() then
            audioState(false);releaseInput();pendingTarget=nil;entryFired=false;stableSince=clock
            status('Pausado · faca equipada');return
        end
        audioState(true)
        local camera=Workspace.CurrentCamera;if not camera then pendingTarget=nil;return end
        local target
        if state.triggerDetect=='body' then target=bodyTarget(camera,mouse) else target=squareTarget(camera,mouse) end
        if not target then pendingTarget=nil;entryFired=false;status('Ativo · passe o cursor pelo corpo');return end
        if pendingTarget~=target then pendingTarget=target;entryFired=false;stableSince=clock end
        local tool=player.Character:FindFirstChildOfClass('Tool')
        if not tool or tool.Enabled==false then status('Equipe uma arma habilitada / aguardando recarga');return end
        local atomic=type(mouse1click)=='function'
        local pair=type(mouse1press)=='function' and type(mouse1release)=='function'
        if state.triggerMethod=='click' and not atomic and not pair then status('Executor sem clique/pressão · tente Ativar Tool');return end
        if not heldMouse and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then pendingTarget=nil;status('Pausado · disparo manual');return end
        status('Corpo detectado: @'..target.Name)
        if entryFired and not state.triggerRepeat then status('Clique enviado · saia do corpo para repetir');return end
        if clock-stableSince<state.triggerDelay or clock-lastShot<state.triggerInterval then return end
        lastShot=clock
        local ok,err=pcall(function()
            if state.triggerMethod=='click' and atomic then mouse1click() else
                releaseInput();local version=heldVersion
                if state.triggerMethod=='click' then heldMouse=true;mouse1press() else heldTool=tool;tool:Activate() end
                task.delay(0.02,function() if heldVersion==version then releaseInput() end end)
            end
        end)
        if ok then entryFired=true;status('Clique enviado · @'..target.Name)
        else trigger.reset(true);fault='Falha no clique: '..tostring(err):sub(1,100);status(fault) end
    end
    connect(UIS.WindowFocusReleased,function() focused=false;trigger.reset(true) end)
    if UIS.WindowFocused then connect(UIS.WindowFocused,function() focused=true end) end
    RunService:BindToRenderStep('EVINI_Trigger',Enum.RenderPriority.Camera.Value+2,function(dt)
        local ok,err=pcall(step,dt)
        if not ok then trigger.reset(true);fault='Trigger pausado: '..tostring(err):sub(1,100);status(fault) end
    end)
end

local function cameraActive()
    if viewer.active or closing or not state.camEnabled or uiOpen or uiBusy or capturing or UIS:GetFocusedTextBox() then return false end
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
-- Standalone implementation of the supplied velocity pulse. No remote loader/group hook.
local anti={root=nil,velocity=nil,focused=true}
function anti.restore()
    local root,velocity=anti.root,anti.velocity;anti.root=nil;anti.velocity=nil
    if root and velocity then pcall(function() root.AssemblyLinearVelocity=velocity end) end
end
function anti.step()
    anti.restore()
    if not alive or closing or not state.antiEnabled or viewer.active or not anti.focused or uiOpen or uiBusy or capturing or UIS:GetFocusedTextBox() then return end
    local character=player.Character
    local root=character and character:FindFirstChild('HumanoidRootPart')
    local hum=character and character:FindFirstChildOfClass('Humanoid')
    if not root or not hum or hum.Health<=0 or hum:GetState()==Enum.HumanoidStateType.Dead or root.Anchored then return end
    local effects=character:FindFirstChild('BodyEffects')
    if flagOn(effects,'Dead') or flagOn(effects,'K.O') then return end
    local ok=pcall(function()
        anti.root=root;anti.velocity=root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity=Vector3.new(state.antiX,state.antiY,state.antiZ)
    end)
    if not ok then anti.restore() end
end
connect(RunService.Heartbeat,anti.step)
RunService:BindToRenderStep('EVINI_AntiRestore',Enum.RenderPriority.First.Value,anti.restore)
connect(UIS.WindowFocusReleased,function() anti.focused=false;anti.restore() end)
connect(UIS.WindowFocused,function() anti.focused=true end)
-- Spectate owns only our local Camera; another client's Camera is not replicated.
do
    local notice=create('Frame',{Name='SpectateNotice',AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,80),Size=UDim2.new(0.9,0,0,78),BackgroundColor3=Color3.fromRGB(12,12,15),BackgroundTransparency=0.15,BorderSizePixel=0,Visible=false},overlays)
    create('UISizeConstraint',{MaxSize=Vector2.new(600,78)},notice);round(notice,7)
    local caption=text(notice,'',UDim2.fromOffset(12,6),UDim2.new(1,-96,1,-12),13)
    local exitButton=button(notice,'Parar',UDim2.new(1,-78,0,23),UDim2.fromOffset(66,32));exitButton.Name='StopSpectate'
    local dot=create('Frame',{Name='SpectateAimPoint',AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(7,7),BackgroundColor3=Color3.fromRGB(255,64,64),BorderSizePixel=0,Visible=false},overlays);round(dot,7)
    local function validVector(v)
        return typeof(v)=='Vector3' and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e7 and math.abs(v.Y)<1e7 and math.abs(v.Z)<1e7
    end
    local function lookup(id)
        for _,p in ipairs(Players:GetPlayers()) do if p.UserId==id and p~=player and not departing[p] then return p end end
    end
    function viewer.search(query)
        query=type(query)=='string' and query:match('^%s*(.-)%s*$'):lower() or ''
        local usernameOnly=query:sub(1,1)=='@';query=query:gsub('^@','')
        local users,names,partial={},{},{}
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and not departing[p] then
                local name,display=p.Name:lower(),p.DisplayName:lower()
                if query~='' and name==query then users[#users+1]=p
                elseif not usernameOnly and query~='' and display==query then names[#names+1]=p
                elseif query=='' or name:find(query,1,true) or (not usernameOnly and display:find(query,1,true)) then partial[#partial+1]=p end
            end
        end
        local result=#users>0 and users or #names>0 and names or partial
        table.sort(result,function(a,b) if a.Name==b.Name then return a.UserId<b.UserId end;return a.Name:lower()<b.Name:lower() end)
        return result
    end
    local function report(message)
        local p=viewer.target
        local summary=(p and (p.DisplayName..' (@'..p.Name..') · ID '..tostring(p.UserId)..'\n') or '')..message
        if viewer.status==message and caption.Text==summary and notice.Visible==viewer.active then return end
        viewer.status=message;viewer.onState(message)
        caption.Text=summary;notice.Visible=viewer.active
    end
    function viewer.clearSource()
        if viewer.sourceConnection then viewer.sourceConnection:Disconnect() end
        viewer.sourceConnection=nil;viewer.source=nil;viewer.sourceTime=nil;viewer.sourceConfirmed=false
    end
    function viewer.restore()
        local saved=viewer.snapshot;viewer.snapshot=nil;dot.Visible=false
        if not saved then return end
        local camera=saved.camera
        local subject=saved.subject
        local fallback=not subject or not subject.Parent or (subject:IsA('Humanoid') and subject.Health<=0)
        if fallback then subject=player.Character and player.Character:FindFirstChildOfClass('Humanoid') end
        pcall(function()
            if subject then camera.CameraSubject=subject end
            camera.CFrame=saved.cframe;camera.Focus=saved.focus;camera.FieldOfView=saved.fov
            camera.CameraType=fallback and Enum.CameraType.Custom or saved.kind
        end)
    end
    local function claim(camera)
        if viewer.snapshot and viewer.snapshot.camera==camera then return end
        viewer.restore()
        viewer.snapshot={camera=camera,kind=camera.CameraType,subject=camera.CameraSubject,cframe=camera.CFrame,focus=camera.Focus,fov=camera.FieldOfView}
    end
    function viewer.stop(message,clear)
        viewer.active=false;state.viewerEnabled=false;viewer.restore();viewer.clearSource();viewer.character=nil
        if clear then viewer.userId=nil;viewer.target=nil end
        report(message or 'Observação encerrada')
    end
    function viewer.start()
        local target=viewer.userId and lookup(viewer.userId)
        if not target then viewer.stop('Selecione um jogador presente no servidor',true);return false end
        viewer.target=target;viewer.active=true;state.viewerEnabled=true
        resetCamera();trigger.reset(true);anti.restore();report('Preparando Spectate aproximado')
        return true
    end
    function viewer.selectId(id)
        if type(id)~='number' or id~=id then return false end
        local target=lookup(id)
        if not target then report('Jogador não encontrado no servidor');return false end
        viewer.clearSource();viewer.character=nil;viewer.userId=id;viewer.target=target
        return viewer.start()
    end
    function viewer.selectQuery(query)
        local matches=viewer.search(query)
        if #matches==1 then viewer.onSelection('Selecionado: @'..matches[1].Name);return viewer.selectId(matches[1].UserId) end
        local message=#matches==0 and 'Nenhum jogador encontrado' or tostring(#matches)..' correspondências: escolha pelo @username na lista de Jogadores'
        viewer.onSelection(message)
        if not viewer.active then report(message) end
        return false
    end
    local function readAim(character,origin)
        if viewer.source and (not viewer.source.Parent or not viewer.source:IsDescendantOf(character)) then viewer.clearSource() end
        if not viewer.source and viewer.clock>=(viewer.nextProbe or 0) then
            viewer.nextProbe=viewer.clock+0.2
            local effects=character:FindFirstChild('BodyEffects')
            local candidate=(effects and (effects:FindFirstChild('MousePos') or effects:FindFirstChild('MousePosition'))) or character:FindFirstChild('MousePos') or character:FindFirstChild('MousePosition')
            if candidate and (candidate:IsA('Vector3Value') or candidate:IsA('CFrameValue')) then
                viewer.source=candidate;viewer.sourceTime=viewer.clock;viewer.sourceConfirmed=false
                viewer.sourceConnection=candidate:GetPropertyChangedSignal('Value'):Connect(function()
                    if viewer.source==candidate then viewer.sourceTime=viewer.clock;viewer.sourceConfirmed=true end
                end)
            end
        end
        local source=viewer.source
        if not source or not viewer.sourceTime or viewer.clock-viewer.sourceTime>0.75 then return nil end
        local value=source.Value
        if source:IsA('CFrameValue') then value=typeof(value)=='CFrame' and value.Position or nil end
        if not validVector(value) then return nil end
        local distance=(value-origin).Magnitude
        if distance<0.01 or distance>5000 then return nil end
        return value
    end
    function viewer.step(dt)
        viewer.clock=viewer.clock+math.max(dt,0)
        if not viewer.active then return end
        local p=viewer.target
        if not p or departing[p] then viewer.stop('Jogador saiu do servidor',true);return end
        local character=p.Character
        if character~=viewer.character then
            viewer.clearSource();viewer.character=character;viewer.nextProbe=0
        end
        local hum=character and character:FindFirstChildOfClass('Humanoid')
        local head=character and character:FindFirstChild('Head')
        local root=character and character:FindFirstChild('HumanoidRootPart')
        local effects=character and character:FindFirstChild('BodyEffects')
        if not character or not character.Parent or not hum or hum.Health<=0 or hum:GetState()==Enum.HumanoidStateType.Dead or flagOn(effects,'Dead') then
            viewer.restore();viewer.clearSource();report('Aguardando renascimento · câmera local restaurada');return
        end
        if not head or not head:IsA('BasePart') then head=root end
        if not head or not root or not root:IsA('BasePart') or not validVector(head.Position) then
            viewer.restore();report('Personagem ainda não disponível neste cliente');return
        end
        local camera=Workspace.CurrentCamera
        if not camera then viewer.restore();report('Câmera local indisponível');return end
        local origin=head.Position
        local aim=readAim(character,origin)
        local direction=head.CFrame.LookVector
        if not validVector(direction) or direction.Magnitude<0.001 then direction=Vector3.new(0,0,-1) end
        direction=direction.Unit
        local destination=aim or origin+direction*100
        local position,focus,message
        if state.viewerMode=='aim' then
            local forward=(destination-origin).Unit
            position=origin+forward*math.min(head.Size.Magnitude*0.5+0.15,(destination-origin).Magnitude*0.25);focus=destination
            message=aim and (viewer.sourceConfirmed and 'Câmera aproximada · mira replicada do jogo' or 'Câmera aproximada · dado de mira com idade não confirmada') or 'Câmera aproximada · direção estimada, sem mira recente'
        else
            local forward=root.CFrame.LookVector
            if not validVector(forward) or forward.Magnitude<0.001 then forward=direction end
            forward=forward.Unit
            position=origin-forward*8+Vector3.new(0,3,0);focus=origin+forward*3
            message='Spectate aproximado · orientação do personagem'
            if aim then message=message..(viewer.sourceConfirmed and ' · ponto de mira replicado' or ' · ponto de mira com idade não confirmada') end
        end
        claim(camera)
        camera.CameraType=Enum.CameraType.Scriptable;camera.CameraSubject=hum
        camera.CFrame=CFrame.lookAt(position,focus);camera.Focus=CFrame.new(focus)
        dot.Visible=false
        if aim and not state.hideVisuals then
            local point,onScreen=camera:WorldToViewportPoint(aim)
            if onScreen and point.Z>0 then dot.Position=UDim2.fromOffset(point.X,point.Y);dot.Visible=true end
        end
        report(message)
    end
    connect(exitButton.Activated,function() viewer.stop() end)
end

local espElapsed,statusElapsed=0,0
local function render(dt)
    aimClock=aimClock+dt
    local viewingOK=pcall(viewer.step,dt)
    if not viewingOK then viewer.stop("Observação interrompida por erro; câmera restaurada") end
    ringStroke.Transparency=state.fovTransparency
    local camera=Workspace.CurrentCamera
    if not camera then return end
    local mouse=UIS:GetMouseLocation()
    ring.Position=UDim2.fromOffset(mouse.X,mouse.Y)
    ring.Size=UDim2.fromOffset(state.fov*2,state.fov*2)
    ring.Visible=not viewer.active and not state.hideVisuals and state.camEnabled and state.showFov and not uiOpen and not uiBusy
    espElapsed=espElapsed+dt; statusElapsed=statusElapsed+dt
    if espElapsed>=0.15 then espElapsed=0;updateESP() end
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
local palette={bg=Color3.fromRGB(7,7,10),panel=Color3.fromRGB(25,26,31),edge=Color3.fromRGB(104,105,114),muted=Color3.fromRGB(151,153,163),white=Color3.fromRGB(240,240,243)}
gui.IgnoreGuiInset=true
local backdrop=create('CanvasGroup',{Name='StudioBackdrop',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,GroupTransparency=1,Visible=false},gui)
local shade=create('Frame',{Name='Shade',Size=UDim2.fromScale(1,1),BackgroundColor3=palette.bg,BackgroundTransparency=state.uiOpacity,BorderSizePixel=0},backdrop)
create('UIGradient',{Name='Fade',Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.08),NumberSequenceKeypoint.new(0.25,0.2),NumberSequenceKeypoint.new(0.55,0.60),NumberSequenceKeypoint.new(1,1)})},shade)
local rootUI=create('Frame',{Name='Hub',Position=UDim2.fromScale(0.065,0.13),Size=UDim2.fromOffset(465,670),BackgroundTransparency=1,Visible=false},gui)
local uiScale=create('UIScale',{Name='UserScale',Scale=1},rootUI)
local panel=create('CanvasGroup',{Name='UnifiedPanel',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,GroupTransparency=1},rootUI)
local header=create('Frame',{Name='Header',Size=UDim2.new(1,0,0,132),BackgroundTransparency=1},panel)
local hide=button(header,'‹  Voltar',UDim2.fromOffset(0,0),UDim2.fromOffset(130,35));hide.Name='Hide';hide.Modal=true;hide.BackgroundTransparency=1;hide.TextXAlignment=Enum.TextXAlignment.Left;hide.TextSize=18
local title=text(header,'EVINI',UDim2.fromOffset(0,43),UDim2.new(1,-20,0,64),48);title.Name='HubTitle';title.Font=Enum.Font.GothamBold
local sidebar=create('ScrollingFrame',{Name='Navigation',Position=UDim2.fromOffset(0,132),Size=UDim2.new(1,0,1,-176),CanvasSize=UDim2.fromOffset(0,410),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=palette.muted,ScrollingDirection=Enum.ScrollingDirection.Y},panel)
local body=create('CanvasGroup',{Name='Content',Position=UDim2.fromOffset(0,132),Size=UDim2.new(1,0,1,-176),BackgroundTransparency=1,Visible=false},panel)
local footer=create('Frame',{Name='Footer',Position=UDim2.new(0,0,1,-34),Size=UDim2.new(1,0,0,34),BackgroundTransparency=1},panel)
local fitReadout=function() end
local refreshSizeControls=function() end
local function fitUI()
    local camera=Workspace.CurrentCamera
    if not camera then return end
    local v=camera.ViewportSize
    local desired=math.clamp(math.min(v.X/1440,v.Y/900),0.38,1.8)*state.uiSize
    uiScale.Scale=math.max(0.1,math.min(desired,(v.X*0.87)/465,(v.Y*0.82)/670))
    fitReadout(state.uiSize)
end
local animationVersion=0
local activeTweens={}
local destroyed=false
local pages,tabs={},{}
local currentPage=nil
local navigationTween=nil
local menuMotion={items={},version=0,tweens={}}
function menuMotion.cancel()
    menuMotion.version=menuMotion.version+1
    for _,t in ipairs(menuMotion.tweens) do t:Cancel() end
    menuMotion.tweens={}
end
function menuMotion.arrive()
    menuMotion.cancel();local version=menuMotion.version
    for i,item in ipairs(menuMotion.items) do
        item.group.GroupTransparency=state.reduceMotion and 0 or 1
        item.group.Position=UDim2.fromOffset(state.reduceMotion and 8 or -17,item.y)
        if not state.reduceMotion then
            task.delay((i-1)*0.045,function()
                if not alive or version~=menuMotion.version then return end
                local t=TweenService:Create(item.group,TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{GroupTransparency=0,Position=UDim2.fromOffset(8,item.y)})
                menuMotion.tweens[#menuMotion.tweens+1]=t;t:Play()
            end)
        end
    end
end
local function refreshTabs() end
local function navigate(name)
    currentPage=name
    menuMotion.cancel()
    if not name then menuMotion.arrive() end
    sidebar.Visible=name==nil;body.Visible=name~=nil
    title.Text=name=='Mira' and 'Cam Lock' or name or 'EVINI'
    title.TextSize=name and 34 or 48
    hide.Text=name and '‹  Categorias' or '‹  Voltar'
    for key,p in pairs(pages) do p.scroll.Visible=key==name end
    if navigationTween then navigationTween:Cancel() end
    if name then
        body.GroupTransparency=state.reduceMotion and 0 or 1
        navigationTween=TweenService:Create(body,TweenInfo.new(state.reduceMotion and 0 or 0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{GroupTransparency=0})
        navigationTween:Play()
    end
end
local function showUI(open,after)
    if not alive then return end
    animationVersion=animationVersion+1;local version=animationVersion
    menuMotion.cancel()
    for _,t in ipairs(activeTweens) do t:Cancel() end
    activeTweens={};uiOpen=open;uiBusy=true;trigger.reset();anti.restore();fitUI()
    if open then
        if not rootUI.Visible then panel.Position=UDim2.fromOffset(-25,0);panel.GroupTransparency=1 end
        rootUI.Visible=true;backdrop.Visible=true;navigate(nil)
    end
    local duration=state.reduceMotion and 0 or (open and 0.32 or 0.22)
    local function tween(object,props)
        local t=TweenService:Create(object,TweenInfo.new(duration,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props)
        activeTweens[#activeTweens+1]=t;t:Play()
    end
    tween(panel,{Position=UDim2.fromOffset(open and 0 or -25,0),GroupTransparency=open and 0 or 1})
    tween(backdrop,{GroupTransparency=open and 0 or 1})
    task.delay(duration,function()
        if not alive or version~=animationVersion then return end
        uiBusy=false;rootUI.Visible=open;backdrop.Visible=open
        if after then after() end
    end)
end
-- Studio resources for settings/players; simple native geometry for the other categories.
local function categoryIcon(parent,name)
    local holder=create('Frame',{Name='CategoryIcon',Position=UDim2.fromOffset(0,16),Size=UDim2.fromOffset(24,24),BackgroundTransparency=1},parent)
    local assets={Ajustes='GameSettingsTab@2x.png',Jogadores='PlayersTabIcon@2x.png',Mira='CaptureTab@2x.png'}
    if assets[name] then
        create('ImageLabel',{Name='StudioIcon',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image='rbxasset://textures/ui/Settings/MenuBarIcons/'..assets[name],ImageColor3=palette.white,ScaleType=Enum.ScaleType.Fit},holder)
        return
    end
    local function line(x,y,w,h,rotation)
        return create('Frame',{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Rotation=rotation or 0,BackgroundColor3=palette.white,BorderSizePixel=0},holder)
    end
    if name=='Hitbox' then
        local box=create('Frame',{Position=UDim2.fromOffset(3,3),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1},holder)
        round(box,3);create('UIStroke',{Color=palette.white,Thickness=1.5},box)
    elseif name=='Triggerbot' then
        local ring=create('Frame',{Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(14,14),BackgroundTransparency=1},holder)
        round(ring,20);create('UIStroke',{Color=palette.white,Thickness=1.5},ring)
        line(11,0,2,6);line(11,18,2,6);line(0,11,6,2);line(18,11,6,2)
    elseif name=='Visual' then
        local eye=create('Frame',{Position=UDim2.fromOffset(1,5),Size=UDim2.fromOffset(22,14),BackgroundTransparency=1},holder)
        round(eye,10);create('UIStroke',{Color=palette.white,Thickness=1.5},eye)
        local pupil=line(9,9,6,6);round(pupil,6)
    end
end
local function page(name,index)
    local frame=create('ScrollingFrame',{Name=name,Position=UDim2.fromOffset(0,0),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=palette.muted,CanvasSize=UDim2.fromOffset(0,0),Visible=false},body)
    frame.ScrollingDirection=Enum.ScrollingDirection.Y;frame.VerticalScrollBarInset=Enum.ScrollBarInset.Always
    local content=create('Frame',{Name=name..'Content',Position=UDim2.fromOffset(8,10),Size=UDim2.new(1,-25,0,0),BackgroundTransparency=1,BorderSizePixel=0},frame)
    pages[name]={frame=content,scroll=frame,y=0}
    local group=create('CanvasGroup',{Name='Arrival_'..name,Position=UDim2.fromOffset(8,8+(index-1)*66),Size=UDim2.new(1,-25,0,64),BackgroundTransparency=1},sidebar)
    local b=button(group,'',UDim2.fromOffset(8,4),UDim2.new(1,-16,0,56));b.Name='Tab_'..name;b.BackgroundTransparency=1
    local hoverScale=create('UIScale',{Name='HoverScale',Scale=1},b)
    local glow=create('Frame',{Name='CursorLight',Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(84,48),BackgroundColor3=palette.white,BackgroundTransparency=1,BorderSizePixel=0},b);round(glow,24)
    menuMotion.items[index]={group=group,button=b,scale=hoverScale,glow=glow,y=8+(index-1)*66,x=0,dy=0,weight=0}
    categoryIcon(b,name)
    local caption=text(b,name=='Mira' and 'Cam Lock' or name,UDim2.fromOffset(42,0),UDim2.new(1,-82,1,0),20)
    caption.Name='CategoryLabel';caption.Font=Enum.Font.GothamMedium;caption.TextWrapped=false
    local arrow=text(b,'›',UDim2.new(1,-22,0,0),UDim2.fromOffset(22,56),23);arrow.TextColor3=palette.muted
    create('Frame',{Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BackgroundColor3=palette.edge,BackgroundTransparency=0.65,BorderSizePixel=0},b)
    tabs[name]=b
    connect(b.Activated,function() if not uiBusy then navigate(name) end end)
    return pages[name]
end
local camPage=page('Mira',1)
local hitPage=page('Hitbox',2)
local espPage=page('Visual',4)
local playersPage=page('Jogadores',5)
local settingsPage=page('Ajustes',6)
page('Triggerbot',3)
RunService:BindToRenderStep('EVINI_MenuMotion',Enum.RenderPriority.Camera.Value+3,function(dt)
    if not alive or not uiOpen then return end
    local mouse=UIS:GetMouseLocation()
    for _,item in pairs(menuMotion.items) do
        local b=item.button;local pos,size=b.AbsolutePosition,b.AbsoluteSize
        local over=uiOpen and not uiBusy and not currentPage and not state.reduceMotion and mouse.X>=pos.X and mouse.X<=pos.X+size.X and mouse.Y>=pos.Y and mouse.Y<=pos.Y+size.Y
        local x=over and math.clamp(((mouse.X-pos.X)/math.max(1,size.X)-0.5)*2,-1,1) or 0
        local y=over and math.clamp(((mouse.Y-pos.Y)/math.max(1,size.Y)-0.5)*2,-1,1) or 0
        local blend=state.reduceMotion and 1 or 1-math.exp(-math.max(0,dt)*14)
        item.x=item.x+(x-item.x)*blend;item.dy=item.dy+(y-item.dy)*blend
        item.weight=item.weight+((over and 1 or 0)-item.weight)*blend
        b.Position=UDim2.fromOffset(8+item.x*3,4+item.dy*2-item.weight*2)
        b.Rotation=item.x*0.8;item.scale.Scale=1+item.weight*0.012
        item.glow.Position=UDim2.new(0.5,item.x*math.max(0,size.X/uiScale.Scale/2-50)-42,0,4+item.dy*2)
        item.glow.BackgroundTransparency=1-item.weight*0.06
    end
end)
local function subPage() return {frame=create('Frame',{BackgroundTransparency=1,Visible=false,Size=UDim2.new(1,0,0,0)},camPage.frame),y=0} end
local predPage=subPage()
local function slot(p,h)
    local y=p.y;p.y=y+h
    p.frame.Size=UDim2.new(1,p.scroll and -25 or 0,0,p.y+8)
    if p.scroll then p.scroll.CanvasSize=UDim2.fromOffset(0,p.y+22) end
    return y
end
local function label(p,value,description)
    local y=slot(p,description and 85 or 36)
    local t=text(p.frame,value,UDim2.fromOffset(0,y),UDim2.new(1,0,0,20),15); t.Font=Enum.Font.Gotham; accent(t,'TextColor3')
    if description then local d=text(p.frame,description,UDim2.fromOffset(0,y+23),UDim2.new(1,-4,0,52),13); d.Font=Enum.Font.Gotham; d.TextColor3=palette.muted end
end
local function rowText(p,value,y)
    local backdrop=create('Frame',{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,48),BackgroundColor3=palette.panel,BackgroundTransparency=1,BorderSizePixel=0},p.frame)
    local t=text(p.frame,value,UDim2.fromOffset(10,y+7),UDim2.new(1,-132,0,36),16); t.Font=Enum.Font.Gotham; return t
end
local controlRefresh={}
local function switch(p,value,key,onChange)
    local y=slot(p,54); rowText(p,value,y)
    local b=button(p.frame,'',UDim2.new(1,-56,0,y+8),UDim2.fromOffset(46,22)); b.Name=key
    local gradient=b:FindFirstChildOfClass('UIGradient');if gradient then gradient.Color=ColorSequence.new(Color3.new(1,1,1)) end
    local corner=b:FindFirstChildOfClass('UICorner');if corner then corner:Destroy() end
    local shadow=create('Frame',{Name='ToggleShadow',Size=UDim2.fromOffset(19,19),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.2,BorderSizePixel=0},b)
    local dot=create('Frame',{Name='ToggleKnob',Size=UDim2.fromOffset(16,16),BackgroundColor3=palette.white,BorderSizePixel=1,BorderColor3=Color3.fromRGB(50,50,50),ZIndex=2},b)
    local function refresh()
        b.BackgroundColor3=state[key] and Color3.fromRGB(100,102,113) or Color3.fromRGB(48,48,48)
        dot.BackgroundColor3=palette.white
        local x=state[key] and 27 or 3
        shadow.Position=UDim2.fromOffset(x-1,3)
        dot.Position=UDim2.fromOffset(x,3)
    end
    connect(b.Activated,function() state[key]=not state[key]; refresh(); if onChange then onChange() end;queueSave() end)
    refresh();controlRefresh[key]=refresh; return b
end
local function field(p,value,key,min,max,step,onChange)
    local y=slot(p,54); rowText(p,value,y)
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
local function slider(p,value,key,min,max,step,onChange)
    local box,set=field(p,value,key,min,max,step,onChange)
    local y=slot(p,24)-7
    local hit=create('TextButton',{Name=key..'_Slider',Text='',BackgroundTransparency=1,Position=UDim2.fromOffset(12,y),Size=UDim2.new(1,-24,0,22)},p.frame)
    local track=create('Frame',{Position=UDim2.fromOffset(0,8),Size=UDim2.new(1,0,0,5),BackgroundColor3=palette.edge,BorderSizePixel=0},hit)
    local fill=create('Frame',{Size=UDim2.fromScale((state[key]-min)/(max-min),1),BackgroundColor3=green,BorderSizePixel=0},track)
    accent(fill,'BackgroundColor3')
    local knob=create('Frame',{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale((state[key]-min)/(max-min),0.5),Size=UDim2.fromOffset(18,18),BackgroundColor3=green,BorderSizePixel=0},track)
    round(knob,20);create('UIStroke',{Color=Color3.fromRGB(29,29,34),Thickness=3},knob)
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
    local y=slot(p,54); local caption=rowText(p,value,y); caption.Size=UDim2.new(1,-184,0,36)
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


do
    local p=pages.Triggerbot
    label(p,'TRIGGERBOT','Corpo sob cursor: um clique ao passar por qualquer parte do personagem. Não move a mira nem altera hitboxes.')
    switch(p,'Habilitar triggerbot','triggerEnabled',trigger.configure)
    choice(p,'Ativação','triggerMode',{{'auto','Automático'},{'hold','Segurar tecla'},{'toggle','Ligar / desligar'}},trigger.configure)
    choice(p,'Detecção','triggerDetect',{{'body','Corpo inteiro sob cursor'},{'square','Quadrado · corpo inteiro'}},trigger.configure)
    switch(p,'Repetir enquanto no alvo','triggerRepeat',trigger.configure)
    field(p,'Lado do quadrado · pixels','triggerSize',4,300,1,trigger.configure)
    switch(p,'Mostrar indicador do cursor','triggerShow')
    switch(p,'Sons de ativar / desativar','triggerSounds')
    switch(p,'Verificar paredes','triggerWalls',trigger.configure)
    switch(p,'Ignorar meu time','triggerTeam',trigger.configure)
    switch(p,'Knock Check','triggerKnock',trigger.configure)
    field(p,'Atraso inicial · segundos','triggerDelay',0,0.5,0.01,trigger.configure)
    field(p,'Intervalo de disparos · s','triggerInterval',0.05,1,0.01,trigger.configure)
    choice(p,'Método de disparo','triggerMethod',{{'click','Clique (executor)'},{'tool','Ativar Tool'}},trigger.configure)
    label(p,'USO','Ative, equipe a arma e esconda o painel. Automático não exige segurar tecla. T pausa/retoma; Esc e perda de foco desarmam.')
    label(p,'COMPATIBILIDADE','Clique depende do executor. Ativar Tool depende da arma. Desligar paredes permite disparar, mas não atravessa obstáculos.')
end

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
        item.check.BackgroundColor3=selectedPlayer(p) and Color3.fromRGB(100,102,113) or palette.panel
        if visible then item.row.Position=UDim2.fromOffset(0,y);y=y+62 end
    end
    playersPage.frame.Size=UDim2.new(1,-25,0,y+8)
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
    local name=text(row,p.DisplayName,UDim2.fromOffset(58,6),UDim2.new(1,-190,0,21),15);name.Font=Enum.Font.GothamBold
    text(row,'@'..p.Name,UDim2.fromOffset(58,29),UDim2.new(1,-190,0,18),12).TextColor3=palette.muted
    local check=button(row,'',UDim2.new(1,-43,0,11),UDim2.fromOffset(32,32));check.Name='Select_'..id;check.TextSize=22
    local gradient=check:FindFirstChildOfClass('UIGradient');if gradient then gradient.Color=ColorSequence.new(Color3.new(1,1,1)) end
    local observe=button(row,'Observar',UDim2.new(1,-121,0,11),UDim2.fromOffset(70,32));observe.Name='Observe_'..id;observe.TextSize=11
    local item={player=p,row=row,check=check};roster[p.UserId]=item
    item.observeConnection=observe.Activated:Connect(function() viewer.selectId(p.UserId) end)
    item.connection=check.Activated:Connect(function() state.playerSelection[id]=not selectedPlayer(p);selectionChanged() end)
    layoutRoster()
end
local function removeRoster(p)
    departing[p]=true
    if viewer.userId==p.UserId then viewer.stop('Jogador saiu do servidor',true) end
    local item=roster[p.UserId]
    if item then item.connection:Disconnect();item.observeConnection:Disconnect();item.row:Destroy();roster[p.UserId]=nil end
    if cameraTarget and cameraTarget.player==p then resetCamera() end
    if p.Character then
        local root=p.Character:FindFirstChild('HumanoidRootPart');if root then restore(root) end
        destroyESP(p.Character)
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

do
    label(espPage,'SPECTATE / AIM VIEWER','Câmera aproximada. A câmera real de outro cliente não é replicada. Escolha por nome ou use Observar na lista de Jogadores.')
    local search=create('TextBox',{Name='SpectateSearch',Position=UDim2.fromOffset(0,slot(espPage,46)),Size=UDim2.new(1,0,0,36),BackgroundColor3=palette.panel,TextColor3=palette.white,BorderSizePixel=0,PlaceholderText='@username ou DisplayName (parcial)',Text='',ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=14},espPage.frame);round(search,7)
    local select=button(espPage.frame,'Buscar e observar',UDim2.fromOffset(0,slot(espPage,46)),UDim2.new(1,0,0,36));select.Name='SpectateSelect'
    connect(select.Activated,function() viewer.selectQuery(search.Text) end)
    connect(search.FocusLost,function(enter) if enter then viewer.selectQuery(search.Text) end end)
    local result=text(espPage.frame,'Use @username para distinguir nomes iguais.',UDim2.fromOffset(0,slot(espPage,48)),UDim2.new(1,0,0,44),12);result.Name='SpectateSearchResult'
    viewer.onSelection=function(message) result.Text=message end
    local list=button(espPage.frame,'Escolher na lista de jogadores',UDim2.fromOffset(0,slot(espPage,46)),UDim2.new(1,0,0,36));list.Name='SpectateRoster'
    connect(list.Activated,function() navigate('Jogadores') end)
    switch(espPage,'Ativar observação','viewerEnabled',function() if state.viewerEnabled then viewer.start() else viewer.stop() end end)
    choice(espPage,'Modo da câmera','viewerMode',{{'character','Personagem'},{'aim','Direção da mira'}})
    local status=text(espPage.frame,viewer.status,UDim2.fromOffset(0,slot(espPage,86)),UDim2.new(1,0,0,80),12);status.Name='SpectateStatus'
    viewer.onState=function(message)
        local target=viewer.target
        status.Text=(target and (target.DisplayName..' (@'..target.Name..') · ID '..tostring(target.UserId)..'\n') or '')..message
        controlRefresh.viewerEnabled()
    end
end
label(espPage,'ANTI-AIM','Pulso de velocidade do trecho enviado. C ativa/desativa. Pode afetar a física; começa desligado a cada execução.')
switch(espPage,'Ativar anti-aim','antiEnabled',anti.restore)
field(espPage,'Velocidade X','antiX',-100000,100000,1,anti.restore)
field(espPage,'Velocidade Y','antiY',-100000,100000,1,anti.restore)
field(espPage,'Velocidade Z','antiZ',-100000,100000,1,anti.restore)
label(espPage,'Visibilidade','Ocultar estes desenhos não desliga o recurso de mira.')
switch(espPage,'Ocultar todos os desenhos','hideVisuals')
switch(espPage,'Marcador do cam lock','camMarker')
switch(espPage,'Linha do cam lock','camTracer')
label(espPage,'Só nomes','Etiquetas nativas acompanham os personagens. Sem caixas ou distância; mortos e K.O. ficam ocultos.')
label(camPage,'CAM LOCK + PREDICT','Clique na tecla para capturar no FOV. Clique de novo para soltar. Esc também solta.')
local camKeyY=slot(camPage,54)
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
    if keyButtons.trigger then keyButtons.trigger.Text=state.triggerKeyName end
    if keyButtons.anti then keyButtons.anti.Text=state.antiKeyName end
end
local function stopCapture() capturing=nil; captureVersion=captureVersion+1; refreshKeys() end
local function keyField(value,which)
    local p=which=='anti' and espPage or which=='trigger' and pages.Triggerbot or which~='hide' and camPage or settingsPage
    local y=which=='cam' and camKeyY or slot(p,54); rowText(p,value,y)
    local b=button(p.frame,'',UDim2.new(1,-116,0,y+3),UDim2.fromOffset(106,32)); b.Name=which=='anti' and 'AntiKeybind' or which=='trigger' and 'TriggerKeybind' or which=='hide' and 'Keybind' or 'CamKeybind'; keyButtons[which]=b
    connect(b.Activated,function()
        if capturing==which then stopCapture(); return end
        stopCapture(); capturing=which; trigger.reset(); resetCamera(); b.Text='Tecla?'; local version=captureVersion
        task.delay(8,function() if alive and version==captureVersion then stopCapture() end end)
    end)
end
keyField('Ocultar / abrir hub','hide'); keyField('Tecla do cam lock','cam');keyField('Tecla do triggerbot','trigger');keyField('Tecla do anti-aim','anti'); refreshKeys()
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
    camPage.frame.Size=UDim2.new(1,-25,0,y+10)
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
    local darkness=math.floor(48*(1-state.uiDarkness)+0.5)
    palette.bg=Color3.fromRGB(darkness,darkness,darkness)
    shade.BackgroundColor3=palette.bg;shade.BackgroundTransparency=state.uiOpacity
    for _,refresh in pairs(controlRefresh) do refresh() end
    refreshTabs()
    fitUI()
end
label(settingsPage,'Aparência')
choice(settingsPage,'Contraste','accent',{{'Branco','Branco'},{'Cinza','Cinza claro'}},refreshAppearance)
slider(settingsPage,'Transparência · 0–0,80','uiOpacity',0,0.8,0.01,refreshAppearance)
slider(settingsPage,'Escurecimento · 1 = preto','uiDarkness',0,1,0.05,refreshAppearance)
slider(settingsPage,'Tamanho da interface · 0,45–1,50','uiSize',0.45,1.5,0.05)
local refreshSize=controlRefresh.uiSize
controlRefresh.uiSize=function() refreshSize();fitUI() end
refreshSizeControls=controlRefresh.uiSize
switch(settingsPage,'Reduzir animações','reduceMotion')
switch(settingsPage,'Sons dos botões','uiSounds')
local soundInfo=text(settingsPage.frame,soundStatus,UDim2.fromOffset(0,slot(settingsPage,38)),UDim2.new(1,-4,0,34),11);soundInfo.Name='SoundStatus';soundInfo.TextColor3=palette.muted
soundReport=function(value) if alive then soundInfo.Text=value end end
slider(settingsPage,'Volume dos botões','soundVolume',0,0.6,0.05)

switch(settingsPage,'Notificações de alvo','notifications')
switch(settingsPage,'Avisar entradas e saídas','serverNotices')
local foot=text(footer,'K · HUB     Q · CAM LOCK',UDim2.fromOffset(12,8),UDim2.new(0.45,-12,0,18),12); foot.Font=Enum.Font.Gotham; foot.TextColor3=palette.muted
local stats=text(footer,'PING —',UDim2.new(0.45,0,0,8),UDim2.new(0.55,-12,0,18),12); stats.Font=Enum.Font.Gotham; stats.TextXAlignment=Enum.TextXAlignment.Right; stats.TextColor3=palette.muted
cameraStatus=function(name,ping,pred)
    targetReadout.Text='ALVO: '..name
    stats.Text=(ping and math.floor(ping*1000)..' ms' or 'ping indisponível')..' / '..string.format('%.3f s',pred)
    foot.Text=hideKey.Name..' · HUB   '..camBind.Name..' · '..(cameraTarget and 'LOCK' or 'CAM')
end
local toast=create('Frame',{Name='TargetNotice',AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-28,1,-110),Size=UDim2.fromOffset(300,58),BackgroundColor3=palette.bg,BorderSizePixel=0,Visible=false},overlays)
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
        trigger.reset(true);resetCamera();viewer.stop('Observação encerrada com Esc')
        return
    end
    if not capturing and latched and event.KeyCode==camBind then resetCamera();return end
    if UIS:GetFocusedTextBox() then return end
    if capturing then
        if event.UserInputType~=Enum.UserInputType.Keyboard then return end
        if event.KeyCode==Enum.KeyCode.Escape then stopCapture(); return end
        if processed or event.KeyCode==Enum.KeyCode.Unknown then return end
        local assigned={hide=hideKey,cam=camBind,trigger=Enum.KeyCode[state.triggerKeyName],anti=Enum.KeyCode[state.antiKeyName]}
        for role,key in pairs(assigned) do if role~=capturing and event.KeyCode==key then keyButtons[capturing].Text='Em uso';return end end
        if event.KeyCode==Enum.KeyCode.Escape then stopCapture(); return end
        if capturing=='anti' then state.antiKeyName=event.KeyCode.Name;anti.restore() elseif capturing=='hide' then hideKey=event.KeyCode;state.hideKeyName=hideKey.Name elseif capturing=='trigger' then state.triggerKeyName=event.KeyCode.Name;trigger.reset() else camBind=event.KeyCode;state.camKeyName=camBind.Name end
        queueSave();stopCapture(); return
    end
    if processed then return end
    if event.KeyCode==Enum.KeyCode[state.antiKeyName] then
        state.antiEnabled=not state.antiEnabled;anti.restore();controlRefresh.antiEnabled();playClick();queueSave()
    elseif event.KeyCode==Enum.KeyCode[state.triggerKeyName] then trigger.press()
    elseif event.KeyCode==hideKey then playClick();showUI(not uiOpen)
    elseif event.KeyCode==camBind and not viewer.active and not uiOpen and not uiBusy then
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
    if event.KeyCode==Enum.KeyCode[state.triggerKeyName] then trigger.release() end
    if sliderDrag and (event==sliderDrag.input or event.UserInputType==Enum.UserInputType.MouseButton1) then sliderDrag=nil end
end)
connect(UIS.WindowFocusReleased,function() resetCamera();sliderDrag=nil end)
connect(UIS.InputChanged,function(event)
    local mouse=event.UserInputType==Enum.UserInputType.MouseMovement
    if sliderDrag and (event==sliderDrag.input or (mouse and sliderDrag.input.UserInputType==Enum.UserInputType.MouseButton1)) then sliderDrag.move(event.Position) end
end)
connect(hide.Activated,function() stopCapture();if currentPage then navigate(nil) else showUI(false) end end)
local api={Settings=state,Save=saveSettings,GetTriggerStatus=function() return trigger.lastStatus end,Spectate={Search=viewer.search,SelectUserId=viewer.selectId,Select=viewer.selectQuery,Stop=viewer.stop,Status=function() return viewer.status end}}
function api.Destroy()
    if not alive then return end
    viewer.stop('EVINI encerrado');saveSettings();alive=false; animationVersion=animationVersion+1; resetCamera()
    for _,c in ipairs(connections) do c:Disconnect() end
    for _,t in ipairs(activeTweens) do t:Cancel() end
    if navigationTween then navigationTween:Cancel() end
    menuMotion.cancel();RunService:UnbindFromRenderStep('EVINI_MenuMotion')
    trigger.reset();RunService:UnbindFromRenderStep('EVINI_Trigger')
    RunService:UnbindFromRenderStep('EVINI_Camera')
    for _,item in pairs(roster) do item.connection:Disconnect();item.observeConnection:Disconnect() end
    anti.restore();RunService:UnbindFromRenderStep('EVINI_AntiRestore')
    restoreAll(); overlays:Destroy(); gui:Destroy()
    espObjects={}; candidates={}; npcModels={}
    if env.EVINI==api then env.EVINI=nil end
end
env.EVINI=api
local close=button(settingsPage.frame,'Encerrar EVINI',UDim2.fromOffset(0,slot(settingsPage,48)),UDim2.new(1,0,0,38));close.Name='Close'
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
-- No loading screen: K opens the categories directly.
showUI(false)
return api
