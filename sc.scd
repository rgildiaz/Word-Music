// Word Sound Music


					/////////////////////////
					//        Setup        //
					/////////////////////////

(
t = TempoClock.new(180);

~scale = Scale.lydian;

SynthDef.new( \perc, {
	arg out=0, amp=0.2, rev=0.5,
	atk=0.01, rel=1;
	var sig, env;
	sig;
}).add;

SynthDef.new( \pitch, {
	arg out=0, amp=0.2, rev=0.5,
	atk=0.01, rel=1;
	var sig, env;
}).add;

SynthDef.new( \bell, {
	arg out=0, pan=0, freq=300, amp=0.8, rel=0.25;
	var sig, mod, am, hit, high, dampenv,
	env, modenv, amenv, hitenv, highenv;

	amp = amp * rrand(0.45, 0.55);

	modenv = EnvGen.ar(
		Env.perc(0.01, rrand(rel+5, rel+25))
	);
	env = EnvGen.ar(Env.new(
		[0.005, 1, 0.6, 0.0001],
		[0.002, 0.075, rrand(7,9)],
		'exp'
	), doneAction: 2
	);
	amenv = EnvGen.ar(
		Env.perc(0.005, rrand(rel+5, rel+25))
	);
	hitenv = EnvGen.ar(
		Env.perc(0.05, 0.2)
	);
	highenv = EnvGen.ar(
		Env.perc(0.005, rrand(rel+5, rel+25))
	);
	dampenv = EnvGen.ar(Env.new(
		[15000, 30],
		[rel+0.25],
		1
	)
	);

	hit = RLPF.ar(
		SinOsc.ar(
			XLine.ar(freq*4, freq, 0.05)
			*SinOsc.ar(freq*0.92, mul:0.5)
			*SinOsc.ar(freq*0.98, mul:0.5),
			mul: amp/4,
			add: SinOsc.ar(freq, mul:0.5) + 0.5),
		XLine.ar(freq*2, freq, 0.05), 1/2)
	* hitenv;

	high = Mix.ar(
		SinOsc.ar(
		[
			freq*rrand(1.5, 2)*SinOsc.ar(freq*rrand(1.5, 2)),
			freq*rrand(1.5,2),
			freq*rrand(2.1, 2.5)*SinOsc.ar(freq*rrand(2.2, 2.5))
	],
		mul:rrand(amp/8, amp/15)))
	* highenv;

	am = SinOsc.ar(
		freq * rrand(0.9, 1.1),
		mul: rrand(0.4, 0.6))
	* amenv;

	mod = SinOsc.ar(freq, mul: rrand(0.4, 0.6)) + SinOsc.ar(freq*rrand(1.77, 1.82),
		mul: rrand(0.4, 0.6)) * modenv;

	sig = SinOsc.ar(
		[
			freq + rrand(1000, 2000),
			(freq - rrand(1000, 2000)).clip(50, 20000),
			freq
		] * mod * 1/3,
		add: ((am * 0.5) + 0.5)
		* (SinOsc.ar(LFNoise1.ar(rrand(1,2)).range(1.5, 2),
			mul:0.2
		) + 0.2)
	);
	sig = sig + hit + high;
	sig = sig * env * amp;
	sig = LPF.ar(sig, (freq * rrand(18, 22)));
	sig = LPF.ar(sig, dampenv);
	sig = HPF.ar(sig, freq);
	sig = Mix.ar(sig);
	Pan2.ar(sig, rrand(-0.2, 0.2));
	Out.ar(out, sig);
}).add;

SynthDef.new(\tone, {
	arg freq=200, rel=0.1;
	var sig, mod, env, modenv, amp;
	amp = 1;
	env = EnvGen.ar(Env.perc(0.01, rel), doneAction: 2);
	modenv = EnvGen.ar(Env.perc(0.001, rel));
	mod = Saw.ar(freq, mul: modenv);
	// freq = freq*mod;
	sig = LPF.ar(
		SinOsc.ar(freq, mul: 0.7) +
		LPF.ar(WhiteNoise.ar(0.3), 1000*XLine.ar(1, 0.001, 0.1), modenv) +
		SinOsc.ar(freq/2, mul:0.2),
		1000
	).tanh;
	sig = Pan2.ar(sig*amp*env, 0);
	Out.ar(0, sig);
}).add;
)

					/////////////////////////
					// Load the input file //
					/////////////////////////
(
~path = PathName(thisProcess.nowExecutingPath).parentPath;
~in = ~path ++ "alg_out/out.txt";
~in.postln;

// Check if path to file is correct
if(
	File.exists(~in),
	{ x = FileReader.read(~in); },
	{ Error("File % could not be opened.".format(~in)).throw; }
);

// Clean empty strings (if any got left in by accident)
c = x[0].collect({
	|i|
	if(
		i.size >= 2,
		{i}
	)
});
c.postln;
"File loaded!".postln;
)

					/////////////////////////
					//    Parse + Output   //
					/////////////////////////
/*
Parsing Structure:
Encoding
    Text is sent to SuperCollider through a space-separated .txt file. Tokens can be either control changes or note events Each token is created as follows:

            Example:
                Control:
                     0         0           0
                     ^         ^           ^
                    type  control type   value

                Note:
                     1         0           0           0           0           0
                     ^         ^           ^           ^           ^           ^
                    type    quality     velocity     reverb      pitch      repeats

    Each value is encoded as follows:
        type                0: Control
                            1: Note

        Control
            control type    0: Tempo
                            1: Key
            value           range(0,z) (36 possible values)

        Note
            quality         0: Rest
                            1: Short Perc
                            2: Long Perc
                            3: Short Pitch
                            4: Long Pitch
            velocity        range(0,z) (36 possible values)
            reverb          range(0,z) (36 possible values)
			pitch           range(0,z) (36 possible values)
*/

(
~note = {
	|i|
	case
	{ i[1].asString == "0" }			{ ~rest.value(i)      }
	{ i[1].asString == "1" }			{ ~percShort.value(i) }
	{ i[1].asString == "2" }			{ ~percShort.value(i) }
	{ i[1].asString == "3" }			{ ~percShort.value(i) }
	{ i[1].asString == "4" }			{ ~percShort.value(i) }
	{ Error("Note: Unexpected 2nd character: % in %".format(i[1], i)).throw; }
};

~ctrl = {
	|i|
	case
	{ i[1].asString == "0" }			{ ~tempo.value(i) }
	{ i[1].asString == "1" }			{ ~key.value(i)   }
	{ Error("Control: Unexpected 2nd character: % in %".format(i[1], i)).throw; }
};

~rest = {
	nil;
};

~percShort = {
	|i|
	"percShortcalled".postln;
	~deg = rrand(0, 6);
	~repeats = i[5].asInt;
	Pbindef(\percShort,
		\instrument, \tone,
		\scale, ~scale,
		\degree, ~deg - 16,
	).play;
};

r = Routine({
	c.do({
		|i|
		case
		{ i[0].asString == "1" }		{ ~note.value(i) }
		{ i[0].asString == "0" }		{ ~ctrl.value(i) }
		{ Error("Unexpected 1st character: % in %".format(i[0], i)).throw; };
		(1/6).yield;
	})
}).play;
)

					/////////////////////////
					//       Testing       //
					/////////////////////////
// Bell
({
	var sig, mod, am, hit, high,
	env, modenv, amenv, hitenv, highenv, dampenv,
	rel, freq, amp;

	freq = rrand(299,301);
	amp = 0.8 * rrand(0.48, 0.5);
	rel = 0.25;

	modenv = EnvGen.ar(
		Env.perc(0.01, rrand(rel+5, rel+25))
	);
	env = EnvGen.ar(Env.new(
		[0.005, 1, 0.6, 0.0001],
		[0.002, 0.075, rrand(7,9)],
		'exp'
	), doneAction: 2
	);
	amenv = EnvGen.ar(
		Env.perc(0.005, rrand(rel+5, rel+25))
	);
	hitenv = EnvGen.ar(
		Env.perc(0.05, 0.2)
	);
	highenv = EnvGen.ar(
		Env.perc(0.005, rrand(rel+5, rel+25))
	);
	dampenv = EnvGen.ar(Env.new(
		[15000, 30],
		[rel+0.25],
		1
	)
	);

	hit = RLPF.ar(
		SinOsc.ar(
			XLine.ar(freq*4, freq, 0.05)
			*SinOsc.ar(freq*0.92, mul:0.5)
			*SinOsc.ar(freq*0.98, mul:0.5),
			mul: amp/4,
			add: SinOsc.ar(freq, mul:0.5) + 0.5),
		XLine.ar(freq*2, freq, 0.05), 1/2)
	* hitenv;

	high = Mix.ar(
		SinOsc.ar(
		[
			freq*rrand(1.5, 2)*SinOsc.ar(freq*rrand(1.5, 2)),
			freq*rrand(1.5,2),
			freq*rrand(2.1, 2.5)*SinOsc.ar(freq*rrand(2.2, 2.5))
	],
		mul:rrand(amp/8, amp/15)))
	* highenv;

	am = SinOsc.ar(
		freq * rrand(0.9, 1.1),
		mul: rrand(0.4, 0.6))
	* amenv;

	mod = SinOsc.ar(freq, mul: rrand(0.4, 0.6)) + SinOsc.ar(freq*rrand(1.77, 1.82),
		mul: rrand(0.4, 0.6)) * modenv;

	sig = SinOsc.ar(
		[
			freq + rrand(1000, 2000),
			(freq - rrand(1000, 2000)).clip(50, 20000),
			freq
		] * mod * 1/3,
		add: ((am * 0.5) + 0.5)
		* (SinOsc.ar(LFNoise1.ar(rrand(1,2)).range(1.5, 2),
			mul:0.2
		) + 0.2)
	);
	sig = sig + hit + high;
	sig = sig * env * amp;
	sig = LPF.ar(sig, (freq * rrand(18, 22)));
	sig = LPF.ar(sig, dampenv);
	sig = HPF.ar(sig, freq);
	sig = Mix.ar(sig);
	Pan2.ar(sig, rrand(-0.2, 0.2));
}.play;
)

s.boot;

Synth.new(\bell);

({
	var sig, mod, env, modenv, amp, freq;
	freq = 200;
	amp = 1;
	env = EnvGen.ar(Env.perc(0.01, 0.1), doneAction: 2);
	modenv = EnvGen.ar(Env.perc(0.001, 0.1));
	sig = LPF.ar(
		SinOsc.ar(freq, mul: 0.7) +
		LPF.ar(WhiteNoise.ar(0.3), 1000*XLine.ar(1, 0.001, 0.1), modenv) +
		SinOsc.ar(freq/2, mul:0.2),
		1000
	);
	Pan2.ar(sig*amp*env, 0);
}.play;
)


(
SynthDef.new(\tone, {
	arg freq=200, rel=0.1;
	var sig, mod, env, modenv, amp;
	amp = 1;
	env = EnvGen.ar(Env.perc(0.01, rel), doneAction: 2);
	modenv = EnvGen.ar(Env.perc(0.001, rel));
	mod = Saw.ar(freq, mul: modenv);
	// freq = freq*mod;
	sig = LPF.ar(
		SinOsc.ar(freq, mul: 0.7) +
		LPF.ar(WhiteNoise.ar(0.3), 1000*XLine.ar(1, 0.001, 0.1), modenv) +
		SinOsc.ar(freq/2, mul:0.2),
		1000
	).tanh;
	sig = Pan2.ar(sig*amp*env, 0);
	Out.ar(0, sig);
}).add;
)

(
Pbind(
    \instrument, \tone,
    \midinote, Pseq([0, 2, 4, 5, 7, 9, 12, 0, 4, 7, 6, 5, 4, 9, 12], inf) + 40,
	\dur, Pseq([0.1], inf),
	\rel, 0.1,
	\pan, Pwhite(-1, 1),
).play;
)




