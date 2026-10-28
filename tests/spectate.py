"""Spectate lifecycle/selection tests using a simulated Roblox client, never remote code."""
import ast,json
from pathlib import Path
from lupa import LuaRuntime
base=Path(__file__).resolve().parent
module=ast.parse((base/'regression.py').read_text())
fixture=next(n.value.args[0].value for n in module.body if isinstance(n,ast.Expr) and isinstance(n.value,ast.Call) and isinstance(n.value.func,ast.Attribute) and n.value.func.attr=='execute' and n.value.args and isinstance(n.value.args[0],ast.Constant))
lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(fixture)
def to_py(v):return {k:to_py(x) for k,x in v.items()} if hasattr(v,'items') else v
lua.globals().py_encode=lambda v:json.dumps(to_py(v))
lua.globals().py_decode=lambda v:lua.table_from(json.loads(v),recursive=True)
lua.execute(r'''
CFrame.new=function(v) return {Position=v} end
local nativeType=typeof
function typeof(v) if type(v)=='table' and v.Position and not v.X then return 'CFrame' end;return nativeType(v) end
function setupCamera(c)
 c.Parent=workspace;c.CameraSubject=me.Character.hum;c.CameraType=Enum.CameraType.Custom;c.FieldOfView=73;c.Focus=CFrame.new(Vector3.new(0,0,10))
 return c
end
setupCamera(workspace.CurrentCamera)
originalCamera=workspace.CurrentCamera;originalFrame=originalCamera.CFrame;originalFocus=originalCamera.Focus
originalSubject=originalCamera.CameraSubject
function tick(dt) advance(dt);run.Heartbeat:Fire(dt);frame(dt) end
function activeValueConnections(v)
 local n=0;local sig=v:GetPropertyChangedSignal('Value')
 for _,c in ipairs(sig.handlers) do if c.active then n=n+1 end end
 return n
end
game.GameId=1234;files={};function writefile(p,d) files[p]=d end;function readfile(p) assert(files[p]);return files[p] end
''')
source=(base.parent/'main.lua').read_text();lua.execute(source)
lua.execute(r'''
tick(.6)
local v=EVINI.Spectate;local s=EVINI.Settings
assert(not s.viewerEnabled,'no automatic observation')
assert(v.Search(' @EnemyUser ')[1]==enemy,'username normalization')
assert(v.Search('Opponent')[1]==enemy,'display name')
assert(v.Search('nemy')[1]==enemy,'partial username')
assert(v.Search('ppon')[1]==enemy,'partial display')
assert(#v.Search('')==2,'all remote players in search')
friend.DisplayName='Opponent';assert(#v.Search('opponent')==2,'duplicate display names retained')
assert(not v.Select('opponent') and not s.viewerEnabled,'ambiguous query cannot silently choose player')
assert(v.Select('@enemyuser') and s.viewerEnabled,'exact username wins')
assert(not v.Select('Opponent') and s.viewerEnabled,'ambiguous search keeps current observation')
assert(find('SpectateSearchResult').Text:find('2 correspondências',1,true),'ambiguous result stays in selector')
tick(.01)
assert(originalCamera.CameraType==Enum.CameraType.Scriptable and originalCamera.CameraSubject==originalSubject,'owns local camera')
assert(v.Status():find('independente',1,true),'approximate spectate labelled')
assert(find('SpectateNotice').Visible,'identity/approximation notice remains visible')
local before=originalCamera.CFrame.Position
local head=enemy.Character.head
head.Position=Vector3.new(12,4,100);enemy.Character.root.CFrame.LookVector=Vector3.new(1,0,0)
tick(.01)
assert(originalCamera.CFrame.Position.X==12 and math.abs(originalCamera.CFrame.Position.Y-4.15)<.001,'follows movement and orientation')
-- No new instances while following; selected identity is never a DisplayName lookup.
local count=#nodes;for i=1,120 do tick(1/120) end;assert(#nodes==count,'no per-frame objects')
assert(v.SelectUserId(3));tick(.01);assert(originalCamera.CameraSubject==originalSubject,'switch by UserId without restart')
assert(not v.SelectUserId(999));tick(.01);assert(originalCamera.CameraSubject==originalSubject,'invalid selection keeps current subject')
assert(v.SelectUserId(2));s.aimViewer=true;tick(.01)
assert(v.Status():find('sem dado',1,true),'missing aim is explicitly estimated')
assert(not find('AimViewerLine').Enabled,'no fake replicated dot')
local source=attach(enemy.Character.effects,'MousePos',Instance.new('Vector3Value'));source.Value=Vector3.new(30,20,160)
tick(.21)
assert(v.Status():find('sem dado',1,true),'initial replicated data does not imply freshness')
assert(activeValueConnections(source)==1,'one source listener')
source.Value=Vector3.new(40,30,170);source:GetPropertyChangedSignal('Value'):Fire();tick(.01)
assert(v.Status():find('atualizado',1,true),'replicated point labelled separately from approximate camera')
assert(find('Destination').Position==source.Value and find('AimViewerLine').Enabled,'uses replicated point continuously')
tick(.8);assert(v.Status():find('sem dado',1,true) and not find('AimViewerLine').Enabled,'stale point falls back explicitly')
source.Value=Vector3.new(0/0,0,0);source:GetPropertyChangedSignal('Value'):Fire();tick(.01)
assert(v.Status():find('sem dado',1,true),'NaN rejected')
source.Value=Vector3.new(1e6,0,0);source:GetPropertyChangedSignal('Value'):Fire();tick(.01)
assert(v.Status():find('sem dado',1,true),'implausible range rejected')
source.Value=Vector3.new(40,30,170);source:GetPropertyChangedSignal('Value'):Fire();tick(.01)
-- Repeated target switching disconnects the old source and keeps only one listener.
for i=1,20 do v.SelectUserId(3);tick(.01);assert(activeValueConnections(source)==0);v.SelectUserId(2);tick(.21);assert(activeValueConnections(source)==1) end
-- Replace streamed/recreated aim source and verify only the new value remains connected.
source.Parent=nil;enemy.Character.effects.children.MousePos=nil
local replacementSource=attach(enemy.Character.effects,'MousePosition',Instance.new('CFrameValue'));replacementSource.Value=CFrame.new(Vector3.new(70,25,180))
tick(.21);assert(activeValueConnections(source)==0 and activeValueConnections(replacementSource)==1,'replaced source disconnects old listener')
replacementSource:GetPropertyChangedSignal('Value'):Fire();tick(.01)
assert(find('Destination').Position==replacementSource.Value.Position and find('AimViewerLine').Enabled,'CFrame source is supported')
replacementSource.Parent=nil;enemy.Character.effects.children.MousePosition=nil;tick(.01)
assert(activeValueConnections(replacementSource)==0,'removed source disconnects')
v.Stop();assert(originalCamera.CameraType==Enum.CameraType.Custom and originalCamera.CameraSubject==originalSubject,'restore type/subject')
assert(originalCamera.CFrame==originalFrame and originalCamera.Focus==originalFocus and originalCamera.FieldOfView==73,'restore transform/focus/FOV from first camera claim')
assert(activeValueConnections(source)==0 and not find('SpectateNotice').Visible,'stop clears source and notice')
-- Camera replacement restores old camera, then independently owns/restores the replacement.
v.SelectUserId(2);tick(.01)
local replacement=setupCamera({CFrame=CFrame.lookAt(Vector3.new(3,2,1),Vector3.new(0,0,0)),ViewportSize=Vector2.new(1200,800),WorldToViewportPoint=originalCamera.WorldToViewportPoint})
local replacementFrame=replacement.CFrame
workspace.CurrentCamera=replacement;tick(.01)
assert(originalCamera.CFrame==originalFrame and originalCamera.CameraType==Enum.CameraType.Custom,'restore replaced camera')
assert(replacement.CameraType==Enum.CameraType.Scriptable,'claim replacement')
v.Stop();assert(replacement.CFrame==replacementFrame and replacement.CameraType==Enum.CameraType.Custom,'restore replacement')
-- Death returns camera temporarily; respawn of same selected UserId resumes.
v.SelectUserId(2);tick(.01);enemy.Character.hum.Health=0;tick(.01)
assert(replacement.CameraType==Enum.CameraType.Custom and s.viewerEnabled,'death waits without staying on corpse')
assert(v.Status():find('renascimento',1,true),'waiting state')
local old=enemy.Character;enemy.Character=makeChar('NewEnemy',30);tick(.01)
assert(replacement.CameraType==Enum.CameraType.Scriptable and activeValueConnections(source)==0,'respawn follows new character')
-- Cam-lock and trigger must not compete while viewing.
s.camEnabled=true;s.smoothing=0;press('Q');tick(.01)
assert(replacement.CameraType==Enum.CameraType.Scriptable,'camera lock cannot replace spectate')
s.triggerEnabled=true
local unchangedVelocity=me.Character.root.AssemblyLinearVelocity;tick(.1)
assert(EVINI.GetTriggerStatus()=='Pausado · Spectate ativo','trigger is explicitly paused')
assert(me.Character.root.AssemblyLinearVelocity==unchangedVelocity,'observation never modifies velocity')
s.triggerEnabled=false
-- UI path and live roster selection.
press('K');tick(.4);find('Tab_Visual').Activated:Fire();tick(.3)
find('SpectateSearch').Text='FriendUser';find('SpectateSelect').Activated:Fire();tick(.01)
assert(replacement.CameraType==Enum.CameraType.Scriptable,'UI query observes target')
find('SpectateRoster').Activated:Fire();assert(find('Jogadores').Visible,'reuse roster page')
find('Observe_2').Activated:Fire();tick(.01);assert(replacement.CameraType==Enum.CameraType.Scriptable,'roster selects correct Player')
players.PlayerRemoving:Fire(enemy);table.remove(players.list,2);tick(.01)
assert(not s.viewerEnabled and replacement.CameraType==Enum.CameraType.Custom,'departure stops/restores')
assert(not v.SelectUserId(2),'departed UserId cannot resolve')
assert(#v.Search('enemy')==0,'departed absent from search')
-- Original local subject destroyed during observation: recover current local humanoid.
v.SelectUserId(3);tick(.01);local oldLocal=me.Character;oldLocal.hum.Parent=nil;me.Character=makeChar('LocalRespawn',0)
v.Stop();assert(replacement.CameraSubject==me.Character.hum,'fallback to new local humanoid')
v.SelectUserId(3);tick(.01);press('Escape');assert(not s.viewerEnabled and replacement.CameraType==Enum.CameraType.Custom,'escape exits')
v.SelectUserId(3);tick(.01);find('StopSpectate').Activated:Fire();assert(not s.viewerEnabled,'overlay stop button')
v.SelectUserId(3);tick(.01);EVINI.Destroy();assert(replacement.CameraType==Enum.CameraType.Custom,'destroy restores')
assert(not run.bindings.EVINI_Camera,'no render connection leak')
''')
lua.execute(source)
lua.execute("tick(.6);assert(not EVINI.Settings.viewerEnabled,'reload does not resume observation');EVINI.Destroy()")
print('PASS: username/display/partial/duplicate identity, UI + roster selection, switching, approximate vs replicated/stale/invalid aim, frame reuse, source cleanup, death/respawn/leave, camera replacement/restoration, Escape/stop/destroy/reload.')
