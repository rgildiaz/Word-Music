// Word Sound Music

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


					/////////////////////////
					//    Make SynthDefs   //
					/////////////////////////

(
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
	arg out=0, freq=200, amp=0.5;
	var sig, mod, am,
	env, modenv, amenv;
	amp = amp * rrand(0.45, 0.55);
	modenv = EnvGen.ar(Env.perc(0.05, rrand(15, 35)));
	env = EnvGen.ar(Env.new(
		[0.0001, 1, 0.6, 0.0001],
		[0.01, 0.075, rrand(7,9)],
		'exp'
	), doneAction: 2
	);
	amenv = EnvGen.ar(Env.perc(0.05, rrand(15, 35)));
	am = SinOsc.ar(freq * rrand(0.9, 1.2), mul: rrand(0.4, 0.6)) * amenv;
	mod = SinOsc.ar(freq, mul: rrand(0.4, 0.6)) + SinOsc.ar(freq*rrand(1.77, 1.82), mul: rrand(0.4, 0.6));
	mod = mod * modenv;
	sig = SinOsc.ar([freq, freq + rrand(1000, 4000), (freq - rrand(1000, 2000)).clip(50, 20000)] * mod * 1/3, add: ((am * 0.5) + 0.5) * (SinOsc.ar(LFNoise1.ar(rrand(1,2)).range(1.5, 2), mul:0.2) + 0.2));
	sig = sig * env * amp;
	sig = LPF.ar(sig, freq * rrand(5,8));
	sig = HPF.ar(sig, freq);
	sig = Mix.ar(sig);
	sig = Pan2.ar(sig);
	Out.ar(out, sig);
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



					/////////////////////////
					//       Testing       //
					/////////////////////////
// Bell
({
	var sig, mod, am,
	env, modenv, amenv,
	freq, amp;
	freq = rrand(200, 200);
	amp = 0.8 * rrand(0.45, 0.55);
	modenv = EnvGen.ar(Env.perc(0.05, rrand(15, 35)));
	env = EnvGen.ar(Env.new(
		[0.0001, 1, 0.6, 0.0001],
		[0.01, 0.075, rrand(7,9)],
		'exp'
	), doneAction: 2
	);
	amenv = EnvGen.ar(Env.perc(0.05, rrand(15, 35)));
	am = SinOsc.ar(freq * rrand(0.9, 1.1), mul: rrand(0.4, 0.6)) * amenv;
	mod = SinOsc.ar(freq, mul: rrand(0.4, 0.6)) + SinOsc.ar(freq*rrand(1.77, 1.82), mul: rrand(0.4, 0.6));
	mod = mod * modenv;
	sig = SinOsc.ar([freq + rrand(1000, 2000), (freq - rrand(1000, 2000)).clip(50, 20000), freq] * mod * 1/3, add: ((am * 0.5) + 0.5) * (SinOsc.ar(LFNoise1.ar(rrand(1,2)).range(1.5, 2), mul:0.2) + 0.2));
	sig = sig * env * amp;
	sig = LPF.ar(sig, freq * rrand(5,8));
	sig = HPF.ar(sig, freq);
	sig = Mix.ar(sig);
	Pan2.ar(sig, rrand(-0.2, 0.2));
}.play;
)













