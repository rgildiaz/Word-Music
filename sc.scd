// Word Sound Music

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
x.postln;


)
