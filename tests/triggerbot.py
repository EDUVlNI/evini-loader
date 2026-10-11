"""Trigger timing, input lifetime and filtering tests in a simulated client."""
import ast
import json
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
shots=0;nativeShots=0;nativeActive=false
function mouse1click() shots=shots+1 end
uis.WindowFocused=signal();uis.mouseDown=false
function uis:IsMouseButtonPressed() return self.mouseDown end
gun=attach(me.Character,'Gun',Instance.new('Tool'));gun.Enabled=true
function gun:Activate() nativeShots=nativeShots+1;nativeActive=true end
function gun:Deactivate() nativeActive=false end
files={};function writefile(p,d) files[p]=d end;function readfile(p) assert(files[p]);return files[p] end
function tick(dt) run.Heartbeat:Fire(dt);frame(dt);advance(dt) end
''')
source=(base.parent/'main.lua').read_text();lua.execute(source)
lua.execute(r'''
advance(.6)
local s=EVINI.Settings
assert(not s.triggerEnabled,'off by default')
assert(s.triggerMode=='auto' and s.triggerDetect=='body','body/auto defaults')
s.triggerMode='hold';s.triggerDetect='square';s.triggerRepeat=true;s.triggerDelay=.08
assert(find('Tab_Triggerbot'),'own tab')
find('triggerEnabled').Activated:Fire();press('T');tick(.2);assert(shots==0,'cannot arm while UI open')
press('L');tick(.2);assert(shots==0,'closing UI never auto-arms')
local camera=workspace.CurrentCamera.CFrame
press('T');tick(.04);tick(.04);assert(shots==0,'reaction delay')
tick(.05);assert(shots==1,'shoot once after stable delay')
assert(workspace.CurrentCamera.CFrame==camera,'does not move camera')
tick(.02);assert(shots==1,'rate limit');tick(.2);assert(shots==2,'repeat while held')
release('T');tick(.5);assert(shots==2,'release stops')
assert(find('TriggerSquare').Size.X.Offset==32,'square size applied')
-- Square bounds are independent from hitbox geometry.
s.triggerSize=4;press('T');tick(.2);tick(.2);assert(shots==2,'outside small square')
s.triggerSize=40;tick(.2);tick(.2);assert(shots==3,'larger selection area works')
assert(enemy.Character.root.Size.X==2 and enemy.Character.torso.Size.X==2,'no hitbox changes')
release('T')
wall={Instance={IsDescendantOf=function() return false end}};press('T');tick(.2);tick(.2);assert(shots==3,'wall blocks')
s.triggerWalls=false;tick(.2);tick(.2);assert(shots==4,'wall option changes trigger filtering')
s.triggerWalls=true;wall=nil;release('T')
s.playerSelection['2']=false;press('T');tick(.2);tick(.2);assert(shots==4,'unselected ignored');s.playerSelection['2']=true
setFlag(enemy.Character,'K.O',true);tick(.2);assert(shots==4,'KO ignored');setFlag(enemy.Character,'K.O',false)
enemy.Character.hum.Health=0;tick(.2);assert(shots==4,'dead target ignored');enemy.Character.hum.Health=100
s.triggerTeam=true;enemy.Team=me.Team;tick(.2);assert(shots==4,'team ignored');enemy.Team='Red';s.triggerTeam=false
uis.mouseDown=true;tick(.2);assert(shots==4,'manual click not doubled');uis.mouseDown=false
uis.focused=true;tick(.2);uis.focused=false;tick(.2);tick(.2);assert(shots==4,'typing disarms, no deferred resume')
press('T');tick(.2);tick(.2);assert(shots==5,'explicit rearm')
uis.WindowFocusReleased:Fire();tick(.2);assert(shots==5,'focus loss stops');uis.WindowFocused:Fire();tick(.2);assert(shots==5,'focus return never auto-arms')
-- Toggle mode, escape, menu, own death and tool gating.
s.triggerMode='toggle';press('T');release('T');tick(.2);tick(.2);assert(shots==6,'toggle survives key release')
press('T');tick(.2);assert(shots==6,'second toggle stops')
press('T');press('Escape');tick(.2);assert(shots==6,'escape stops')
press('T');press('L');tick(.2);assert(shots==6,'menu disarms')
find('TriggerKeybind').Activated:Fire();press('Q');assert(find('TriggerKeybind').Text=='Em uso','prevent conflicting camera bind');press('R');assert(s.triggerKeyName=='R','editable key')
find('triggerSize').Text='44';find('triggerSize').FocusLost:Fire();assert(s.triggerSize==44,'numeric square input')
press('L');press('R');me.Character.hum.Health=0;tick(.2);assert(shots==6,'own death stops');me.Character.hum.Health=100;tick(.2);assert(shots==6,'revival not auto armed')
me.Character.children.Gun=nil;gun.Parent=nil;press('R');tick(.2);tick(.2);assert(shots==6,'no Tool no click');press('R')
gun.Parent=me.Character;me.Character.children.Gun=gun
-- Missing click capability is diagnosed; native Tool pulse is bounded.
mouse1click=nil;press('R');tick(.2);assert(find('TriggerStatus').Text:find('Executor sem clique',1,true),'unsupported click status');press('R')
s.triggerMethod='tool';press('R');tick(.1);frame(.1);assert(nativeShots==1 and nativeActive,'native activation')
advance(.03);assert(not nativeActive,'native pulse releases')
frame(.2);assert(nativeActive,'next native pulse');press('Escape');assert(not nativeActive,'escape releases owned activation immediately')
press('R');frame(.1);frame(.1);assert(nativeActive,'native pulse before shutdown')
EVINI.Save();EVINI.Destroy();assert(not nativeActive and not run.bindings.EVINI_Trigger,'shutdown releases and unbinds')
advance(1);assert(not nativeActive,'no delayed reactivation')
''')
lua.execute(source)
lua.execute(r'''
advance(.6)
assert(EVINI.Settings.triggerKeyName=='R' and EVINI.Settings.triggerSize==44,'settings persisted')
local count=nativeShots;press('L');tick(.3);tick(.3);assert(nativeShots==count,'saved enabled setting never restores armed state')
EVINI.Destroy()
''')
print('PASS: trigger hold/toggle, stable delay/rate, square bounds, filters, key conflicts, focus/menu/death/Tool gates, native release, persistence and cleanup.')
