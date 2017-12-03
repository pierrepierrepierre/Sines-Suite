s.boot;

// Charger les bandes
(a = Buffer.read(s,
	"D:/Musique/Mes sons/Enregistrements divers/LS100754 - 5min Fernao Magalhes.WAV"
	,action:{(">> A : Buffer"+a.bufnum+":"+ a.numFrames + "frames").postln};
); // remember to free the buffer later.

b = Buffer.read(s,
	"D:/Musique/Mes sons/Enregistrements divers/fernao magalhes/LS100757 - Chantier Nocturne - fernao magalhes 2017-07.WAV"
	,action:{(">> B : Buffer"+a.bufnum+":"+ b.numFrames + "frames").postln};
); // remember to free the buffer later.
)
a.get

(
SynthDef("playbuf",{
	arg buf=a.bufnum,buffoffset,startPosLag=0, susLag=0,
	att=0.0001, rel=0.0001, attC=0, relC=0,
	panLag=0,bwLag=0,ampLag=0, out=0, rateLag=0,freqLag=0,loop=0;

	var pan = NamedControl.kr(\pan,0,panLag);
	var rate = NamedControl.kr(\rate,1,rateLag);
	var sus = NamedControl.kr(\sus,1.0,susLag);
	var startPos = NamedControl.kr(\startPos,0,startPosLag);
	var freq = NamedControl.kr(\freq,2000,freqLag);
	var bw = NamedControl.kr(\bw,20,bwLag);
	var amp = NamedControl.kr(\amp,0.2,ampLag);
	var sig, env;

	env= Env([0,1,1,0],[att,sus,rel],[attC,0,relC]).kr(2) * amp;
	sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf)*rate,1, BufFrames.ir(buf)*(startPos),loop);
	sig = BBandPass.ar(sig,freq,bw);
	Out.ar(out,	Mix.new([ Pan2.ar(sig,pan,env)]));
}).add;
)

~play.free; ~play = Synth(\playbuf,[\buf,b,\startPos,1.0.rand,\amp,0.4,\dur,500,\att,1,\sus,499,\freq,1600.rand,\bw,0.5,\freqLag,60,\bwLag,60, \out,0, \loop, 1]); ~play.run(true);
(~play.set(
	\freq, 5600
	,\freqLag,30
	,\bw,0.001
	,\bwLag,100
	,\rate,0.6
	,\rateLag,30
))
~play.set(\amp, 1,\out, ~compIn.index)
~play.set(\ampLag,10, \amp,0);
~play.free

~hit.do{arg item; item.free};
~hit = {arg i; Synth(\playbuf,[\startPos,1.0.rand,\loop,0,\dur,[1,1.5,2.5,0.25,0.75][i],\sus,2.0.rand,\amp,0.6,\att,0.001,\rel,0.13,\attC,12,\relC,-3])}!2
~hit.do{arg item, i; item.set(\dur,[1,1.5,2.5,3.25,0.75][i])}
~hit.do{arg item, i; item.set(\startPos, 1.0.rand)}
~hit


Pbindef(\helico,\instrument,\playbuf,\startPos,Pstutter(24*Pwhite(20,50),Pwhite(0,1.0)),\att,0.1,\rel,0.3,\dur,Pn(Pshuf([1/8,1/16,1/16,1/8,1/4,1/8].sputter(0.75,8)),inf),\attC,12,\relC,-3,\sus,Pexprand(0.5,0),\amp,0.2).play
Pbindef(\helico,\relC,-1)
Pbindef(\helico,\stretch, 1)
Pbindef(\helico).stop.clear

Pbindef(\sur,\instrument,\playbuf,\startPos,Pstutter(24*Pwhite(20,50),Pwhite(0,1.0)),\sus,0,\att,0.1,\rel,0.5,\dur,Prand([1/4,1/3,2/4,3/4,2/3,1,4/3,5/4,6/4,7/4,7/3],inf),\attC,30,\relC,0,\amp,0.3,\rate,1).play
Pbindef(\sur,\dur,Pseq([Pgeom(0.1,1.01,300),Pseq([4],inf)],1),\sus,(Pkey(\dur)),\att,0,\rel,0,\startPos,Pstutter(Pwhite(1,8),Pwhite(0,1.0)));
Pbindef(\sur, \amp, 0.01)
Pbindef(\sur).stop.


////////////// NEWS ///////////////

(p = Buffer.read(s,
	"D:/Musique/Musique maison/Bandes Annonces/Elephant/elephant-seq_debut.wav"
	,action:{(">> P : Buffer"+p.bufnum+":"+ p.numFrames + "frames").postln};
); // remember to free the buffer later.

q = Buffer.read(s,
	"D:/Musique/Musique maison/Bandes Annonces/Elephant/elephant-clarke_premiere_moitie.wav"
	,action:{(">> B : Buffer"+q.bufnum+":"+ q.numFrames + "frames").postln};
); // remember to free the buffer later.

r = Buffer.read(s,
	"D:/Musique/Musique maison/Bandes Annonces/Elephant/behind-scenes-of-elephant_doc.wav"
	,action:{(">> R : Buffer"+r.bufnum+":"+ r.numFrames + "frames").postln};
); // remember to free the buffer later.
)

(
SynthDef("PlayHoles", {arg out=0, buf=p.bufnum, amp=1, fpulse=0.5, rate=1, width=0.5, startPos=0, lag=0, rq=1;
	var sig, env, pan, trig;
	env = Lag.kr(LFPulse.kr(fpulse, 0, width), lag);
	sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf) * rate,1,BufFrames.ir(buf)*(startPos),1);
	// sig = BLowPass.ar(sig, LFNoise0.kr(0.1, 200, 300), rq);
	// sig = BBandPass.ar(sig, LFNoise1.ar(0.1,800, 900), bw);
	sig = sig * env;
	Out.ar(out, sig * amp);
}).add;
)

z.free; z = Synth("PlayHoles",[\fpulse,0.5.rand, \width,0.08.rand, \startPos, 0.9.rand, \amp, 1, \lag, 0.25,\buf,a])
y.free; y = Synth("PlayHoles",[\fpulse,0.5.rand, \width,0.8.rand, \startPos, 0.9.rand, \amp, 1, \lag, 0.25,\buf,a])

z.set(\lag,0.1)

x.free; x = Synth("PlayHoles",[\fpulse,10, \width,0.07, \startPos, 0.9.rand])
x.set(\width,0.05, \fpulse,0.5, \amp, 2)

(z.free; z = {arg amp=0.051;
	(SinOsc.ar(
		LFPulse.kr(LFNoise1.kr(0.2,1,1), 0, LFNoise1.kr(0.5,0.5,0.5), 100, 140), 0, amp
)!2)!3
}.play)
z.set(\amp, 0.02)
z.free

{PlayBuf.ar(2, p.bufnum,BufRateScale.kr(p.bufnum)) * PlayBuf.ar(2, q.bufnum, BufRateScale.kr(q.bufnum)) * 0.2}.play;

(y.free; y = {var ch1, ch2, ch3;
	ch1 = PlayBuf.ar(2, p.bufnum, BufRateScale.kr(p.bufnum),1,BufFrames.ir(p.bufnum)*(0.5));
	ch2 = DelayC.ar(ch1, 0.5, 0.5);
	ch3 = DelayC.ar(ch2, 0.5,  0.5);
	// ch2 = PlayBuf.ar(2, q.bufnum, BufRateScale.kr(p.bufnum) * ch1.range(0,1.0));
	// ch3 = PlayBuf.ar(2, r.bufnum, BufRateScale.kr(r.bufnum) * ch2.range(0,1.0));
	(ch2 * ch3 * ch1) + (ch1 * ch2) * 16 + ( Dust2.ar(Pulse.kr(5, 0.5, 500, 600),0))
}.play)


(
SynthDef("PlayWeird", {arg out=0, buf=p.bufnum, amp=1, fpulse=0.5, rate=1, width=0.5, startPos=0, lag=0, rq=1;
	var sig, env, pan, trig;


	sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf) * rate * LFNoise0.kr([0.1,0.05], 0.1,1),1,BufFrames.ir(buf)*(startPos),1) * (1/3);

	// sig = Lag.ar(LFPulse.ar(fpulse,0,width, sig),0.2);

	sig = DelayC.ar(sig, 0.5, SinOsc.kr([0.12,0.1],pi.rand,[0.1,0.05], 1) );

	Out.ar(out, sig * amp);
}).add;
)

y.free; y = Synth("PlayWeird", [\startPos, 0.5.rand, \fpulse, 0.01, \amp, 2, \buf, a, \width, [0.25,0.75]])
y.set()


(
SynthDef("PlayMant", {arg out=0, buf=p.bufnum, amp=1, startPos=0, rate=1,freq =440, addFreq=440, att=0.1, sus=1, rel=0.1, rq=0.1;
	var sig, env, dur, dry;
	dur = att+rel+sus;
	sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf) * rate,1,BufFrames.ir(buf)*(startPos),1);
	dry = sig;
	sig = BLowShelf.ar(sig,freq/2, rq);
	sig = Formant.ar(freq, LFNoise1.ar(0.5,freq, (freq + addFreq) * LFNoise1.kr(0.25,1,1)), freq * LFNoise1.kr(0.5,0.5,0.5), sig);
	sig = SelectXFocus.ar(LFNoise1.kr(1),[sig,dry]);

	Out.ar(out, sig * amp);
}).add;
)

x.free; x = Synth("PlayMant", [\startPos, 1.0.rand])
x.set(\amp,1, \buf, q.bufnum)