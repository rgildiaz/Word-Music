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

t 		= 	TempoClock.new(240/60).permanent_(false);

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
	\sperc,	3,
	\lperc,	1,
	\sptch, 2,
	\lptch, 4
]);

// control dict
~cdict	=	Dictionary.newFrom([
	\tempo,	0,
	\key,	1
]);

// env arrays represent atk and rel times.
~env1	=	[0.01, 0.5];
~env2	=	[1, 1];
~env 	=	~env1;

// set arrays represent pitches.
~set1 	= 	Array.exprand(100, 50, 10000).sort;
~set2 	= 	Array.exprand(100, 50, 10000).sort;
~set	= 	~set1;

~set1.do({|i| i.postln;});
~set2.do({|i| i.postln;});

// scount counts the beats. Used by ~change.() and ~count.().
~scount =	0;
~maxcnt =	16;


/////////////////////////////////////////////////////////////////////



s.waitForBoot({

	// SynthDefs

	SynthDef.new( \percShort, {
		arg freq=400, amp=0.5, out=0, rel=0.1, pan=0;
		var sig, mod, env, modenv;

		env		= EnvGen.ar(Env.perc(0.01, rel), doneAction:2);
		modenv	= EnvGen.ar(Env.perc(0.01, rel*0.8));

		mod		= SinOsc.ar(freq/1.9290329834, mul:0.8).unipolar;

		sig		= PinkNoise.ar(0.8) + SinOsc.ar(freq*mod, mul:0.2);
		sig		= BPF.ar(sig, freq, rrand(1/6, 1/2));
		sig		= sig * env * amp;

		sig		= Pan2.ar(sig, pan);

		Out.ar(out, sig);
	}).add;

	SynthDef.new( \percLong, {
		arg freq=400, amp=0.8, out=0, rel=0.8, pan=0;
		var sig, mod, env, modenv, revenv;

		env		= EnvGen.ar(Env.perc(0.01, rel));
		modenv	= EnvGen.ar(Env.perc(0.01, rel*0.8));
		revenv	= EnvGen.ar(Env.perc(0.001, 10), doneAction:2);

		mod		= SinOsc.ar(freq/1.9290329834, mul:0.8).unipolar;

		sig		= PinkNoise.ar(0.9) + SinOsc.ar(freq*mod, mul:0.1);
		sig		= BPF.ar(sig, freq, rrand(1/3, 1/2));
		sig		= sig * env * amp;

		sig		= FreeVerb.ar(sig, mul:revenv);

		sig		= Pan2.ar(sig, pan);

		Out.ar(out, sig);
	}).add;

	SynthDef.new( \pitchShort, {
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

	SynthDef.new( \pitchLong, {
		arg freq=200, atk=2, rel=2, pan=0, out=0, amp=0.2;
		var sig, env;

		env = EnvGen.ar(
			Env.new(
				[0, 1, 0],
				[atk*~env[0]+10, rel*~env[1]+10],
				-4
			),
			doneAction: 2
		);

		sig = Saw.ar(freq * rrand(0.97, 1.03), 1/20)!20;
		sig = LPF.ar(sig, LFNoise1.kr(LFNoise1.kr(2).range(0.1, 1)).range(0.5, 5));
		sig = sig * env * amp;

		Splay.ar(sig, LFNoise1.kr(0.2).range(0.1, 0.3), center: pan.linlin(-1, 1, -0.8, 0.8));

		Out.ar(out, sig);
	}).add;

	// Sync server
	s.sync();


					/////////////////////////
					//    Parse + Output   //
					/////////////////////////

	~note = {
		|i|
		var vel, pitch, rep, dur;
		j = i[1].asString;

		vel 	= ~amp.(i);
		pitch 	= ~pitch.(i);
		rep		= ~repeat.(i);
		dur		= ~dur.(i);

		case
		{ j == ~qdict[\rest] .asString }			{ ~rest      .value()				 }
		{ j == ~qdict[\sperc].asString }			{ ~percShort .value(vel, pitch, rep) }
		{ j == ~qdict[\lperc].asString }			{ ~percLong  .value(vel, pitch, dur) }
		{ j == ~qdict[\sptch].asString }			{ ~pitchShort.value(vel, pitch, rep) }
		{ j == ~qdict[\lptch].asString }			{ ~pitchLong .value(vel, pitch, dur) }
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
			~scount >= ~maxcnt,
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

		Pdefn(\set, ~set);
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
		~set1 	= 	Array.exprand(100, 50, 10000).sort;
		~set2 	= 	Array.exprand(100, 50, 10000).sort;
		~set	= 	~set1;
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
		Array.interpolation(32, temp, val).postln;
	};

	/////////////////////////////////////////

	// Note funcs
	~rest = {
		nil;
	};

	~percShort = {
		|vel, pitch, rep|
		var pan;

		pitch 	= ~set[pitch];
		pan 	= rrand(-1.0, 1.0);
		vel		= vel.linlin(0, 0.8, 0, 0.3);

		rep.postln;

		Pbind(
			\instrument,	\percShort,
			\dur,           Pwrand([0.5, 1, 1.5, 2, 2.5], [1, 50, 2, 10, 1].normalizeSum, rep),
			\freq, 			Pseq([pitch], inf),
			\amp,           Pgeom(vel, 0.6, inf),
			\pan,           Pwhite(-1.0, 1.0, inf),
			\out, 			0,
		).play(t);

	};

	~percLong = {
		|vel, pitch, dur|
		var pan;

		pitch 	= ~set[pitch]/2;
		pan 	= rrand(-1.0, 1.0);
		vel		= vel.linlin(0, 0.8, 0, 0.3);
		dur		= dur[0].linlin(0, 104, 5, 15);

		Pbind(
			\instrument,	\percLong,
			\dur,           Pseq([1], 1),
			\freq, 			Pseq([pitch], inf),
			\rel,			dur,
			\amp,           Pgeom(vel, 0.6),
			\pan,           Pwhite(-1.0, 1.0),
			\out, 			0,
		).play(t);
	};

	~pitchShort = {
		|vel, pitch, rep|
		var pan, panmod;
		pitch = ~set[pitch];

		pan		= rrand(-1.0, 1.0);
		panmod 	= rrand(0.8, 1.2) * [-1, 1].choose;

		vel		= vel.linlin(0, 0.8, 0, 0.2);

		Pbind(
			\instrument, 	\pitchShort,
			\dur,           Pwrand([0.5, 1, 1.5, 2, 2.5], [1, 50, 2, 10, 1].normalizeSum, rep),
			\freq, 			Pseq([pitch], inf),
			\amp,           Pgeom(vel, 0.6, inf),
			\pan,           Pwhite(-1.0, 1.0, inf),
			\out, 			0,
		).play(t);
	};

	~pitchLong = {
		|vel, pitch, dur|
		var pan;

		pitch = ~set[pitch];

		Pbind(
			\instrument,	\pitchLong,
			\dur,			dur[0] + dur[1],
			\freq,			Pseq([pitch], 1),
			\amp,			vel,
			\atk,			dur[0],
			\rel,			dur[1],
			\pan,			Pwhite(-1, 1),
		).play(t)
	};

	s.sync();


/////////////////////////////////////////////////////////////////////////


	r = Routine({
		c.do({
			|i|

			i.postln;

			case
			{ i[0].asString == "1" }		{ ~note.value(i) }
			{ i[0].asString == "0" }		{ ~ctrl.value(i) }
			{ Error("Unexpected 1st character: % in %".format(i[0], i)).throw; };
			~count.value();
			1.yield;
		});
		"Routine Finished".postln;
	}).play(t);

}, onFailure: \waitForBoot_FAILED.postln
);
)
