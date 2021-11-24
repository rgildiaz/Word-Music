(
s.quit;
s.waitForBoot({
					/////////////////////////
					// Load the input file //
					/////////////////////////

	~path = PathName(thisProcess.nowExecutingPath).parentPath;
	~in = ~path ++ "alg_out/out.txt";
	~in.postln;

	// Check if path to file is correct
	if(
		File.exists(~in),
		// for some reason, FileReader returns a nested array. .flatten removes the outer layer.
		{ x = FileReader.read(~in).flatten; },
		{ Error("File % could not be opened.".format(~in)).throw; }
	);

	// Clean empty strings (if any were left in by accident)
	c = x.collect({
		|i|
		if(
			i.size >= 2,
			{i}
		)
	});
	// c = ["0099", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307"];
	c.postln;
	// c = Array.fill(1, c[2]);
	"File loaded!".postln;

					/////////////////////////
					//        Setup        //
					/////////////////////////

	t = TempoClock.new(240/60).permanent_(true);
	~scale = Scale.dorian;

	// Buses
	s.newBusAllocators;
	~revBus = Bus.new('audio', numChannels:2);

	// SynthDefs
	SynthDef.new( \tone2, {
		arg freq=200, amp=0.5, out=0, rel=0.25, pan=0;
		var sig, mod, env, modenv;
		env = EnvGen.ar(Env.perc(0.01, rel), doneAction: 2);
		modenv = EnvGen.ar(Env.perc(0.001, rel));
		sig = LPF.ar(
			SinOsc.ar(freq, mul: 0.7) +
			LPF.ar(WhiteNoise.ar(0.3), 1000*XLine.ar(1, 0.001, 0.1), modenv) +
			SinOsc.ar(freq/2, mul:0.2),
			1000
		);
		sig = Pan2.ar(sig*amp*env, pan);
		Out.ar(out, sig);
	}).add;

	// scrap this
	SynthDef.new( \bell, {
		arg freq=300, amp=0.8, rel=0.25, out=0;
		var sig, mod, am, hit, high,
		env, modenv, amenv, hitenv, highenv, dampenv;

		amp = amp * rrand(0.48, 0.5);

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

		dampenv = EnvGen.ar(
			Env.perc(0.0001, rel)
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

		mod = SinOsc.ar(freq, mul: rrand(0.45, 0.5)) + SinOsc.ar(freq*rrand(1.77, 1.82),
			mul: rrand(0.45, 0.5)) * modenv;

		sig = SinOsc.ar(
			[
				freq + rrand(1500, 1600),
				(freq - rrand(1500, 1600)).clip(50, 20000),
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
		sig = sig * dampenv;
		sig = HPF.ar(sig, freq);
		sig = Mix.ar(sig);
		sig = Pan2.ar(sig, rrand(-0.2, 0.2));
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\tone, {
		arg freq=200, rel=0.1, amp=0.8, pan=0, out=0;
		var sig, mod, env, modenv;
		env = EnvGen.ar(Env.perc(0.01, rel), doneAction: 2);
		modenv = EnvGen.ar(Env.perc(0.001, rel));
		mod = Saw.ar(freq, mul: modenv);
		freq = freq*mod;
		sig = LPF.ar(
			SinOsc.ar(freq, mul: 0.7) +
			LPF.ar(WhiteNoise.ar(0.3), 1000*XLine.ar(1, 0.001, 0.1), modenv) +
			SinOsc.ar(freq/2, mul:0.2),
			1000
		).tanh;
		sig = Pan2.ar(sig*amp*env, pan);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\reverb, {
		arg in=~revBus, out=0, amount=0.6;
		var sig;
		sig = In.ar(in, 2);
		sig = FreeVerb.ar(sig, amount, 0.75, 0.3);
		// sig = Compander.ar(sig, sig, 0.2, 1, 0.1, 0.01, 0.01);
		sig = Limiter.ar(sig, 0.8);
		Out.ar(out, sig);
	}).add;

	// Sync server
	s.sync();

	Synth.new(\reverb, target: s.defaultGroup, addAction: \addAfter);


					/////////////////////////
					//    Parse + Output   //
					/////////////////////////
/*
Parsing Structure:
Encoding
    Text is sent to SuperCollider through a space-separated .txt file. Tokens can be either control changes or note events. Each token is created as follows:

            Example:
                Control:
                     0         0           00
                     ^         ^           ^
                    type  control type   value

                Note:
                     1         0           00          00          00          00
                     ^         ^           ^           ^           ^           ^
                    type    quality     velocity     reverb      pitch      repeats

    Each value is encoded as follows:
        type                0: Control
                            1: Note

        Control
            control type    0: Tempo
                            1: Key
            value           range(0,99)

        Note
            quality         0: Rest
                            1: Short Perc
                            2: Long Perc
                            3: Short Pitch
                            4: Long Pitch
            velocity        range(0,99)
            reverb          range(0,99)
            pitch           range(0,99)
*/


	~note = {
		|i|
		case
		{ i[1].asString == "0" }			{ ~rest.value(i)      }
		{ i[1].asString == "1" }			{ ~percShort.value(i) }
		{ i[1].asString == "2" }			{ ~percShort.value(i) }
		{ i[1].asString == "3" }			{ ~percShort.value(i) }
		{ i[1].asString == "4" }			{ ~pitchLong.value(i) }
		{ Error("Note: Unexpected 2nd character: % in %".format(i[1], i)).throw; }
	};

	~ctrl = {
		|i|
		case
		{ i[1].asString == "0" }			{ ~tempo.value(i) }
		{ i[1].asString == "1" }			{ ~key.value(i)   }
		{ Error("Control: Unexpected 2nd character: % in %".format(i[1], i)).throw; }
	};

	// Control funcs

	~key = {
		// ~scale = Scale.modename
		// change Pdefn
		Pdefn(\scale, ~scale);
	};


	~tempo = {
		// make another routine
		|i|
		var temp, val, minTempo, maxTempo;

		minTempo = 160/60;
		maxTempo = 300/60;
		temp = t.tempo;
		val = "".catList(i[(2..3)]).asInteger.linlin(0, 99, minTempo, maxTempo);

		// Should overwrite if two tempo changes in a row since this is named
		~tempoChange = Routine.new({
			Array.interpolation(12, temp, val).do({
				|i|
				t.tempo_(i).postln;
				3.yield;
		})}
		).play(t);
		Array.interpolation(12, temp, val).postln;
	};

	// Note funcs

	~rest = {
		nil;
	};

	~pitchLong = {
		|i|
		var deg, repeats, pan;
		i.postln;
		deg = [0, 4].choose;
		// .asInteger cannot handle chars.
		repeats = "".catList(i[(8..9)]).asInteger;
		repeats.postln;
		pan = rrand(-1.0, 1.0);
		Pbind(
			\instrument, \bell,
			\scale, Pdefn(\scale, ~scale),
			\degree, deg,
			\amp, Pgeom(0.8, 0.7),
			\rel, 10,
			\dur, Pseq([2], repeats),
			\pan, pan,
			\out, ~revBus,
		).play(t);
	};

	~percShort = {
		|i|
		var deg, repeats, pan;
		i.postln;
		deg = (1..100).collect({
			|i|
			i*50;
		});
		repeats = "".catList(i[(8..9)]).asInteger;
		repeats.postln;
		Pbind(
			\instrument, \tone2,
			\freq, Pseq(deg, inf),
			\amp, Pgeom(0.2, 0.9, repeats),
			\rel, 0.5,
			\dur, Pwrand([1, 1.5, 2, 2.5], [3, 1, 12, 1].normalizeSum, inf),
			\out, ~revBus,
		).play(t);
	};

	r = Routine({
		c.do({
			|i|
			case
			{ i[0].asString == "1" }		{ ~note.value(i) }
			{ i[0].asString == "0" }		{ ~ctrl.value(i) }
			{ Error("Unexpected 1st character: % in %".format(i[0], i)).throw; };
			1.yield;
		})
	}).play(t);
}, onFailure: \waitForBoot_FAILED.postln
);
)

					/////////////////////////
					//       Testing       //
					/////////////////////////
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
b
(
Pbind(
    \instrument, \tone,
    \midinote, Pseq([0, 0, 0], inf) + 40,
	\dur, Pseq([1/6], inf),
	\rel, 2,
	\pan, Pwhite(-1, 1),
).play;
)



(
x = "1234567890";
"".catList(x[(0..1)]).postln;
x.slice([0, 1]).postln;

i = [$1, $2, $3, $4];
y = "".catList(i[(2..3)]).postln;
y.asInteger.linlin(0, 99, 160, 200).postln;
)

