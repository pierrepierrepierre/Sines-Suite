// GLISSADES //
s.boot;


(/* VU METRE & FREQSCOPE */ w = Window.new("Levels");w.visible = true; r.free; r = ServerMeterView.new(s,w,0@0,2,2);
f.free; f = FreqScope.new(800,600,0,server:s); f.window.front;)

(
// Sine
SynthDef("gliss",{arg ampLag=0.5, freqLag=0, panLag=0, panFreq=0.1,panMod=0, out=0 ;
	var freq = NamedControl.kr(\freq,440,freqLag);
	var pan = NamedControl.kr(\pan,0,panLag);
	var amp = NamedControl.kr(\amp,0.05,ampLag);
	var pano = FSinOsc.kr(panFreq,0,panMod,pan);
	Out.ar(out,Pan2.ar(SinOsc.ar(freq),pano, amp));
},[10,0,0,10,10]).add;

~info = {arg group; group.size.do({arg i; ~sines[i].get(\freq, {arg val; (i+"").post; val.post;}); ~sines[i].get(\amp, {arg val; " : ".post; val.round(0.001).postln})})}
)

/* BATCH MAKE */
( ~sines.do({arg i; i.free}); ~sines = 3.collect({arg i; Synth(\gliss,[
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
	,\freq,exprand(140,620.0)
	,\freqLag,0.05
	,\pan,1.0.bilinrand
	,\panMod,0
	,\amp,0.05
	,\ampLag,0.1
)});)

/* CONTROL AU HASARD -- Panoramique modulation */
~sines[~sines.size.rand.post].set(\pan, 0, \panMod, 1.0.rand, \panFreq, 0.5.rand.postln)

/* CONTROL au HASARD -- Freqs */
~sines[~sines.size.rand.post].set(\freq, exprand(460, 1210), \freqLag, 350, \amp, 0.025, \ampLag, 0.01)

/* ADD */
~sines = ~sines.addAll(Synth(\gliss, [\amp, 0.001,\freq, 1480.rand + 10.0.rand]))

 /*CONTROL PRECIS */
~info.value(~sines)

(~sines[3
].set(
	\freq,402 + 30.0.rand
	,\freqLag, 100
	,\amp, 0.025
	,\ampLag, 500
))

/* BATCH CONTROL -- Freqs */
( ~sines
.do({ arg i; i.set(
	\freq,exprand(4000,16020.0)
	,\freqLag,400
	// ,\amp, 0
	// ,\ampLag,10
	// \out, ~compIn.index
)});)

/* LOOP CONTROL -- Freqs */
(r.free; r = Routine({ loop {~sines.do({arg i; i.post; i.set( // Module lentement
	\freq, exprand(160,1690).postln
	,\freqLag, 1000
	, \amp, 0.025
	, \ampLag,1000.0.rand
	)}); 1000
		.wait;}
}).play)
r.stop

~sines.do({arg item; item.set(\amp,0); item.free})

~sines.do({arg i; i.set(\ampLag, rrand(100,630), \amp, 0.01)})
(s.free; s = Routine({ loop{ ~sines.scramble.do({arg i; i.set(\amp, [0.1,0].choose); 0.25.wait}); 1.wait }}).play )

/////////////////////////////////////////

/* ADD */
~sines = ~sines.addAll(Synth(\gliss, [\amp, 0.001,\freq, 4540.0.rand]))

~sines[1].set(\freq,55,\amp, 0.1)