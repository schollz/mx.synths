-- mx.synths v0.0.1
-- ?
--
-- llllllll.co/t/mx-synths
--
-- 1. plug in a midi controller
-- 2. select a synth.
-- 3. profit.

local UI=require "ui"

engine.name="MxSynths"

function init()
  local mxsynths_=include("mx.synths/lib/mx.synths")
  mxsynths=mxsynths_:new()
  mxsynths:setup_midi()
  clock.run(redraw_clock)
end

kon=false
function key(k,z)
  kon=z==1
end

function enc(k,d)
  if kon then
    params:delta("mxsynths_mod4",d)
    do return end
  end
  if k>0 then
    params:delta("mxsynths_mod"..k,d)
  end
end

function redraw_clock() -- our grid redraw clock
  while true do -- while it's running...
    clock.sleep(1/10) -- refresh
    redraw()
  end
end

function redraw()
  screen.clear()
  piano()

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end

function piano()
  local m1=util.linlin(-1,1,10,30,params:get("mxsynths_mod1"))
  local radius=math.floor(m1)
  local m2=util.linlin(-1,1,1,radius,params:get("mxsynths_mod2"))
  local m3=util.linlin(-1,1,0,30,params:get("mxsynths_mod3"))
  local m4=math.ceil(util.linlin(-1,1,0.1,15,params:get("mxsynths_mod4")))
  local pos={80,31}
  screen.level(m4)
  for y=pos[2]-radius,pos[2]+radius do
    local x=math.sqrt(radius^2-math.pow(y-pos[2],2))+pos[1]
    local xback=-1*math.sqrt(radius^2-math.pow(y-pos[2],2))+pos[1]
    local shift=(y%2*2-1)*m3
    screen.move(x+shift,y)
    screen.line(x-m2+shift,y)
    screen.stroke()
    screen.move(xback-m2+shift,y)
    screen.line(xback+1-m2+shift,y)
    screen.stroke()
  end
end
