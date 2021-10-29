local MusicUtil=require "musicutil"
local Formatters=require 'formatters'
local chordsequencer_=include("mx.synths/lib/chordsequencer")
local lattice=include("mx.synths/lib/lattice")


local MxSynths={}

function MxSynths:new(args)
  local l=setmetatable({},{__index=MxSynths})
  local args=args==nil and {} or args
  l.debug=args.debug --true-- args.debug -- true --args.debug

  local filter_freq=controlspec.new(20,20000,'exp',0,20000,'Hz')
  local delay_rates_names={"whole-note","half-note","quarter note","eighth note","sixteenth note","thirtysecond"}
  local delay_rates={4,2,1,1/2,1/4,1/8,1/16}
  local delay_last_clock=0

  -- add parameters
  l.save_on_change=args.save or false
  l.lfos={"pan","attack","decay","sustain","release","mod1","mod2","mod3","mod4","lpf","delay"}
  l.synths={"piano","epiano","casio","malone","toshiya","synthy","PolyPerc","icarus","mdapiano","kalimba"}
  l.presets={}
  l.presets["synthy"]={"massive"}
  -- https://sumire-io.gitlab.io/midi-velocity-curve-generator/
  l.velocities={}
  l.velocities[1]={1,4,7,10,13,16,19,22,25,28,31,34,38,41,43,46,49,52,55,57,60,62,64,66,68,70,71,73,74,76,77,79,80,81,83,84,85,86,87,89,90,91,92,93,94,95,95,96,97,98,99,99,100,101,102,102,103,104,104,105,105,106,106,107,107,108,108,109,109,109,110,110,111,111,111,112,112,112,112,113,113,113,114,114,114,114,115,115,115,115,115,116,116,116,116,116,117,117,117,117,118,118,118,118,118,119,119,119,120,120,120,120,121,121,121,122,122,122,123,123,124,124,124,125,125,126,126,127}
  l.velocities[2]={0,2,3,4,6,7,8,10,11,13,14,15,17,18,19,21,22,23,25,26,27,29,30,31,33,34,35,37,38,39,40,42,43,44,45,47,48,49,50,52,53,54,55,57,58,59,60,61,62,64,65,66,67,68,69,70,71,72,73,75,76,77,78,79,80,81,82,83,83,84,85,86,87,88,89,90,91,92,92,93,94,95,96,97,97,98,99,100,100,101,102,103,103,104,105,106,106,107,108,109,109,110,111,111,112,113,113,114,115,115,116,117,117,118,119,119,120,120,121,122,122,123,124,124,125,126,126,127}
  l.velocities[3]={1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,8,8,8,9,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,18,18,19,20,20,21,22,23,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,42,43,44,45,47,48,49,51,52,54,55,57,58,60,62,63,65,66,68,70,72,73,75,77,79,80,82,84,86,88,90,92,94,95,97,99,101,103,105,107,109,111,113,115,117,119,121,123,125,127}
  l.velocities[4]={}
  for i=1,128 do
    table.insert(l.velocities[4],64)
  end

  params:add_group("MX.SYNTHS",22+12*5)

  -- synth selector
  params:add_option("mxsynths_synth","synth",l.synths,1)
  params:set_action("mxsynths_synth",function(x)
    if engine.name=="MxSynths" then
      engine.mx_set_synth(l.synths[x])
      l:save()
    end
  end)

  -- amp
  params:add{type="control",id="mxsynths_amp",name="volume",controlspec=controlspec.new(-96,20,'lin',1,-9,'',1/(20+96)),formatter=function(v)
    local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
    return ((val<0) and "" or "+")..val.." dB"
  end}
  params:set_action("mxsynths_amp",function(x)
    if engine.name=="MxSynths" then
      engine.mx_set("amp",util.dbamp(x))
      l:save()
    end
  end)

  params:add{type="control",id="mxsynths_sub",name="sub",controlspec=controlspec.new(-96,20,'lin',1,-9,'',1/(20+96)),formatter=function(v)
    local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
    return ((val<0) and "" or "+")..val.." dB"
  end}
  params:set_action("mxsynths_sub",function(x)
    if engine.name=="MxSynths" then
      engine.mx_set("sub",util.dbamp(x))
      l:save()
    end
  end)

  params:add {
    type='control',
    id="mxsynths_pan",
    name="pan",
    controlspec=controlspec.new(-1,1,'lin',0,0),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_set("pan",x)
        l:save()
      end
    end
  }

  params:add {
    type='control',
    id="mxsynths_attack",
    name="attack",
    controlspec=controlspec.new(0,10,'lin',0.01,0.01,'s',0.01/10),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_set("attack",x)
        l:save()
      end
    end
  }

  params:add {
    type='control',
    id="mxsynths_decay",
    name="decay",
    controlspec=controlspec.new(0,10,'lin',0,1,'s'),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_set("decay",x)
        l:save()
      end
    end
  }

  params:add {
    type='control',
    id="mxsynths_sustain",
    name="sustain",
    controlspec=controlspec.new(0,2,'lin',0,0.9,'amp'),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_set("sustain",x)
        l:save()
      end
    end
  }

  params:add {
    type='control',
    id="mxsynths_release",
    name="release",
    controlspec=controlspec.new(0,10,'lin',0,1,'s'),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_set("release",x)
        l:save()
      end
    end
  }

  for i=1,4 do
    params:add {
      type='control',
      id="mxsynths_mod"..i,
      name="mod"..i,
      controlspec=controlspec.new(-1,1,'lin',0.01,0,'',0.01/2),
      action=function(x)
        if engine.name=="MxSynths" then
          engine.mx_set("mod"..i,x)
          l:save()
        end
      end
    }
  end

  params:add {
    type='control',
    id="mxsynths_tune",
    name="tune",
    controlspec=controlspec.new(-100,100,'lin',0,0,'cents',1/200),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_set("tune",x/100)
        l:save()
      end
    end
  }

  params:add {
    type='control',
    id='mxsynths_lpf',
    name='low-pass filter',
    controlspec=filter_freq,
    formatter=Formatters.format_freq,
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_fxset("lpf",x)
        l:save()
      end
    end
  }

  params:add {
    type='control',
    id="mxsynths_delay",
    name="delay send",
    controlspec=controlspec.new(0,100,'lin',0,10,'%',1/100),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_fxset("delay",x/100)
        l:save()
      end
    end
  }

  params:add {
    type='control',
    id="mxsynths_delay_times",
    name="delay iterations",
    controlspec=controlspec.new(0,100,'lin',0,11,'beats',1/100),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_fxset("delayFeedback",x/100)
        l:save()
      end
    end
  }

  params:add_option("mxsynths_delay_rate","delay rate",delay_rates_names,3)
  params:set_action("mxsynths_delay_rate",function(x)
    if engine.name=="MxSynths" then
      engine.mx_fxset("delayBeats",delay_rates[x])
      l:save()
    end
  end)

  -- polyphony selector
  params:add_option("mxsynths_polyphony","polyphony",{"polyphonic","monophonic"},1)
  params:set_action("mxsynths_polyphony",function(x)
    if engine.name=="MxSynths" then
      engine.mx_set("monophonic",x-1)
      l:save()
      if x==2 then
        params:show("mxsynths_portamento")
      else
        params:hide("mxsynths_portamento")
      end
      _menu.rebuild_params()
    end
  end)
  params:add {
    type='control',
    id="mxsynths_portamento",
    name="portamento",
    controlspec=controlspec.new(0,5,'lin',0.01,0,'s',0.01/5),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_set("portamento",x)
        l:save()
      end
    end
  }
  params:add {
    type='control',
    id="mxsynths_max_polyphony",
    name="max polyphony",
    controlspec=controlspec.new(0,100,'lin',2,20,'notes',1/100),
    action=function(x)
      if engine.name=="MxSynths" then
        engine.mx_set_polyphony(math.floor(x))
        l:save()
      end
    end
  }

  params:add_option("mxsynths_sensitivity","velocity sensitivity",{"delicate","normal","stiff","fixed"},2)
  params:set_action("mxsynths_sensitivity",function(x)
    if engine.name=="MxSynths" then
      l:save()
    end
  end)

  params:add_option("mxsynths_pedal_mode","pedal mode",{"sustain","sostenuto"},1)


  params:add_separator("lfos")
  l:create_lfo_param("pan",{-1,1},{-0.5,0.5})
  l:create_lfo_param("sub",{-96,10},{-36,-5})
  l:create_lfo_param("attack",{0,10},{0.01,0.05})
  l:create_lfo_param("decay",{0,10},{1,2})
  l:create_lfo_param("sustain",{0,1},{0.5,1})
  l:create_lfo_param("release",{0,10},{0,2})
  for i=1,4 do
    l:create_lfo_param("mod"..i,{-1,1},{-0.5,0.5})
  end
  l:create_lfo_param("lpf",{20,20000},{300,6000})
  l:create_lfo_param("delay",{0,100},{0,100})

  -- osc.event=function(path,args,from)
  --   if path=="voice" then
  --     local voice_num=args[1]
  --     local onoff=args[2]
  --     if onoff==0 and voice_num~=nil then
  --       l.voice[voice_num].age=current_time()
  --       l.voice[voice_num].active={name="",midi=0}
  --     end
  --   end
  -- end

  if engine.name=="MxSynths" then
    engine.mx_fxset("secondsPerBeat",clock.get_beat_sec())
  end

  l.ready=false
  l.lattice=lattice:new{}
  l:setup_arp()
  l:setup_chord_sequencer()

  if args.previous==true then
    if util.file_exists(_path.data.."mx.synths/default.pset") then
      params:read(_path.data.."mx.synths/default.pset")
    end
  end
  params:set("chordy_start",0)
  params:bang()
  l:refresh_params()
  l:run()

  -- params:set("lfo_mxsynths_pan",2)
  -- params:set("lfo_mxsynths_sub",2)
  -- params:set("lfo_mxsynths_mod1",2)
  -- params:set("lfo_mxsynths_mod2",2)
  -- params:set("lfo_mxsynths_mod3",2)
  -- params:set("lfo_mxsynths_mod4",2)


  l.ready=true

  params:set("chordy_start",1)

  return l
end

function MxSynths:setup_chord_sequencer()
  -- initiate sequencer
  chordy=chordsequencer_:new({lattice=self.lattice})
  chordy.note_on=function(note)
    self:note_on(note,0.5,10)
  end
  chordy.note_off=function(note)
    self:note_off(note)   
  end
end

function MxSynths:setup_arp()
  self.arp=Arp:new({lattice=self.lattice})
  self.arp.note_on=function(note)
    print("arp: "..note)
    engine.mx_note_on(note,0.5,2)
  end
  self.arp.note_off=function(note)
    engine.mx_note_off(note)
  end
end

function MxSynths:note_on(note,amp,duration)
  if params:get("arp_start")==1 then 
    self.arp:add(note)
    self.arp:start()
  else
    print("note_on: "..note)
    engine.mx_note_on(note,amp,duration)
  end
end

function MxSynths:note_off(note)
  if params:get("arp_start")==1 then 
    self.arp:remove(note)
    engine.mx_note_off(note)
  else
    engine.mx_note_off(note)
  end
end

function MxSynths:play(s)
  -- note velocity (1-127) amp tune pan sub attack decay sustain release mod1 mod2 mod3 mod4
  for k,v in pairs(s) do
    if k~="note" and k~="velocity" and k~="synth" then
      params:set("mxsynths_"..k,v)
    end
  end
  if s.synth~=nil then
    for i,syn in ipairs(self.synths) do
      if syn==s.synth then
        params:set("mxsynths_synth",i)
      end
    end
  end
  if s.velocity==nil then
    s.velocity=64
  end
  local duration=params:get("mxsynths_attack")
  duration=duration+params:get("mxsynths_decay")
  duration=duration+params:get("mxsynths_release")
  self:note_on(s.note,self.velocities[params:get("mxsynths_sensitivity")][math.floor(s.velocity+1)]/127,duration)
end

function MxSynths:run()
  self.waiting_to_save=false
  self.debouncer=0
  clock.run(function()
    while true do
      clock.sleep(1/10)
      self:lfo()
      if self.debouncer>0 then
        if self.debouncer==1 then
          params:write(_path.data.."mx.synths/default.pset")
        end
        self.debouncer=self.debouncer-1
      end
    end
  end)
end

function MxSynths:save(pname)
  if not self.ready then
    do return end
  end
  if not self.save_on_change then
    do return end
  end
  local has_lfo=pcall(function() params:get("lfo_mxsynths_"..pname) end)
  if has_lfo then
    if params:get("lfo_mxsynths_"..pname)==2 then
      do return end
    end
  end
  -- reset debounce
  self.debouncer=10
  -- if self.waiting_to_save then
  --   do return end
  -- end
  -- self.waiting_to_save=true
  -- clock.run(function()
  --   print("waiting to save")
  --   while self.debouncer>0 do
  --     clock.sleep(1)
  --     print(self.debouncer)
  --   end
  --   print("saving "..self.synths[params:get("mxsynths_synth")])
  --   -- save for current synth
  --   params:write(_path.data.."mx.synths/mx/mx-0"..params:get("mxsynths_synth")..".pset",self.synths[params:get("mxsynths_synth")])
  --   self.waiting_to_save=false
  -- end)
end

function MxSynths:current_synth()
  return self.synths[params:get("mxsynths_synth")]
end

function MxSynths:create_lfo_param(name,range,default)
  params:add_option("lfo_mxsynths_"..name,name.." lfo",{"off","on"},1)
  params:set_action("lfo_mxsynths_"..name,function(x)
    self:refresh_params()
  end)
  params:add {
    type='control',
    id="lfolo_mxsynths_"..name,
    name=name.." lfo lo",
  controlspec=controlspec.new(range[1],range[2],'lin',0.01,default[1],'',0.01/(range[2]-range[1]))}
  params:add {
    type='control',
    id="lfohi_mxsynths_"..name,
    name=name.." lfo hi",
  controlspec=controlspec.new(range[1],range[2],'lin',0.01,default[2],'',0.01/(range[2]-range[1]))}
  params:add {
    type='control',
    id="lfoperiod_mxsynths_"..name,
    name=name.." lfo period",
  controlspec=controlspec.new(0,60,'lin',0.1,math.random(1,60),'s',0.1/60)}
  params:add {
    type='control',
    id="lfophase_mxsynths_"..name,
    name=name.." lfo phase",
  controlspec=controlspec.new(0,3,'lin',0.01,math.random(1,300)/100,'s',0.01/3)}
end

function MxSynths:refresh_params()
  local lfoparms={"lo","hi","period","phase"}
  for k,v in pairs(params.params) do
    if v.id then
      if self:has_prefix(v.id,"lfo_") then
        if params:get(v.id)==2 then
          -- lfo is on
          for _,p in ipairs(lfoparms) do
            params:show(v.id:gsub("lfo_","lfo"..p.."_"))
          end
        else
          for _,p in ipairs(lfoparms) do
            params:hide(v.id:gsub("lfo_","lfo"..p.."_"))
          end
        end
      end
    end
  end
  _menu.rebuild_params()
end

function MxSynths:lfo()
  local t=clock.get_beats()*clock.get_beat_sec()
  for _,lfoname in ipairs(self.lfos) do
    if params:get("lfo_mxsynths_"..lfoname)==2 then
      -- lfo is active
      local val=math.sin(2*math.pi*t/params:get("lfoperiod_mxsynths_"..lfoname)+params:get("lfoperiod_mxsynths_"..lfoname))
      val=util.linlin(-1,1,params:get("lfolo_mxsynths_"..lfoname),params:get("lfohi_mxsynths_"..lfoname),val)
      params:set("mxsynths_"..lfoname,val)
    end
  end
  -- check if any lfos are activated
  -- if period==0 then
  --   return 1
  -- else
  --   return math.sin(2*math.pi*current_time/period+offset)
  -- end
end

function MxSynths:setup_midi()
  -- get list of devices
  local mididevice={}
  local mididevice_list={"none"}
  midi_channels={"all"}
  for i=1,16 do
    table.insert(midi_channels,i)
  end
  for _,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local name=string.lower(dev.name)
      table.insert(mididevice_list,name)
      print("adding "..name.." to port "..dev.port)
      mididevice[name]={
        name=name,
        port=dev.port,
        midi=midi.connect(dev.port),
        active=false,
      }
      mididevice[name].midi.event=function(data)
        if mididevice[name].active==false then
          do return end
        end
        local d=midi.to_msg(data)
        if d.ch~=midi_channels[params:get("midichannel")] and params:get("midichannel")>1 then
          do return end
        end
        if d.type=="note_on" then
          self:note_on(d.note,self.velocities[params:get("mxsynths_sensitivity")][math.floor(d.vel+1)]/127,600)
        elseif d.type=="note_off" then
          self:note_off(d.note)
        elseif d.type=="pitchbend" then
          local bend_st = (util.round(d.val / 2)) / 8192 * 2 -1 -- Convert to -1 to 1
          engine.mx_set("bend", bend_st * params:get("bend_range"))
        elseif d.cc==64 then -- sustain pedal
          local val=d.val
          if val>126 then
            val=1
          else
            val=0
          end
          if params:get("mxsynths_pedal_mode")==1 then
            engine.mx_sustain(val)
          else
            engine.mx_sustenuto(val)
          end
        end
      end
    end
  end
  tab.print(mididevice_list)

  params:add{type="option",id="midi",name="midi in",options=mididevice_list,default=1}
  params:set_action("midi",function(v)
    if v==1 then
      do return end
    end
    for name,_ in pairs(mididevice) do
      mididevice[name].active=false
    end
    mididevice[mididevice_list[v]].active=true
  end)
  params:add{type="option",id="midichannel",name="midi ch",options=midi_channels,default=1}
  params:add_number("bend_range", "bend range", 1, 48, 2)


  if #mididevice_list>1 then
    params:set("midi",2)
  end
end

function MxSynths:has_prefix(s,prefix)
  return s:find(prefix,1,#prefix)~=nil
end

return MxSynths
