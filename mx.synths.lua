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
  if z==1 and k==3 then
    params:delta("mxsynths_synth",1)
  elseif z==1 and k==2 then
    params:delta("mxsynths_synth",-1)
  end
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

mod={}

function redraw()
  screen.clear()
  local synth=mxsynths:current_synth()
  for i=1,4 do
    mod[i]=params:get("mxsynths_mod"..i)
  end
  if synth=="piano" then
    piano()
  elseif synth=="toshiya" then
    tree_scene()
  else
    generic()
  end

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end

function generic()
  for i=1,4 do
    local m=util.linlin(-1,1,30,-30,params:get("mxsynths_mod"..i))
    x=64-8+i*4
    y=32
    screen.level(15)
    screen.move(x,y)
    screen.line(x,y+m+1)
    screen.stroke()
  end
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

function tree_scene()
  local r=60
  local t=util.linlin(-1,1,3,2,mod[1])
  local x=r*math.sin(t)+64
  local y=r*math.cos(t)+64
  screen.level(math.floor(util.linlin(-1,1,15,1,mod[4])))
  screen.circle(x,y,10)
  screen.fill()
  local x=r*math.sin(t)+64-util.linlin(-1,1,20,2,mod[4])
  local y=r*math.cos(t)+64
  screen.level(0)
  screen.circle(x,y,10)
  screen.fill()
  tree_create()
end

function tree_rotate(x,y,a)
  local s,c=math.sin(a),math.cos(a)
  local a,b=x*c-y*s,x*s+y*c
  return a,b
end
function tree_branches(a,b,len,ang,dir,count,color)
  local angle=27*math.pi/180
  len=len*.66
  if count>8 then return end
  if len<3 then return end
  if dir>0 then ang=ang-angle
  else ang=ang+angle
  end
  local vx,vy=tree_rotate(0,len,ang)
  vx=a+vx;vy=b-vy
  math.randomseed(len)
  line(a,b,vx,vy,color)
  tree_branches(vx,vy,len+math.random()*2,ang,1,count+1,color)
  tree_branches(vx,vy,len+math.random()*2,ang,0,count+1,color)
end
function tree_create()
  local wid=110
  local hei=64
  local a,b=wid/2,hei-5
  line(wid/2,hei,a,b,15)
  math.randomseed(4)
  tree_branches(a,b,util.linlin(-1,1,5,30,mod[2])+math.random()*10,0,0,2,math.floor(util.linlin(-1,1,1,15,mod[2])))
  tree_branches(a,b,util.linlin(-1,1,5,30,mod[3])+math.random()*10,0,1,2,math.floor(util.linlin(-1,1,1,15,mod[3])))
end

function line(x1,y1,x2,y2,level)
  screen.level(level)
  screen.move(x1,y1)
  screen.line(x2,y2)
  screen.stroke()
end
