// GLISSADES //
s.boot;


(/* VU METRE & FREQSCOPE */ w = Window.new("Levels");w.visible = true; r.free; r = ServerMeterView.new(s,w,0@0,2,2);
f.free; f = FreqScope.new(400,400,0,server:s); f.window.front;)

(
~info = {arg group; group.size.do({arg i; ~sines[i].get(\freq, {arg val; (i+"").post; val.post;}); ~sines[i].get(\amp, {arg val; " : ".post; val.round(0.001).postln})})};

~compIn = Bus.audio(s,2);
~compCtrl = Bus.audio(s,2);
~compOut = Bus.audio(s,2);
~compIn.scope;

// Sine
SynthDef("gliss",{arg ampLag=0.5, freqLag=0, panLag=0, panFreq=0.1,panMod=0, out=0 ;
	var freq = NamedControl.kr(\freq,440,freqLag);
	var pan = NamedControl.kr(\pan,0,panLag);
	var amp = NamedControl.kr(\amp,0.05,ampLag);
	var pano = FSinOsc.kr(panFreq,0,panMod,pan);
	Out.ar(out,Pan2.ar(SinOsc.ar(freq),pano, amp));
},[10,0,0,10,10]).add;

SynthDef("sidechain",{
	arg out = 0, in = ~compIn.index, ctrl = ~compCtrl.index,
	thresh = 0.5, slopeBelow = 1, slopeAbove = 0.5, clampT = 0.001, rel = 0.01, amp = 0.5,treshGate=0.01;
	var sig, control;
	sig = In.ar(in,2);
	control = In.ar(ctrl, 2);
	// Side Chain
	sig = Compander.ar(sig, control,thresh,slopeBelow,slopeAbove,clampT,rel);
	// Then, Gate
	sig = Compander.ar(sig,sig,treshGate, 10, 1, 0.01, 0.01);
	Out.ar(out, sig * amp);
}).add;
)

// SIDECHAIN TEST //
Pbindef(\test, \instrument, \kick, \dur, 4,\amp, 0.8,\rel, 0.1, \out, [0, ~compCtrl]).play

// SIDE CHAIN //
(y.free; y = Synth.new("sidechain",[\in, ~compIn.index, \ctrl, ~compCtrl.index,
	\thresh, 0.001,\amp, 1, \slopeBelow, 1, \slopeAbove,0.001, \rel, 0.4, \clampT, 0.002],s,\addToTail))

y.set(\rel, 0.2)
y.set(\treshGate,0.01)
y.free


/* BATCH MAKE */
( ~sines.do({arg i; i.free}); ~sines = 6.collect({arg i; Synth(\gliss,[
	\out, ~compIn.index,
	\freq,rrand(2060,5500).postln
	,\freqLag,0.025
	,\panLag,20
	,\pan,1.0.bilinrand
	,\amp,0
	,\ampLag,0.1
])}))

/* BATCH CONTROL -- Entrée */
( ~sines
.do({ arg i; i.set(\dum,0
	,\freq,exprand(100,520.0)
	,\freqLag,0.05
	,\pan,1.0.bilinrand
	,\panMod,0
	,\amp,0.015
	,\ampLag,0.1
)});)

/* CONTROL AU HASARD -- Panoramique modulation */
~sines[~sines.size.rand.post].set(\pan, 0, \panMod, 1.0.rand, \panFreq, 0.5.rand.postln)

/* ADD */
~sines = ~sines.addAll(Synth(\gliss, [\out, ~compIn.index, \amp, 0.0, \freq, 73 + 10.rand], ))

 /*CONTROL PRECIS */
~info.value(~sines)

(~sines[8
].set(
	\freq,86 + 3.0.rand
	,\freqLag, 500
	// ,\amp, 0.01
	// ,\ampLag, 500
))

/* BATCH CONTROL -- Freqs */
( ~sines
.do({ arg i; i.set(
	// \freq,exprand(60,5020.0)
	// ,\freqLag,600
	\amp, 0.0
	,\ampLag,100
	// \out, ~compIn.index
)});)

/* LOOP CONTROL -- Freqs */
(r.free; r = Routine({ loop {~sines.do({arg i; i.post; i.set( // Module lentement
	\freq, exprand(80,1290).postln
	,\freqLag, 500
	// , \amp, 0.0
	// , \ampLag,1500.0.rand
	)}); 500
		.wait;}
}).play)
r.stop

~sines.do({arg item; item.set(\amp,0, \ampLag, 10.rand); wait.10; item.free})

~sines.do({arg i; i.set(\ampLag, rrand(100,630), \amp, 0.01)})
(s.free; s = Routine({ loop{ ~sines.scramble.do({arg i; i.set(\amp, [0.1,0].choose); 0.25.wait}); 1.wait }}).play )

/////////////////////////////////////////

/* ADD */
~sines = ~sines.addAll(Synth(\gliss, [\amp, 0.001,\freq, 4540.0.rand]))

~sines[1].set(\freq,55,\amp, 0.1)