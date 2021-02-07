/*
CPSC 531 01 (FA20): Algorithmic Computer Music
Assignment 5: Musical Mealy Machines
Co-authors: Jiaqi Yang, Sihan Sun
*/

(
s.waitForBoot {
	// User input: define the initial key (\C or \G), by default \C
	~startingKey = \C;

	// User input: define the input array. \stay means stay in the same key (modulation), \change means chaneg to another key (progression)
	~input=[\stay,\stay,\stay,\stay,\change,\stay,\stay,\stay,\stay,\stay,\stay,\stay,\stay,\change];

	/*
	Based on this table, C starts from 60 (MIDI):
	C: I    ii    iii    IV    V    vi    vii*

	   C    D     E      F     G    A     B
	   E    F     G      A     B    C     D
	   G    A     B      C     D    E     F

	G: I    ii    iii    IV    V    vi    vii*

	   G    A     B      C     D    E     F#
	   B    C     D      E     F#   G     A
	   D    E     F#     G     A    B     C
	*/
	~keychordMapping = {
		|key, chord|
		var output;
		case
		// C Major chord from I to vii
		{key == \C && (chord == 0)} { output = [60, 64, 67] }
		{key == \C && (chord == 1)} { output = [62, 65, 69] }
		{key == \C && (chord == 2)} { output = [64, 67, 71] }
		{key == \C && (chord == 3)} { output = [65, 69, 72] }
		{key == \C && (chord == 4)} { output = [67, 71, 74] }
		{key == \C && (chord == 5)} { output = [69, 72, 76] }
		{key == \C && (chord == 6)} { output = [71, 74, 77] }

		// G Major chord from I to vii
		{key == \G && (chord == 0)} { output = [67, 71, 74] }
		{key == \G && (chord == 1)} { output = [69, 72, 76] }
		{key == \G && (chord == 2)} { output = [71, 74, 78] }
		{key == \G && (chord == 3)} { output = [60, 64, 67] }
		{key == \G && (chord == 4)} { output = [62, 66, 69] }
		{key == \G && (chord == 5)} { output = [64, 67, 71] }
		{key == \G && (chord == 6)} { output = [66, 69, 72] }

		// Default : if input not recognized (Error Handling)
		{ "PLEASE CHECK THE INPUT KEY!".warn;};
		output;
	};

	// Fefine the chord progression rules
	~rules = [ // to help generate 'valid' chord progressions
		[2, 3, 4, 5, 6, 7],     // tonic         // I
		[1, 5, 7],              // supertonic    // ii
		[1, 4, 6],              // mediant       // iii
		[1, 2, 5, 7],           // subdominant   // IV
		[1, 4],                 // dominant      // V
		[1, 2, 3, 4, 5],        // submediant    // vi
		[1]                     // leading tone  // vii
	];

	/*
	Define the mealy machine
	in: represents the input, which could be \stay and \change
	state: represents the current states in the form of array. first element is the current key, which could be \C and \G.
	       Second element is the current chord, which could be \tonic, ..., \leading tone, represneted by 0, ..., 6 based on ~rules array indexation.
	output: represnets the output of the function.
	*/
	~mm = (in: \stay, state: [~startingKey, 0], output: [\C, 0],
		func: {
			case
			// If the current input is \stay, modulate based on the current state.
			{(~mm.in == \stay)} {
				~mm.state[1] = ~rules[~mm.state[1]][rrand(0, ~rules[~mm.state[1]].size-1)]-1;
				~mm.output = [~mm.state[0], ~mm.state[1]];
			}
			// If the current input is \change and current key is \C, progress to corresponding G major chord.
			{(~mm.in == \change && ~mm.state[0] == \C)} {
				~mm.state[1] = ~rules[~mm.state[1]][rrand(0, ~rules[~mm.state[1]].size-1)]-1;
				// swtich to G major
				~mm.state[1] = (~mm.state[1] + 3) % 7;
				~mm.state[0] = \G;
				~mm.output = [\G, ~mm.state[1]];
			}
			// If the current input is \change and current key is \G, progress to corresponding C major chord.
			{(~mm.in == \change && ~mm.state[0] == \G)} {
				~mm.state[1] = ~rules[~mm.state[1]][rrand(0, ~rules[~mm.state[1]].size-1)]-1;
				// swtich to G major
				~mm.state[1] = (~mm.state[1] + 4) % 7;
				~mm.state[0] = \C;
				~mm.output = [\C, ~mm.state[1]];
			}

			// Default : if input not recognized (Error Handling)
			{ "PLEASE CHECK THE INPUT ARRAY!".warn;};}
	);

	// Use the mealy machine to generate raw output. sample result: [[\C, 0 (I)], [\C, 2 (iii)], ...]
	~result = List[];
	~result.add([\C, 0]);
	~input.size.do({
		|i|
		~mm.in=~input[i];
		~mm.func;
		~result.add(~mm.output)
	});

	~res = List[];
	~result.size.do({
		|i|
		~res.add(~keychordMapping.value(~result[i][0], ~result[i][1]));
	});

	// Split the raw output to 3 sound tracks (Also build "left and right hand layer" for creativity)
	~t1 = List[];
	~t2 = List[];
	~t3 = List[];

	~res.size.do({
		|i|
		~t1.add(~res[i][0] - 12); // left hand note
		~t1.add(~res[i][0]); // right hand note
		~t1.add(~res[i][0] - 12); // left hand note
		~t1.add(~res[i][0]); // right hand note

		// all right hand notes
		~t2.add(~res[i][1]);
		~t2.add(Rest(1));
		~t2.add(~res[i][1]);
		~t2.add(Rest(1));

		// all right hand notes
		~t3.add(~res[i][2]);
		~t3.add(Rest(1));
		~t3.add(~res[i][2]);
		~t3.add(Rest(1));
	});

	// Synthdef from https://github.com/viswans83/supercollider-stuff/blob/master/piano.scd. Piano-like sound.
	SynthDef(\piano,
		ugenGraphFunc:{ |freq = 261.63, vol = 1, gate = 1|
			var ampls = [3.7, 5.4, 1.2, 1.1, 0.95, 0.6, 0.5, 0.65, 0, 0.1, 0.2];
			var freqs = Array.fill(ampls.size, { |i| freq * (i + 1) });
			var waves = Array.fill(ampls.size, { |i| SinOsc.ar(freqs.at(i),mul: ampls.at(i))});
			var mixedwaves = Mix.ar(waves).range(vol * -1,vol);
			var env = Env.perc(0.09,4,curve: -10);
			var final = mixedwaves * EnvGen.ar(env, gate, doneAction: 2);
			Out.ar(0, [final,final]);
	}).add;

	s.sync;

	~p1 = Pbind(\instrument, \piano, \dur, 1, \midinote, Pseq(~t1), \amp, 1);
	~p2 = Pbind(\instrument, \piano, \dur, 1, \midinote, Pseq(~t2), \amp, 1);
	~p3 = Pbind(\instrument, \piano, \dur, 1, \midinote, Pseq(~t3), \amp, 1);

	Ppar([~p1, ~p2, ~p3], inf).play;
}
)