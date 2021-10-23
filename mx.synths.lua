-- mx.synths v0.2.1
--
--
-- llllllll.co/t/mx-synths
--
--
--
--    ▼ instructions below ▼
-- K2/K3 changes instrument
-- E1 controls mod1
-- E2 controls mod2
-- E3 controls mod3
-- K1+any E controls mod4

local UI=require "ui"

engine.name="MxSynths"

function init()
  local mxsynths_=include("mx.synths/lib/mx.synths")
  mxsynths=mxsynths_:new({save=true})
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
  elseif synth=="PolyPerc" then
    squares()
  elseif synth=="malone" then
    organ()
  elseif synth=="casio" then
    casio()
  elseif synth=="synthy" then
    saws()
  elseif synth=="epiano" then
    epiano()
  elseif synth=="icarus" then
    icarus()
  else
    generic()
  end

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end

function icarus()
  local current_time=clock.get_beats()*clock.get_beat_sec()
  local mod={0,0,0,0}
  for i=1,4 do
    mod[i]=params:get("mxsynths_mod"..i)
  end
  -- make the sun curve in the sky based on delay time
  local delay_range={0.05,0.5}
  local rdelay=util.linlin(-1,1,270,90,mod[2])
  local center={64,32}
  local rpos={center[1]+40*math.sin(math.rad(rdelay)),center[2]+40*math.cos(math.rad(rdelay))}
  local rfeedback=util.linlin(-1,1,4,20,mod[1])
  local rvolume=util.linlin(-1,1,4,8,math.sin(clock.get_beat_sec()*clock.get_beats()/5))
  local rlow=rfeedback
  local rhigh=rfeedback+rvolume
  for i=rhigh,rlow,-1 do
    local ll=math.floor(util.linlin(rlow,rhigh,14,1,i))
    screen.level(ll)
    i=i*math.pow(1.5,1/ll)
    screen.circle(rpos[1],rpos[2]+10,i)
    screen.fill()
  end
  screen.level(15)
  screen.circle(rpos[1],rpos[2]+10,rfeedback)
  screen.fill()
  screen.update()
  -- the ocean
  local rfilter=util.linlin(-1,1,62,20,mod[3])
  local horizon=math.floor(rfilter)
  screen.update()
  math.randomseed(4)
  screen.level(0)
  screen.rect(0,rfilter,129,65)
  screen.fill()
  for y=0,64 do
    local z=64/(y+1)
    for i=0,z*5 do
      x=(rnd(160)+current_time*160/z)%150-16
      w=cos(rnd()+current_time)*12/z
      if (w>0) then
        local s=screen.peek(math.floor(x),math.floor(horizon-1-y/2),math.floor(x+1),math.floor(horizon-y/2))
        if s~=nil then
          local pgot=util.clamp(string.byte(s,1),1,15)
          screen.level(pgot+1)
          screen.move(x-w,y+horizon)
          screen.line(x+w,y+horizon)
          screen.stroke()
        end
      end
    end
  end
end

--- Cos of value
-- Value is expected to be between 0..1 (instead of 0..360)
-- @param x value
function cos(x)
  return math.cos(math.rad(x*360))
end

function rnd(x)
  if x==0 then
    return 0
  end
  if (not x) then
    x=1
  end
  x=x*100
  x=math.random(x)/100
  return x
end

function epiano()
  local mod={0,0,0,0}
  for i=1,4 do
    mod[i]=params:get("mxsynths_mod"..i)
  end
  local w=util.linlin(-1,1,50,120,mod[2])
  local h=util.linlin(-1,1,10,40,mod[3])
  local x=(128-w)/2
  local y=(64-h)/2
  for i=1,8 do
    screen.level(math.floor(util.linlin(-1,1,1,15.9,mod[1])))
    screen.rect(x,y,w/8,h)
    screen.stroke()
    x=x+w/8
  end
  x=(128-w)/2
  for i=1,8 do
    if i~=8 and i~=3 then
      screen.level(math.floor(util.linlin(-1,1,1,15.9,mod[4])))
      screen.rect(x+w/8/4*3,y+0.5,w/8/2,h/2)
      screen.fill()
    end
    x=x+w/8
  end
end
local pospos={}
for i=1,128 do
  table.insert(pospos,i)
end

function saws()
  local mod={0,0,0,0}
  for i=1,4 do
    mod[i]=params:get("mxsynths_mod"..i)
  end
  local h=util.linlin(-1,1,10,60,mod[1])
  local p=util.linlin(-1,1,25,2,mod[2])
  local n=math.floor(util.linlin(-1,1,1,15,mod[4]))
  for i=1,128 do
    local x=i
    for j=1,n do
      local y=61-h/(2*p)*(pospos[i]%(2*p))
      y=y+math.sin(pospos[i]/util.linlin(-1,1,120,60,mod[3])*clock.get_beats()*clock.get_beat_sec()/100)*util.linlin(-1,1,0,20,mod[3])
      screen.level(math.ceil(j/n*15))
      y=y-(j-1)
      if i>1 then
        screen.line(x,y)
        screen.stroke()
      end
      screen.move(x,y)
    end
  end
  local next=table.remove(pospos,1)
  table.insert(pospos,next)
end

function squares()
  local mod={0,0,0,0}
  for i=1,4 do
    mod[i]=params:get("mxsynths_mod"..i)
  end
  local w=util.linlin(-1,1,10,127,mod[2])
  local h=util.linlin(-1,1,10,63,mod[3])
  local n=util.linlin(-1,1,1,15,mod[1])
  for i=1,n do
    local w1=w/n*i
    local h1=h/n*i
    local x=(127-w1)/2+1
    local y=(64-h1)/2
    screen.level(math.ceil(15/n*i))
    screen.rect(x,y,w1,h1)
    if i==1 then
      screen.level(math.floor(util.linlin(-1,1,1,15.99,mod[4])))
      screen.fill()
    else
      screen.stroke()
    end
  end
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

function organ()
  local mod={0,0,0,0}
  for i=1,4 do
    mod[i]=params:get("mxsynths_mod"..i)
  end

  math.randomseed(43)
  local rs={}
  local ctl={}
  local rtotal=0
  for i=1,30 do
    local r=math.random()*8+2
    if rtotal+r<63 then
      table.insert(rs,r)
      table.insert(ctl,math.random(1,4))
      rtotal=rtotal+r
    end
  end
  table.sort(rs)

  local x=1
  for i,r in ipairs(rs) do
    r=math.random(90,110)/100*r
    local h=util.linlin(-1,1,1,math.random(30,60),mod[ctl[i]])
    if i%2==0 then
      h=util.linlin(-1,1,math.random(30,60),1,mod[ctl[i]])
    end
    local y=64-h
    if i==1 then
      screen.move(x-r,y)
    end
    screen.level(5)
    screen.circle(x+r,y,r)
    screen.fill()
    screen.level(1)
    screen.circle(x+r,y+2,r)
    screen.fill()
    screen.level(0)
    screen.circle(x+r,y+r/3,r)
    screen.fill()
    screen.level(15)
    screen.circle(x+r,y,r)
    screen.stroke()

    screen.move(x,y)
    screen.line(x,64)
    screen.stroke()
    screen.move(x+2*r,y)
    screen.line(x+2*r,64)
    screen.stroke()
    screen.level(5)
    screen.move(x+2*r-1,y+5)
    screen.line(x+2*r-1,64)
    screen.stroke()
    screen.level(1)
    screen.move(x+2*r-2,y+8)
    screen.line(x+2*r-2,64)
    screen.stroke()
    x=x+r*2
  end
end

function casio()
  local mod={0,0,0,0}
  for i=1,4 do
    mod[i]=params:get("mxsynths_mod"..i)
  end
  screen.font_face(37)
  screen.font_size(18)
  screen.level(5)
  screen.text_center_rotate(21,32,"CASIO",-90)
  screen.level(15)
  screen.rect(6,5,20,55)
  screen.stroke()
  local x=28
  local y=20
  for i=0,5 do
    screen.move(x+i*2,y-i*3)
    screen.line(x+i*2,y+20-i*3)
    screen.stroke()
  end

  screen.rect(40,1,128-40,64-1)
  screen.stroke()
  for i=1,4 do
    local x=30+i*20
    local y=10
    screen.move(x+3,8)
    screen.line(x+3,56)
    screen.stroke()
    screen.level(0)
    local h=util.linlin(-1,1,40,5,mod[i])
    screen.rect(x,h,6,20)
    screen.fill()
    screen.level(15)
    screen.rect(x,h,6,20)
    screen.stroke()
  end
  screen.font_face(1)
  screen.font_size(8)
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
  local period=math.random(5,20)
  local offset=math.random(5,20)
  local angle=27*math.pi/180*(util.linlin(-1,1,0.75,1.25,math.sin(clock.get_beat_sec()*clock.get_beats()/period+offset)))
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
