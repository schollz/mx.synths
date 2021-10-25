local ChordSequencer={}

local music=include("mx.synths/lib/music")

function ChordSequencer:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function ChordSequencer:init()
  params:add_group("CHORDY",6)
  params:add{type='binary',name="start/stop",id='chordy_start',behavior='toggle',
    action=function(v)
      if v==1 then
        self:start()
      else
        self:stop()
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

  -- start lattice
  self.sequencer=lattice:new{
    ppqn=16
  }
  self.sequencer:new_pattern({
    action=function(t)
      self:step(t)
    end,
    division=1/4,
  })
end

function ChordSequencer:start()
  local chord_text=params:get("chordy_chords_show")
  if chord_text=="" then
    print("no chords to play")
    do return end
  end
  self.chords={}
  for chord in chord_text:gmatch("%S+") do
    local data=music.chord_to_midi(chord..":"..params:get("chordy_octave"))
    if data~=nil then
      table.insert(self.chords,{chord,data})
      print("chordsequencer: added "..chord)
    end
  end
  self.beat=-1
  self.measure=-1
  self.chord_current=nil
  self.sequencer:hard_restart()
  if self.fn_start~=nil then
    self.fn_start()
  end
end

function ChordSequencer:stop()
  self.sequencer:stop()
  if self.fn_note_off~=nil and self.chord_current~=nil then
    self.fn_note_off(self.chord_current)
  end
  if self.fn_stop~=nil then
    self.fn_stop()
  end
end

function ChordSequencer:step(t)
  self.beat=self.beat+1
  if self.beat%params:get("chordy_beats_per_chord")==0 then
    self.measure=self.measure+1
    self.chord_current=self.chords[self.measure%#self.chords+1]
    print("chordsequencer: playing "..self.chord_current[1])
    if self.fn_note_on~=nil then
      self.fn_note_on(self.chord_current)
    end
  end
  if self.beat%params:get("chordy_beats_per_chord")==params:get("chordy_beats_per_chord")-1 then
    print("chordsequencer: stopping "..self.chord_current[1])
    if self.fn_note_off~=nil then
      self.fn_note_off(self.chord_current)
    end
  end
end

function ChordSequencer:chord_on(fn)
  self.fn_note_on=fn
end

function ChordSequencer:chord_off(fn)
  self.fn_note_off=fn
end

function ChordSequencer:on_start(fn)
  self.fn_start=fn
end

function ChordSequencer:on_stop(fn)
  self.fn_stop=fn
end

return ChordSequencer
