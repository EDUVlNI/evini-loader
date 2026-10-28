"""Studio-style UI integration with simulated input, timers and sound playback."""
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
game.GameId=1234;files={}
function writefile(p,d) files[p]=d end
function readfile(p) assert(files[p]);return files[p] end
files['evini-settings-1234.json']=py_encode({version=1,settings={hideKeyName='L',camKeyName='K',painEnabled=true,painSize=18,size=12,prediction=.18,playerSelection={['3']=false},triggerBodyVersion=true}})
uis.WindowFocused=signal()
function uis:IsMouseButtonPressed() return false end
function workspace.CurrentCamera:ViewportPointToRay(x,y) return {Origin=Vector3.new(0,0,0),Direction=Vector3.new(100,100,100).Unit} end
function tick(dt) advance(dt);run.Heartbeat:Fire(dt);frame(dt) end
function absent(name) for _,n in ipairs(nodes) do if n.Name==name and not n.destroyed then return false end end return true end
''')
source=(base.parent/'main.lua').read_text();lua.execute(source)
lua.execute(r'''
tick(.6)
local s=EVINI.Settings
assert(s.hideKeyName=='K' and s.camKeyName=='Q','migrate K and resolve old camera conflict')
assert(s.size==12 and s.prediction==.18 and s.playerSelection['3']==false,'preserve preferences')
assert(s.painEnabled==nil and s.painSize==nil,'removed adapter settings')
for _,name in ipairs({'TriggerHUD','TriggerStatus','CrewIntro','BevanTitle','Tab_Hitbox (Painhood)','AimViewerStatus','EVINI_AimEffects'}) do assert(absent(name),name..' removed') end
assert(not find('Hub').Visible and not find('StudioBackdrop').Visible,'start hidden without splash')
uis.focused=true;press('K');tick(.4);assert(not find('Hub').Visible,'typing does not open menu');uis.focused=false
press('K');tick(.6)
assert(find('Hub').Visible and find('Navigation').Visible and not find('Content').Visible,'K opens categories')
assert(find('HubTitle').TextSize==48,'larger EVINI title')
for _,name in ipairs({'Mira','Hitbox','Triggerbot','Visual','Jogadores','Ajustes'}) do assert(find('Arrival_'..name).GroupTransparency==0,'stagger finishes') end
local menu=find('Tab_Ajustes');menu.AbsolutePosition=Vector2.new(200,200);menu.AbsoluteSize=Vector2.new(400,56)
uis.mouse=Vector2.new(560,228);frame(.3)
local visual=find('Magnetic_Ajustes')
assert(visual.Rotation>0 and visual.Position.X.Offset>0,'visual follows pointer gently')
assert(menu.Position.X.Offset==8,'hit area stays still')
s.reduceMotion=true;frame(.1);assert(visual.Rotation==0 and visual.Position.X.Offset==0,'reduced motion disables follow');s.reduceMotion=false
uis.mouse=Vector2.new(560,228);frame(.1)
local scale
for _,n in ipairs(nodes) do if n.Name=='HoverScale' and n.Parent==visual then scale=n end end
menu.InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1});frame(.1)
assert(scale.Scale<1,'press compresses visual')
uis.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1})
uis.mouse=Vector2.new(1000,1000)
for i=1,90 do frame(1/60) end
assert(math.abs(visual.Position.X.Offset)<.01 and math.abs(scale.Scale-1)<.001,'elastic return settles')
for _,n in ipairs(nodes) do assert(n.Name~='CursorLight' or n.ClassName~='Frame','no rectangular light') end

for _,name in ipairs({'Mira','Hitbox','Triggerbot','Visual','Jogadores','Ajustes'}) do
 find('Tab_'..name).Activated:Fire();tick(.3)
 assert(find(name).Visible and find('Content').Visible and not find('Navigation').Visible,'category '..name)
 assert(find('HubTitle').Text==(name=='Mira' and 'Cam Lock' or name),'category heading')
 find('Hide').Activated:Fire();tick(.3)
 assert(find('Navigation').Visible and not find('Content').Visible,'back to list')
end
-- Feature effects survive closing and the default K binding remains available.
find('enabled').Activated:Fire();find('espPlayers').Activated:Fire();tick(.2)
assert(enemy.Character.root.Size.X==12,'normal hitbox')
press('K');tick(.4)
assert(enemy.Character.root.Size.X==12,'closing does not restore enabled hitbox')
local esp=false;for _,n in ipairs(nodes) do if n.Name=='ESPName' and not n.destroyed then esp=true end end
assert(esp,'ESP still updates hidden')
press('K');tick(.4)
find('triggerEnabled').Activated:Fire();tick(.2)
local on,off=find('TriggerOn'),find('TriggerOff')
assert((on.playCount or 0)==0,'menu pauses trigger')
press('K');tick(.4);assert(on.playCount==1,'one activation sound')
for i=1,20 do tick(.05) end
assert(on.playCount==1,'no per-frame sound spam')
press('T');tick(.1);assert(off.playCount==1,'deactivation sound')
for i=1,10 do tick(.1) end
assert(off.playCount==1,'no repeated deactivation')
press('T');tick(.1);assert(on.playCount==2,'activation after pause')
local knife=attach(me.Character,'Knife',Instance.new('Tool'));tick(.1)
assert(off.playCount==2,'knife pause sound')
knife.Parent=nil;me.Character.children.Knife=nil;tick(.1)
assert(on.playCount==3,'resume after knife')
s.triggerSounds=false;press('T');tick(.1);assert(off.playCount==2,'sound option respected')
-- Interrupted exit must not hide a newly opened panel.
press('K');press('K');press('K');tick(.7)
assert(find('Hub').Visible and find('StudioBackdrop').Visible,'rapid reversal remains open')
for _,v in ipairs({Vector2.new(800,600),Vector2.new(1920,1080),Vector2.new(390,844)}) do
 workspace.CurrentCamera.ViewportSize=v;s.uiSize=1.5;tick(.1)
 local scale=find('UserScale').Scale
 assert(465*scale<=v.X*.87+.01 and 670*scale<=v.Y*.82+.01,'viewport fit')
end
EVINI.Save()
local saved=py_decode(files['evini-settings-1234.json']).settings
assert(saved.painEnabled==nil and saved.size==12 and saved.studioUIVersion,'save drops removed settings')
find('Close').Activated:Fire();tick(.7)
assert(EVINI==nil and run.bindings.EVINI_Trigger==nil and run.bindings.EVINI_Camera==nil,'shutdown unbinds')
assert(enemy.Character.root.Size.X==2,'shutdown restores normal hitbox')
''')
print('PASS: K migration, all categories/back, old preference preservation, no Painhood/HUD/splash, audio edges/knife/mute, hidden effects, animation reversal, viewport fit and shutdown.')
