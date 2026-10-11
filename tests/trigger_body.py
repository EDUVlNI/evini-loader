"""Body-under-cursor detection tests; fixture ray hits stand in for Roblox physics."""
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
game.GameId=1234;game.PlaceId=0
uis.WindowFocused=signal();uis.mouseDown=false
function uis:IsMouseButtonPressed() return self.mouseDown end
function workspace.CurrentCamera:ViewportPointToRay(x,y)
 lastRayX=x;lastRayY=y;return {Origin=self.CFrame.Position,Direction=Vector3.new(x-400,300-y,100).Unit}
end
local bodyRaycast=workspace.Raycast
function workspace:Raycast(origin,direction,params)
 lastParams=params
 if params.FilterType==Enum.RaycastFilterType.Exclude and wall then return wall end
 return bodyHit and {Instance=bodyHit} or nil
end
arm=makePart(enemy.Character,'LeftUpperArm',Vector3.new(100,1,100))
leg=makePart(enemy.Character,'LeftLowerLeg',Vector3.new(100,-2,100))
hat=attach(enemy.Character,'Hat',Instance.new('Accessory'));hatHandle=makePart(hat,'Handle',Vector3.new(100,3,100))
gun=attach(me.Character,'Gun',Instance.new('Tool'));gun.Enabled=true
shots=0;presses=0;releases=0
function mouse1click() shots=shots+1 end
function mouse1press() presses=presses+1 end
function mouse1release() releases=releases+1 end
function tick(dt) run.Heartbeat:Fire(dt);frame(dt);advance(dt) end
files={};function writefile(p,d) files[p]=d end;function readfile(p) assert(files[p]);return files[p] end
''')
source=(base.parent/'main.lua').read_text();lua.execute(source)
lua.execute(r'''
advance(.6)
local s=EVINI.Settings
assert(s.triggerDetect=='body' and s.triggerMode=='auto' and s.triggerDelay==0 and not s.triggerRepeat,'new body defaults')
find('triggerEnabled').Activated:Fire();bodyHit=arm;uis.mouse=Vector2.new(555,277)
tick(.2);assert(shots==0 and find('TriggerHUD').Visible,'menu paused with visible status')
press('L');tick(.2)
assert(shots==1,'automatic click at arm without activation key or center proximity')
assert(lastRayX==555 and lastRayY==277,'ray originates from cursor coordinates')
assert(find('TriggerSquare').Visible and find('TriggerHUD').Visible,'both indicators shown')
tick(.4);bodyHit=leg;tick(.2);assert(shots==1,'one click per character entry, not every limb')
gun.Enabled=false;tick(.2);gun.Enabled=true;tick(.2);assert(shots==1,'weapon cooldown does not invent new body entry')
bodyHit=nil;tick(.2);bodyHit=leg;tick(.2);assert(shots==2,'leaving and reentering fires again')
bodyHit=friend.Character.head;tick(.2);assert(shots==3,'moving onto a different player fires')
bodyHit=hatHandle;tick(.2);assert(shots==3,'accessory is not body')
bodyHit=arm;wall={Instance=Instance.new('Part')};tick(.2);assert(shots==3,'wall blocks direct body ray')
s.triggerWalls=false;tick(.2);assert(shots==4 and lastParams.FilterType==Enum.RaycastFilterType.Include,'walls-off restricts ray to eligible characters')
wall=nil;s.triggerWalls=true;bodyHit=nil;tick(.2)
s.playerSelection['2']=false;bodyHit=leg;tick(.2);assert(shots==4,'player exclusion applies');s.playerSelection['2']=true
setFlag(enemy.Character,'K.O',true);tick(.2);assert(shots==4,'KO rejected');setFlag(enemy.Character,'K.O',false)
press('Escape');tick(.2);assert(shots==4,'escape suspends automatic mode');press('T');tick(.2);assert(shots==5,'T explicitly resumes')
uis.WindowFocusReleased:Fire();uis.WindowFocused:Fire();tick(.2);assert(shots==5,'focus return stays suspended');press('T');tick(.2);assert(shots==6,'explicit focus resume')
-- If atomic clicks are unavailable, a bounded press/release pair is used.
mouse1click=nil;bodyHit=nil;tick(.2);bodyHit=arm;frame(.2)
assert(presses==1 and releases==0,'press fallback used')
press('Escape');assert(releases==1,'Escape releases injected press immediately');advance(.1);assert(releases==1,'stale scheduled release cancelled')
press('T');bodyHit=nil;tick(.2);bodyHit=arm;tick(.2);assert(presses==2 and releases==2,'automatic press releases after bounded pulse')
mouse1press=nil;mouse1release=nil;bodyHit=nil;tick(.2);bodyHit=arm;tick(.2)
assert(find('TriggerHUD').Text:find('Executor sem clique',1,true),'missing capability visible outside hub')
EVINI.Save();EVINI.Destroy()
-- Old v4.4 preferences migrate to the requested defaults without changing hitboxes.
files['evini-settings-1234.json']=py_encode({version=1,settings={triggerMode='hold',triggerDelay=.08,triggerEnabled=true,painSize=13,painEnabled=false}})
''')
lua.execute(source)
lua.execute(r'''
assert(EVINI.Settings.triggerMode=='auto' and EVINI.Settings.triggerDetect=='body' and EVINI.Settings.triggerDelay==0,'old defaults migrated')
assert(not EVINI.Settings.triggerEnabled and EVINI.Settings.painSize==13,'migration leaves Painhood preference intact and starts disarmed')
EVINI.Destroy()
''')
print('PASS: real body ray selection, automatic activation, one click per entry, cooldown preservation, HUD, walls/filters, bounded mouse fallback and migration.')
