// SC2
// Slow, sliding

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
c.postln;
"File loaded!".postln;


/////////////////////////
//        Setup        //
/////////////////////////

t = TempoClock.new(240/60).permanent_(true);

// Buses
s.newBusAllocators;

s.waitForBoot({

	// SynthDefs

					/////////////////////////
					//    Parse + Output   //
					/////////////////////////
/*
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

