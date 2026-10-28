"""Behavioral regression: local camera input, source validation, beam lifecycle and hover isolation."""
import ast,json
from pathlib import Path
from lupa import LuaRuntime
base=Path(__file__).resolve().parent
m=ast.parse((base/'regression.py').read_text())
f=next(n.value.args[0].value for n in m.body if isinstance(n,ast.Expr) and isinstance(n.value,ast.Call) and isinstance(n.value.func,ast.Attribute) and n.value.func.attr=='execute' and n.value.args and isinstance(n.value.args[0],ast.Constant))
lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(f)
lua.execute('''
function tick(dt) advance(dt);frame(dt) end
workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
workspace.CurrentCamera.CameraSubject=me.Character.hum
workspace.CurrentCamera.Focus=CFrame.new(Vector3.new(0,0,0))
uis.MouseBehavior=Enum.MouseBehavior.Default;uis.MouseIconEnabled=true
original=workspace.CurrentCamera.CFrame
stages={}
task.wait=function()
 for _,n in ipairs(nodes) do if n.Name=='LoadingProgress' then stages[#stages+1]=n.Size.X.Scale end end
end
''')
lua.execute((base.parent/'main.lua').read_text())
lua.execute('''
tick(1)
assert(stages[1]==0 and stages[#stages]==1,'real startup milestones begin zero and reach one')
for i=2,#stages do assert(stages[i]>=stages[i-1],'progress monotonic') end
for _,n in ipairs(nodes) do if n.Name=='Initialization' then assert(n.destroyed,'loading overlay destroyed') end end
assert(not find('Hub').Visible,'startup ends closed')
assert(EVINI.Settings.antiEnabled==nil and run.bindings.EVINI_AntiRestore==nil,'anti aim fully removed')
local v,s=EVINI.Spectate,EVINI.Settings
assert(v.Search('EnemyUser')[1]==enemy and v.Search('Opponent')[1]==enemy)
assert(v.SelectUserId(2));tick(.02)
local c=workspace.CurrentCamera
assert(c.CameraType==Enum.CameraType.Scriptable,'scriptable camera')
local before=c.CFrame.Target-c.CFrame.Position
uis.delta=Vector2.new(40,-20);tick(.02);uis.delta=Vector2.new(0,0)
local after=c.CFrame.Target-c.CFrame.Position
assert(math.abs(after.X-before.X)>.01,'mouse changes direction')
enemy.Character.head.CFrame.LookVector=Vector3.new(1,0,0)
enemy.Character.root.CFrame.LookVector=Vector3.new(1,0,0)
local pos=c.CFrame.Position
enemy.Character.head.Position=enemy.Character.head.Position+Vector3.new(4,3,2);tick(.02)
local direction=c.CFrame.Target-c.CFrame.Position
assert(math.abs(direction.X-after.X)<.0001,'target rotation cannot turn spectator')
assert(math.abs(c.CFrame.Position.X-pos.X-4)<.0001,'camera follows position')
assert(uis.MouseBehavior==Enum.MouseBehavior.LockCenter,'free-look captures mouse')
s.aimViewer=true;tick(.02)
local beam=find('AimViewerLine');assert(not beam.Enabled,'no guessed aim line')
local source=attach(enemy.Character.effects,'MousePos',Instance.new('Vector3Value'));source.Value=Vector3.new(30,20,160)
tick(.3);assert(not beam.Enabled,'unconfirmed initial value not presented as real-time')
source:GetPropertyChangedSignal('Value'):Fire();tick(.01)
assert(beam.Enabled and beam.Width0==.035,'valid updated data renders thin beam')
assert(find('Destination').Position==source.Value,'beam ends at reported target')
find('aimViewer').Activated:Fire();assert(not beam.Enabled,'toggle removes line immediately')
find('aimViewer').Activated:Fire();tick(.01);assert(beam.Enabled)
assert(v.SelectUserId(3));assert(not beam.Enabled,'switch immediately clears old line');tick(.01)
assert(v.SelectUserId(2));tick(.3);source:GetPropertyChangedSignal('Value'):Fire();tick(.01)
assert(beam.Enabled);tick(.8);assert(not beam.Enabled,'stale source hidden')
v.Stop();assert(c.CFrame==original and c.CameraType==Enum.CameraType.Custom,'restores camera snapshot')
assert(uis.MouseBehavior==Enum.MouseBehavior.Default and uis.MouseIconEnabled,'restores mouse')
press('K');tick(.7)
local first,second=find('Tab_Mira'),find('Tab_Hitbox')
first.MouseEnter:Fire();uis.mouse=Vector2.new(100,20)
for i=1,30 do frame(1/60) end
assert(math.abs(find('Magnetic_Mira').Rotation)>.01)
assert(find('Magnetic_Hitbox').Rotation==0,'only entered button responds')
first.MouseLeave:Fire();second.MouseEnter:Fire()
for i=1,90 do frame(1/60) end
assert(math.abs(find('Magnetic_Mira').Rotation)<.001,'previous button settles')
press('K');tick(.3);assert(not find('Hub').Visible,'K closes')
local folder=find('EVINI_AimLine');EVINI.Destroy();assert(folder.destroyed,'line folder cleaned')
''')
print('PASS: startup milestones/cleanup, independent mouse rotation + positional follow, camera/input restoration, real-data beam toggle/staleness/switch, hover isolation, K and removal of Anti-Aim.')
