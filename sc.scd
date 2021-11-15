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
})

SynthDef.new( \pitch, {
	arg out=0, amp=0.2, rev=0.5,
	atk=0.01, rel=1;
	var sig, env;
})
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


















