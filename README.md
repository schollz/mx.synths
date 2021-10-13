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


mx.synths has a bunch of different synths. each one has four "mod" parameters that are synth specific. usually mods 2 and 3 are frequency and resonance respectively and usually mod 4 is detuning.

all synths share a parameters which can be found in the `MX.SYNTHS` PSET menu. most the parameters are evident. one special parameter is called "sub". sub is synth specific (and not implemented in every synth) which activates some sound with low-note priority. many of the parameters have lfos. since all synths share the parameters menu, you should *save your settings* if you find a patch you like (`PSET > SAVE`), so it is easier to come back to. I am planning making patch saving easiaer via the PSET (also making it synth specific).

## ideas/roadmap

- [ ] synth-specific PSET save/load
- [ ] add BPeakEQ to the fx stage
- [ ] add tremelo to the fx stage
- [ ] add noise version of each synth (noise level, adsr)
- [ ] add one-shot API for integrating into one-shot scripts
- [ ] integrate into other scripts?

## the synths

![piano](https://user-images.githubusercontent.com/6550035/137188153-420d65bd-c950-4098-abb1-558795be86fa.png)

**piano**: this is an 'acoustic piano'-like synth from @zebra's [DreadMoon engine](https://github.com/catfact/zebra/blob/master/lib/Engine_DreadMoon.sc#L20-L41). it is essentialy noise being filtered through a comb filter. the mod parameters can make it sound more like a drum than a piano sometimes.


![epiano](https://user-images.githubusercontent.com/6550035/137188151-2bb3c65b-3885-422a-857c-859e9c0a146e.png)

**epiano**: this is an electric piano based on FM rhodes type sounds. it is taken with minimal adjustments from [snappizz's FM Rhodes SynthDef](https://sccode.org/1-522).

![casio](https://user-images.githubusercontent.com/6550035/137188146-f893c656-6e16-4150-a72f-0057733f7f8d.png)

**casio**: this is an emulation of the phase distortion synthesis from the 1984 Casio CZ-101. I implemented it purely based [on their patent](https://schollz.com/blog/phasedistortion/) and has all sorts of weird artifacts.

![malone](https://user-images.githubusercontent.com/6550035/137188150-b87db2e6-a332-42be-9b1d-be003a004303.png)

**malone**: malone comes from designing an organ sound for a drone. it is a heavily modified version of [Svdk Vedeka's port of Coloscope's pure-data organ](https://sccode.org/svdk-vedeka).

![toshiya](https://user-images.githubusercontent.com/6550035/137188149-12df22e8-63c1-4b04-aa46-61f9dca22929.png)

**toshiya**: this is a another from sound designing for making drones. I [wrote about it here](https://llllllll.co/t/12-000/48354#toshiyahttpsgithubcomschollz12000blobmaindronetoshiyascd-object-bound-resonate-space-2). it has a klank sound that can be modulated.

![synthy](https://user-images.githubusercontent.com/6550035/137188143-2dc07d18-e1fd-4dab-841c-194dcbf612dd.png)

**synthy**: this is the basis of a couple of synths - [starlids](https://llllllll.co/t/12-000/48354#starlidshttpsgithubcomschollz12000blobmaindronestarlidsscd-symphonic-meek-radiant-1) and [synthy](https://llllllll.co/t/synthy/48062), this is yet another iteration.


![polyperc](https://user-images.githubusercontent.com/6550035/137188141-7d1aad4d-2c2a-43c5-ab17-33bdb555966b.png)

**PolyPerc**: this is the classic PolyPerc engine from @tehn, with some adjustments.

### contributions

please feel free to contribute your own synth! its quite easy - you can simply make a SynthDef and design it so it can be modulated by 4 parameters that vary between -1 and +1. see the code for examples. you can make a graphics screen if you want too, or use a default one.

## thanks


this script wouldn't exist without @zebra, who gave me lots of guidance in SuperCollider in general and also the "piano" is from their [DreadMoon engine](https://github.com/catfact/zebra/blob/master/lib/Engine_DreadMoon.sc#L20-L41). thanks also to @tehn, a version of [PolyPerc](https://github.com/monome/dust/blob/master/lib/sc/Engine_PolyPerc.sc) is in this engine. and thanks to [@snappiz](https://sccode.org/snappizz) which the "epiano" is adapted.

## Install

install with

```
;install https://github.com/schollz/mx.synths
```

https://github.com/schollz/mx.synths


