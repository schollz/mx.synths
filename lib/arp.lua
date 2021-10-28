local Arp={}

-- https://monome.org/docs/norns/reference/lib/sequins
local Sequins=require 'sequins'

-- initializer for arpeggio
function Arp:new(o)
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self
  o:init()
  if o.menu==true then
    o:make_menu()
  end
  return o
end

function Arp:init()
  self:sequencer_init()

  params:add_group("ARP",8)

  params:add{type='binary',name="start/stop",id='arp_start',behavior='toggle',
    action=function(v)
      if v==1 then
        self:sequencer_start()
      else
        self:sequencer_stop()
      end
    end
  }

  -- define time signature
  self.time_signatures={"1","1/2","1/4","1/8T","1/8","1/16T","1/16","1/32"}
  self.time_divisions={1,1/2,1/4,1/6,1/8,1/12,1/16,1/32}
  params:add_option("arp_time_signature","time signature",self.time_signatures,5)
  params:set_action("arp_time_signature",function(x)
    self.pattern_note_off:set_division(self.time_divisions[x])
    self.pattern_note_on:set_division(self.time_divisions[x])
  end)

  -- define duration of a note
  params:add {
    type='control',
    id="arp_duration",
    name="note duration",
    controlspec=controlspec.new(0,100,'lin',1,50,'%',1/100),
    action=function(x)
      self.pattern_note_off:set_delay(x/100)
    end
  }

  -- define length multiplier
  -- which will increase the arpeggio over more octaves
  params:add {
    type='control',
    id="arp_length",
    name="arp length",
    controlspec=controlspec.new(0,4,'lin',0.1,1,'x',0.1/4),
  }
  params:set_action("arp_length",function(x)
    self:refresh()
  end)

  -- define possible shapes
  self.shapes={"up","down","up-down","down-up","converge","diverge","converge-diverge","diverge-converge","pinky up","pinky up-down","thumb up","thumb up-down","random"}
  params:add_option("arp_shape","shape",self.shapes,1)
  params:set_action("arp_shape",function(x)
    self:refresh()
  end)


  -- define possible modes
  self.modes={"12","+12,-12","+7,+9,-5","2,4,5,7,9"}
  params:add_option("arp_mode","mode",self.modes,1)
  params:set_action("arp_mode",function(x)
    self:refresh()
  end)

  -- define the trigger that will trigger the mode
  self.triggers={"none","first","last","each"}
  params:add_option("arp_trigger","mode trigger",self.triggers,1)
  params:set_action("arp_trigger",function(x)
    self:refresh()
  end)

  -- the original notes
  self.notes={}

  -- the hold notes
  self.hold_notes={}

  -- define hold mode
  params:add{type='binary',name="hold",id='arp_hold',behavior='toggle'}
  params:set_action("arp_hold",function(x)
    self:refresh()
  end)

  -- the sequins sequence
  self.seq=nil
end

function Arp:sequencer_init()
  local lattice=include("mx.synths/lib/lattice")
  self.lattice=lattice:new{}

  local notes_on = {} -- keeps track of which notes are on
  self.pattern_note_on=self.lattice:new_pattern{
    action=function(t)
      -- trigger next note in sequence
      if self.note_on~=nil then
        local note_new=self:next()
        if note_new~=nil then
          notes_on[note_new]=true
          self.note_on(note_new)
        end
      end
    end,
    division=1/16,
  }
  self.pattern_note_off=self.lattice:new_pattern{
    action=function(t)
      -- trigger next note in sequence
      if self.note_off~=nil then
        for note,_ in pairs(notes_on) do
          self.note_off(note)
          notes_on[note]=nil
        end
      end
    end,
    division=1/16,
    offset=0.5,
  }
end

function Arp:sequencer_start()
  if not self.sequencer_started then
    self.lattice:hard_restart()
  end
  self.sequencer_started=true
end

function Arp:sequencer_stop()
  self.lattice:stop()
  self.sequencer_started=false
end

function Arp:refresh()
  self.seq=nil
  local notes=self.notes 
  if params:get("arp_hold")==1 then 
    notes=self.hold_notes
  end
  if #notes==0 then
    do return end
  end

  -- first sort the notes
  table.sort(notes)
  
  -- define the root
  local root=notes[1]

  -- hold the temporary sequence
  local s={}

  -- first setup the basic sequence
  -- with arbitrary number of octaves
  for octave=0,4 do
    for i,n in ipairs(notes) do
      table.insert(s,n+(octave*12))
    end
  end

  -- truncate the sequence to the length
  local notes_total=math.floor(params:get("arp_length")*#notes)
  if notes_total==0 then
    do return end
  end
  s={table.unpack(s,1,notes_total)}

  -- create reverse table
  local s_reverse={}
  for i=#s,1,-1 do
    table.insert(s_reverse,s[i])
  end

  -- create the sequence based on the shapes
  if self.shapes[params:get("arp_shape")]=="down" then
    -- down
    -- 1 2 3 4 5 becomes
    -- 5 4 3 2 1
    s=s_reverse
  elseif self.shapes[params:get("arp_shape")]=="up-down" then
    -- up-down
    -- 1 2 3 4 5 becomes
    -- 1 2 3 4 5 4 3 2
    for i,n in ipairs(s_reverse) do
      if i>1 and i<#s_reverse then
        table.insert(s,n)
      end
    end
  elseif self.shapes[params:get("arp_shape")]=="down-up" then
    -- down-up
    -- 1 2 3 4 5 become
    -- 5 4 3 2 1 2 3 4
    local s2={}
    for _,n in ipairs(s_reverse) do
      table.insert(s2,n)
    end
    for i,n in ipairs(s) do
      if i>1 and i<#s_reverse then
        table.insert(s2,n)
      end
    end
    s=s2
  elseif self.shapes[params:get("arp_shape")]=="converge" then
    -- converge
    -- 1 2 3 4 5 becomes
    -- 5 1 4 2 3
    local s2={}
    for i,n in ipairs(s_reverse) do
      if #s2<#s then
        table.insert(s2,n)
        if #s2~=#s then
          table.insert(s2,s_reverse[#s_reverse-(i-1)])
        end
      end
    end
    s=s2
  elseif self.shapes[params:get("arp_shape")]=="diverge" then
     -- diverge
    -- 1 2 3 4 5 becomes
    -- 1 5 2 4 3
    local s2={}
    for i,n in ipairs(s) do
      if #s2<#s then
        table.insert(s2,n)
        if #s2~=#s then
          table.insert(s2,s[#s-(i-1)])
        end
      end
    end
    s=s2
  elseif self.shapes[params:get("arp_shape")]=="converge-diverge" then
     -- converge-diverge
    -- 1 2 3 4 5 becomes
    -- 5 1 4 2 3 2 4 1
    local s2={}
    for i,n in ipairs(s_reverse) do
      if #s2<#s_reverse then
        table.insert(s2,n)
        if #s2~=#s_reverse then
          table.insert(s2,s_reverse[#s_reverse-(i-1)])
        end
      end
    end
    for i=#s2,1,-1 do
      if i>1 and i<#s2 then
        table.insert(s2,s2[i])
      end
    end
    s=s2
  elseif self.shapes[params:get("arp_shape")]=="diverge-converge" then
     -- diverge-converge
    -- 1 2 3 4 5 becomes
    -- 1 5 2 4 3 4 2 5
    local s2={}
    for i,n in ipairs(s) do
      if #s2<#s then
        table.insert(s2,n)
        if #s2~=#s then
          table.insert(s2,s[#s-(i-1)])
        end
      end
    end
    for i=#s2,1,-1 do
      if i>1 and i<#s2 then
        table.insert(s2,s2[i])
      end
    end
    s=s2
  elseif self.shapes[params:get("arp_shape")]=="pinky up" then
    -- pinky up
    -- 1 2 3 4 5 becomes
    -- 1 5 2 5 3 5 4 5
    local s2={}
    for i,n in ipairs(s) do
      if i<#s then
        table.insert(s2,n)
        table.insert(s2,s[#s])
      end
    end
    s=s2
  elseif self.shapes[params:get("arp_shape")]=="pinky up-down" then
    -- pinky up-down
    -- 1 2 3 4 5 becomes
    -- 1 5 2 5 3 5 4 5 4 5 3 5 2 5
    local s2={}
    for i,n in ipairs(s) do
      if i>1 and i<#s then
        table.insert(s2,n)
        table.insert(s2,s[#s])
      end
    end
    for i,n in ipairs(s_reverse) do
      if i>1 and i<#s_reverse then
        table.insert(s2,n)
        table.insert(s2,s[#s])
      end
    end
    s=s2
  elseif self.shapes[params:get("arp_shape")]=="thumb up" then
    -- thumb up
    -- 1 2 3 4 5 becomes
    -- 1 2 1 3 1 4 1 5
    local s2={}
    for i,n in ipairs(s) do
      if i>1 then
        table.insert(s2,s[1])
        table.insert(s2,n)
      end
    end
    s=s2
  elseif self.shapes[params:get("arp_shape")]=="thumb up-down" then
    -- thumb up-down
    -- 1 2 3 4 5 becomes
    -- 1 2 1 3 1 4 1 5 1 4 1 3 1 2
    local s2={}
    for i,n in ipairs(s) do
      if i>1 then
        table.insert(s2,s[1])
        table.insert(s2,n)
      end
    end
    for i,n in ipairs(s_reverse) do
      if i>1 and i<#s_reverse then
        table.insert(s2,s[1])
        table.insert(s2,n)
      end
    end
    s=s2
  elseif self.shapes[params:get("arp_shape")]=="random" then
    -- random
    -- 1 2 3 4 5 becomes
    -- 2 3 1 5 4 or 3 1 2 4 5 or ...
    for i,n in ipairs(s) do
      math.randomseed(os.time())
      local j = math.random(i)
      s[i], s[j] = s[j], s[i]
    end
  end

  -- now "s" has the basic sequence
  -- add the special notes based on root
  if self.triggers[params:get("arp_trigger")]~="none" then
    local ss=Sequins{root+12}
    if self.modes[params:get("arp_mode")]=="+12,-12" then
      ss=Sequins{root+12,root-12}
    elseif self.modes[params:get("arp_mode")]=="+7,+9,-5" then
      ss=Sequins{root+7,root+9,root-5}
    elseif self.modes[params:get("arp_mode")]=="2,4,5,7,9" then
      ss=Sequins{root+2,root+4,root+5,root+7,root+9}
    end
    local s2={}
    for i,n in ipairs(s) do
      table.insert(s2,n)
      if i==1 and self.triggers[params:get("arp_trigger")]=="first" then
        table.insert(s2,ss)
      elseif i==#s and self.triggers[params:get("arp_trigger")]=="last" then
        table.insert(s2,ss)
      elseif self.triggers[params:get("arp_trigger")]=="each" then
        table.insert(s2,ss)
      end
    end
    s=s2
  end

  -- convert to a sequins
  if self.seq==nil then
    self.seq=Sequins(s)
  else
    self.seq:settable(s)
  end
end

function Arp:next()
  if self.seq~=nil and params:get("arp_start")==1 then
    do return self.seq() end
  end
end

function Arp:contains(note)
  for i,n in ipairs(self.notes) do
    if note==n then
      do return i end
    end
  end
end

function Arp:add(note)
  if self:contains(note) then
    self:remove(note)
  end
  table.insert(self.notes,note)
  self.hold_notes={table.unpack(self.notes)}
  self:refresh()
  print("Arp: added "..note)
end

function Arp:remove(note)
  local notes={}
  for i,n in ipairs(self.notes) do
    if n~=note then
      table.insert(notes,n)
    end
  end
  self.notes=notes
  self:refresh()
  print("Arp: removed "..note)
end

-- local arp=Arp:new()
-- arp.length=2
-- arp.shape=3 -- up down
-- arp.trigger=2 -- trigger the mode after the first note
-- arp.mode=2 -- when triggered play a +12/-12 octave
-- arp:add(0)
-- arp:add(3)
-- arp:add(5)
-- arp:remove(3)
-- arp:add(7)
-- for i,n in ipairs(arp.seq) do
--   print(i,n)
-- end
-- local ss=""
-- for i=1,20 do
--   ss=ss.." "..arp:next()
-- end
-- print(ss)

-- local s=Sequins{1,1,1}
-- local seq=Sequins{1,s,3,s}
-- for i=1,6 do
--   print(seq())
-- end
-- seq:settable({1,2,3,4})
-- for i=1,5 do
--   print(seq())
-- end

return Arp