from pathlib import Path
from lupa import LuaRuntime
from luaparser import ast
source=(Path(__file__).resolve().parents[1] / 'main.lua').read_text()
ast.parse(source)
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
now=0
function signal()
 local s={handlers={}}
 function s:Connect(fn) local c={active=true,fn=fn}; function c:Disconnect() self.active=false end; table.insert(self.handlers,c); return c end
 function s:Fire(...) for _,c in ipairs(self.handlers) do if c.active then c.fn(...) end end end
 return s
end
local values=0
Enum=setmetatable({}, {__index=function(t,k) local v=setmetatable({}, {__index=function(t,s) values=values+1; local e={Name=s,Value=values}; rawset(t,s,e); return e end}); rawset(t,k,v); return v end})
-- Font names are strict: invalid enums must fail as they do in Roblox.
local fonts={}
for _,name in ipairs({'Gotham','GothamMedium','GothamBold','GothamBlack','Merriweather'}) do fonts[name]={Name=name} end
Enum.Font=setmetatable(fonts,{__index=function(_,key) error('Invalid Font: '..key) end})
local vec={}
vec.__index=function(v,k)
 if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+(v.Z or 0)^2) end
 if k=='Unit' then return v/v.Magnitude end
end
vec.__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=(a.Z or 0)+(b.Z or 0)},vec) end
vec.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=(a.Z or 0)-(b.Z or 0)},vec) end
vec.__mul=function(a,b) return setmetatable({X=a.X*b,Y=a.Y*b,Z=(a.Z or 0)*b},vec) end
vec.__div=function(a,b) return a*(1/b) end
Vector2={new=function(x,y) return setmetatable({X=x,Y=y},vec) end}
Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vec) end}
CFrame={lookAt=function(position,target) return {Position=position,Target=target,Lerp=function(_,other) return CFrame.lookAt(other.Position,other.Target) end} end}
Color3={fromRGB=function(r,g,b) return {r,g,b} end,new=function(r,g,b) return {r,g,b} end}
UDim={new=function(s,o) return {Scale=s,Offset=o} end}
UDim2={new=function(xs,xo,ys,yo) return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)} end}
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
math.clamp=function(v,a,b) return math.min(b,math.max(a,v)) end
nodes={}
Instance={new=function(class)
 local n={ClassName=class,Name=class,children={},Visible=true,Activated=signal(),InputBegan=signal(),FocusLost=signal(),AbsoluteSize=Vector2.new(446,32),AbsolutePosition=Vector2.new(0,0)}
 function n:GetPropertyChangedSignal(key) self.signals=self.signals or {};self.signals[key]=self.signals[key] or signal();return self.signals[key] end
 function n:IsA(kind) return self.ClassName==kind or (kind=='BasePart' and self.ClassName=='Part') end
 function n:FindFirstChild(name) return self.children[name] end
 function n:FindFirstChildOfClass(kind) for _,c in pairs(self.children) do if c:IsA(kind) then return c end end end
 function n:IsDescendantOf(p) local parent=self.Parent; while parent do if parent==p then return true end; parent=parent.Parent end; return false end
 function n:Play() self.playCount=(self.playCount or 0)+1 end
 function n:Destroy()
  self.Parent=nil; self.destroyed=true
  for _,value in pairs(self) do if type(value)=='table' and value.handlers then for _,c in ipairs(value.handlers) do c:Disconnect() end end end
  for _,child in ipairs(nodes) do if child.Parent==self then child:Destroy() end end
 end
 table.insert(nodes,n); return n
end}
workspace=Instance.new('Workspace'); workspace.Gravity=196.2; workspace.DescendantAdded=signal(); workspace.DescendantRemoving=signal()
function attach(parent,name,child) child.Name=name; child.Parent=parent; parent.children[name]=child; return child end
function makePart(parent,name,pos)
 local p=Instance.new('Part'); p.Size=Vector3.new(2,2,1);p.Transparency=1;p.Color='original';p.Material='original';p.CanCollide=true;p.Position=pos;p.CFrame={LookVector=Vector3.new(0,0,1)};p.AssemblyLinearVelocity=Vector3.new(10,0,0)
 return attach(parent,name,p)
end
function makeChar(name,x)
 local c=Instance.new('Model');c.Name=name;c.Parent=workspace
 c.root=makePart(c,'HumanoidRootPart',Vector3.new(x,0,100)); c.head=makePart(c,'Head',Vector3.new(x,2,100)); c.torso=makePart(c,'Torso',Vector3.new(x,1,100))
 c.PrimaryPart=c.root
 c.hum=attach(c,'Humanoid',Instance.new('Humanoid'));c.hum.Health=100;c.hum.MaxHealth=100;c.hum.state=Enum.HumanoidStateType.Running
 function c.hum:GetState() return self.state end
 c.effects=attach(c,'BodyEffects',Instance.new('Folder'))
 return c
end
function setFlag(c,key,val) local flag=c.effects:FindFirstChild(key);if not flag then flag=attach(c.effects,key,Instance.new('BoolValue')) end;flag.Value=val end
me={UserId=1,Name='LocalUser',DisplayName='Me',Team='Blue',Neutral=false,Character=makeChar('LocalUser',0)}
enemy={UserId=2,Name='EnemyUser',DisplayName='Opponent',Team='Red',Neutral=false,Character=makeChar('EnemyUser',2)}
friend={UserId=3,Name='FriendUser',DisplayName='Buddy',Team='Blue',Neutral=false,Character=makeChar('FriendUser',12)}
npc=makeChar('Zombie',20)
function me:WaitForChild() return {} end
function me:GetNetworkPing() return 0.2 end
players={PlayerAdded=signal(),PlayerRemoving=signal(),LocalPlayer=me,list={me,enemy,friend}}
function players:GetPlayers() return self.list end
function players:GetPlayerFromCharacter(m) for _,p in ipairs(self.list) do if p.Character==m then return p end end end
uis={InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal(),focused=false,mouse=Vector2.new(400,300)}
function uis:GetFocusedTextBox() return self.focused end
function uis:GetMouseLocation() return self.mouse end
run={Heartbeat=signal(),bindings={}}
function run:BindToRenderStep(name,priority,fn) self.bindings[name]=fn end
function run:UnbindFromRenderStep(name) self.bindings[name]=nil end
function frame(dt) for _,fn in pairs(run.bindings) do fn(dt) end end
local camera={CFrame=CFrame.lookAt(Vector3.new(0,0,0),Vector3.new(0,0,100)),ViewportSize=Vector2.new(1200,800)}
function camera:WorldToViewportPoint(pos) return Vector3.new(400+pos.X*5,300-pos.Y*5,pos.Z),pos.Z>0 end
workspace.CurrentCamera=camera
function workspace:GetDescendants() return {me.Character.hum,enemy.Character.hum,friend.Character.hum,npc.hum} end
wall=nil
function workspace:Raycast() return wall end
function typeof(v) if type(v)=='table' and v.X~=nil and v.Y~=nil and v.Z~=nil then return 'Vector3' end;return type(v) end
ColorSequence={new=function(value) return value end};NumberSequence={new=function(value) return value end}
RaycastParams={new=function() return {} end}
tween={}
function tween:Create(obj,info,props) return {Play=function() for k,v in pairs(props) do obj[k]=v end end,Cancel=function() end} end
TweenInfo={new=function(...) return {} end}
content={}; function content:PreloadAsync(items) for _,item in ipairs(items) do item.IsLoaded=true end end
lighting=Instance.new('Lighting')
local services={Players=players,UserInputService=uis,RunService=run,TweenService=tween,ContentProvider=content,Workspace=workspace,Lighting=lighting,GuiService={},ReplicatedStorage=Instance.new('Folder'),HttpService={JSONEncode=function(_,v) return py_encode(v) end,JSONDecode=function(_,v) return py_decode(v) end}}
game={GetService=function(_,name) return services[name] end}
task={pending={},spawn=function(fn) table.insert(task.pending,{at=now,fn=fn}) end,delay=function(t,fn) table.insert(task.pending,{at=now+t,fn=fn}) end,wait=function() end}
function advance(dt)
 now=now+dt
 for repeatCount=1,20 do
  local ready={};local remaining={}
  for _,item in ipairs(task.pending) do table.insert(item.at<=now and ready or remaining,item) end
  task.pending=remaining
  if #ready==0 then return end
  for _,item in ipairs(ready) do item.fn() end
 end
end
function find(name)
 for i=#nodes,1,-1 do local n=nodes[i];if n.Name==name and not n.destroyed then return n end end
 error('Missing '..name)
end
function press(key) uis.InputBegan:Fire({KeyCode=Enum.KeyCode[key],UserInputType=Enum.UserInputType.Keyboard},false) end
function release(key) uis.InputEnded:Fire({KeyCode=Enum.KeyCode[key],UserInputType=Enum.UserInputType.Keyboard}) end
''')

import json
def to_py(value):
    if hasattr(value, 'items'):
        return {k: to_py(v) for k, v in value.items()}
    return value
lua.globals().py_encode=lambda value: json.dumps(to_py(value))
lua.globals().py_decode=lambda value: lua.table_from(json.loads(value), recursive=True)
lua.execute("files={}; game.GameId=1234; function writefile(path,data) files[path]=data end; function readfile(path) assert(files[path], 'missing'); return files[path] end")
lua.execute(source)
lua.execute(r'''
advance(0);advance(0.6)
local s=EVINI.Settings
s.camEnabled=true;s.smoothing=0;s.prediction=0.1
press('L');advance(0.6)
local old=workspace.CurrentCamera.CFrame
frame(0.1);assert(workspace.CurrentCamera.CFrame==old,'never auto lock without key')
-- No target when key pressed -> no delayed acquisition.
s.fov=5;press('Q');s.fov=140;frame(0.1)
assert(workspace.CurrentCamera.CFrame==old,'empty press cannot arm deferred lock')
press('Q');frame(0.1)
assert(math.abs(workspace.CurrentCamera.CFrame.Target.X-3)<0.001,'press acquires closest')
release('Q');old=workspace.CurrentCamera.CFrame;frame(0.1)
assert(workspace.CurrentCamera.CFrame~=old,'release does not break sticky lock')
-- FOV only matters at acquisition; another player crossing center does not replace target.
uis.mouse=Vector2.new(900,700);friend.Character.head.Position=Vector3.new(0,2,100);frame(0.1)
assert(math.abs(workspace.CurrentCamera.CFrame.Target.X-3)<0.001,'retain captured target outside mouse FOV')
press('Q');old=workspace.CurrentCamera.CFrame;frame(0.1);assert(workspace.CurrentCamera.CFrame==old,'second press releases')
uis.mouse=Vector2.new(400,300);friend.Character.head.Position=Vector3.new(12,2,100)
press('Q');frame(0.1);setFlag(enemy.Character,'K.O',true);old=workspace.CurrentCamera.CFrame;frame(0.1)
assert(workspace.CurrentCamera.CFrame==old,'KO no retarget')
setFlag(enemy.Character,'K.O',false);frame(0.1);assert(workspace.CurrentCamera.CFrame==old,'revival needs new press')
press('Q');frame(0.1);press('Escape');old=workspace.CurrentCamera.CFrame;frame(0.1);assert(workspace.CurrentCamera.CFrame==old,'escape releases')
-- Auto Pred Math own formula, 80/120 ms examples and divisor direction.
s.autoPrediction=true;s.autoPredMath=250;s.autoBase=0.04
function me:GetNetworkPing() return 0.08 end
run.Heartbeat:Fire(1.1);press('Q');frame(0.1)
assert(math.abs(workspace.CurrentCamera.CFrame.Target.X-3.2)<0.001,'80ms -> 0.120 seconds')
s.autoPredMath=500;frame(0.1)
assert(math.abs(workspace.CurrentCamera.CFrame.Target.X-2.8)<0.001,'higher math lowers lead')
function me:GetNetworkPing() error('unsupported') end
run.Heartbeat:Fire(1.1);frame(0.1);assert(math.abs(workspace.CurrentCamera.CFrame.Target.X-3)<0.001,'manual fallback')
-- Occlusion pauses camera without releasing the same selected target.
wall={Instance={IsDescendantOf=function() return false end}}
local paused=workspace.CurrentCamera.CFrame
frame(0.2);assert(workspace.CurrentCamera.CFrame==paused,'wall pauses tracking')
wall=nil;frame(0.2);assert(workspace.CurrentCamera.CFrame~=paused,'visibility resumes without key')
local originalProjection=workspace.CurrentCamera.WorldToViewportPoint
workspace.CurrentCamera.WorldToViewportPoint=function() return Vector3.new(0,0,-1),false end
paused=workspace.CurrentCamera.CFrame;frame(0.2);assert(workspace.CurrentCamera.CFrame==paused,'offscreen pauses')
workspace.CurrentCamera.WorldToViewportPoint=originalProjection
frame(0.2);assert(workspace.CurrentCamera.CFrame~=paused,'same target resumes onscreen')
s.fovTransparency=0.75;frame(0.1)
local strokeFound=false
for _,n in ipairs(nodes) do if n.ClassName=='UIStroke' and n.Parent==find('FOV') then assert(n.Transparency==0.75);strokeFound=true end end
assert(strokeFound,'FOV opacity applies')
s.cycleParts=true;s.cycleInterval=0.3
local sawHead,sawTorso=false,false
for i=1,12 do frame(0.11);local y=workspace.CurrentCamera.CFrame.Target.Y;if y==2 then sawHead=true elseif y==1 then sawTorso=true end end
assert(sawHead and sawTorso,'cycles head and torso');s.cycleParts=false
for _,n in ipairs(nodes) do assert(n.ClassName~='BlurEffect','no external blur') end
-- Appearance settings, collapsed panels, names-only ESP.
press('L');advance(0.6)
find('accent').Activated:Fire();assert(s.accent=='Cinza','accent change')
local opacity=find('uiOpacity');opacity.Text='0.2';opacity.FocusLost:Fire();assert(find('StraightBody').BackgroundTransparency==0.2 and find('TopCurve').BackgroundTransparency==0.2,'opacity applies')
local scale=find('uiSize');scale.Text='0.85';scale.FocusLost:Fire()
s.reduceMotion=true
find('Calibração avançada').Activated:Fire()
s.espPlayers=true;s.espEntities=true;run.Heartbeat:Fire(0.4);frame(0.2)
local names=0
for _,n in ipairs(nodes) do
 if n.Name=='ESPName' and not n.destroyed then names=names+1 end
 assert(n.Name~='ESPBox','no ESP boxes')
end
assert(names==3,'player and NPC names')
local tabs=0;for _,n in ipairs(nodes) do if n.Name:sub(1,4)=='Tab_' then tabs=tabs+1 end end
assert(tabs==5,'five tabs with separate hitbox')
press('L');advance(0.1)
-- Basic earlier regression checks.
find('enabled').Activated:Fire();assert(enemy.Character.root.Size.X==8,'expansion')
setFlag(enemy.Character,'K.O',true);run.Heartbeat:Fire(0.1);assert(enemy.Character.root.Size.X==2,'hitbox KO restore')
setFlag(enemy.Character,'K.O',false)
press('L');advance(0.6)
find('CamKeybind').Activated:Fire();press('E');assert(find('CamKeybind').Text=='E','camera bind near camera controls')
find('Keybind').Activated:Fire();press('K');assert(find('Keybind').Text=='K','hide bind')
local box=find('SizeInput');box.Text='11.5';box.FocusLost:Fire()
local pred=find('prediction');pred.Text='0.155';pred.FocusLost:Fire()
advance(0.4)
assert(files['evini-settings-1234.json'],'automatic file save')
assert(find('Mira').Name=='Mira','combined page')
for _,n in ipairs(nodes) do assert(n.Name~='Tab_PREDICT','no separate prediction tab') end

-- Single panel, scale access and audio controls.
assert(find('HubTitle').Text=='EVINI','center title')
assert(find('BevanTitle') and not find('HubTitle').Visible,'native Bevan independent of executor')
assert(find('UnifiedPanel').ClassName=='CanvasGroup','one animated panel')
for _,name in ipairs({'Mira','Hitbox','Visual','Jogadores','Ajustes'}) do
 local scroll=find(name);local content=find(name..'Content')
 assert(content.Parent==scroll and content.Size.X.Offset==-20,'dedicated inset content')
 assert(scroll.ScrollingDirection==Enum.ScrollingDirection.Y,'no horizontal scrolling')
 assert(scroll.VerticalScrollBarInset==Enum.ScrollBarInset.Always,'scroll gutter reserved')
end
find('Tab_Jogadores').Activated:Fire()
assert(find('Jogadores').Visible and not find('Mira').Visible,'tab changes scroll container')

local oldScale=find('Hub').Size.X.Offset
find('SmallerUI').Activated:Fire();assert(find('Hub').Size.X.Offset<oldScale,'shrink immediately')
find('LargerUI').Activated:Fire();assert(math.abs(find('Hub').Size.X.Offset-oldScale)<0.001,'grow immediately')
find('ResetUISize').Activated:Fire();assert(s.uiSize==1,'reset size')
local sound=find('UIClick');local played=sound.playCount or 0
find('Tab_Visual').Activated:Fire();assert(sound.playCount==played+1,'click plays shared sound')
s.uiSounds=false;played=sound.playCount
find('Tab_Mira').Activated:Fire();assert(sound.playCount==played,'muted buttons')
s.uiSounds=true
-- Player selection immediately restores excluded hitboxes and gates camera capture.
find('DeselectAll').Activated:Fire()
assert(enemy.Character.root.Size.X==2 and friend.Character.root.Size.X==2,'bulk restore')
assert(not s.playerSelection['2'] and not s.playerSelection['3'],'bulk selection off')
find('Select_2').Activated:Fire()
assert(enemy.Character.root.Size.X==11.5 and friend.Character.root.Size.X==2,'only selected player expanded')
press('K');advance(0.6);press('E');frame(0.2)
local cameraBefore=workspace.CurrentCamera.CFrame
find('Select_2').Activated:Fire();frame(0.2)
assert(workspace.CurrentCamera.CFrame==cameraBefore,'deselection releases active camera target')
find('SelectAll').Activated:Fire();assert(s.playerSelection['2'] and s.playerSelection['3'],'select all')
-- Search does not change selection and restores layout when cleared.
local search=find('PlayerSearch');search.Text='Enemy';search:GetPropertyChangedSignal('Text'):Fire()
assert(find('Player_2').Visible and not find('Player_3').Visible,'roster search')
search.Text='';search:GetPropertyChangedSignal('Text'):Fire()
-- ESP retains native labels through KO instead of reallocating every frame.
local before=#nodes
setFlag(enemy.Character,'K.O',true);frame(0.2);setFlag(enemy.Character,'K.O',false);frame(0.2)
assert(#nodes==before,'no ESP churn on KO recovery')
-- Beam works from head without a Tool if replicated MousePos exists.
s.aimViewer=true
local mousePos=attach(enemy.Character.effects,'MousePos',Instance.new('Vector3Value'));mousePos.Value=Vector3.new(10,5,150)
frame(0.2)
assert(find('AimRay').Enabled and find('AimPoint').Transparency==0,'replicated aim without tool')
assert(find('AimPoint').Color[1]==255 and find('AimPoint').Color[2]==48,'red endpoint')
assert(find('AimRay').Color[1]==255,'red beam')
local allocations=#nodes
for i=1,100 do frame(1/60) end
assert(#nodes==allocations,'reuse viewer effects')
s.hideVisuals=true;frame(0.2);assert(not find('AimRay').Enabled,'hide effects')
s.hideVisuals=false;s.aimEstimate=true;frame(0.2)
assert(find('AimRay').Enabled,'fallback head direction without weapon')
s.aimEstimate=false;s.aimViewer=false;frame(0.2);assert(not find('AimRay').Enabled,'disable viewer')
-- Initial roster is silent; real joins/leaves get bounded notices and disconnected rows.
s.newPlayersSelected=false
local newcomer={UserId=4,Name='NewUser',DisplayName='New',Character=makeChar('New',30)}
table.insert(players.list,newcomer);players.PlayerAdded:Fire(newcomer)
assert(not s.playerSelection['4'],'new player default off')
assert(find('ServerNotice').Position.X.Offset==18,'upper left notices')
local row=find('Player_4');local check=find('Select_4');players.PlayerRemoving:Fire(newcomer);table.remove(players.list)
assert(row.destroyed and not check.Activated.handlers[1].active,'remove row disconnects handler')
for i=5,15 do players.PlayerAdded:Fire({UserId=i,Name='Join'..i,DisplayName='Join'..i}) end
local noticeCount=0;for _,n in ipairs(nodes) do if n.Name=='ServerNotice' and not n.destroyed then noticeCount=noticeCount+1 end end
assert(noticeCount==4,'bounded notice stack')
run.Heartbeat:Fire(4.1)
for _,n in ipairs(nodes) do if n.Name=='ServerNotice' then assert(n.destroyed,'notice expiry') end end
press('K');advance(0.6)
s.playerSelection['3']=false;EVINI.Save()

-- Animation reversal, close retains enabled preferences and removes the effects.
press('K');press('K');advance(0.6);assert(find('Hub').Visible,'reverse animation')
find('Close').Activated:Fire();advance(0.7)
assert(EVINI==nil and run.bindings.EVINI_Camera==nil,'cleanup')
assert(enemy.Character.root.Size.X==2,'restored on close')
''')
saved=json.loads(lua.globals().files['evini-settings-1234.json'])
assert saved['settings']['playerSelection']['3'] is False
assert saved['settings']['accent']=='Cinza'
assert saved['settings']['uiOpacity']==0.2
assert saved['settings']['reduceMotion'] is True
assert saved['settings']['size']==11.5
assert saved['settings']['prediction']==0.155
assert saved['settings']['camKeyName']=='E'
assert saved['settings']['hideKeyName']=='K'
assert saved['settings']['enabled'] is True
assert saved['settings']['camEnabled'] is True
assert 'latched' not in saved['settings']
lua.execute(source)
lua.execute(r'''
advance(0);advance(0.6)
assert(EVINI.Settings.size==11.5 and EVINI.Settings.prediction==0.155,'load settings')
assert(EVINI.Settings.playerSelection['3']==false and friend.Character.root.Size.X==2,'selection restored by user id')
assert(find('CamKeybind').Text=='E' and find('Keybind').Text=='K','restore bindings')
press('K');advance(0.6);local old=workspace.CurrentCamera.CFrame;frame(0.1)
assert(workspace.CurrentCamera.CFrame==old,'reloaded settings never restore active lock')
EVINI.Destroy()
files['evini-settings-1234.json']='corrupted json'
''')
lua.execute(source)
lua.execute("assert(EVINI.Settings.size==8, 'corruption falls back'); EVINI.Destroy(); writefile=nil; readfile=nil")
lua.execute(source)
lua.execute("advance(0);advance(0.6); assert(EVINI.Save()==false,'unsupported storage does not crash'); EVINI.Destroy()")
print('PASS: roster selection, notices, native ESP reuse, red aim beams without tool, persistence and cleanup; key-only capture, sticky target, release, no deferred lock or automatic retarget, KO, Escape, own Auto Pred Math, unavailable ping fallback, autosave, reloading preferences/keybinds, no restored latch, corrupt file fallback, no file API, animation and shutdown.')
