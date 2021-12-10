(
SynthDef.new( \limit, {
		arg in=~limitBus, out=0;
		var sig;
		sig = In.ar(in, 2);
		sig = Compander.ar(sig, sig, 0.001, 1, 0.0005);
		Out.ar(out, sig);
	}).add;

SynthDef.new( \tone2, {
		arg freq=200, amp=0.5, out=0, rel=0.25, pan=0;
		var sig, mod, env, modenv;

		env 	= EnvGen.ar(Env.perc(0.01, rel), doneAction: 2);
		modenv 	= EnvGen.ar(Env.perc(0.001, rel));

		sig 	= LPF.ar(
			SinOsc.ar(freq, mul: 0.7) +
			LPF.ar(WhiteNoise.ar(0.3), 1000*XLine.ar(1, 0.001, 0.1), modenv) +
			SinOsc.ar(freq/2, mul:0.2),
			1000
		);

		sig 	= Pan2.ar(sig*amp*env, pan);
		Out.ar(~limitBus, sig);
	}).add;

s.newBusAllocators;
~revBus = Bus.new('audio', numChannels:2);
~limitBus = Bus.new('audio', numChannels:2);

~srcGrp = Group.new();
~fxGrp	= Group.new(~srcGrp, \addAfter);
)


(
Pbind(
	\instrument, \tone2,
	\freq, Pseq([100], inf),
	\amp, Pgeom(0.9, 0.9, inf),
	\rel, 0.5,
	\out, ~limitBus,
).play(t);
)
Synth.new(\tone2, [\out, ~limitBus], target: ~srcGrp, addAction: \addToHead)
Synth.new(\limit, target: ~fxGrp, addAction: \addToHead);







(
play{

}
)









