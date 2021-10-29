local ChordSequencer={}

local music=include("mx.synths/lib/music")
local fourchords_=include("mx.synths/lib/fourchords")
local fourchords=fourchords_:new({fname=_path.code.."mx.synths/lib/4chords_top1000.txt"})
-- https://monome.org/docs/norns/reference/lib/sequins
local Sequins=require 'sequins'


function ChordSequencer:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function ChordSequencer:init()
  params:add_group("CHORDS",7)
  params:add{type='binary',name="start/stop",id='chordy_start',behavior='toggle',
    action=function(v)
      if v==1 then
        self:start()
      else
        self:stop()
      end
    end
  }
  params:add{type='binary',name="generate chords",id='chordy_generate',behavior='momentary',
    action=function(v)
      if v==1 then
        if math.random()<0.5 then
          params:set("chordy_chords",table.concat(fourchords:random_weighted()," "))
        else
          params:set("chordy_chords",table.concat(fourchords:random_unpopular()," "))
        end
        if params:get("chordy_start")==1 then 
          self:stop()
          self:start()
        end        
      end
    end
  }
  params:add_text("chordy_chords_show","chords","C Am F G")
  params:add_text("chordy_chords","chords show","C Am F G")
  params:hide("chordy_chords")
  params:set_action("chordy_chords",function(x)
    -- apply any transposition
    local chords={}
    for v in x:gmatch("%S+") do
      table.insert(chords,music.transpose_chord(v,params:get("chordy_transpose")))
    end
    params:set("chordy_chords_show",table.concat(chords," "))
  end)
  params:add_number("chordy_beats_per_chord","beats per chord",1,64,4)
  params:add_number("chordy_octave","octave",1,8,3)
  params:add_number("chordy_transpose","transpose",-11,11,0)
  params:set_action("chordy_transpose",function(x)
    local xx=params:get("chordy_chords")
    local chords={}
    for v in xx:gmatch("%S+") do
      table.insert(chords,music.transpose_chord(v,x))
    end
    params:set("chordy_chords_show",table.concat(chords," "))
  end)

  self:sequencer_init()
end

function ChordSequencer:sequencer_init()
  self.notes_on = {} -- keeps track of which notes are on
  self.pattern_note_on=self.lattice:new_pattern{
    action=function(t)
      -- trigger next note in sequence
      if self.note_on~=nil then
        local notes_new=self:next()
        if notes_new~=nil then
          for _, note_new in ipairs(notes_new) do
            self.notes_on[note_new]=true
            self.note_on(note_new)
          end
        end
      end
    end,
    division=0.5,
  }
  self.pattern_note_off=self.lattice:new_pattern{
    action=function(t)
      -- trigger next note-off in sequence
      if self.note_off~=nil then
        for note,_ in pairs(self.notes_on) do
          self.note_off(note)
          self.notes_on[note]=nil
        end
      end
    end,
    division=0.5,
    delay=0.9,
  }
end

function ChordSequencer:stop()
  print("chordsequencer: stop")
  self.pattern_note_on:stop()
  self.pattern_note_off:stop()
  self.lattice:stop_x()
  self.seq=nil
  for note,_ in pairs(self.notes_on) do
    if self.note_off~=nil then
      self.note_off(note)
    end
    self.notes_on[note]=nil
  end
end

function ChordSequencer:start()
  print("chordsequencer: start")
  self:refresh()
  self.pattern_note_on:start()
  self.pattern_note_off:start()
  self.lattice:start_x()
end

function ChordSequencer:refresh()
  local chord_text=params:get("chordy_chords_show")
  if chord_text=="" then
    self.seq=nil
    do return end
  end
  local seq={}
  for chord in chord_text:gmatch("%S+") do
    local data=music.chord_to_midi(chord..":"..params:get("chordy_octave"))
    if data~=nil then
      local notes={}
      for _,d in ipairs(data) do
        table.insert(notes,d.m)
      end
      if #notes>0 then
        table.insert(seq,notes)
      end
    end
  end
  if #seq>0 then
    print("refresh: "..#seq)
    if self.seq==nil then 
      self.seq=Sequins(seq)
    else
      self.seq:settable(seq)
    end
  else
    self.seq=nil
  end
end

function ChordSequencer:next()
  if self.seq~=nil then 
    return self.seq()
  end
end


return ChordSequencer
