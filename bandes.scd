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
Pbindef(\sur).stop.clear
