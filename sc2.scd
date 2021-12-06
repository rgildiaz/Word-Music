// SC2
// Slow, sliding

(
s.quit;
					/////////////////////////
					// Load the input file //
					/////////////////////////

~path = PathName(thisProcess.nowExecutingPath).parentPath;
~in = ~path ++ "alg_out/out1.txt";
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

// Buses
s.newBusAllocators;

// Variables
~amstr = "";
~fmstr = "";
~MAXAMP = 0.8;


s.waitForBoot({

	t = TempoClock.new(120/60).permanent_(true);

	// SynthDefs
	/*
	\basic

	@param out			output channel
	@param pan			pan position
	@param dur			note duration

	@param freq1		carrier starting freq
	@param freq2		carrier ending freq
	@param freqcurve	carrier freq curve
	@param amp			carrier overall amp
	@param ampatk		carrier atk
	@param amprel		carrier rel

	@param amdur		am duration
	@param amamount		am amount
	@param amfreq1		am starting freq
	@param amfreq2		am ending freq
	@param amfreqcurve	am freq curve
	@param amamp		am overall amp
	@param amampatk		am atk
	@param amamprel		am rel

	@param fmdur		fm duration
	@param fmamount		fm amount
	@param fmfreq1		fm starting freq
	@param fmfreq2		fm ending freq
	@param fmfreqcurve	fm freq curve
	@param fmamp		fm overall amp
	@param fmampatk		fm atk
	@param fmamprel		fm rel
	*/
	SynthDef.new( \basic, {
		arg out=0, pan=0,
		dur, freq1, freq2, freqcurve, amp, ampcurve, ampatk, amprel,
		amdur, amamount, amfreq1, amfreq2, amfreqcurve, amamp, amampcurve, amampatk, amamprel,
		fmdur, fmamount, fmfreq1, fmfreq2, fmfreqcurve, fmamp, fmampcurve, fmampatk, fmamprel;

		var sig, freqenv, ampenv, am, amenv, amampenv, fm, fmenv, fmampenv;

		// carrier envs
		ampenv = EnvGen.ar(
			Env.new(
				[0, 1, 0],
				[ampatk, amprel],
				ampcurve
			),
			doneAction:2
		);

		freqenv = EnvGen.ar(
			Env.new(
				[freq1, freq2],
				[dur],
				freqcurve
			)
		);

		// am envs
		amampenv = EnvGen.ar(
			Env.new(
				[0, 1, 0],
				[amampatk, amamprel],
				amampcurve
			)
		);

		amfreqenv = EnvGen.ar(
			Env.new(
				[amfreq1, amfreq2],
				[amdur],
				amfreqcurve
			)
		);

		// fm envs
		fmampenv = EnvGen.ar(
			Env.new(
				[0, 1, 0],
				[fmampatk, fmamprel],
				fmampcurve
			)
		);

		fmfreqenv = EnvGen.ar(
			Env.new(
				[fmfreq1, fmfreq2],
				[fmdur],
				fmfreqcurve
			)
		);

		// Synthesis
		fm = SinOsc.ar(fmenv, mul:fmampenv);
		am = SinOsc.ar(amenv, mul:amampenv);
		sig = SinOsc.ar(freqenv*fm, mul: am);

		sig = Pan2.ar(sig, pan);
		Out.ar(out, sig);

	}).add;



					/////////////////////////
					//    Parse + Output   //
					/////////////////////////
/*
*/


	~note = {
		|i|
		Synth(\basic, [
			dur,
			freq1,
			freq2,
			freqcurve,
			amp,
			ampcurve,
			ampatk,
			amprel,

			amdur,
			amamount,
			amfreq1,
			amfreq2,
			amfreqcurve,
			amamp,
			amampcurve,
			amampatk,
			amamprel,

			fmdur,
			fmamount,
			fmfreq1,
			fmfreq2,
			fmfreqcurve,
			fmamp,
			fmampcurve,
			fmampatk,
			fmamprel,
		]);
	};


	// Helper funcs

	// Return a dictionary containing the token's dur, amamount, fmamount, freq1, freq2, freqcurve, amp, ampcurve, ampatk, and amprel.
	~parseToken = {
		arg i;
		var out;
		out = Dictionary();

		out.put(\dur, 		~dur.value(i)		);
		out.put(\amamount, 	~amamount.value(i)	);
		out.put(\fmamount, 	~dur.value(i)		);
		out.put(\freq1, 	~freq.value(i)[0]	);
		out.put(\freq2, 	~freq.value(i)[1]	);
		out.put(\freqcurve, ~freqcurve.value(i)	);
		out.put(\amp,	 	~amp.value(i)		);
		out.put(\ampcurve, 	~ampcurve.value(i)	);
		out.put(\ampatk, 	~ampdurs.value(i)[0]);
		out.put(\amprel, 	~ampdurs.value(i)[1]);


		out;
	}

	// read velocity input and scale accordingly
	~amp = {
		|i|
		a = "".catList(i[(2..3)]).asInteger;
		a.linlin(0, 99, 0, ~MAXAMP)
	};

	r = Routine({
		c.do({
			|i|
			~note.value(i);
			1/4.yield;
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

(
SynthDef.new( \test, {
	var sig, freqenv;
	sig = SinOsc.ar(freqenv);
}
).add;
)

