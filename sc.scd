// SC
// Plucky

(
s.quit;
					/////////////////////////
					// Load the input file //
					/////////////////////////

~path 	=	PathName(thisProcess.nowExecutingPath).parentPath;
~in 		=	~path ++ "alg_out/out.txt";
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

// root pitch. (defunct)
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
~env2	=	[0.2, 0.02];
~env 	=	~env1;
Pdefn(\env, ~env);

// set arrays represent pitches.
~set1	=	Array.fill(100, {([40, 42, 39, 45, 47] +.x [0, 12, 24]).choose;}).midicps;
~set2	=	Array.fill(100, {([42, 45, 40, 49, 50] +.x [0, 12, 24]).choose;}).midicps;

// ~set1 	= 	Array.exprand(100, 50, 10000).sort;
// ~set2 	= 	Array.exprand(100, 50, 10000).sort;

~set	= 	~set1;
Pdefn(\set, ~set);

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

		mod		= SinOsc.ar(freq*rrand(1.7,2.2), mul:0.8).unipolar;

		sig		= PinkNoise.ar(0.9) + SinOsc.ar(freq*mod, mul:0.1);
		sig		= BPF.ar(sig, freq*rrand(0.2, 8), rrand(1/5, 1/2));
		sig		= sig * env * amp;

		sig		= FreeVerb.ar(sig, 0.5, 0.99, mul:revenv);

		sig		= Pan2.ar(sig, pan);

		Out.ar(out, sig);
	}).add;

	SynthDef.new( \pitchShort, {
		arg freq=200, amp=0.5, out=0, atk=0.001, rel=0.25, pan=0;
		var sig, mod, env, modenv;

		env 	= EnvGen.ar(Env.perc(atk, rel), doneAction: 2);
		modenv 	= EnvGen.ar(Env.perc(atk, rel));

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

		freq = freq / 2;

		env = EnvGen.ar(
			Env.new(
				[0, 1, 0],
				[atk+10, rel+10],
				-4
			),
			doneAction: 2
		);

		sig = Saw.ar({freq * rrand(0.99, 1.01)}!20, 1/20);
		sig = LPF.ar(sig, LFNoise1.kr(LFNoise1.kr(2).range(0.1, 1)).range(freq*0.9, freq*6));
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
		var val;
		j = i[1].asString;

		val		= ~ctrlval.(i);

		case
		{ j == "0" }			{ ~tempo.value(val) }
		{ j == "1" }			{ ~key.value(val)   }
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
		Pdefn(\set, ~set);

		if (
			  ~env == ~env1,
			{ ~env = ~env2 },
			{ ~env = ~env1 }
		);
		Pdefn(\env, ~env);

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

	// range(0,99)
	~ctrlval = {
		|i|
		"".catList(i[(2..3)]).asInteger;
	};


	////////////////////////////////////////

	// Control funcs
	~key = {
		|i|
		"keycalled".postln;

		~set1	=	Array.fill(100, {(Array.rand(5, 40, 50).floor +.x [0, 12, 24]).choose;}).midicps;
		~set2	=	Array.fill(100, {(Array.rand(5, 40, 50).floor +.x [0, 12, 24]).choose;}).midicps;

		~set	= 	~set1;
		Pdefn(\set, ~set);

		~env1	=	[rrand(0,1), rrand(0,1)].normalizeSum;
		~env2	=	[rrand(0,1), rrand(0,1)].normalizeSum;
		~env	= 	~env1;
		Pdefn(\env, ~env);
	};


	~tempo = {
		// make another routine
		|i|
		var temp, val, minTempo, maxTempo;

		"tempocalled".postln;

		minTempo = 200/60;
		maxTempo = 340/60;
		temp = t.tempo;

		val = i.linlin(0, 99, minTempo, maxTempo);

		// Should overwrite if two tempo changes in a row since this is named
		~tempoChange = Routine.new({
			Array.interpolation(64, temp, val).do({
				|i|
				t.tempo_(i);
				3.yield;
		})}
		).play(t);
	};

	/////////////////////////////////////////

	// Note funcs
	~rest = {
		nil;
	};

	~percShort = {
		|vel, pitch, rep|
		var pan;

		pitch 	= Pdefn(\set).asStream.value()[pitch];
		pan 	= rrand(-1.0, 1.0);
		vel		= vel.linlin(0, 0.8, 0, 1);

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

		pitch 	= Pdefn(\set).asStream.value()[pitch];
		pan 	= rrand(-1.0, 1.0);
		vel		= vel.linlin(0, 0.8, 0, 1);
		dur		= dur[0].linlin(0, 104, 5, 15);

		Pbind(
			\instrument,	\percLong,
			\dur,           Pseq([1], 1),
			\freq, 			Pseq([pitch], inf),
			\atk,           Pdefn(\env).asStream.value()[0],
			\rel,           Pdefn(\env).asStream.value()[1],
			\amp,           Pgeom(vel, 0.6),
			\pan,           Pwhite(-1.0, 1.0),
			\out, 			0,
		).play(t);
	};

	~pitchShort = {
		|vel, pitch, rep|
		var pan, panmod;
		pitch = Pdefn(\set).asStream.value()[pitch];

		pan		= rrand(-1.0, 1.0);
		panmod 	= rrand(0.8, 1.2) * [-1, 1].choose;

		vel		= vel.linlin(0, 0.8, 0, 0.25);

		Pbind(
			\instrument, 	\pitchShort,
			\dur,           Pwrand([0.5, 1, 1.5, 2, 2.5], [1, 50, 2, 10, 1].normalizeSum, rep),
			\freq, 			Pseq([pitch], inf),
			\atk,           Pdefn(\env).asStream.value()[0],
			\rel,           Pdefn(\env).asStream.value()[1],
			\amp,           Pgeom(vel, 0.6, inf),
			\pan,           Pwhite(-1.0, 1.0, inf),
			\out, 			0,
		).play(t);
	};

	~pitchLong = {
		|vel, pitch, dur|
		var pan;

		pitch = Pdefn(\set).asStream.value()[pitch];

		Pbind(
			\instrument,	\pitchLong,
			\dur,			dur[0] + dur[1],
			\freq,			Pseq([pitch], 1),
			\amp,			vel,
			\atk,			dur[0],
			\rel,			dur[1],
			\pan,			Pwhite(-1.0, 1.0),
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
