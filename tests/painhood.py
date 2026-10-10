"""Painhood local geometry/lifecycle tests. This does not emulate server hit registration."""
import ast
import json
from pathlib import Path
from lupa import LuaRuntime

base=Path(__file__).resolve().parent
# Reuse the existing static Roblox fixture without executing the DH test suite.
module=ast.parse((base/'regression.py').read_text())
fixture=next(n.value.args[0].value for n in module.body if isinstance(n,ast.Expr) and isinstance(n.value,ast.Call) and isinstance(n.value.func,ast.Attribute) and n.value.func.attr=='execute' and n.value.args and isinstance(n.value.args[0],ast.Constant))
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute(fixture)
def to_py(v):
    return {k:to_py(x) for k,x in v.items()} if hasattr(v,'items') else v
lua.globals().py_encode=lambda v:json.dumps(to_py(v))
lua.globals().py_decode=lambda v:lua.table_from(json.loads(v),recursive=True)
lua.execute(r'''
game.GameId=10770257767;game.PlaceId=138308349761110
for _,p in ipairs(players.list) do
 function p.Character:GetDescendants()
  local out={};for _,n in ipairs(nodes) do if not n.destroyed and n:IsDescendantOf(self) then out[#out+1]=n end end;return out
 end
end
customFolder=attach(enemy.Character,'Collision',Instance.new('Folder'))
custom=makePart(customFolder,'BodyBox',Vector3.new(0,0,0));custom.Transparency=.55
accessory=attach(enemy.Character,'Hat',Instance.new('Accessory'));accessoryPart=makePart(accessory,'Handle',Vector3.new(0,0,0))
files={};function writefile(path,data) files[path]=data end;function readfile(path) assert(files[path]);return files[path] end
''')
source=(base.parent/'main.lua').read_text()
lua.execute(source)
lua.execute(r'''
advance(.6)
local s=EVINI.Settings
local originalRoot=enemy.Character.root.Size
assert(not s.enabled and not s.painEnabled,'both independent defaults off')
find('Tab_Hitbox (Painhood)').Activated:Fire()
assert(find('Hitbox (Painhood)').Visible and not find('Hitbox').Visible,'separate page')
find('painEnabled').Activated:Fire()
assert(enemy.Character.torso.Size.X==8 and friend.Character.torso.Size.X==8,'actual torso geometry expanded')
assert(enemy.Character.root.Size==originalRoot and not s.enabled,'legacy root untouched')
assert(me.Character.torso.Size.X==2,'local player excluded')
find('enabled').Activated:Fire()
assert(enemy.Character.root.Size.X==8,'original hitbox still functional concurrently')
find('painEnabled').Activated:Fire()
assert(enemy.Character.torso.Size.X==2 and enemy.Character.root.Size.X==8,'Painhood disable preserves original mode')
find('painEnabled').Activated:Fire()
find('enabled').Activated:Fire()
assert(enemy.Character.root.Size.X==2 and enemy.Character.torso.Size.X==8,'original disable preserves Painhood')
-- Shared selection, KO and death restore existing geometry.
s.playerSelection['2']=false;run.Heartbeat:Fire(.11);assert(enemy.Character.torso.Size.X==2,'deselect restores')
s.playerSelection['2']=true;run.Heartbeat:Fire(.11);assert(enemy.Character.torso.Size.X==8,'reselect expands')
setFlag(enemy.Character,'K.O',true);run.Heartbeat:Fire(.11);assert(enemy.Character.torso.Size.X==2,'KO restore')
setFlag(enemy.Character,'K.O',false);enemy.Character.hum.Health=0;run.Heartbeat:Fire(.11);assert(enemy.Character.torso.Size.X==2,'death restore')
enemy.Character.hum.Health=100;run.Heartbeat:Fire(.11)
-- Select an actual nested custom part discovered in this character, not a cloned box.
find('PainScan').Activated:Fire()
for i=1,50 do if s.painTarget=='part:Collision/BodyBox' then break end;find('PainTarget').Activated:Fire() end
assert(s.painTarget=='part:Collision/BodyBox' and custom.Size.X==8,'nested selector applies existing part')
assert(enemy.Character.torso.Size.X==2,'target change restores prior part')
find('painInvisible').Activated:Fire();assert(custom.Transparency==1,'visibility setting')
find('painSize').Text='12';find('painSize').FocusLost:Fire();assert(custom.Size.X==12,'numeric size')
-- Never force continuous writes after the game changes the size back repeatedly.
for i=1,3 do custom.Size=Vector3.new(2,2,1);run.Heartbeat:Fire(.11) end
assert(find('PainStatus').Text:find('1 bloqueadas',1,true),'reversion reported')
run.Heartbeat:Fire(.11);assert(custom.Size.X==2 and custom.Transparency==.55,'blocked part restored and not forced')
find('painEnabled').Activated:Fire();find('painEnabled').Activated:Fire();assert(custom.Size.X==12,'explicit retry after toggle')
-- Root and accessories cannot be selected even via the exposed settings table.
s.painTarget='part:HumanoidRootPart';run.Heartbeat:Fire(.11)
assert(enemy.Character.root.Size.X==2 and custom.Size.X==2,'root excluded and prior custom restored')
s.painTarget='part:Hat/Handle';run.Heartbeat:Fire(.11);assert(accessoryPart.Size.X==2,'accessory excluded')
s.painTarget='part:Missing';run.Heartbeat:Fire(.11);assert(find('PainStatus').Text:find('sem a peça',1,true),'missing target explicit')
s.painTarget='part:Collision/BodyBox';run.Heartbeat:Fire(.11)
-- Character replacement and original-property restoration.
local oldCharacter=enemy.Character
enemy.Character=makeChar('Respawned',2);run.Heartbeat:Fire(.11);assert(custom.Size.X==2,'respawn restores old character')
enemy.Character=oldCharacter;run.Heartbeat:Fire(.11);assert(custom.Size.X==12,'existing selected part resumes')
s.painEnabled=false;run.Heartbeat:Fire(.11)
assert(custom.Size.X==2 and custom.Transparency==.55 and custom.CanCollide,'disable restores all changed properties')
s.painEnabled=true;run.Heartbeat:Fire(.11);EVINI.Save()
EVINI.Destroy();assert(custom.Size.X==2 and custom.Transparency==.55,'shutdown restore')
assert(not EVINI,'clean shutdown')
''')
lua.execute(source)
lua.execute(r'''
advance(.6)
assert(EVINI.Settings.painSize==12 and EVINI.Settings.painTarget=='part:Collision/BodyBox','persist independent values')
assert(custom.Size.X==12,'restored settings apply in confirmed experience')
EVINI.Destroy()
game.PlaceId=0;game.GameId=1234
''')
lua.execute(source)
lua.execute(r'''
advance(.6);find('painEnabled').Activated:Fire();run.Heartbeat:Fire(.11)
assert(enemy.Character.torso.Size.X==2 and custom.Size.X==2,'other experience gated')
assert(find('PainStatus').Text:find('apenas no jogo',1,true),'wrong game status')
EVINI.Destroy()
''')
print('PASS: separate tabs/modes, real nested part selection, selection/KO/death/respawn restoration, reversion detection, persistence and game gating.')
