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

// the arg direct will control the proportion of direct to processed signal

SynthDef("tutorial-DecayPink", { arg outBus = 0, effectBus, direct = 0.5;

    var source;

    // Decaying pulses of PinkNoise. We'll add reverb later.

    source = Decay2.ar(Impulse.ar(1, 0.25), 0.01, 0.2, PinkNoise.ar);

    // this will be our main output

    Out.ar(outBus, source * direct);

    // this will be our effects output

    Out.ar(effectBus, source * (1 - direct));

}).add;

​

SynthDef("tutorial-DecaySin", { arg outBus = 0, effectBus, direct = 0.5;

    var source;

    // Decaying pulses of a modulating sine wave. We'll add reverb later.

    source = Decay2.ar(Impulse.ar(0.3, 0.25), 0.3, 1, SinOsc.ar(SinOsc.kr(0.2, 0, 110, 440)));

    // this will be our main output

    Out.ar(outBus, source * direct);

    // this will be our effects output

    Out.ar(effectBus, source * (1 - direct));

}).add;

​

SynthDef("tutorial-Reverb", { arg outBus = 0, inBus;

    var input;

    input = In.ar(inBus, 1);
    // a low-rent reverb
    // aNumber.do will evaluate its function argument a corresponding number of times
    // {}.dup(n) will evaluate the function n times, and return an Array of the results
    // The default for n is 2, so this makes a stereo reverb

    16.do({ input = AllpassC.ar(input, 0.04, { Rand(0.001,0.04) }.dup, 3)});
    Out.ar(outBus, input);

}).add;

​

b = Bus.audio(s,1); // this will be our effects bus

)

​

(

x = Synth.new("tutorial-Reverb", [\inBus, b]);

y = Synth.before(x, "tutorial-DecayPink", [\effectBus, b]);

z = Synth.before(x, "tutorial-DecaySin", [\effectBus, b, \outBus, 1]);

)

​

// Change the balance of wet to dry

y.set(\direct, 1); // only direct PinkNoise

z.set(\direct, 1); // only direct Sine wave

y.set(\direct, 0); // only reverberated PinkNoise

z.set(\direct, 0); // only reverberated Sine wave

x.free; y.free; z.free; b.free;