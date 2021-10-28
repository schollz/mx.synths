// Engine_MxSynths
Engine_MxSynths : CroneEngine {
	// <mx>
	var mxParameters;
	var mxVoices;
	var mxVoicesOn;
	var mxSynthFX;
	var mxBusFx;
	var fnNoteOn, fnNoteOnMono, fnNoteOnPoly, fnNoteAdd;
	var fnNoteOff, fnNoteOffMono, fnNoteOffPoly;
	var updateSub;
	var pedalSustainOn=false;
	var pedalSostenutoOn=false;
	var pedalSustainNotes;
	var pedalSostenutoNotes;
	var mxPolyphonyMax=20;
	var mxPolyphonyCount=0;
	// </mx>


	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		// <mx>
		// initialize variables
		mxParameters=Dictionary.with(*["synth"->"synthy","sub"->1.0,"amp"->1.0,
			"portamento"->0.0,"monophonic"->0.0,
			"pan"->0.0,"tune"->0.0,"bend"->0.0,
			"attack"->1.0,"decay"->0.2,"sustain"->0.9,"release"->5.0,
			"mod1"->0.0,"mod2"->0.0,"mod3"->0.0,"mod4"->0.0]);
		mxVoices=Dictionary.new;
		mxVoicesOn=Dictionary.new;
		pedalSustainNotes=Dictionary.new;
		pedalSostenutoNotes=Dictionary.new;

		// initialize synth defs
		SynthDef("mxfx",{
			arg out=0, inBus=10, 
			lpf=20000, delay=0,
			secondsPerBeat=1,delayBeats=4,delayFeedback=0.1;

			var snd, snd2;

			snd=In.ar(inBus,2);
	
			// // add flanger
			// flanger = snd+LocalIn.ar(2); //add some feedback
			// flanger= DelayN.ar(flanger,0.02,SinOsc.kr(0.1,0,0.005,0.005)); //max delay of 20msec
			// LocalOut.ar(0.5*flanger);
			// snd=SelectX.ar(flang,[snd,flanger]);

			// lpf
			snd = LPF.ar(snd.tanh,Lag.kr(lpf,1));
			
			// delay
			snd = snd + (delay * CombL.ar(
				snd,
				2,
				secondsPerBeat*delayBeats,
				secondsPerBeat*delayBeats*LinLin.kr(delayFeedback,0,1,2,128),// delayFeedback should vary between 2 and 128
			)); 

			// todo:
			// add tremelo
			// env=env*Clip.ar(1+(perturb2val*LFPar.ar(perturb2val*10).range(-1,0)));

			Out.ar(out,snd);
		}).add;

		SynthDef("synthy",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,note,env,detune,stereo,lowcut,chorus,res;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			note=Lag.kr(hz,portamento).cpsmidi+bend;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			sub=Lag.kr(sub,1);
			snd=Pan2.ar(Pulse.ar((note-12).midicps,LinLin.kr(LFTri.kr(0.5),-1,1,0.2,0.8))*sub);
			stereo=LinLin.kr(mod1,-1,1,0,1);
			lowcut=LinExp.kr(mod2,-1,1,25,11000);
			res=LinExp.kr(mod3,-1,1,0.25,1.75);
			detune=LinExp.kr(mod4,-1,1,0.00001,0.3);
			snd=snd+Mix.ar({
				arg i;
				var snd2;
				snd2=SawDPW.ar((note+(detune*(i*2-1))).midicps);
				snd2=RLPF.ar(snd2,LinExp.kr(SinOsc.kr(rrand(1/30,1/10),rrand(0,2*pi)),-1,1,lowcut,12000),res);
				snd2=DelayC.ar(snd2, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/15);
				Pan2.ar(snd2,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine)*stereo)
			}!2);
			snd = Balance2.ar(snd[0],snd[1],Lag.kr(pan,0.1));
			Out.ar(out,snd*env*amp/8);
		}).add;

		SynthDef("casio",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var freq, env, freqBase, freqRes, pdbase, pd, pdres, pdi, snd,res,detuning,artifacts,phasing;
			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			artifacts=LinLin.kr(mod1,-1,1,1,10);
			phasing=LinExp.kr(mod2,-1,1,0.125,8);
			res=LinExp.kr(mod3,-1,1,0.1,10);
			detuning=LinExp.kr(mod4,-1,1,0.000001,0.02);
			freq=[hz*(1-detuning),hz*(1+detuning)];
			freqBase=freq;
			freqRes=SinOsc.kr(Rand(0.01,0.2),0).range(freqBase/2,freqBase*2)*res;
			pdbase=Impulse.ar(freqBase);
			pd=Phasor.ar(pdbase,2*pi*freqBase/context.server.sampleRate*phasing,0,2pi);
			pdres=Phasor.ar(pdbase,2*pi*freqRes/context.server.sampleRate*phasing,0,2pi);
			pdi=LinLin.ar((2pi-pd).max(0),0,2pi,0,1);
			snd=Lag.ar(SinOsc.ar(0,pdres)*pdi,1/freqBase);
			snd = LPF.ar(snd,Clip.kr(hz*artifacts,20,18000));
			snd = Pan2.ar(snd,Lag.kr(pan,0.1));
			Out.ar(out,snd*env*amp/5);
		}).add;

		SynthDef("icarus",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=1.0,portamento=1,bend=0,
			attack=0.1,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=1;
			var bass,basshz,feedback=0.5,delaytime=0.25, delaytimelag=0.1;
			var ender,snd,local,in,ampcheck,env,detuning=0.1,pwmcenter=0.5,pwmwidth=0.4,pwmfreq=1.5;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);

			feedback=LinLin.kr(mod1,-1,1,0.1,2);
			delaytime=LinLin.kr(mod2,-1,1,0.05,0.6);
			pwmwidth=LinLin.kr(mod3,-1,1,0.1,0.9);
			detuning=LinExp.kr(mod4,-1,1,0.01,1);

			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			snd=Mix.new({VarSaw.ar(
				hz+(SinOsc.kr(LFNoise0.kr(1),Rand(0,3))*
					(((hz).cpsmidi+1).midicps-(hz))*detuning),
				width:LFTri.kr(pwmfreq+rrand(0.1,0.3),mul:pwmwidth/2,add:pwmcenter),
				mul:0.25
			)}!2);
			snd=snd+Mix.new({VarSaw.ar(
				hz/2+(SinOsc.kr(LFNoise0.kr(1),Rand(0,3))*
					(((hz/2).cpsmidi+1).midicps-(hz/2))*detuning),
				width:LFTri.kr(pwmfreq+rrand(0.1,0.3),mul:pwmwidth/2,add:pwmcenter),
				mul:0.15
			)}!2);

			basshz=hz;
			basshz=Select.kr(basshz>90,[basshz,basshz/2]);
			basshz=Select.kr(basshz>90,[basshz,basshz/2]);
			bass=PulseDPW.ar(basshz,width:SinOsc.kr(1/3).range(0.2,0.4));
			bass=bass+LPF.ar(WhiteNoise.ar(SinOsc.kr(1/rrand(3,4)).range(1,rrand(3,4))),2*basshz);
			bass = Pan2.ar(bass,LFTri.kr(1/6.12).range(-0.2,0.2));
			bass = HPF.ar(bass,20);
			bass = LPF.ar(bass,SinOsc.kr(0.1).range(2,5)*basshz);


			ampcheck = Amplitude.kr(Mix.ar(snd));
			snd = snd * (ampcheck > 0.02); // noise gate
			local = LocalIn.ar(2);
			local = OnePole.ar(local, 0.4);
			local = OnePole.ar(local, -0.08);
			local = Rotate2.ar(local[0], local[1],0.2);
			local = DelayC.ar(local, 0.5,
				Lag.kr(delaytime,0.2)
			);
			local = LeakDC.ar(local);
			local = ((local + snd) * 1.25).softclip;

			LocalOut.ar(local*Lag.kr(feedback,1));


			snd= Balance2.ar(local[0],local[1],pan);
			snd=snd+(SinOsc.kr(0.123,Rand(0,3)).range(0.2,1.0)*bass*sub);

			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);

			Out.ar(out,snd*env*amp/8);
		}).add;

		// port of STK's Rhodey (yamaha DX7-style Fender Rhodes) https://sccode.org/1-522
		SynthDef("epiano",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;

			// all of these range from 0 to 1
			var vel = 0.8, modIndex = 0.2, mix = 0.2, lfoSpeed = 0.4, lfoDepth = 0.1;
			var env1, env2, env3, env4;
			var osc1, osc2, osc3, osc4, snd;
			var env;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			lfoDepth=LinExp.kr(mod1,-1,1,0.01,1);
			mix=LinLin.kr(mod2,-1,1,0.0,0.4);
			modIndex=LinExp.kr(mod3,-1,1,0.01,4);
			lfoSpeed=LinLin.kr(mod4,-1,1,0,0.5);

			lfoSpeed = lfoSpeed * 12;

			hz = hz * 2;

			env1 = EnvGen.ar(Env.adsr(0.001, 1.25, 0.5, release, curve: \lin),gate);
			env2 = EnvGen.ar(Env.adsr(0.001, 1.00, 0.5, release, curve: \lin),gate);
			env3 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.5, release, curve: \lin),gate);
			env4 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.5, release, curve: \lin),gate);

			osc4 = SinOsc.ar(hz * 0.5) * 2pi * 2 * 0.535887 * modIndex * env4 * vel;
			osc3 = SinOsc.ar(hz, osc4) * env3 * vel;
			osc2 = SinOsc.ar(hz * 15) * 2pi * 0.05 * env2 * vel;
			osc1 = SinOsc.ar(hz, osc2) * env1 * vel;
			snd = Mix((osc3 * (1 - mix)) + (osc1 * mix));
			snd = snd * (SinOsc.ar(lfoSpeed) * lfoDepth + 1);

			snd = Pan2.ar(snd,Lag.kr(pan,0.1));
			Out.ar(out,snd*env*amp/8);
		}).add;


		SynthDef("toshiya",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,note,env,detune,stereo,lowcut,chorus,klanky,klankyvol;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			detune=LinExp.kr(mod1,-1,1,0.001,0.1);
			klankyvol=LinLin.kr(mod2,-1,1,0,2);
			lowcut=LinExp.kr(mod3,-1,1,25,11000);
			chorus=LinExp.kr(mod4,-1,1,0.2,5);
			
			note=Lag.kr(hz,portamento).cpsmidi + bend;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			sub=Lag.kr(sub,1);
			snd=Pan2.ar(SinOsc.ar((note-12).midicps,LinLin.kr(LFTri.kr(0.5),-1,1,0.2,0.8))/12*amp,SinOsc.kr(0.1,mul:0.2))*sub;
			snd=snd+Mix.ar({
				arg i;
				var snd2;
				snd2=SinOsc.ar((note+(detune*(i*2-1))).midicps);
				snd2=LPF.ar(snd2,LinExp.kr(SinOsc.kr(rrand(1/30,1/10),rrand(0,2*pi)),-1,1,lowcut,12000),2);
				snd2=DelayC.ar(snd2, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/NRand(10,20,3)*chorus );
				Pan2.ar(snd2,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine))
			}!2);
			snd=snd+(Amplitude.kr(snd)*VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0.1,1.0)*klankyvol*Klank.ar(`[[hz, hz*2+2, hz*4+5, hz*8+2], nil, [1, 1, 1, 1]], PinkNoise.ar([0.007, 0.007])));
			snd = Balance2.ar(snd[0],snd[1],Lag.kr(pan,0.1));
			Out.ar(out,snd*env*amp/8);
		}).add;

		SynthDef("malone",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,note,env, basshz,bass, detuning,pw, res,filt,detuningSpeed;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			
			detuningSpeed=LinExp.kr(mod1,-1,1,0.1,10);
			filt=LinLin.kr(mod2,-1,1,2,10);
			res=LinExp.kr(mod3,-1,1,0.25,4);
			detuning=LinExp.kr(mod4,-1,1,0.002,0.8);
			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			note=hz.cpsmidi;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			snd=Mix.ar(Array.fill(2,{
				arg i;
				var hz_,snd_;
				hz_=((2*hz).cpsmidi+SinOsc.kr(detuningSpeed*Rand(0.1,0.5),Rand(0,pi)).range(detuning.neg,detuning)).midicps;
				snd_=PulseDPW.ar(hz_,0.17);
				snd_=snd_+PulseDPW.ar(hz_/2,0.17);
				snd_=snd_+PulseDPW.ar(hz_*2,0.17);
				snd_=snd_+LFTri.ar(hz_/4);
				snd_=RLPF.ar(snd_,Clip.kr(hz_*filt,hz_*1.5,16000),Clip.kr(LFTri.kr([0.5,0.45]).range(0.3,1)*res,0.2,2));
				Pan2.ar(snd_,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine))/10
			}));
			
			
			basshz=hz;
			basshz=Select.kr(basshz>90,[basshz,basshz/2]);
			basshz=Select.kr(basshz>90,[basshz,basshz/2]);
			bass=PulseDPW.ar(basshz,width:SinOsc.kr(1/3).range(0.2,0.4));
			bass=bass+LPF.ar(WhiteNoise.ar(SinOsc.kr(1/rrand(3,4)).range(1,rrand(3,4))),2*basshz);
			bass = Pan2.ar(bass,LFTri.kr(1/6.12).range(-0.2,0.2));
			bass = HPF.ar(bass,20);
			bass = LPF.ar(bass,SinOsc.kr(0.1).range(2,5)*basshz);
			snd=snd+(SinOsc.kr(0.123).range(0.2,1.0)*bass*sub);
			
			snd = Balance2.ar(snd[0],snd[1],Lag.kr(pan,0.1));
			Out.ar(out,snd*env*amp/8);
		}).add;


		// another resonate thing
		// http://sccode.org/1-4EG
		// (
		// {
		// 	var attack=1;
		// 	var dur=2;
		// 	var spread=0.8;
		// 	var freq=110;
		// 	var num=8;
		// 	var harm = Array.geom(num, 1, 1.5);
		// 	var harma = Array.geom(num, 0.5, 0.8);
		// 	var detune = Array.fill(num, { LFNoise2.kr(1,0.01,1) });
		// 	var source = SelectX.ar(MouseX.kr(),[PinkNoise.ar,BrownNoise.ar]);
		// 	var bandwidth = Rand(0.001,0.01);
		// 	var generator = [
		// 		SinOsc.ar(freq*harm*detune, mul:harma*0.3),
		// 		Resonz.ar(source, freq*harm*detune, bandwidth, mul:harma) * 50
		// 	].wchoose([0.2,0.8]);
		// 	var snd = Splay.ar(generator,spread);
		// 	snd
		// }.play;
		// )

		// http://sccode.org/1-51n
		SynthDef("kalimba",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=0.8,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=0.5;
			var snd,env,click,mix;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			env=EnvGen.ar(Env.adsr(attack,0,1.0,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			mix=LinLin.kr(mod4,-1,1,0.01,0.4);
			
			// Basic tone is a SinOsc
			snd = SinOsc.ar((hz.cpsmidi+mod4).midicps);
			snd = HPF.ar( LPF.ar(snd, 380), 40);
			// The "clicking" sounds are modeled with a bank of resonators excited by enveloped white noise
			click = DynKlank.ar(`[
				// the resonant frequencies are randomized a little to add variation
				// there are two high resonant freqs and one quiet "bass" freq to give it some depth
				[240*ExpRand(0.97, 1.02), 2020*ExpRand(0.97, 1.02), 3151*ExpRand(0.97, 1.02)],
				[-9, 0, -5].dbamp,
				[0.8, 0.07, 0.08]
			], BPF.ar(PinkNoise.ar, Rand(5500,8500), Rand(0.05,0.2)) * EnvGen.ar(Env.perc(0.001, 0.01)));
			snd = (snd*mix) + (click*(1-mix));
			snd = Splay.ar(snd,center:Rand(-1,1)*LinLin.kr(mod1,-1,1,0,1));

			snd=Vibrato.ar(
				snd,
				rate:LinExp.kr(mod2,-1,1,0.0001,20),
				depth:LinExp.kr(mod3,-1,1,0.0001,1)
			);
			
			snd = Balance2.ar(snd[0],snd[1],Lag.kr(pan,0.1));
			Out.ar(out,snd*env*amp);
		}).add;

		SynthDef("mdapiano",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,env,tuning;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			hz=Lag.kr(hz,portamento);
			env=EnvGen.ar(Env.adsr(attack,0,1.0,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);

			tuning=LinLin.kr(Clip.kr(mod4),0,1,0,1);
			snd=MdaPiano.ar(
				freq:hz,
				gate:gate,
				decay:decay,
				release:release,
				stereo:LinLin.kr(mod1,-1,1,0.3,1),
				vel:Rand(40,80),
				tune:Rand(0.5+tuning.neg,0.5+tuning)
			);
			snd=Vibrato.ar(
				snd,
				rate:LinExp.kr(mod2,-1,1,0.0001,20),
				depth:LinExp.kr(mod3,-1,1,0.0001,1)
			);
			snd = Pan2.ar(snd,Lag.kr(pan,0.1));
			Out.ar(out,snd*env*amp/6);
		}).add;

		// https://github.com/monome/dust/blob/master/lib/sc/Engine_PolyPerc.sc
		SynthDef("PolyPerc",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,filt,env,pw,co,gain,detune,note;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			hz=Lag.kr(hz,portamento);
			pw=LinLin.kr(mod1,-1,1,0.3,0.7);
			co=LinExp.kr(mod2,-1,1,hz,Clip.kr(10*hz,200,18000));
			gain=LinLin.kr(mod3,-1,1,0.25,3);
			detune=LinExp.kr(mod4,-1,1,0.00001,0.3);
			note=hz.cpsmidi + bend;
			snd = Pulse.ar([note-detune,note+detune].midicps, pw);
			snd = MoogFF.ar(snd,co,gain);
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			snd = Pan2.ar(snd,Lag.kr(pan,0.1));
			Out.ar(out,snd*env*amp/12);
		}).add;

		// https://github.com/catfact/zebra/blob/master/lib/Engine_DreadMoon.sc#L20-L41
		SynthDef("piano",{
			arg out=0,hz=220,amp=1.0,pan=0,gate=1,
			sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,duration=600;
			var snd,note,env, damp;
			var noise, string, delaytime, lpf, noise_env, damp_mul;
			var noise_hz = 4000, noise_attack=0.002, noise_decay=0.06,
			tune_up = 1.0005, tune_down = 0.9996, string_decay=3.0,
			lpf_ratio=2.0, lpf_rq = 4.0, hpf_hz = 40, damp_time=0.1;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);

			// mods
			string_decay=LinLin.kr(mod1,-1,1,0.1,6);
			noise_hz=LinExp.kr(mod2,-1,1,200,16000);
			lpf_rq=LinLin.kr(mod3,-1,1,0.1,8);
			tune_up=1+LinLin.kr(mod4,-1,1,0.0001,0.0005*4);
			tune_down=1-LinLin.kr(mod4,-1,1,0.00005,0.0004*4);
			
			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);

			damp = 0;
			damp_mul = LagUD.ar(K2A.ar(1.0 - damp), 0, damp_time);

			noise_env = Decay2.ar(Impulse.ar(0));
			noise = LFNoise2.ar(noise_hz) * noise_env;

			delaytime = 1.0 / (hz * [tune_up, tune_down]);
			string = Mix.new(CombL.ar(noise, delaytime, delaytime, string_decay * damp_mul));

			snd = RLPF.ar(string, lpf_ratio * hz, lpf_rq);
			snd = HPF.ar(snd, hpf_hz);
			snd = Pan2.ar(snd,Lag.kr(pan,0.1));
	
			Out.ar(out,snd*env*amp/5);
		}).add;

		// initialize fx synth and bus
		context.server.sync;
		mxBusFx = Bus.audio(context.server,2);
		context.server.sync;
		mxSynthFX = Synth.new("mxfx",[\out,0,\inBus,mxBusFx]);
		context.server.sync;

		fnNoteOnMono={
			arg note,amp,duration;
			var notesOn=false;
			var setNote=false;
			// check to see if any notes are on
			mxVoices.keysValuesDo({ arg key, syn;
				if (syn.isRunning,{
					notesOn=true;
				});
			});
			if (notesOn==false,{
				fnNoteOnPoly.(note,amp,duration);
			},{
					mxVoices.keysValuesDo({ arg key, syn;
					if (syn.isRunning,{
						syn.set(
							\gate,0,
						);
						if (setNote==false,{
							syn.set(
								\gate,1,
								\hz,(note+mxParameters.at("tune")).midicps,
							);
							setNote=true;
						});
					});
				});
			});
			fnNoteAdd.(note);
		};

		fnNoteOnPoly={
			arg note,amp,duration;
			var lowestNote=10000;
			var sub=0;
			// (mxParameters.at("synth")++" note_on "++note).postln;

			// low-note priority for sub oscillator
			mxVoicesOn.keysValuesDo({ arg key, syn;
				if (key<lowestNote,{
					lowestNote=key;
				});
			});
			if (lowestNote<10000,{
				if (note<lowestNote,{
					sub=1;
					mxVoices.at(lowestNote).set(\sub,0);
				},{
					sub=0;
				});
			},{
				sub=1;
			});

			// ("sub at "++(sub*mxParameters.at("sub"))).postln;

			mxVoices.put(note,
				Synth.before(mxSynthFX,mxParameters.at("synth"),[
					\amp,amp*mxParameters.at("amp"),
					\out,mxBusFx,
					\hz,(note+mxParameters.at("tune")).midicps,
					\bend,mxParameters.at("bend"),
					\pan,mxParameters.at("pan"),
					\sub,sub*mxParameters.at("sub"),
					\attack,mxParameters.at("attack"),
					\decay,mxParameters.at("decay"),
					\sustain,mxParameters.at("sustain"),
					\release,mxParameters.at("release"),
					\portamento,mxParameters.at("portamento"),
					\mod1,mxParameters.at("mod1"),
					\mod2,mxParameters.at("mod2"),
					\mod3,mxParameters.at("mod3"),
					\mod4,mxParameters.at("mod4"),
					\duration,duration,
				]);
			);
			NodeWatcher.register(mxVoices.at(note));
			fnNoteAdd.(note);
		};

		fnNoteAdd={
			arg note;
			var oldestNote=0;
			var oldestNoteVal=10000000;
			mxPolyphonyCount=mxPolyphonyCount+1;
			mxVoicesOn.put(note,mxPolyphonyCount);
			if (mxVoicesOn.size>mxPolyphonyMax,{
				// remove the oldest voice
				mxVoicesOn.keysValuesDo({ arg key, val;
					if (val<oldestNoteVal,{
						oldestNoteVal=val;
						oldestNote=key;
					});	
				});
				("max polyphony reached, removing note "++oldestNote).postln;
				fnNoteOff.(oldestNote);
			});
		};

		// intialize helper functions
		fnNoteOn= {
			arg note,amp,duration;
			// ("note on: "++note).postln;
			
			// if monophonic, remove all the other sounds
			if (mxParameters.at("monophonic")>0,{
				fnNoteOnMono.(note,amp,duration);
			},{
				fnNoteOnPoly.(note,amp,duration);
			});
		};
		
		fnNoteOff = {
			arg note;
			// ("note off: "++note).postln;		
			// remove it it hasn't already been removed	and synth gone	
			if ((mxVoices.at(note) == nil) || ((mxVoices.at(note).isRunning==false)&&(mxVoicesOn.at(note)==nil)),{},{
				// if monophonic, remove all the other sounds
				if (mxParameters.at("monophonic")>0,{
					fnNoteOffMono.(note);
				},{
					fnNoteOffPoly.(note);
				});
			});
		};

		fnNoteOffMono = {
			arg note;
			var notesOn=false;
			var playedAnother=false;
			mxVoicesOn.removeAt(note);
			mxVoicesOn.keysValuesDo({ arg note, syn;
				notesOn=true;
			});
			if (notesOn==false,{
				// turn off synth, wherever it is
				mxVoices.keysValuesDo({ arg note, syn;
					if (syn.isRunning,{
						syn.set(\gate,0);
					});
				});
			},{
				// play another note that is pressed down
				mxVoices.keysValuesDo({ arg note, syn;
					if (syn.isRunning,{
						syn.set(
							\gate,0,
						);
						if (playedAnother==false,{
							//"mono: replaying synth".postln;
							syn.set(
								\gate,1,
								\hz,(note+mxParameters.at("tune")).midicps,
							);
							playedAnother=true;
						});
					});
				});
			});
		};

		fnNoteOffPoly = {
			arg note;
			var lowestNote=10000;
			// ("mx_note_off "++note).postln;

			mxVoicesOn.removeAt(note);

			if (pedalSustainOn==true,{
				pedalSustainNotes.put(note,1);
			},{
				if ((pedalSostenutoOn==true)&&(pedalSostenutoNotes.at(note)!=nil),{
					// do nothing, it is a sostenuto note
				},{
					// remove the sound
					mxVoices.at(note).set(\gate,0);
					updateSub.();
				});
			});
		};

		updateSub = {
			var lowestNote=10000;
			// swap sub
			mxVoicesOn.keysValuesDo({ arg note, syn;
				if (note<lowestNote,{
					lowestNote=note;
				});
				// ("note "++note++" lowestNote "++lowestNote).postln;
			});
			mxVoicesOn.keysValuesDo({ arg note, syn;
				if (note.asInteger>lowestNote.asInteger,{
					mxVoices.at(note).set(\sub,0);
				},{
					mxVoices.at(note).set(\sub,mxParameters.at("sub"));
				});
			});
		};

		// add norns commands
		this.addCommand("mx_note_on", "iff", { arg msg;
			var lowestNote=10000;
			var note=msg[1];
			if (mxVoices.at(note)!=nil,{
				if (mxVoices.at(note).isRunning==true,{
					// (mxParameters.at("synth")++" retrigger "++note).postln;
					mxVoices.at(note).set(\gate,0);
				});
			});
			fnNoteOn.(msg[1],msg[2],msg[3]);
		});	

		this.addCommand("mx_note_off", "i", { arg msg;
			var note=msg[1];
			fnNoteOff.(note);
		});

		this.addCommand("mx_sustain", "i", { arg msg;
			pedalSustainOn=(msg[1]==1);
			if (pedalSustainOn==false,{
				// release all sustained notes
				// that aren't currently being held down
				pedalSustainNotes.keysValuesDo({ arg note, val; 
					if (mxVoicesOn.at(note)==nil,{
						pedalSustainNotes.removeAt(note);
						fnNoteOff.(note);
					});
				});
			},{
				// add currently down notes to the pedal
				mxVoicesOn.keysValuesDo({ arg note, val; 
					pedalSustainNotes.put(note,1);
				});
			});
		});

		this.addCommand("mx_sustenuto", "i", { arg msg;
			pedalSostenutoOn=(msg[1]==1);
			if (pedalSostenutoOn==false,{
				// release all sustained notes
				// that aren't currently being held down
				pedalSostenutoNotes.keysValuesDo({ arg note, val; 
					if (mxVoicesOn.at(note)==nil,{
						pedalSostenutoNotes.removeAt(note);
						fnNoteOff.(note);
					});
				});
			},{
				// add currently held notes
				mxVoicesOn.keysValuesDo({ arg note, val;
					pedalSostenutoNotes.put(note,1);
				});
			});
		});

		this.addCommand("mx_fxset","sf",{ arg msg;
			var key=msg[1].asSymbol;
			var val=msg[2];
			mxSynthFX.set(key,val);
		});

		this.addCommand("mx_set_synth","s",{ arg msg;
			var val=msg[1].asSymbol;
			// ("setting synth to "++val).postln;
			mxParameters.put("synth",val.asSymbol);
		});

		this.addCommand("mx_set_polyphony","i",{ arg msg;
			mxPolyphonyMax=msg[1];
		});

		this.addCommand("mx_set","sf",{ arg msg;
			var key=msg[1].asString;
			var val=msg[2];
			// ("setting "++key++" to "++val).postln;
			mxParameters.put(key,val);
			switch (key, 
				"sub",{
					updateSub.();
				}, 	// update sub
				"synth",{
					if (mxParameters.at("monophonic")>0,{
						// remove all synths if monophonic
						mxVoices.keysValuesDo({ arg note, syn;
							if (syn.isRunning,{
								syn.set(\gate,0);
							});
						});
					});
				}, 
				"amp",{}, 	// do nothing
				"attack",{}, 	// do nothing
				"sustain",{}, 	// do nothing
				"decay",{}, 	// do nothing
				{
					mxVoices.keysValuesDo({ arg note, syn;
						if (syn.isRunning==true,{
							syn.set(key.asSymbol,val);
						});
					});
				}
			);
		});
		// </mx>
	}

	free {
		// <mx>
		mxBusFx.free;
		mxSynthFX.free;
		mxVoices.keysValuesDo({ arg key, value; value.free; });
		// </mx>
	}
}
