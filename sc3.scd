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
// c = ["0099", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307", "1224241307"];
c.postln;
"File loaded!".postln;


/////////////////////////
//        Setup        //
/////////////////////////

t = TempoClock.new(120/60).permanent_(true);

// Buses
s.newBusAllocators;
~revBus = Bus.new('audio', numChannels:2);
~limitBus = Bus.new('audio', numChannels:2);


s.waitForBoot({

	// SynthDefs
	SynthDef.new( \choruSin, {
		arg out=0,
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

	};

	~percShort = {

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
SynthDef.new( \choruSin, {
	arg out=0, freq=50, amp=0.8;
	var sig, env;

	env = EnvGen.ar();

	sig = VarSaw.ar({freq * LFNoise1.kr(Rand(0.5, 3)).range(0.95, 1.05)}!20, iphase: rrand(0,2pi), mul: LFNoise1.kr(2).range(1/10, 1/5));
	sig = RLPF.ar(sig, LFNoise1.kr(Rand(0, 0.5)).exprange(200, 3000).poll, LFNoise1.ar(LFNoise1.kr(2).range(0.1, 0.3)).range(0.5, 0.9)).tanh;

	sig = Splay.ar(sig);
	sig = sig * amp;
	Out.ar(out, sig);

}).add;
)

Synth(\choruSin);


play{RLPF.ar(VarSaw.ar({50 * LFNoise1.kr(Rand(0.5, 3)).range(0.98, 1.02)}!5, mul: 1/5), LFNoise1.kr(Rand(0, 0.5)).exprange(200, 3000).poll, LFNoise1.ar(3).range(0.1, 0.9))}




