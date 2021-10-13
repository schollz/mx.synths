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

-- function enc(k,d)
--   if kon then
--     params:delta()
--   end
--   if k==1 then
--     mod1=util.clamp(mod1+d/100,-1,1)
--   elseif k==2 then
--     mod2=util.clamp(mod2+d/100,-1,1)
--   elseif k==3 then
--     mod3=util.clamp(mod3+d/100,-1,1)
--   end
--   redraw()
-- end

function redraw_clock() -- our grid redraw clock
  while true do -- while it's running...
    clock.sleep(1/10) -- refresh
    redraw()
  end
end

function redraw()
  screen.clear()

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end

function piano()

end
