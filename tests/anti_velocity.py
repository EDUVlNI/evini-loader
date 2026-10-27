"""Velocity pulse lifecycle simulation; does not establish replication or anti-aim effectiveness."""
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
lua.execute("game.GameId=1234;files={};function writefile(p,d) files[p]=d end;function readfile(p) assert(files[p]);return files[p] end")
source=(base.parent/'main.lua').read_text();lua.execute(source)
lua.execute(r'''
advance(.6)
local s=EVINI.Settings;local root=me.Character.root;local original=root.AssemblyLinearVelocity
assert(not s.antiEnabled and s.aimViewer==nil,'starts off and viewer removed')
press('C');run.Heartbeat:Fire(.01)
assert(root.AssemblyLinearVelocity.X==68756 and root.AssemblyLinearVelocity.Y==100 and root.AssemblyLinearVelocity.Z==-344,'supplied values applied')
run.bindings.EVINI_AntiRestore(.01);assert(root.AssemblyLinearVelocity==original,'render restores captured velocity')
run.Heartbeat:Fire(.01);run.Heartbeat:Fire(.01);run.bindings.EVINI_AntiRestore(.01)
assert(root.AssemblyLinearVelocity==original,'duplicate heartbeat cannot capture injected velocity')
run.Heartbeat:Fire(.01);press('C');assert(root.AssemblyLinearVelocity==original and not s.antiEnabled,'key disables and immediately restores')
press('C');run.Heartbeat:Fire(.01);press('K');assert(root.AssemblyLinearVelocity==original,'opening UI restores')
advance(.4);run.Heartbeat:Fire(.01);assert(root.AssemblyLinearVelocity==original,'no pulse while menu open')
find('AntiKeybind').Activated:Fire();press('T');assert(find('AntiKeybind').Text=='Em uso','conflict rejected');press('V');assert(s.antiKeyName=='V','custom key')
find('antiX').Text='42';find('antiX').FocusLost:Fire();press('K');advance(.4)
run.Heartbeat:Fire(.01);assert(root.AssemblyLinearVelocity.X==42,'custom vector')
uis.WindowFocusReleased:Fire();assert(root.AssemblyLinearVelocity==original,'focus loss restores')
run.Heartbeat:Fire(.01);assert(root.AssemblyLinearVelocity==original,'focus gates pulse');uis.WindowFocused:Fire()
run.Heartbeat:Fire(.01);me.Character.hum.Health=0;run.Heartbeat:Fire(.01)
assert(root.AssemblyLinearVelocity==original,'death restores');me.Character.hum.Health=100
run.Heartbeat:Fire(.01);local old=me.Character;me.Character=makeChar('Respawn',0);local newVelocity=me.Character.root.AssemblyLinearVelocity
run.Heartbeat:Fire(.01);assert(old.root.AssemblyLinearVelocity==original,'old character restored')
run.bindings.EVINI_AntiRestore(.01);assert(me.Character.root.AssemblyLinearVelocity==newVelocity,'new character restores its own velocity')
run.Heartbeat:Fire(.01);EVINI.Save();EVINI.Destroy()
assert(me.Character.root.AssemblyLinearVelocity==newVelocity and not run.bindings.EVINI_AntiRestore,'shutdown restores and unbinds')
''')
lua.execute(source)
lua.execute("advance(.6);assert(not EVINI.Settings.antiEnabled and EVINI.Settings.antiX==42 and EVINI.Settings.antiKeyName=='V','reload preserves values but starts disabled');EVINI.Destroy()")
print('PASS: velocity apply/restore, repeated heartbeat, disable, UI/focus/death/respawn, key conflicts, custom values and cleanup; live efficacy unverified.')
