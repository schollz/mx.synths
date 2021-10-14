# mx.synths

mx.samples: like mr.coffee or mr.radar, but for instrument synths. (companion to [mx.samples](https://github.com/schollz/mx.samples)).

https://vimeo.com/631313246


## Requirements

- norns
- midi keyboard

## Documentation

- K2/K3 changes instrument
- E1 controls mod1
- E2 controls mod2
- E3 controls mod3
- K1+any E controls mod4


mx.synths is a collection of eclectic polyphonic synths.

each synth has a specific style that can be tweakable via "mod" parameters. their are four mod parameters and they are synth-specific (though usually mods 2 and 3 are frequency and resonance respectively and usually mod 4 is detuning). all other parameters - found in the `MX.SYNTHS` PSET menu - are shared for each synth. most the parameters are evident (delay send, adsr, etc.). one special parameter is called "sub". sub is synth specific (and not implemented in every synth) which activates some sound with low-note priority. many of the parameters have lfos. 

since all synths share the parameters menu, you should save your settings if you find a patch you like (`PSET > SAVE`), so it is easier to come back to. I am planning making patch saving easiaer via the PSET (also making it synth specific).

### the synths

![piano](https://user-images.githubusercontent.com/6550035/137188153-420d65bd-c950-4098-abb1-558795be86fa.png)

**piano**: this is an 'acoustic piano'-like synth from @zebra's [DreadMoon engine](https://github.com/catfact/zebra/blob/master/lib/Engine_DreadMoon.sc#L20-L41). it is essentialy noise being filtered through a comb filter. the mod parameters can make it sound more like a drum than a piano sometimes. mods:
1. decay
2. noise freq
3. resonance
4. detuning


![epiano](https://user-images.githubusercontent.com/6550035/137188151-2bb3c65b-3885-422a-857c-859e9c0a146e.png)

**epiano**: this is an electric piano based on FM rhodes type sounds. it is taken with minimal adjustments from [snappizz's FM Rhodes SynthDef](https://sccode.org/1-522). mods:
1. lfo depth
2. mix 
3. modulator index
4. lfo speed

![casio](https://user-images.githubusercontent.com/6550035/137188146-f893c656-6e16-4150-a72f-0057733f7f8d.png)

**casio**: this is an emulation of the phase distortion synthesis from the 1984 Casio CZ-101. I implemented it purely based [on their patent](https://schollz.com/blog/phasedistortion/) and has all sorts of weird artifacts. mods:
1. artfiacts
2. phasing
3. resonance
4. detuning

![malone](https://user-images.githubusercontent.com/6550035/137188150-b87db2e6-a332-42be-9b1d-be003a004303.png)

**malone**: malone comes from designing an organ sound for a drone. it is a heavily modified version of [Svdk Vedeka's port of Coloscope's pure-data organ](https://sccode.org/svdk-vedeka). mods:
1. detuning speed
2. filter
3. resonance
4. detuning

![toshiya](https://user-images.githubusercontent.com/6550035/137188149-12df22e8-63c1-4b04-aa46-61f9dca22929.png)

**toshiya**: this is a another from sound designing for making drones. I [wrote about it here](https://llllllll.co/t/12-000/48354#toshiyahttpsgithubcomschollz12000blobmaindronetoshiyascd-object-bound-resonate-space-2). it has a klank sound that can be modulated. mods:
1. pitch spread
2. klank volume
3. filter oscillator
4. detuning

![synthy](https://user-images.githubusercontent.com/6550035/137188143-2dc07d18-e1fd-4dab-841c-194dcbf612dd.png)

**synthy**: this is the basis of a couple of synths - [starlids](https://llllllll.co/t/12-000/48354#starlidshttpsgithubcomschollz12000blobmaindronestarlidsscd-symphonic-meek-radiant-1) and [synthy](https://llllllll.co/t/synthy/48062), this is yet another iteration. mods:
1. stereo spread
2. filter spread
3. resonance
4. detuning


![polyperc](https://user-images.githubusercontent.com/6550035/137188141-7d1aad4d-2c2a-43c5-ab17-33bdb555966b.png)

**PolyPerc**: this is the classic PolyPerc engine from @tehn, with some adjustments. mods:
1. pulse width
2. filter
3. resonance
4. detuning

### usage as library

mx.synths can be included in other libraries. its probably easiest to change the engine and import the menu library:

```lua
engine.name="MxSynths"
local mxsynths_=include("mx.synths/lib/mx.synths")
mxsynths=mxsynths_:new()
```

now you can edit the current sound by directly editing the parameters, as all the parameters will update the engine. to then play a note you can use

```lua
engine.mx_note_on(<midi>,<amp>,<duration>)
```

the `<duration>` is the number of seconds to automatically release. it effectively lets you choose whether it will play as a "one-shot" synth. if you want it to be "one-shot" then set the duration to the duration you want and it will be released after. if you want to instead use it with note off signals, then you should set `<duration>` to a large number (like 600 seconds). then you can tell it when you want to do the release by sending a subsequent command:

```lua
engine.mx_note_off(<midi>)
```

### limitations

there are a couple limitations that may become obvious when you spend time with mx.synths. 

first - while you *can* play multiple synth voices simultaneously, the way I wrote the engine is such that only all synth voices will voice-steal from each other if they are playing the *same note*. (also currently there isn't a engine command to send all the parameters, rather the parameters are gathered from the PSET menu, but that can be added soon). 

second - polyphony is not limited in the engine, but it will be limited by the norns cpu. probably 4-6 polyphony is the max for most synths. setting a quick release if you can will help with this. the synths could also be better optimized I'm sure.


### making your own synth

any and all contributions are welcome and accepted.

making your own synth is a simple process. there are three basic steps.

1. make your SynthDef. start with a basic SynthDef like this:

```supercollider
SynthDef("yoursynth",{
    arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,
    attack=0.01,decay=0.2,sustain=0.9,release=5,
    mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
    var snd,env,pw;
    mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
    hz=Lag.kr(hz,portamento).cpsmidi;
    env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);

    // <yoursynth>
    
    // (optional but recommended) map the mods to something/
    // mods always are limited to [-1,1]
    pw=LinLin.kr(mod1,-1,1,0.2,0.8);

    // make some sound
    snd = Pulse.ar(hz,width:pw);
    
    // </yoursynth>

    snd = Pan2.ar(snd,Lag.kr(pan,0.1));
    Out.ar(out,snd*env*amp/8);
}).add;
```

once you finish, you can paste it into the `Engine_MxSynths.sc`, like [around here](https://github.com/schollz/mx.synths/blob/main/lib/Engine_MxSynths.sc#L35).

2. add "your synth" to the registry. edit `l.synths` in the [lib/mx.synths.lua](https://github.com/schollz/mx.synths/blob/7a1ed748fb2836828ead289af0524019ca901592/lib/mx.synths.lua#L18) script to include the name of your synth. make sure it matches exactly what you named your SynthDef is step #1.

3. (optional) add some graphics for your synth. simply write a function that draws something to the screen and update `redraw()` [in mx.synths.lua](https://github.com/schollz/mx.synths/blob/7a1ed748fb2836828ead289af0524019ca901592/mx.synths.lua#L75) to run your function when it is selected.



## Thanks

this script wouldn't exist without @zebra, who gave me lots of guidance in SuperCollider in general and also the "piano" is from their [DreadMoon engine](https://github.com/catfact/zebra/blob/master/lib/Engine_DreadMoon.sc#L20-L41). thanks also to @tehn, a version of [PolyPerc](https://github.com/monome/dust/blob/master/lib/sc/Engine_PolyPerc.sc) is in this engine. and thanks to [@snappiz](https://sccode.org/snappizz) which the "epiano" is adapted.



## Ideas/Roadmap

- [ ] fix monophonic/portamento
- [ ] synth-specific PSET save/load
- [ ] add BPeakEQ to the fx stage
- [ ] add tremelo to the fx stage
- [ ] add noise version of each synth (noise level, adsr)
- [ ] add one-shot API for integrating into one-shot scripts
- [ ] integrate into other scripts?



## Install

install with

```
;install https://github.com/schollz/mx.synths
```

https://github.com/schollz/mx.synths


