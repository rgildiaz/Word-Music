// SC
// Plucky

(
s.quit;

					/////////////////////////
					// Load the input file //
					/////////////////////////

~path 	=	PathName(thisProcess.nowExecutingPath).parentPath;
~in 	=	~path ++ "alg_out/out.txt";
~in.postln;

// Check if path to file is correct
if(
	File.exists(~in),
	// for some reason, FileReader returns a nested array. .flatten removes the outer layer.
	{ x = FileReader.read(~in).flatten; },
	{ Error( "File % could not be opened.".format(~in) ).throw; }
);

// Clean empty strings (if any were left in by accident)
c = x.collect({
	|i|
	if(
		i.size >= 2,
		{i}
	)
});
c.postln;
"File loaded!".postln;


		/////////////////////////
		//        Setup        //
		/////////////////////////

t 		= 	TempoClock.new(240/60).permanent_(true);

// root pitch. (pitch sets are created using fib, so don't set this too high).
~root	=	25;

// parse dict
d 		=	Dictionary.newFrom([
	\type,	0,
	\qual,	1,
	\vel, 	(2..3),
	\pitch,	(4..5),
	\rep,	(6..7)
]);

// qual dict
~qdict	=	Dictionary.newFrom([
	\rest,	0,
	\sperc,	1,
	\lperc,	2,
	\sptch, 3,
	\lptch, 4
]);

// control dict
~cdict	=	Dictionary.newFrom([
	\tempo,	0,
	\key,	1
]);


// env arrays represent atk and rel times.
~env1	=	[0.01, 1.99];
~env2	=	[1, 1];
~env 	=	~env1;

// set arrays represent pitches.
~set1 	= 	Array.fib(8, 1, 1).collect({|i| (i+~root);});
~set2 	= 	Array.fib(8, 2, 1).collect({|i| (i+~root);});
~set	= 	~set1;

// scount counts the beats. Used by ~change.() and ~count.().
~scount =	0;


// Busses
s.newBusAllocators;
~revBus = 	Bus.new('audio', numChannels:2);
~limBus = 	Bus.new('audio', numChannels:2);



/////////////////////////////////////////////////////////////////////



s.waitForBoot({

	// Groups
	~srcGrp = Group.new();
	~fxGrp	= Group.new(~srcGrp, \addAfter);

	// SynthDefs
	SynthDef.new( \tone2, {
		arg freq=200, amp=0.5, out=0, rel=0.25, pan=0;
		var sig, mod, env, modenv;

		env 	= EnvGen.ar(Env.perc(~env[0], ~env[1]), doneAction: 2);
		modenv 	= EnvGen.ar(Env.perc(~env[0], ~env[1]));

		sig		= SinOsc.ar(freq, mul:0.7);
		sig		= sig + LPF.ar(WhiteNoise.ar(0.3), 1000*XLine.ar(1, 0.001, 0.1), modenv);
		sig		= sig + SinOsc.ar(freq/2, mul:0.2);
		sig		= LPF.ar(sig, 1000);

		sig 	= Pan2.ar(sig*amp*env, pan);

		Out.ar(0, sig);
	}).add;

	SynthDef.new(\tone, {
		arg freq=200, rel=0.1, amp=0.8, pan=0, out=0;
		var sig, mod, env, modenv;
		env = EnvGen.ar(Env.perc(~env[0], ~env[1]), doneAction: 2);
		modenv = EnvGen.ar(Env.perc(~env[0], ~env[1]));
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
		arg freq=200, atk=2, rel=2, pan=0, out=0, gate=1, amp=0.2;
		var sig, env;
		env = EnvGen.ar(
			Env.new(
				[0, 1, 0],
				[atk*~env[0], rel*~env[1]],
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

	// Sync server
	s.sync();


					/////////////////////////
					//    Parse + Output   //
					/////////////////////////

	~note = {
		|i|
		j = i[1].asString;
		case
		{ j == ~qdict[\rest] .asString }			{ ~rest.value(i)      }
		{ j == ~qdict[\sperc].asString }			{ ~percShort.value(i) }
		{ j == ~qdict[\lperc].asString }			{ ~percShort.value(i) }
		{ j == ~qdict[\sptch].asString }			{ ~percShort.value(i) }
		{ j == ~qdict[\lptch].asString }			{ ~percShort.value(i) }
		{ Error("Note: Unexpected 2nd character: % in %".format(j, i)).throw; }
	};

	~ctrl = {
		|i|
		case
		{ j == "0" }			{ ~tempo.value(i) }
		{ j == "1" }			{ ~key.value(i)   }
		{ Error("Control: Unexpected 2nd character: % in %".format(j, i)).throw; }
	};

	///////////////////////////////

	// Helper funcs

	// Every 8 counts, change tone set and env.
	~count = {
		~scount = ~scount + 1;
		if (
			~scount > 8,
			{
				~change.value();
				~scount = 0;
			},
		);
	};

	// change.() is called by ~count.() every 8 beats.
	~change = {
		if (
			  ~set == ~set1,
			{ ~set = ~set2 },
			{ ~set = ~set1 }
		);

		if (
			  ~env == ~env1,
			{ ~env = ~env2 },
			{ ~env = ~env1 }
		);
	};

	~repeat = {
		|i|
		"".catList(i[d[\rep]]).asInteger;
	};

	~amp = {
		|i|
		a = "".catList(i[d[\vel]]).asInteger;
		a.linlin(0, 99, 0, 0.8)
	};

	~pitch = {
		|i|
		"".catList(i[d[\pitch]]).asInteger;
	};

	// read dur instead of repeats for long words
	~dur = {
		|i|
		r = "".catList(i[d[\rep]]).asInteger;
		r = r+5;
		x = rrand(0, 1);
		[r*x, r*(1-x)];
	};


	////////////////////////////////////////

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

		minTempo = 200/60;
		maxTempo = 340/60;
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

	/////////////////////////////////////////

	// Note funcs
	~rest = {
		nil;
	};

	~percShort = {
		|i|
		var deg, repeats, pan, chose;
		chose = ~set.choose.midicps;
		repeats = ~repeat.value(i);
		Pbind(
			\instrument, 	\tone2,
			\group, 		~srcGrp,
			\freq, 			Pseq([chose], inf),
			\amp, 			Pgeom(0.1, 0.9, repeats),
			\rel, 			0.5,
			\out, 			0,
		).play(t);
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
			\instrument, 	\toneLong,
			\freq, 			deg,
			\group, 		~srcGrp,
			\amp, 			amp,
			\atk, 			atk,
			\rel, 			rel,
			\pan, 			pan,
			\out, 			0,
		).play(t);
	};



/////////////////////////////////////////////////////////////////////////


	r = Routine({
		c.do({
			|i|
			case
			{ i[0].asString == "1" }		{ ~note.value(i) }
			{ i[0].asString == "0" }		{ ~ctrl.value(i) }
			{ Error("Unexpected 1st character: % in %".format(i[0], i)).throw; };
			~count.value();
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

play{Limiter.ar(Saw.ar(50, mul: SinOsc.ar(0.2).range(0,1)), 0.001)}

play{Saw.ar(50, mul: SinOsc.ar(0.1).range(0,1))}

