s.boot;
s.quit;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;

(/* VU METRE & FREQSCOPE */ w.free; w = Window.new("Levels",Rect(0,Window.screenBounds.height-350,200,300));w.visible = true; r.free; r = ServerMeterView.new(s,w,0@0,2,2);
f.free; f = FreqScope.new(300,300,0,server:s); f.window.front;)

(
~pat =  Pseq([(1/6),(1/4),(2/6),(1/4)],inf);
~pat2 =  {arg repeat=inf; Pseq([(1/6),(1/4),1/2,(2/6),(1/4)],repeat);};

~onBeat = {arg d;  TempoClock.default.nextBar - TempoClock.default.beats == d};

~noKick = {arg t; (((~lastKick[\amp] < 0.1) && (~lastKick[\dur] >= (t/2))) || (~lastKick[\dur] >= t))};

// Sine
SynthDef("sine",{arg freq=400,amp=0.35,pan=0,att=0.001,rel=0.005,phase=0,sus=0,out=0;
	var env = Env([0,1,1,0],[att,sus,rel]).ar(2);
	Out.ar(out,Pan2.ar(SinOsc.ar(freq,phase) * env,pan, amp));
}).add;


// Sine
SynthDef("droneSine",{arg freq = 440, amp=0.1, pan=0,out=0;
	Out.ar(out,Pan2.ar(SinOsc.ar(freq),pan, amp));
},15).add;

// Gendy

// Snare
SynthDef("snare", {arg out=0,amp=1,fq=320, hifreq=1020, noiseDecay=0.002,pan=0,
	att=0.001,dec=0.01, rel=0.1,attC=(0),decC=0,relC=(-12),sinDel=0,
	noiseAtt= 0.002,noiseRel= 0.3, noiseAttC=(\wel),noiseRelC=(\wel),noiseDel=0,
	crash = 0.1;
	var sig, sin, env, noise, noiseEnv,harms, noiseAmp;
	noiseAmp = amp/1.5;
	env = Env([0,0,1,0.5,0],[sinDel,att,dec,rel],[0,attC,decC,relC]).kr();
	noiseEnv = Env([0,0,1,0],[noiseDel, noiseAtt,noiseRel],[0,noiseAttC,noiseRelC]).kr(2);
	harms = [0.9,1,1.1];
	sin = Mix.fill(harms.size, {arg i; LFSaw.ar(fq*harms[i],pi/2,1/((i*0.5)+1.5));});
	sin = sin * env * amp;
	noise = Mix.ar([ClipNoise.ar(0.3), Dust2.ar(fq*50,0)]);
	noise = Ringz.ar(noise, [fq, hifreq], noiseDecay);
	noise = noise * noiseEnv * noiseAmp;
	sig = Mix.new([sin,noise]);
	sig = Pan2.ar(sig, pan);
	Out.ar(out,sig);
	DetectSilence.ar(sig, 0.00001, crash, 2);
}).add;

// Noise
SynthDef("noise", {arg out=0,bw=1.5, amp=1, pan=0,
	att=0.001, rel=0.5, sus=0.02, attC=20,relC=(-6),
	freqA=30000, freqB=80, freqC=3500, attSweep=0.1, relSweep=0.15, attSweepC=0, relSweepC=0;
	var sig, env, sweep;
	env = Env([0,1,1,0],[att,sus,rel],[attC,0,relC]).kr(2);
	sweep = Env([freqA, freqB, freqC], [attSweep, relSweep], [attSweepC,relSweepC]).kr(2);
	sig = BBandPass.ar(PinkNoise.ar(),sweep,bw * env,1/bw);
	Out.ar(out,Pan2.ar(sig * env,pan, amp));
}).add;

SynthDef("noiseDwn", {arg out, sus=0.5, amp=0.2, panFreq=0, panMod=1;
	var sig, env;
	env = XLine.kr(amp, 0.0001, sus, 1,0, 2);
	sig = PinkNoise.ar({LFNoise1.kr(panFreq,panMod,0.5)}!2);
	Out.ar(out, sig * env);
}).add;

SynthDef("noiseUp",
	{arg out, sus=0.5, amp=0.2, panFreq=0, panMod=1;
	var sig, env;
	env = XLine.kr(0.0001, amp, sus, 1,0,2);
	sig = PinkNoise.ar({LFNoise1.kr(panFreq,panMod,0.5)}!2);
	Out.ar(out, Pan2.ar(sig * env));
}).add;

SynthDef("clap",{
	arg out=0, att=0.001, rel=0.5, relC = -12, pan=0, amp=0.2, freq=900, del=0.015, rq=0.2;
	var sig, env, enva, envb, envc;
	env = Env.perc(att, rel, amp, relC).kr(2);
	enva = DelayN.ar(env,0.2,del*2);
	envb = DelayN.ar(env,0.2,del);
	envc = DelayN.ar(env,0.2,del*3);
	sig = Mix.fill(6,{arg i; var delay;
		delay = DelayN.ar(env, 0.2, rrand(0,del));
		BPF.ar(ClipNoise.ar(), freq * Rand((i*0.25) + 1, (i*0.25) + 1.1), rq, 1 + (1/rq) * (1/6)) * delay;
	});
	sig = LinSelectX.ar(Rand(0,2), sig)!2;
	Out.ar(out, sig);
}).add;

// Blip
SynthDef("blip",{arg out=0,freq=60,nharm=3,amp=0.5,pan=0,att=0.003,rel=0.002,phase=0,sus=0;
	var env = Env([0,1,1,0],[att,sus,rel]).ar(2);
	// panoramic = pan;
	Out.ar(out,Pan2.ar(Blip.ar(freq,nharm) * env,pan, amp));
}).add;

SynthDef("kick", {arg out=0,amp=0.5,pan=0,att=0.02,rel=0.1, sus=0,attC=6, relC=6,
	freqA=2800,freqB=120,freqC=35,freqAC=(0),freqBC=(-8);
	var env = Env([0,1,1,0],[att,sus,rel],[attC,0,relC]).ar(2);
	var sweep = Env([freqA,freqB,freqB,freqC],[att,sus,rel],[freqAC,0,freqBC]).ar;
	var sig = Mix.fill(4, {arg i; LFPar.ar(sweep * ( 1 + (i*0.12)), pi*(i*0.66),(1/(i+1.25)))});
	sig = sig * env * amp;
	Out.ar(out,Pan2.ar(sig,pan));
}).add;

SynthDef("snaredel", {
	arg out=0, amp=0.5, att=0.002,sus=0.01, rel=0.001,
	attC=0,relC=(-24),
	pan=0, ff=1200, deldur=0.5, delvit=0.3,delfq=0.5,
	crash=2;
	var env, sig, envsin, sin,envdel;
	var rs = 0.0005, fqs = ff * [0.366, 1, 1.683, 1.333];

	env = EnvGen.ar(Env([0,1,1,0],[att,sus,rel],[attC,0,relC]));
	envsin = EnvGen.ar(Env([0,1,0],[att,rel*0.01],[attC,relC - 30]));
	envdel = Env([0,1,1,0],[att,sus,rel],[24,0,24]).ar(2);
	sig = Mix.fill(fqs.size, {arg i;
		BHiPass.ar(
			ClipNoise.ar(0.5),
			fqs[i],
			rs*(fqs),
			fqs.size/((i+1*6))
		);
	});
	sin = Mix.fill(fqs.size, {arg i; SinOsc.ar(fqs[i],0,fqs.size/((i+1*6))) });
	sig = (sig * env * 0.5) + (sin * envsin * 1);
	sig = sig * env;
	sig = sig + CombN.ar(sig,delvit+0.1,LFNoise1.kr(delfq,delvit,delvit+0.01),deldur); // COMB DELAY
	// sig = sig * envdel;
	sig = Pan2.ar(sig,pan);
	sig = sig * amp;
	DetectSilence.ar(sig, time:crash, doneAction:2);
	Out.ar(out,sig);

}).add;

SynthDef("bloc", { arg out=0, freq=880, amp=0.5, att=0.01, sus=0, rel=0.1, pan=0, lpf = 600;
	var sig, env;
	env = Env([0,1,1,0], [att, sus, rel], [3,0,-3]).kr(2);
	sig = Mix.ar([
		LFPulse.ar(LFNoise1.ar(freq,freq/2,freq), pi/3, 0.5,0.5,-0.25),
		SinOscFB.ar(freq,LFNoise1.kr(150,0.5,1), 0.3),
		SinOscFB.ar(freq/3,LFNoise1.kr(50,0.5,1), 0.3),
	]);
	// sig = BLowPass4.ar(sig, lpf, 0.25);
	sig = BHiShelf.ar(sig, freq, 1, 3);
	sig = Pan2.ar(sig, pan, env * amp);
	Out.ar(out, sig);

}).add;

SynthDef("spacy", {arg out=0, freq=880, amp=0.5, att=0.01, sus=0, rel=0.1, pan=0, fm=1;
	var sig, env, len, mods, nharms;
	nharms = 6;
	len = att+sus+rel;
	env = Env([0,1,1,0], [att, sus, rel], [3,0,-3]).kr(2);

	mods = Array.fill(nharms, {arg i;
		SinOsc.kr((i/2) + 1, pi*(i+1), freq/2 , freq)
	});

	sig = DynKlank.ar(`[ mods, nil, 1!(nharms)],  Impulse.ar(0.01) , 1,0,len*4) / nharms;

	sig = Pan2.ar(sig, pan, amp * env);
	Out.ar(out, sig);
}).add;

SynthDef("bass", {
	arg out=0, freq=75, amp=0.5, att=0.1, rel=0.1, sus=0.1, attC=0, relC=0, pan=0, rq=1;
	var sig, env;

	env = Env([0,1,1,0], [att,sus,rel], [attC, 0, relC]).kr(2);

	sig = LFCub.ar(LFSaw.ar(freq, 0, freq/2, freq*2),2, LFPar.ar(freq/2));
	sig = RLPF.ar(sig, freq, rq);
	sig = Pan2.ar(sig, pan, amp * env);
	Out.ar(out, sig);
}).add;

SynthDef("formant", { arg out=0,freq=60,addFreq=700,amp=0.5,
	att=0.1,rel=0.1,sus=0,attC=0,relC=0,
	bwfreq=880,lenmul=2,pan=0,panrand=1;
	var len, env, sound, sfreq = freq, efreq = freq+(addFreq);
	len = (att+sus+rel)*lenmul;
	env = Env([0,1,1,0],[att,sus,rel],[attC,0,relC]).kr(2);
	sfreq = XLine.kr(sfreq,efreq,len); /* XLine pour le formant */
	efreq = XLine.kr(efreq,sfreq,len); /* XLine pour le formant */
	sound = Formant.ar(sfreq,efreq,bwfreq);
	sound = sound * env * amp;
	sound =  Pan2.ar(sound ,Lag.kr(LFNoise1.kr(1.0),2,panrand,pan));
	Out.ar(out, sound);
}).add;

SynthDef("glob", {arg att=0.001, sus=0, rel=0.1, relC=(-3), attC=3,argA=10, argB=0.2,argC=400, ampLag=2,out=0,panFreq=10;
	var amp = NamedControl.kr(\amp,0.2,ampLag);
	var env = Env([0,1,1,0], [att, sus, rel], [attC,0,relC]).kr(2);
	var sig =
	Formant.ar(
		(LFNoise1.kr(LFNoise1.kr(0.1,1,0.5) * argA,1) * 140).scaleneg(argA),
		(LFNoise1.kr(LFNoise1.kr(0.02,0.5,0.5) * argB ,1,1 )*800).scaleneg(argB),
		(LFNoise1.kr(1,0.5,1) * argC),
		(Gendy1.kr(
			/*ampdist*/ 2
			,/*durdist*/ 0.1
			, /*adparam*/ 0.001
			, /*ddparam*/ 0.99
			,/*minfre*/ 0.0001
			,/*maxfreq*/ 2
			,/*ampscale*/ 0.000001
			,/*durscale*/ 0.01
			,/*initCPs*/ 12
			,/*knum*/ 1
			,/*mul*/ 0.5)
	));
	sig = Pan2.ar(sig, LFNoise1.kr(LFNoise1.kr(panFreq,100,100)),amp*env);
	Out.ar(out,sig);
}).add;

SynthDef("autoglob", {arg argA=10, argB=0.2,argC=400, ampLag=2,out=0,panFreq=10;
	var amp = NamedControl.kr(\amp,0.2,ampLag);
	var sig =
	Formant.ar(
		(LFNoise1.kr(LFNoise1.kr(0.1,1,0.5) * argA,1) * 140).scaleneg(argA),
		(LFNoise1.kr(LFNoise1.kr(0.02,0.5,0.5) * argB ,1,1 )*800).scaleneg(argB),
		(LFNoise1.kr(1,0.5,1) * argC),
		(Gendy1.kr(
			/*ampdist*/ 2
			,/*durdist*/ 0.1
			, /*adparam*/ 0.001
			, /*ddparam*/ 0.99
			,/*minfre*/ 0.0001
			,/*maxfreq*/ 2
			,/*ampscale*/ 0.000001
			,/*durscale*/ 0.01
			,/*initCPs*/ 12
			,/*knum*/ 1
			,/*mul*/ 0.5)
	));
	sig = Pan2.ar(sig, LFNoise1.kr(LFNoise1.kr(panFreq,100,100)),amp);
	Out.ar(out,sig);
}).add;

SynthDef("autoformant", {arg fund=80,form=300,bw=600,ampLag=2,out=0,speed1=0.1, speed2=0.1,pres=0.5;
	var amp = NamedControl.kr(\amp,0.2,ampLag);
	var sig, fundfq, formfq, bwfq, randy;

	randy = [LFNoise0.kr(0.5*speed2,100,100)/100,LFNoise0.kr(0.2*speed2,100,100)/100,LFNoise0.kr(0.75*speed2,100,100)/100,SinOsc.kr(0.5*speed2,pi/2).scaleneg(0),SinOsc.kr(0.33*speed2,pi/4).scaleneg(0),Pulse.kr(0.1*speed2,pi/5).scaleneg(0)];

	fundfq = SelectXFocus.kr(LFDNoise1.kr(LFDNoise1.kr(0.5,1,1)*speed1,0.5,0.5) * randy.size,	randy,randy.size/(pres*10),true) * (fund*2)	;
	formfq = SelectXFocus.kr(LFDNoise1.kr(LFDNoise1.kr(0.5,1,1)*speed1,0.5,0.5) * randy.size,randy,randy.size/(pres*10),true) * (form*2)	;
	bwfq = LFDNoise1.kr(LFDNoise1.kr(0.5,1,1)*speed1,bw,bw);
	sig = Formant.ar(fundfq	,formfq	,bwfq);
	sig = Pan2.ar(sig, LFNoise1.kr(LFNoise1.kr(0.5*speed1).range(0.1,10)),amp);
	Out.ar(out,sig);
}).add;
)

t = {LFNoise1.kr(LFNoise1.kr(1,100,100)) }.plot(4)

// TESTING
x.free; x=[];
x = x.add(Synth.new(\autoglob,[\argA,6,\argB,12,\amp,0.8,\panFreq,1]))
x[0].free
Synth.new(\blip);
Pbindef(\hptest, \instrument, \kick, \dur, 2, \amp, 0.5).play
Synth(\bloc,[\freq, 120])

// PLAYING
TempoClock.tempo = 60/ 60
TempoClock.schedAbs(TempoClock, TempoClock.nextBar, {TempoClock.beatsPerBar_(4)})


// APRES SINES //



// SOUNDCHECK
/* Snare Level */
Pbindef(\snareChk,\instrument,\snare,\dur,Prand([2,Pseq([1,3])],inf),\amp,0.5,\noiseRelC,Pwhite(-7.0,-9),\noiseRel,0.2,\fq,Pwhite(400,410.0),\hifreq,Pwhite(3050,3020)).play(quant:[4,0.25])
Pbindef(\snareChk).stop

/* Snare Freqs */
Pbindef(\snareChk,\fq,Pstutter(1,Pseries(480, 1)).trace)

/* Kick level */
Pbindef(\kickChk, \instrument,\kick,\amp,0.5,\freqA,Pwhite(2540,2550), \freqAC,-4.85,\freqBC,-8, \freqC,Pwhite(42,44.0),	\freqB,Pwhite(75.0,78),\rel, 0.05, \attC,0, \relC,6, \sus, 0, \out, [0,~compCtrl], \dur, 4).play

/* Kick Freqs */
Pbindef(\kickChk, \instrument,\kick,\freqB,Pstutter(1,Pseries(5,1)).trace).play
Pbindef(\kickChk, \freqC, Pstutter(2,Pseries(30, 1)).trace)
Pbindef(\kickChk,  \freqB, 85, \freqC, 40, \freqAC, -6, \freqBC, 3, \rel, 0.05)

/* Bass */
Pbindef(\baaas, \instrument, \blip, \sus, 1, \freq, (Pwhite(40,45!3)-10).trace, \dur, 4, \amp, 0.2).play(quant:[4,3])


// PUMP
Pbindef(\testkick, \instrument, \kick, \dur, 0.6, \nharm, 2).play(quant:4)
Pbindef(\testkick).stop.clear
Pbindef(\mimi, \instrument, \snare).play
Synth("snare",[\amp, 0.5]).play
Pbindef(\mimi,\amp,0.5)
Pbindef(\mimi).stop.clear
Pbindef(\testsnare, \noiseRelC,-10, \amp,0.1)
Pbindef(\snare, \out, ~compIn.index)
Pbindef(\snark, \out, ~compIn.index)
( ~sines
.do({ arg i; i.set(\out, ~compIn.index
)});)

~beatseq = [1/6,1/4,2/6,1/4]

// Intro
Pbindef(\intro, \instrument, \sine, \freq, Pexprand(180, 220), \amp, Pwhite(0.005,0.005), \pan, Pwhite(-0.5, 0.5), \dur, 1/6).play
Pbindef(\intro, \stretch, Pseq([1,0.5, 0.2, 0.6, 4, 6],inf))
Pbindef(\intro).stop.clear

Pbindef(\introb, \instrument, \glob, \sus, Pwhite(0,0.25), \rel, Pwhite(0.01, 0.05), \dur, 1/2 + Pwhite(-0.05,0.05)).play
Pbindef(\introb, \dur, 0.1)
Pbindef(\introb).stop.clear

Synth([\noiseDwn, \noiseUp].choose, [\sus, 1.0.rand, \rel, 2.rand, \amp, 0.01])
Synth(\sine, [\freq, 600.rand, \amp, 0.05.rand, \pan, rrand(-1, 1.0)])

Pbindef(\kick).stop;
Pbindef(\taktak, \instrument, \sine, \freq, 110,\amp, 0.2, \dur, Pseq([1],inf)).play(quant:4);


Pdef.removeAll
TempoClock.tempo = 1


//// PARTY 1

Pbindef(\dubbysnare,\instrument,\snare,\dur,Pseq([8,10,1,6]),\amp,0.8,\noiseRelC,Pwhite(-7.0,-9),\noiseRel,0.2,\fq,Pseq([ Pwhite(600,610.0, 4), Pwhite(400,410.0)]),\hifreq,Pwhite(4050,4020), \noiseDecay, 0.004, \out, 0).play(quant:[8,3])


Pbindef(\heartbeat, \instrument,\kick,\amp,0.5,\freqA,Pwhite(2540,2550), \freqAC,-4.85,\freqBC,-8, \freqC,Pwhite(42,44.0),	\freqB,Pwhite(75.0,78),\rel, 0.05, \attC,0, \relC,6, \sus, Pseq([Pseq([0],19), 3,Pseq([0],inf)]), \out, [0,~compCtrl])

///// Collect Kick
(k.stop; k = Pbindef(\heartbeat, \dur, Pseq([8,4,6-0.25, Pseq([1],16), 10, Pseq([1/3],inf)])).stop.collect({|e| ~lastKick = e;}).play(quant:[8,0.25,0.1]);
Pbindef(\dubbysnare, \out, Pseq([Pseq([0],3), Prand([0, [0, ~compCtrl]],inf)]) ,\dur, Pseq([8,4,6.25+1, Pseq([6/8,10/8],7), 8, Pseq([1],inf)]), \amp, Pseq([0.55,0.8,0.45, Pwhite(0.25,0.35)])).stop.play(quant:[8,0]))

// Quand le kick part >>
Pbindef(\dubbysnare,\noiseRelC, Pwhite(-5.0,-3), \noiseDecay, 0.002)

k.stop;
// Side Chain //
y.set(\amp, 1.5)
y.set(\rel, 0.2)

k.play
// PAN PARTY
(Pbindef(\heartbeat, \pan, Pseq([-1,0,1],inf), \dur, 1/4, \sus, 0, \out, [0, ~compCtrl]);
Pbindef(\dubbysnare, \dur, 3/4 , \amp, Pwhite(0.3,0.4), \noiseDecay, 0.001, \amp, Pwhite(0.25,0.35)))


(Pbindef(\heartbeat,\dur, Pseq([Pseq([1/6],9),4, ~pat2.(inf)]), \out, Pseq([0, [0,~compCtrl],0],inf), \sus, Pseq([Pseq([0],8),1, Pseq([0],inf)]), \pan, 0);
Pbindef(\dubbysnare, \dur, Pseq([8, Pwrand([2,1],[0.9,0.1],inf)]) + Pshuf([0.125,0, -0.125],inf) , \out, 0).play(quant:[4,3]))



// PANNE DE KICK ?
k.stop; k = Pbindef(\heartbeat).stop.collect({|e| ~lastKick = e;}).play(quant:[8,0.25,0.1]);
k.stop
Pbindef(\heartbeat, \amp, 0.5, \out, [0, ~compCtrl]);
Pbindef(\heartbeat, \pan,0)


(Pbindef(\vent, \instrument,\noise,\dur, 0.08,\sus, 0.000,\attSweepC, 20,\bw,Pwhite(0.1,0.005),\amp,Pseq([Pseq((1..250))*0.0005, Pseq([0.125],inf)]), \relC,-20).play(quant:8);

Pbindef(\vent2, \instrument,\noise,\dur,0.081,\sus,0,\rel,0.025,\att,0,\bw,0.002,\amp,Pseq([Pseq((1..150))*0.0005, Pseq([0.075],inf)])).play(quant:8);)

Pbindef(\vent2, \pan, Pwhite(-1.0,1));

Pbindef(\wouin,\instrument,\blip,\dur,Pseq([ Prand([1/6,1/8,1/10],inf), 1/4, 1/3, Pseq([1/12],18), 1/3, 1/4],inf),\att,0.001,\rel,Pwhite(0.02,0.005),\sus,Pkey(\dur) * Pexprand(0.05, 0.1),\freq,Pstutter(Pexprand(500,260),Pwhite([400,600,2000],[800,1000,4000])),\amp,0.02, \pan, Pwhite(-0.5,0.5))


(
Pbindef(\heartbeat, \dur, Pseq([ Pseq([Pseq([1/5],7), 3/5,Pseq([1/6],12)],2), ~pat]), \out,0, \amp,0.5);
Pbindef(\vent2, \dur, Pseq([ Pseq([Pseq([1/5],10) + 0.001, Pseq([1/6],12) + 0.005 ], 1), Pseq([0.081],inf)]));
Pbindef(\vent, \dur, Pseq([ Pseq([ Pseq([1/5],10),Pseq([1/6],6), Pseq([1/8],8) ],2), Pseq([0.08],inf)]));
Pbindef(\wouin, \dur, Pfunc{~lastKick[\dur]}).play(quant:[4,0.25])
)

Pbindef(\wouin, \dur,Pseq([ Pseq([1/6],6), Prand([1/6,1/8,1/10],inf)]), \amp, 0.035)


y.set(\amp,1.5);
y.set(\amp,0.8);
y.set(\rel, 0.05)

(
Pbindef(\vent, \dur,Pseq([Pseq([4]), Pseq([0.08],inf)]));
Pbindef(\vent2, \dur,Pseq([Pseq([1/8],16), 2, Pseq([0.081],inf)]),  \rel, Pseq([Pseq([Pwhite(0.5,1,1), Pseq([0.025],7)],2), Pseq([0.025],inf)]));
Pbindef(\heartbeat, \dur, Pseq([Pseq([1/6],24), ~pat ]));
Pbindef(\wouin,  \dur, Pseq([ 8 , Prand([1/6,1/8,1/10],inf) ]));
Pbindef(\dubbysnare, \amp, Pwhite(0.3,0.2), \dur, Pseq([Pseq([1/6],9),1/2, Pwrand([2,1],[0.9,0.1],inf)]) + Pseq([Pseq([0],24), Pshuf([0.125,0, -0.125],inf)])).stop.play(quant:[1,0])
)

Pbindef(\heartbeat, \out, Pwrand([ 0, [0, ~compCtrl]],[0.2,0.8],inf))

// ----- play it v v v v

Pbindef(\dubbysnare, \dur, Pwrand([2, 1, 1.5, 2.5], [0.6, 0.1, 0.2,0.1],inf))

Pbindef(\wouin,\dur,Pfunc{if (~noKick.(1/2)) { ~lastKick[\dur] / rrand(3,6) } {[1/6,1/8,1/5,1/10].choose} })

Pbindef(\vent, \sus, Pfunc{ if((~noKick.(2/6)) && (0.3.coin)){rrand(0.07,0.0002)}{0.0001}})

Pbindef(\wouin,\sus,Pfunc{if (~noKick.(1/2)) { rrand(0.2,0.5) } {rrand(0.05,0.0005)} })

Pbindef(\heartbeat, \dur, Pwrand([Pseq([1/6, 1/4, 1/2, 2/6, 1/4]), ~pat],[0.9,0.1],inf), \out, [0, ~compCtrl], \pan, 0)

Pbindef(\vent2, \dur,Pfunc{ ~lastKick[\dur] / 4})

y.set(\rel, 0.05)

(Pbindef(\heartbeat, \dur,
	Pseq([
		(1/6),
		Pwrand([
			Pseq([1/4, 2/6, 1/4]),
			Pshuf([ Pseq([((2/6)+(1/4)) / 5],5), 1/4])]
		, [0.9,0.1]) // < change weights
		,Pwrand([ 1/4,Pseq([1/4, 1])], [0.9,0.1])
	],inf)
))


(Pbindef(\vent2,
	\sus, Pfunc({ if (~noKick.(2/6) && 0.5.coin) {0.13.rand} {0.01}}),
	\dur, Pfunc({ if (~noKick.(1)) {0.25} {0.081} }),
	\bw, Pfunc({ if (~noKick.(1)) {3.0.rand} {0.002} })
).play)

Pbindef(\wouin, \sus, Pfunc{ if ((~noKick.(2/6)) && (0.5.coin)) {rrand(0.051,0.35)} {rrand(0.0005,0.005)}})

Pbindef(\dubbysnare, \dur, Pfunc{ if(~noKick.(1)) {[1/8, 1/7].choose} { [1,1.5,2.5,2].choose} })
Pbindef(\dubbysnare, \noiseRelC, Pfunc{ if (~noKick.(1)) {rrand(-5,-3)} { rrand( 0, 3)}})


Pbindef(\wouin, \nharm, Pfunc{ if ((~noKick.(1/2)) && (0.3.coin)) {rrand(3,16)} {2}})

Pbindef(\wouin, \rel, Pfunc{ if (~noKick.(2/6) && (0.1.coin)) {(~lastKick[\dur]-0.001.rand).abs} {rrand(0.05,0.0005)}})

Pbindef(\heartbeat, \dur, Pshuf([Pseq([1/8],8), Pseq([1/2],3), Pseq([1/5],5), 1/2, ~pat.(4) ],inf))

Pbindef(\heartbeat, \freqB, Pseq([Pseq((55..96)), Pwhite(65,62.0)]), \dur, Pseq([Pseq([1/12],42), Pshuf([1,2,1/4],2), Pseq([1/8],4), ~pat2.(4), ~pat]))

y.set(\rel, 0.03)

Pbindef(\wouin, \dur, Pstutter(Pwhite(1,6),Prand([1/8,1/9,1/6,1/12],inf)))


Pbindef(\dubbysnare).stop.clear;

y.set(\rel, 1); TempoClock.tempo = 0.01
TempoClock.tempo = 0.

// VAGUE manuelle
Synth.new("snare", [\amp, 0.5, \noiseRel, 5, \pan,0, \noiseRelC, 3, \fq, 405, \hifreq, rrand(3025,1200), \noiseDecay, 0.005])

PdefAllGui.new()

TempoClock.tempo = 0.05; Pbindef(\wouin, \stretch, 0.05); Pbindef(\heartbeat, \stretch ,0.25);
TempoClock.tempo = 1; Pbindef(\wouin, \stretch,1); Pbindef(\heartbeat, \stretch, 1)


/// ROOKIES ----------



Pbindef(\vent3, \instrument, \bloc, \dur,Pn(Pshuf([1/8,1/16,1/16,1/8,1/4,1/8].sputter(0.75,8)),inf), \sus, 0.02,  \att, 0, \amp, 0.075, \freq, Pstutter(100,Pwhite(700, 2000)), \rel, 0.001).play(quant:[1,0.2])

Pbindef(\vent4, \instrument, \formant, \dur,Pwhite(0.125/2, 0.125/4), \rel, 0.01, \att,0.001, \lenmul,10, \freq, Pstutter(500,Pwhite(700, 2000)), \addFreq, Pwhite(1000,900),\panrand, 0, \amp, 0.1).play

Pbindef(\vent3, \stretch, Pfunc{if (~noKick.(2/6)) { 3 } { 1 } } )
Pbindef(\vent3, \sus, Pfunc{if (~noKick.(1/2)) { 0.3 } { 0.02 } } )
Pbindef(\vent3).stop
Pbindef(\vent4, \amp, 0.005).stop

Pbindef(\vent4, \stretch, Pfunc{if (~noKick.(2/6)) { 3 } { 1 } } )
Pbindef(\vent4, \sus, Pfunc{if (~noKick.(1/2)) { 0.5 } { 0 } } )

/// end ROOKIES


Pbindef(\dubbysnare, \stretch, 1, \noiseRel, 0.5, \noiseRelC,rrand(-4,-12), \dur, Pfunc{ if (~onBeat.(3) && (0.5.coin)) {~lastKick[\dur]} {[1,2,0.5].choose}}, \amp, Pfunc{ if (~noKick.(1/4)){0.2}{if(~onBeat.value(3)){0.3}{0}}}).play(quant:4)

Pbindef(\heartbeat, \amp, Pseq([0.5,Pwrand([0.5,0.25,0],[0.7,0.2,0],3)],inf))
Pbindef(\heartbeat, \dur, Pwrand([1/6,1/4, Pwhite(1,4,1)],[0.85, 0.1,0.05],inf))

Pbindef(\vent, \freq, Pstutter(Pwhite(30,200),Pexprand(6000,8000)))
Pbindef(\vent, \bw,Pwhite(0.03,3))

Pbindef(\vent, \relC,Pseq([Pgeom(-20,1.1)]),\att,Pfunc{if (~noKick.(2/6)) {rrand(0.1,0.5)} {0.06}}) // < ++ \att
Pbindef(\vent2, \rel, 0.6) // < augmente et va dans l'espace

Pbindef(\vent).stop.clear;
Pbindef(\vent2).stop.clear;
Pbindef(\wouin).stop.clear


// 1st STOP

Pbindef(\dubbysnare).stop;
Pbindef(\heartbeat).stop;
k.stop;
Pbindef(\baaas).stop;
Pbindef(\vent).stop;
Pbindef(\vent2).stop;
Pbindef(\vent3).stop;
Pbindef(\vent4).stop;
Pbindef(\wouin).stop;
Pbindef(\wouine).stop;

Pdef.removeAll

// AIDE MEMOIRE KICK
Pbindef(\heartbeat, \instrument,\kick,\amp,0.5,\freqA,Pwhite(2540,2550), \freqAC,-4.85,\freqBC,-8, \freqC,Pwhite(42,44.0),	\freqB,Pwhite(75.0,78),\rel, 0.05, \attC,0, \relC,6, \dur, ~pat, \sus,0, \out, [0,~compCtrl])

k.stop; k = Pbindef(\heartbeat).stop.collect({|e| ~lastKick = e;}).play(quant:[8,0.25,0.1]);
////////////////////////

/////// PARTY 2 : Clubbez moi
Pbindef(\heartbeat).play
Pbindef(\heartbeat, \dur, Pwrand([ Pseq([1/6,1/4,2/6,1/4]), 1],[0.9,0.1],inf))

Pbindef(\heartbeat).stop

Pbindef(\dubbysnare,\instrument,\snare,\dur,Prand([Pseq([2],6), 1,3],inf),\amp,0.3,\noiseRelC,Pwhite(-5,-3),\noiseRel,0.4).play(quant:[4,3])


Pbindef(\clap, \instrument, \clap, \dur, Pxrand([0.5,Pshuf([0.25,0.75])],inf), \amp, 0.3, \rq, Pwhite(0.2,0.6), \rel,Pwhite(0.2,0.4), \freq,900, \stretch, 0.5).play(quant:[4,0.5])


Pbindef(\tremble, \instrument, \sine, \freq,Pwhite([60,63], [65,69]) + Pwhite(10,20), \dur, 1, \sus, 1, \amp, Pfunc {if(~lastKick[\dur] >= 1){0.45}{0}}).play
Pbindef(\tremble, \amp, 0.2)
Pbindef(\tremble).stop


Pbindef(\snare, \instrument, \snaredel, \dur, Prand([Pseq([1/3],3), Pseq([1/5],5)],inf), \amp, Pfunc{ if (~lastKick[\dur] >= 0.4 ) {0.04} {0}}, \deldur, 1, \delfq, 350,  \deldur, 1.5, \sus, 0.15, \delvit, 0.001, \delfq, 1, \lenmul,0.5).play(quant:4)
Pbindef(\snare, \crash, 0.4) // ++ crash pour surcharger cpu :: default = 0.1
Pbindef(\snare).stop.clear


(Pbindef(\snark, \instrument, \snaredel, \pan,Pwhite(-1.0,1),
	\dur,Pfunc{ if(~lastKick[\dur] >= 1) {rrand(0.1,3)}{0.5}},
	\amp,Pfunc{ if(~lastKick[\dur] >= 0.5){0.6}{0.01}},
	\rel,Pwhite(0.05,1),\relC,-3, \deldur,Pwhite(0.05,0.3),\delvit,Pwhite(0.01,0.5),\delfq,Pwhite(1,30),
	\ff,Pwrand([Pwhite(10,100,1), Pwhite(2000,5000,1)],[0.7,0.3],inf)
).play(quant:[4,2]))
Pbindef(\snark, \crash, 4) // ++ crash pour surcharger cpu :: default = 2
Pbindef(\snark).stop.clear;


Pbindef(\heartbeat, \dur, Pwrand([ Pseq([1/6,1/4,2/6,1/4]), Pseq([1/5],10), 1],[0.8,0.1,0.1],inf))


Pbindef(\roll, \instrument, \snare, \dur, Pfunc{if(~lastKick[\dur] < 1) {~lastKick[\dur]} {1/8}}, \noiseRelC, -12, \rel, 0.05,\att, 0.0001, \dec, 0.02, \relC, -8, \fq, [1300, 900], \hifreq, 1600, \noiseDecay, 0.05, \noiseDel, 0.01, \amp,Pfunc{ if(~lastKick[\dur] >= 1) {0.04} {0.001}}).play(quant:4)
Pbindef(\roll, \amp,0.04)
Pbindef(\roll, \crash, 2) // ++ crash pour surcharger cpu :: default = 0.1

Pbindef(\clap, \freq, Pseq([Pseries(900,1,600)],inf))
Pbindef(\clap, \dur, Pshuf([Pxrand([0.5,Pshuf([0.25,0.75])],2), Pseq([0.25],8), 1,2],inf))
Pbindef(\clap, \freq, 950)

Pbindef(\wouin,\instrument,\blip,\dur, Pfunc{ ~lastKick[\dur]} * Pwrand([0.5, 0.25, 1, 2], [0.4,0.1,0.5],inf) + Pshuf([0, -0.125,0.125]),\att,0.01,\rel,Pwhite(0.02,0.005),\sus,Pkey(\dur) * Pexprand(0.05, 0.1),\freq, 2 * [250, 502, Pseq([500, 505, 510],inf)],\amp,0.1, \pan, Pwhite(-0.5,0.5)).play(quant:[4,1.25])

Pbindef(\heartbeat, \dur, Pwrand([1/5, 1/6, 1, 2],[0.5,0.1,0.1,0.1].normalizeSum,inf))

// VARIAS
Pbindef(\heartbeat, \dur, Pwrand([ Pshuf([1/4],2), Pshuf([1/3],3), Pseq([1/6],6), 1/2, 1, 2], [2,0.5,1.5,0.5,0.3,0.1].normalizeSum,inf), \sus, 0)

Pbindef(\clap, \dur, Pshuf([Pxrand([0.5,Pshuf([0.25,0.75])],2), Pseq([0.25],8), 1,2],inf))



//////////////// // ORGANISMES CHEUXLOUS


g=[]; e=[]; // < METS ça / ! ! ! \


g = g.add(Synth(\autoglob,[\argA,10.0.rand,\argB,30.rand,\argC,rrand(500,1400),\amp,0.31,\panFreq,0.05, \ampLag, 0.2]))
g.do({arg i; i.set(\amp, 0, \ampLag, 100)})
g.do({arg i; i.set(\argA, 5)})
g.do({arg i; i.free}); g=[];

e = e.add(Synth(\autoformant,[\fund,100.rand,\form,600.rand,\bw,1800.rand, \amp, 0.1, \ampLag, 0.2]))
e.do({arg i; i.set(\amp, 0, \ampLag, 100)})
e.do({arg i; i.free}); e = [];


Pdef.removeAll;

// STOPTOUT /
Pbindef(\dubbysnare).stop;
Pbindef(\heartbeat).stop.clear;
Pbindef(\baaas).stop;
Pbindef(\vent).stop;
Pbindef(\vent2).stop;
Pbindef(\wouin).stop;
Pbindef(\wouine).stop;

Pbindef(\helico).stop;
Pbindef(\sur).stop;
Pbindef(\secondheart).stop;
Pbindef(\secondsnare).stop;

Pbindef(\tremble).stop;
Pbindef(\snare).stop;
Pbindef(\roll).stop;
Pbindef(\clap).stop;
Pbindef(\snark).stop;



//////////////// // BONUS TRACK

Pdef.removeAll
Pbindef(\sourdkick,\instrument,\kick,\amp,0.25,\dur,Prand([1,1.5,2],inf),\attRel,600,\freqA,220,\freqAC,30).play(quant:4);
Pbindef(\sourdkick,\dur,Pwhite(1,4),\freqA,360,\freqB,100,\freqC,115,\rel,1,\relC,Pwhite(6,-12))
Pbindef(\sourdkick,\freqC,30,\freqB,70,\freqAC,0,\rel,0.5)
Pbindef(\sourdkick).stop.clear;

Pbindef(\soussnare,\instrument,\snare,\dur,Pseq([4,2,1,1],inf),\amp,0.05,\noiseRelC,-80,\noiseRel,1,\rel,0.35,\relC,100,\fq,[220,120,442,80]).play(quant:[4]);
Pbindef(\soussnare,\noiseRelC,-30,\rel,0.75)
Pbindef(\soussnare,\noiseRelC,Pseq([Pseq([-30],Pwhite(4,14,1)),Pseq([10],Pwhite(1,4,1))],inf))
Pbindef(\soussnare).stop.clear;


Pbindef(\baaas, \instrument, \kick, \sus, 1, \freqB, (Pwhite(40,45!3)+30), \dur, 4, \amp, 0.2).play(quant:[8,3])
// OR //
Pbindef(\baaas, \instrument, \blip, \sus, 1, \freq, (Pwhite(40,45!3)+10), \dur, 4, \amp, 0.2).play(quant:[8,3])
Pbindef(\baaas).stop

// BAAAASSSS
Pbindef(\deep,\instrument,\kick,\freqC,[75,70] * Pseq([1,1.25],inf),\freqB,([50,65]+30) * Prand([1,2],inf),\rel,Pwhite(0.025,0.04),\relC,2,\freqBC,0,\dur,Pseq([Pseq([1/4],6), 1/2, 1/4,1/2],inf),\amp,0.1).play(quant:4)
Pbindef(\deep).stop

// Noises
Pbindef(\souris,\instrument, Prand([\noiseUp, \noiseDwn],inf), \dur, Pexprand(5, 0.1), \amp, Pwhite(0,0.6), \sus, Pkey(\dur) * Pwhite(0.1, 1)).play
Pbindef(\souris).stop

(
Pbindef(\clapo,\instrument,\blip,\amp,Pwhite(0.05,0.1),\nharm,1,\freq, Pseq([[1020,1026,1064], [1026,1032,1128], [1032,1064,1256]], inf), \stretch,1/4, \sus, 0.02).play)
Pbindef(\clapo, \dur, 1/3)
Pbindef(\clapo).clear

Pbindef(\nitrate, \instrument,\sine,\freq,Prand([\rest,[1700,7150,1800,1720,1711],[1700,1720,1760,1800,1820,1810]],inf),\amp,Pseq([0.01,0.05],inf),\att,0.001,\sus,0,\rel,Pwhite(0.1,0.03), \dur,Pseq([1/6,2/6],inf) ).play(quant:4)
Pbindef(\nitrate, \amp, 0.05, \dur, 1/7).play
Pbindef(\nitrate).stop.clear

(Pbindef(\snark, \instrument, \snaredel, \pan,Pwhite(-1.0,1),\dur,Prand([1,2],inf),\rel,Pwhite(0.1,1),\relC,-12,
	\deldur,Pwhite(0.05,0.3),\delvit,Pwhite(0.01,0.5),\delfq,Pwhite(1,30),
	\amp,Pwhite(0.5,0.8),\ff,Pwrand([Pwhite(10,100,1), Pwhite(2000,5000,1)],[0.7,0.3],inf)
).play(quant:[4,2]))
Pbindef(\snark, \dur, Pseq([1/4,3/4],inf))
Pbindef(\snark).stop.clear;

Pbindef(\kik, \instrument, \kick, \dur, Pshuf([Pseq([1/4],3), Pseq([1/4],4), 1/8, 1/8],inf), \amp, 0.6, \stretch, 1, \freqAC, -3, \freqBC, -3, \rel, 0.125, \freqA, 6500, \freqB, 103, \freqC, 40).play(quant:4)
Pbindef(\kik,\freqAC, 7)
Pbindef(\kik, \dur, Pseq([ Pseq([1/8], 8), Pshuf([Pseq([1/4],3), Pseq([1/4],4), 1/8, 1/8],inf)]))
Pbindef(\kik, \dur, 1/30)
Pbindef(\kik).stop.clear


//////////////////////////////////////////////////////////////////////////

// PSEG test >> Shepard
Pbindef(\test, \instrument, \sine, \dur, 1/20, \freq, [0.5,1,1.5] * Pseg( Pseq([500,1000,1500,2000, 2500],inf), Pseq([4,4,4,4,1/32],inf), \lin), \rel, 0.1).play(quant:4)

/// LEFTOVERS SineSuite

Pbindef(\testspacy, \instrument, \spacy, \dur, Pseq([Pseq([Pseq([1/6],6),1/2],2), Pseq([1/4],4)],inf), \amp, 0.25, \sus, Pseq([Pseq([0.05],14), Pseq([0.2],4)],inf),\freq,Pseq([Pseq([1],14), Pshuf([1.2,1.4,1.6,Prand([1.8,1.1])])],inf) * [500, 950], \rel, 0.001, \att, 0.0001).play

Pbindef(\wouine,\instrument,\formant,\dur,12,\sus,Pkey(\dur),\freq,Pseq([150,225,262.5,400],inf),\addFreq,Pseq([-20,105,142.5,-180],inf),\amp,Pwhite(0.05,0.15),\lenmul,Pwhite(0.8,1.5),\bwfreq,0).play
Pbindef(\wouine, \freq, 60, \addFreq,-20, \lenmul,2,)
Pbindef(\wouine).stop

//////////// C'EST BIEN POUR LA GROOVE DESSOUS


Pbindef(\bete, \instrument,\kick,\amp,0.3, \rel, 0.05 ,\freqA,2800,\freqBC,Pwhite(4.0,6),\freqB, 180,\dur,1/4).play(quant:4)

Pbindef(\bete,\rel,Pwrand([0.2,0.01,0.8],[0.6,0.2,0.2],inf),\relC,Pgauss(-3,3),\freqC,Pgauss(80,40), \nharm, 2) // Rigolo random
Pbindef(\bete).stop.clear;

Pbindef(\claque, \instrument,\snare,\dur,1,\noiseRelC,-6,\noiseDecay, 0.008, \amp,0.45, \relC, -3, \hifreq, 700, \fq,280).play(quant:[4,0.5])
// Pbindef(\claque, \dur, Prand([1, Pseq([1/2],2), Pshuf([1/4,1/2,1/4])],inf), \amp,Pseq([0.5,Prand([0,0.5],3)],inf));
// Pbindef(\claque, \noiseDecay,Pseq([0.001,0.003,Pwhite(0.001,0.0005,14)],inf));
Pbindef(\claque, \rel,Pseq([0.05,Pseq([0.1,0.05]),Pwhite(0.001,0.05,14)],inf));
Pbindef(\claque, \dur, Pwrand([1,1/2, Pseq([1/4,1/4])],[0.8, 0.1,0.1],inf))
Pbindef(\claque).stop


Pbindef(\clapette,\instrument,\snare,\amp,Pwhite(0.08,0.17),\dur,Prand([1,1/8,3/4],inf),\rel,0.001,\sus,0.1, \noiseDecay, Pwhite(0.001,0.005), \hifreq,Pwhite(1050,1200), \noiseRelC, -6).play(quant:[4,2])
Pbindef(\clapette).stop.clear

(
Pbindef(\clapo,\instrument,\blip,\amp,Pwhite(0.05,0.1),\nharm,1,
	\freq,Pseq([[1020,1026,1064],[1026,1032,1128],[1032,1064,1256]],inf),
	// \freq,Pseq([Array.geom(6,1000,1.1),Array.geom(6,1610.51,1.1),Array.geom(6,620.92132,1.1)].flop,inf),
	\stretch,1/4,\sus,0.02).play)
Pbindef(\clapo).clear

Pbindef(\nitrate, \instrument,\sine,\freq,Prand([\rest,[1700,7150,1800,1720,1711],[1700,1720,1760,1800,1820,1810]],inf),\amp,Pseq([0.01,0.05],inf),\att,0.001,\sus,0,\rel,Pwhite(0.1,0.03), \dur,Pseq([1/4,1/8],inf) ).play(quant:4)
Pbindef(\nitrate, \dur, 1/5)
Pbindef(\nitrate).stop.clear

Pbindef(\bas, \instrument, \sine,\dur,Pseq([1,2,3],inf),\sus, Pkey(\dur) / 2.25,\att,Pkey(\dur)/Pwhite(5,14),\rel,Pkey(\dur)/Pwhite(6,10), \freq,[120,180,90],\amp,0.15).play(quant:4);
Pbindef(\bas,\freq,[120,180,90] * Pstutter(2,Pxrand([0.8,1,1.6,1.3,1.2],inf))) // Marche funebre
Pbindef(\bas,\freq,[120,180,90] * Pstutter(2,Pxrand((0.95,0.96..1.1),inf))) // Marche atonale
Pbindef(\bas,\dur,Pxrand([1/2,2,1/4],inf)) // Accèlere un peu
Pbindef(\bas, \att,0.01, \rel, 0.01, \dur,Prand([1/4,1/4,1],inf),\sus, Pseq([Pwhite(0.05,0.2,2)],inf) ) // accélère carrément
Pbindef(\bass, \amp, 0.2)
Pbindef(\bas).stop.clear


(Pbindef(\snark, \instrument, \snaredel, \pan,Pwhite(-1.0,1),\dur,Prand([1,2],inf),\rel,Pwhite(0.1,1),\relC,-12,
	\deldur,Pwhite(0.05,0.3),\delvit,Pwhite(0.01,0.5),\delfq,Pwhite(1,30),
	\amp,Pwhite(0.5,0.8),\ff,Pwrand([Pwhite(10,100,1), Pwhite(2000,5000,1)],[0.7,0.3],inf)
).play(quant:[4,2]))
Pbindef(\snark, \dur, Pseq([1/4,3/4],inf))
Pbindef(\snark).stop.clear;

Pbindef(\kik, \instrument, \kick,\freq, 1, \dur, Pseq([Pseq([1/8],14),Prand([Pseq([1/8],2), 1/4, 1/2])],inf)).play(quant:4)

(Pbindef(\beachbreak, \instrument, \snaredel,\dur,Pxrand([1,4,8,16],inf),\rel,Pwhite(1,3), \deldur,Pwhite(0.5,3),\delvit,Pwhite(0.01,1),\delfq,Pwhite(1,20), \amp,Pwhite(0.1,0.5),\ff,Pexprand(10,900)).play(quant:4))
Pbindef(\beachbreak).stop.clear


Pbindef(\guuz,\instrument,\sine,\freq,[700,750,800,720,711],\amp,0.1,\att,0.001,\sus,0,\rel,Pwhite(0.1,3),\dur,Prand([4,8,16,],inf)).play
Pbindef(\guuz).stop.clear


(Pbindef(\hardcrack, \instrument,\snaredel,\amp,Prand([0,0.1],inf),\dur,Prand([Pseq([1/4,3/4]),1],inf), \ff, Pwhite(320,500), \relC,Pwhite(-20,-6),
	\rel,Pwrand([Pwhite(1.5,2),Pwhite(3,6,1)],[0.9,0.1],inf),
	\deldur, Pexprand(0.25,0.75),
	\delvit, Pexprand(0.001,0.5),
	\delfq,0.5
).play(quant:4))
Pbindef(\hardcrack).stop.clear


Pbindef(\rales, \instrument,\formant,\amp,Pwhite(0.1,0.3),\att,Pwhite(0.001,0.5),\rel,Pwhite(0.01,0.3),\dur,Pwalk((0.5,1..16),Prand([-1,0,1,2],inf),1,5),\sfreq,Pwhite(30,80),\efreq,Pwhite(300,600),\lenmul,Pwhite(1,2)).play(quant:4);
Pbindef(\rales).clear




/////// SMOOTHIE

Pbindef(\crack, \instrument, \snaredel,\pan,Pwhite(-1.0,1),\dur,Prand([3.5,5.75,1],inf),\rel,Pwhite(0.01,0.3),\deldur,Pwhite(1.0,3),\delvit,Pwhite(0.001,0.5),\delfq,Pwhite(1,30),\amp,Pwhite(0.05,0.15),\ff,Pwhite(10,200)).play(quant:[4,2])
Pbindef(\crack).stop.clear

z.free;
z ={XLine.kr(0.5, 0.015, Rand(0.2, 0.5), PinkNoise.ar({LFNoise1.kr(30,0.5,0.5)}!2),0,2)}.play
z.free; z ={Line.kr(0, 0.6, Rand(0.1, 0.5), PinkNoise.ar({LFNoise1.kr(18)}!2),0,2)}.play

Pbindef(\basse,\instrument,\sine,\amp,0.15,\freq,[200,60,230] * Pseq([Pseq([1],Prand([3,5])),Prand([0.8,1.2])],inf),\att,0.05,\rel,2,\stretch,Pseq([4,3.25,0.75],inf)).play;
Pbindef(\basse).stop.clear

Pbindef(\bete, \instrument,\kick,\amp,0.5,\freqA,1200,\freqBC,Pwhite(-20,-16.5),\dur,4,\rel,Pkey(\dur)).play(quant:4)
Pbindef(\bete).stop.clear

Pbindef(\guuz,\instrument,\sine,\freq,[700,750,800,720,711],\amp,0.1,\att,0.001,\sus,0,\rel,Pwhite(0.1,3),\dur,Prand([4,8,16,],inf)).play
Pbindef(\guuz).stop.clear

Pbindef(\clair, \instrument, Prand([\noiseDwn, \noiseUp],inf), \dur, Pseq([Pseq([0.5],8), Prand([0.25,0.5,0.75,0.125],4)],inf), \sus, 0.3, \amp, 0.5, \panFreq,18).play
Pbindef(\clair).stop.clear

Pbindef(\claire, \instrument, \noise, \dur, Pseq([0.75, 0.25, 0.5],inf), \amp, Pseq([0.1,0],inf), \freqC, 5300).play(quant:[4])
Pbindef(\claire, \rel, 1, \relC,-3)
Pbindef(\claire).stop.clear

(Pbindef(\drags, \instrument,\formant,
	\amp,0.6,
	\dur, 1/4,
	\stretch, Pwrand([1,2,3],[0.5,0.3,0.2],inf), // à commenter pour accélerer
	\rel, Pwhite(0.005,0.075),
	\lenmul, Pexprand(0.001,1),
	\freq,Pstutter(18, Pseq([30,40,55,60],inf)),
	\addFreq,Pstutter(Pwhite(1,16), Pseq([300,Prand([150,1080]),55,800],inf)),
	\bwfreq, Pgauss(880,500)
).play(quant:4);
)
Pbindef(\drags).stop.clear


x.free; x = {var qt = 8; FSinOsc.ar(LFNoise1.kr(1, 20, NamedControl.kr(\freq, {rrand(300, 400).postln}!qt, {rrand(0.1,1)}!qt)), 0, NamedControl.kr(\amp, 0.1, 1))}.play
x.setn(\freq, {rrand(560,530)}!8)
x.setn(\amp,0)
x.free

Pbindef(\hitsine, \instrument, \kick, \rel, 0.5, \relC, 3, \freqBC, 0, \freqA,rrand(2060,5500)!6, \freqB, exprand(600,60)!6, \freqBDur, 30, \freqADur, 0.025, \dur, 3).play(quant:[4,0.5])
Pbindef(\hitsine).stop


/////////////////////////////////////////////


Pbindef(\zoukik,\instrument,\kick,\amp,0.4,\dur,Pshuf([0.5,1,1.5,2],inf),\freqA,1400,\freqAC,0,\freqC,100,\freqBC,-20,\rel,0.3,\relC,-6).play(quant:4);
Pbindef(\zoukik,\dur,Pwrand([1/2,1,1/4],[0.4,0.3,0.5],inf))
Pbindef(\zoukik)
Pbindef(\zoukik).stop.clear

Pbindef(\sous,\instrument,\snare,\freq,Pwrand([200,\rest],[0.95,0.05],inf),\dur,Pn(Pshuf([1/8,1/4,1/4,1/8,1/2].sputter(0.75,8)),inf),\noiseRelC,Pseq([-6,Pseq([-20],Prand([7,15]))],inf),\bw,1.5,\amp,Pseq([0.1,Pseq([0.05],7)],inf)).play(quant:4)
Pbindef(\sous,\dur,Pwrand([1/8,1/4],[0.8,0.2],inf))
Pbindef(\sous).stop.clear


// CINQ ET SEPT / QUATRE ////////////////////////////////////////////
TempoClock.tempo_(70/60)

// Kick Définition
Pbindef(\obs,\instrument,\kick,\freqA,2000,\freqBC,-12, \freqB, 80, \freqC,100)

// de l'air
Pbindef(\obs, \dur,1/7,\amp,Pseq([0.5,Prand([Pseq([ Pshuf([0.01,0.1,0.5,0]),Pshuf([0.5,0.1]) ]), Pwrand([0.1,0,0.5],[0.1,0.8,0.1],6) ]) ],inf)).play(quant:4)

// moins d'air
Pbindef(\obs, \dur,1/7,\amp,Pseq([0.5,Pshuf([0.01,0.1,0.5,0]),Pshuf([0.5,0.1])],inf)).play(quant:4)
Pbindef(\obs, \pan, Pwhite(-0.5,0.5))

Pbindef(\obs, \rel,0.25,\relC,0, \freqC,Pseq((60,61..2800),inf))

// encore moins d'air
Pbindef(\obs, \amp,Pseq([0.5, Pwhite(0,0.5,6)],inf))
Pbindef(\obs, \amp,Pseq([0.5, Prand([0.5,0])],inf)).stop

// BLIPS
Pbindef(\metro,\instrument,\blip,\freq,Pseq([1500,Pn(1000,6)],inf),\dur,1/7).play(quant:4)
Pbindef(\metro,\att,Pexprand(0.001,0.1),\amp,Prand([0.2,0],inf),\freq,Pwhite([800,600,300]/*/2*/,[200,800,400]/**4*/))

// Snare pour 7/4
Pbindef(\idienne, \instrument,\snare, \dur,(Prand([2],inf)),\amp,0.075).play(quant:[4,3/7]);

// Double la snare
Pbindef(\doublidienne,\fq,Pseq((1200,1180..400),inf), \instrument,\snare, \dur,(Prand([0.5,1,2],inf) + Pseq([Pshuf([1/7,-1/7,0])],inf)),\amp,0.075).play(quant:[4,5/7])
Pbindef(\doublidienne).stop

// Petit formant
Pbindef(\for,\instrument,\formant,\amp,Pseq([Pshuf([0.07,0,0.05,0,0])],inf),\dur,1/7,\rel,Pseq([0.01,0.02,0.35,0.001],inf), \freq,Pwhite(80,320), \addFreq,Pwhite(800,900),\lenmul,Pwhite(0.8,6),\bwfreq,880).play(quant:4)
Pbindef(\for).stop.clear


// Ralonge la snare progressivement
Pbindef(\idienne, \noiseRel,Pseq([(0.3,0.32..3),0.3].lace(136),inf),\rel,Pseq([(0.3,0.32..3),0.3].lace(136),inf))
Pbindef(\idienne, \noiseRel,0.1, \rel,0.1)

Pbindef(\idienne, \att, Pdefn(\etale), \noiseAtt, Pdefn(\etale));
Pbindef(\idienne, \noiseRelC,-1, \relC,0, \dur,(Pdefn(\etale) * 1.5).trace,\fq,Pgauss(320,10)).clear

Pdefn(\etale,Pseq([Pseq((0.001,0.5..3)), Pseq([3],inf)],inf))
Pdefn(\gonfle, Pseq((-3,-2.5..6),inf))




(/* CREATE GLOBS */ h.do({arg item, i; item.free});
h.free; h = {Synth(\autoglob,[\argA,10.0.rand,\argB,30.rand,\argC,rrand(500,1400),\amp,0.15,\panFreq,1])}!2;)

/* ADD */ h = h.add(Synth(\autoglob,[\argA,3.5.rand,\argB,200.rand,\argC,3640.rand,\amp,0.5,\panFreq,1]));
/* INFOS */ h.do({arg item, i; i.post; " ".post; item.postln});
/* CONTROL */
h[0].set(\amp,0.5,\argA,4.0.rand,\argB,50.rand,\argC,rrand(50,1400))
h.do({arg item, i; item.set(\amp,0,\argA,4.0.rand,\argB,50.rand,\argC,rrand(50,1400))});
h.do({arg item, i; item.free});

j.do({arg item; item.free;}); j.free;
j = j.add(Synth(\autoformant,[\fund,180.rand,\form,600.rand,\bw,1800.rand]));
j[0].set(\fund,20)
j.do({arg item, i; item.set(\fund,180.rand,\form,600.rand,\bw,1800.rand,\amp,0.1);})

~m = [220,246.94,261.63,293.66,329.63,349.23,392.00];
~n = Array.series(7,0.5,-0.0830);
~n.reverse

/////// AUTRE CHOSE
Pbindef(\harcel,\instrument,\snare,\noiseRelC,-40,\noiseRel,0.3,\rel,0.1,\relC,0,\fq,Pseq([[600,1200,2400],[800,1600,3000],[1000,2000,3600]],inf),\dur,1).play
Pbindef(\ron,\instrument,\blip,\freq,Pseq(~m,inf),\amp,Pseq(~n.reverse,inf),\sus,0.25,\dur,0.25).play;
Pbindef(\rond,\instrument,\blip,\freq,Pseq(~m*2,inf),\amp,Pseq(~n,inf),\sus,0.25,\dur,0.25).play;
Pbindef(\ronde,\instrument,\blip,\freq,Pseq(~m*3,inf),\amp,Pseq(~n.reverse,inf),\sus,0.25,\dur,0.25).play;


Pbindef(\reso,\instrument,\kick,\freqA,2800,\freqB,420,\freqC,45,\rel,0.35,\relC,0,\freqAC,-6,\freqBC,-20,\dur,0.75,\amp,0.5).play

Pbindef(\harcel).stop.clear

TempoClock.default.tempo = 1.5

/////// 14/08/17 // ça peut danser
Pdef.removeAll
Pbindef(\bete,\instrument,\kick,\amp,0.15,\dur,1/8, \rel,0.1).play(quant:4);
Pbindef(\bete,\relC,Pstutter(48,Pgauss(-6,6)),\freqC,Pstutter(72,Pgauss(60,40)));
Pbindef(\bete,\freqA, Pstutter(96, Pwhite(8000,3000)),\freqAC, Pwrand([Pseq([Pwhite(-8,-16)],72), Pseq([Pseries(-16,0.25,48)])],[0.75,0.25],inf));
Pbindef(\bete, \freqADur, Pwalk((0.02,0.021..0.07),Prand([-2,-1,0,1,2],inf),1,25));
Pbindef(\bete,\freqB,Pstutter(96,Pwhite(60,95)));
Pbindef(\bete).stop.clear;


Pbindef(\kik,\instrument,\kick,\amp,Pseq([Pwrand([0.4,0.2,0],[0.8,0.175,0.025]),Prand([0,Pwhite(0,0.3,1)])],inf),/*\freq,Prand([1,1,1,\rest],inf),*/\nharm,Prand([Pseq([1],4),Pseq([1,1,2,3]), Pseq([1,1,3,1])],inf),\stretch,1/4,\relC,-12,\attC,-6).play(quant:4);
Pbindef(\kik, \pan, Pwalk((-1,-0.9..1),Prand([0,1,2],inf), Pseq([1,-1],inf),5))
Pbindef(\kik).stop.clear

Pbindef(\clap,\instrument,\snare,\amp,Pwhite(0.01,0.5),\dur,Prand([1,2],inf),\noiseRelC,-16,\sus,0.05).play(quant:[4,0.5])
Pbindef(\clap, \stretch,1/2)
Pbindef(\clap).stop.clear

////// Formant machine

Pbindef(\fofor, \instrument,\formant, \amp, 0.2,\rel,Pwhite(0.1,0.2), \dur, 0.25).play
Pbindef(\fofor,\freq, 40, \addFreq, 2200, \dur, 1, \rel, 0.8, \lenmul, 1)
Pbindef(\fofor, \addFreq, Pwalk((2200,1950..4), Prand([0,1,2],inf),Pseq([1,-1],inf)));
Pbindef(\fofor, \freq, Pwalk((4,4.5..500), Prand([0,1,2],inf),Pseq([1,-1],inf)));
Pbindef(\fofor, \lenmul, Pwalk((0.5,0.6..16), Prand([0,1,2],inf),Pseq([1,-1],inf)));
Pbindef(\fofor, \dur, 0.25, \rel, Pwhite(0.08,0.2))
Pbindef(\fofor, \dur, 0.75, \rel, Pwhite(0.5,0.8))
Pbindef(\fofor, \lenmul, 3)
Pbindef(\fofor).stop.clear

Pbindef(\testtones, \instrument, \blip, \dur, 4, \sus, 3, \freq,[55,58,82,86], \att, 0.01, \rel, 0.1, \amp, 0.25).play(quant:[4,2])
Pbindef(\testtones, \out, ~compIn.index)
Pbindef(\testtones).play

Pbindef(\testcomp, \instrument, \kick, \dur, Pseq([2,0.5,0.5,1],inf), \amp, 0.8, \out,[ ~compCtrl.index, 0]).play(quant:4)
Pbindef(\testcomp, \out, 0).stop
Pbindef(\testcomp, \out, ~compCtrl.index).play