// COMPRESSEUR
(
~compIn = Bus.audio(s,2);
~compCtrl = Bus.audio(s,2);
~compOut = Bus.audio(s,2);
)
~compIn.scope
(
SynthDef("compresseur",{
	arg out = 0, in = ~compIn.index, ctrl = ~compCtrl.index,
	thresh = 0.5, slopeBelow = 1, slopeAbove = 0.5, clampT = 0.01, rel = 0.01, amp = 0.5;
	var sig, control, compr;
	sig = In.ar(in,2);
	control = In.ar(ctrl, 2);
	compr = Compander.ar(
		sig,
		control,
		thresh: thresh,
		slopeBelow: slopeBelow,
		slopeAbove: slopeAbove,
		clampTime: clampT,
		relaxTime: rel
	);
	Out.ar(out, compr * amp);
}).add;
)


x = Synth.new("compresseur")
x.set(\in, ~compIn.index, \thresh, 1, \slopeAbove, 1, \rel, 0.1)
x.free


// SIDE CHAIN //
(y = Synth.new("compresseur",[\in, ~compIn.index, \ctrl, ~compCtrl.index,
	\thresh, 0.001,\amp, 1, \slopeBelow, 1, \slopeAbove,0.001, \rel, 0.5, \clampT, 0.002],s,\addToTail))
y.set(\rel, 0.1)
y.free

// Son pour test
u = Synth(\droneSine,[\amp, 0.2, \freq, 190, \out, ~compIn.index])
u.set()
u.free


Pbindef(\kt,\instrument, \kick, \freqB, 100, \out, [0, ~compCtrl.index], \dur, Pseq([2,4],inf), \amp,1, \sus, 0.5, \rel, 0.1, \relC, -3).play

~compIn.scope