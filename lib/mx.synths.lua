local MusicUtil=require "musicutil"
local Formatters=require 'formatters'

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
  l.synths={"epiano","malone","toshiya","casio","piano","synthy","PolyPerc"}
  l.presets={}
  l.presets["synthy"]={"massive"}

  params:add_group("MX.SYNTHS",19)

  -- synth selector
  params:add_option("mxsynths_synth","synth",l.synths,1)
  params:set_action("mxsynths_synth",function(x)
    engine.mx_set_synth(l.synths[x])
  end)

  -- polyphony selector
  params:add_option("mxsynths_polyphony","polyphony",{"polyphonic","monophonic"},1)
  params:set_action("mxsynths_polyphony",function(x)
    engine.mx_set("monophonic",x-1)
  end)

  -- amp
  params:add{type="control",id="mxsynths_amp",name="volume",controlspec=controlspec.new(-96,20,'lin',1,-9,'',1/(20+96)),formatter=function(v)
    local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
    return ((val<0) and "" or "+")..val.." dB"
  end}
  params:set_action("mxsynths_amp",function(x)
    engine.mx_set("amp",util.dbamp(x))
  end)

  params:add{type="control",id="mxsynths_sub",name="sub",controlspec=controlspec.new(-96,20,'lin',1,-9,'',1/(20+96)),formatter=function(v)
    local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
    return ((val<0) and "" or "+")..val.." dB"
  end}
  params:set_action("mxsynths_sub",function(x)
    engine.mx_set("sub",util.dbamp(x))
  end)

  params:add {
    type='control',
    id="mxsynths_pan",
    name="pan",
    controlspec=controlspec.new(-1,1,'lin',0,0),
    action=function(x)
      engine.mx_set("pan",x)
    end
  }

  params:add {
    type='control',
    id="mxsynths_attack",
    name="attack",
    controlspec=controlspec.new(0,10,'lin',0.01,0.01,'s',0.01/10),
    action=function(x)
      engine.mx_set("attack",x)
    end
  }

  params:add {
    type='control',
    id="mxsynths_decay",
    name="decay",
    controlspec=controlspec.new(0,10,'lin',0,1,'s'),
    action=function(x)
      engine.mx_set("decay",x)
    end
  }

  params:add {
    type='control',
    id="mxsynths_sustain",
    name="sustain",
    controlspec=controlspec.new(0,2,'lin',0,0.9,'amp'),
    action=function(x)
      engine.mx_set("sustain",x)
    end
  }

  params:add {
    type='control',
    id="mxsynths_release",
    name="release",
    controlspec=controlspec.new(0,10,'lin',0,1,'s'),
    action=function(x)
      engine.mx_set("release",x)
    end
  }

  for i=1,4 do
    params:add {
      type='control',
      id="mxsynths_mod"..i,
      name="mod"..i,
      controlspec=controlspec.new(0,1,'lin',0.01,0,'',0.01/1),
      action=function(x)
        engine.mx_set("mod"..i,x)
      end
    }
  end

  params:add {
    type='control',
    id="mxsynths_tune",
    name="tune",
    controlspec=controlspec.new(-100,100,'lin',0,0,'cents',1/200),
    action=function(x)
      engine.mx_set("tune",x/100)
    end
  }

  params:add {
    type='control',
    id='mxsynths_lpf_mxsynths',
    name='low-pass filter',
    controlspec=filter_freq,
    formatter=Formatters.format_freq,
    action=function(x)
      engine.mx_fxset("lpf",x)
    end
  }

  params:add {
    type='control',
    id="mxsynths_delay_send",
    name="delay send",
    controlspec=controlspec.new(0,100,'lin',0,30,'%',1/100),
    action=function(x)
      engine.mx_fxset("delay",x/100)
    end
  }

  params:add {
    type='control',
    id="mxsynths_delay_times",
    name="delay iterations",
    controlspec=controlspec.new(0,100,'lin',0,11,'beats',1/100),
    action=function(x)
      engine.mx_fxset("delayFeedback",x/100)
    end
  }

  params:add_option("mxsynths_delay_rate","delay rate",delay_rates_names,3)
  params:set_action("mxsynths_delay_rate",function(x)
    engine.mx_fxset("delayBeats",delay_rates[x])
  end)

  params:add_option("mxsynths_pedal_mode","pedal mode",{"sustain","sostenuto"},1)

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

  engine.mx_fxset("secondsPerBeat",clock.get_beat_sec())

  params:bang()
  return l
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
          engine.mx_note_on(d.note,d.vel/127/2+0.5)
        elseif d.type=="note_off" then
          engine.mx_note_off(d.note)
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

  if #mididevice_list>1 then
    params:set("midi",2)
  end
end

return MxSynths
