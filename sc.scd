// SC
// Plucky

(
s.quit;


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
"File loaded!".postln;


/////////////////////////
//        Setup        //
/////////////////////////

t = TempoClock.new(240/60).permanent_(true);
~scale = Scale.dorian;
~set = [60, 59, 48, 50, 72, 80, 55]				// a MIDI notenum set, changed using ~key.value()

// Buses
s.newBusAllocators;
~revBus = Bus.new('audio', numChannels:2);
~limitBus = Bus.new('audio', numChannels:2);


s.waitForBoot({

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

	SynthDef.new( \toneLong, {
		arg freq=200, atk=2, rel=2, pan=0, out=0, gate=1;
		var sig, env;
		env = EnvGen.ar(
			Env.new(
				[0, 1, 0],
				[atk, rel],
				-4
			),
			doneAction: 2
		);
		sig = SinOsc.ar([freq, freq * rrand(0.97, 1.03)]);
		sig = sig * env * amp;
		sig = Pan2.ar(
			Mix.ar(sig),
			pan
		);
		Out.ar(out, sig);
	}).add;

	SynthDef.new( \reverb, {
		arg in=~revBus, out=0, amount=0.6;
		var sig;
		sig = In.ar(in, 2);
		sig = FreeVerb.ar(sig, amount, 0.75, 0.3);
		Out.ar(out, sig);
	}).add;

	SynthDef.new( \limit, {
		arg in=~limitBus, out=0;
		var sig;
		sig = In.ar(in, 2);
		sig = Limiter.ar(sig, 0.8, 0.05);
		Out.ar(out, sig);
	}).add;

	// Sync server
	s.sync();

	Synth.new(\reverb, target: s.defaultGroup, addAction: \addAfter);
	Synth.new(\limit, target: s.defaultGroup, addAction: \addAfter);


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
                     1         0           00         00          00
                     ^         ^           ^          ^           ^
                    type    quality     velocity    pitch      repeats

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
		j = i[1].asString;
		case
		{ j == "0" }			{ ~rest.value(i)      }
		{ j == "1" }			{ ~percShort.value(i) }
		{ j == "2" }			{ ~percShort.value(i) }
		{ j == "3" }			{ ~percShort.value(i) }
		{ j == "4" }			{ ~pitchLong.value(i) }
		{ Error("Note: Unexpected 2nd character: % in %".format(j, i)).throw; }
	};

	~ctrl = {
		|i|
		case
		{ j == "0" }			{ ~tempo.value(i) }
		{ j == "1" }			{ ~key.value(i)   }
		{ Error("Control: Unexpected 2nd character: % in %".format(j, i)).throw; }
	};


	// Helper funcs
	~repeat = {
		|i|
		"".catList(i[(6..7)]).asInteger;
	};

	// read velocity input and scale accordingly
	~amp = {
		|i|
		a = "".catList(i[(2..3)]).asInteger;
		a.linlin(0, 99, 0, 0.8)
	};

	// read dur instead of repeats for long words
	~dur = {
		|i|
		r = "".catList(i[(6..7)]).asInteger;
		r = r+5;
		x = rrand(0, 1);
		[r*x, r*(1-x)];
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
		var deg, pan, amp, dur, atk, rel;
		i.postln;

		deg = ~set.choose.midicps;
		pan = rrand(-1.0, 1.0);
		amp = ~amp.value(i);
		dur = ~dur.value(i);
		atk = dur[0];
		rel = dur[1];

		Pbind(
			\instrument, \toneLong,
			\freq, deg,
			\amp, amp,
			\atk, atk,
			\rel, rel,
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
		repeats = ~repeat.value(i);
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

(
x = "1234567890";
"".catList(x[(0..1)]).postln;
x.slice([0, 1]).postln;

i = [$1, $2, $3, $4];
y = "".catList(i[(2..3)]).postln;
y.asInteger.linlin(0, 99, 160, 200).postln;
)

