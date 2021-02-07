/*
CPSC 531 01 (FA20): Algorithmic Computer Music
Assignment 6: Model MC for Musical System
Co-authors: Jiaqi Yang, Sihan Sun
*/

/*
README:
There are three biomes defined in the system: C major, D major, and G major, corresponding to the forest, dessert, and ocean.
he user will be able to navigate freely in the biom with 'q','a','s','d', corresponding to up, left, down, and right.
The user can also quicky 'jump' to another biome by pressing 1, 2, or 3 on the keyboard.
Whenever the user moves, we will write down the location of current user (\C, \D, or \G).
The user can stop the game by pressing the space, we will have a record of user locations [\G,\G,\G,\C,\C,\D], and triggers the
evaluate function (which is used to do the biome switching & chord progression) and the play function (to play the music).

I have included the major function names or keywords below so you can take a look by doing a global search.

keychordMapping (used for translating the chord to MIDI)
evaluate (Function to map different biomes into different chords)
play (Function to play the chords when the user press space)
char.asString == " " (This is the place where the pressing the space key is detected and all the functions are triggered)
*/

(
s.waitForBoot {
	var win, view, map, info, biome, tele1, tele2, tele3, pos, res, temp_map, keychordMapping, rules, mm, evaluate, startBiome;
	var t1, t2, t3, play, p1, p2, p3, start_condition;

	// The condition to make sure the Pattern classes are called AFTER the game is over
	start_condition = Condition.new(false);

	// There are three biomes defined: C major, D major, and G major, corresponding to the forest, dessert, and ocean.
	// The user will be able to navigate freely in the biom with 'q','a','s','d', corresponding to up, left, down, and right.
	biome = [
		[\C, \C, \C, \G, \G, \G],
		[\C, \C, \C, \G, \G, \G],
		[\C, \C, \C, \G, \G, \G],
		[\C, \C, \C, \G, \G, \G],
		[\D, \D, \D, \D, \D, \D],
		[\D, \D, \D, \D, \D, \D]];

	// The entry point of each biome. The user will be able to quicky 'jump' to another biome by clicking 1, 2, or 3 on the keyboard.
	tele1 = [0,0];
	tele2 = [0,3];
	tele3 = [4,0];
	pos = [0,0];
	res = [];

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

	D: I    ii    iii    IV    V    vi    vii*

	D    E     F#     G     A    B     C#
	F#   G     A      B     C#   D     E
	A    B     C#     D     E    F#    G
	*/
	keychordMapping = {
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

		// D Major chord from I to vii
		{key == \D && (chord == 0)} { output = [62, 66, 69] }
		{key == \D && (chord == 1)} { output = [64, 67, 71] }
		{key == \D && (chord == 2)} { output = [66, 69, 73] }
		{key == \D && (chord == 3)} { output = [67, 71, 74] }
		{key == \D && (chord == 4)} { output = [69, 73, 76] }
		{key == \D && (chord == 5)} { output = [71, 74, 78] }
		{key == \D && (chord == 6)} { output = [73, 76, 79] }

		// Default : if input not recognized (Error Handling)
		{ "PLEASE CHECK THE INPUT KEY!".warn;};
		output;
	};

	// Fefine the chord progression rules
	rules = [ // to help generate 'valid' chord progressions
		[2, 3, 4, 5, 6, 7],     // tonic         // I
		[1, 5, 7],              // supertonic    // ii
		[1, 4, 6],              // mediant       // iii
		[1, 2, 5, 7],           // subdominant   // IV
		[1, 4],                 // dominant      // V
		[1, 2, 3, 4, 5],        // submediant    // vi
		[1]                     // leading tone  // vii
	];

	/* mealy machine to do chord progression based on current biome
	* Input: one of three possilbe biome: \C, \D, and \G.
	* Output: the next chord in the same biome or the chord after switching biome.
	*/
	startBiome = \C;
	mm = (in: \C, state: [startBiome, 0], output: [\C, 0],
		func: {
			case
			// If the currentBiome is same as previous biome, just do chord progression
			{(mm.in == mm.state[0])} {
				mm.state[1] = rules[mm.state[1]][rrand(0, rules[mm.state[1]].size-1)]-1;
				mm.output = [mm.state[0], mm.state[1]];
			}

			// If the current input is \G and current key is \C, progress to corresponding G major chord.
			{(mm.in == \G && mm.state[0] == \C)} {
				mm.state[1] = rules[mm.state[1]][rrand(0, rules[mm.state[1]].size-1)]-1;
				// swtich to G major
				mm.state[1] = (mm.state[1] + 3) % 7;
				mm.state[0] = \G;
				mm.output = [mm.state[0], mm.state[1]];
			}

			// If the current input is \G and current key is \D, progress to corresponding G major chord.
			{(mm.in == \G && mm.state[0] == \D)} {
				mm.state[1] = rules[mm.state[1]][rrand(0, rules[mm.state[1]].size-1)]-1;
				// swtich to G major
				mm.state[1] = (mm.state[1] + 4) % 7;
				mm.state[0] = \G;
				mm.output = [mm.state[0], mm.state[1]];
			}

			// If the current input is \C and current key is \G, progress to corresponding C major chord.
			{(mm.in == \C && mm.state[0] == \G)} {
				mm.state[1] = rules[mm.state[1]][rrand(0, rules[mm.state[1]].size-1)]-1;
				// swtich to G major
				mm.state[1] = (mm.state[1] + 4) % 7;
				mm.state[0] = \C;
				mm.output = [mm.state[0], mm.state[1]];
			}

			// If the current input is \C and current key is \D, progress to corresponding C major chord.
			{(mm.in == \C && mm.state[0] == \D)} {
				mm.state[1] = rules[mm.state[1]][rrand(0, rules[mm.state[1]].size-1)]-1;
				// swtich to G major
				mm.state[1] = (mm.state[1] + 1) % 7;
				mm.state[0] = \C;
				mm.output = [mm.state[0], mm.state[1]];
			}

			// If the current input is \D and current key is \G, progress to corresponding D major chord.
			{(mm.in == \D && mm.state[0] == \G)} {
				mm.state[1] = rules[mm.state[1]][rrand(0, rules[mm.state[1]].size-1)]-1;
				// swtich to G major
				mm.state[1] = (mm.state[1] + 3) % 7;
				mm.state[0] = \D;
				mm.output = [mm.state[0], mm.state[1]];
			}

			// If the current input is \D and current key is \C, progress to corresponding D major chord.
			{(mm.in == \D && mm.state[0] == \C)} {
				mm.state[1] = rules[mm.state[1]][rrand(0, rules[mm.state[1]].size-1)]-1;
				// swtich to G major
				mm.state[1] = (mm.state[1] + 6) % 7;
				mm.state[0] = \D;
				mm.output = [mm.state[0], mm.state[1]];
			}

			// Default : if input not recognized (Error Handling)
			{ "PLEASE CHECK THE INPUT ARRAY!".warn;};}
	);

	/* Function to map different biomes into different chords
	* Input: A list of biomes that the user specifies with input. eg. [\G,\C,\D,\D,\D]
	* Output: A list of three-value chords. eg. [[62, 66, 69], [64, 67, 71], [67, 71, 74], [73, 76, 79]]
	*/
	evaluate = {

		arg biomes;

		var evaluations = List[];
		biomes.size.do {
			|i|

			mm.in = biomes[i];
			mm.func;
			evaluations.add(keychordMapping.value(mm.output[0], mm.output[1]));
		};

		evaluations;
	};

	// Function to play the chords when the user press space
	play = {
		arg evaluations;
		t1 = List[];
		t2 = List[];
		t3 = List[];

		evaluations.size.do({
			|i|
			t1.add(evaluations[i][0] - 12); // left hand note
			t1.add(evaluations[i][0]); // right hand note
			t1.add(evaluations[i][0] - 12); // left hand note
			t1.add(evaluations[i][0]); // right hand note

			// all right hand notes
			t2.add(evaluations[i][1]);
			t2.add(Rest(1));
			t2.add(evaluations[i][1]);
			t2.add(Rest(1));

			// all right hand notes
			t3.add(evaluations[i][2]);
			t3.add(Rest(1));
			t3.add(evaluations[i][2]);
			t3.add(Rest(1));
		});
	};

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

	// GUI Part Start From here
	win = Window("The Wanderer", Rect(128, 64, 1000, 1000));

	// Initialize the text view for the starting point
	view = TextView(win, Rect(0, 300, 1000, 700));
	view.editable = false;
	view.string = "Welcome to the game, wanderer. WSAD for moving up/down/left/right, and 123 for some real magic! Explore the world now! Press space to evaluate the music.";
	view.setFont(Font("Monaco", 50),0, view.string.size);
	view.setStringColor(Color.white, 0, view.string.size);
	view.background = Color.black;

	// Initialize the map view for the starting point
	map = TextView(win, Rect(700, 0, 300, 300));
	map.editable = false;
	map.string =
	"* · · · · · \n· · · · · · \n· · · · · · \n· · · · · · \n· · · · · · \n· · · · · · ";
	map.setFont(Font("Monaco", 40),0, map.string.size);
	map.setStringColor(Color.red, 0, 1);

	// Initialize the location information view for the starting point
	info = TextView(win, Rect(0, 0, 700, 300));
	info.editable = false;
	info.string = "You are currently in a dessert. Wanderer, hope you bring enough water with you!";
	info.setFont(Font("Monaco", 50),0, info.string.size);
	info.setStringColor(Color.blue, 0, info.string.size);
	info.background = Color.yellow;

	// Allow the GUI respond to the key down actions
	view.keyDownAction = {
		arg view, char, modifiers, unicode, keycode;

		case
		// If the player wants to go up
		{char.asString == "w"}
		{
			// Boundary Check
			if(pos[0] != 0) {
				// Update the text view message and the current location
				view.string = "You choose to move up. May the wind be always at your back.\nIf you want to finish your journey, press spacebar.";
				view.setFont(Font("Monaco", 50),0, view.string.size);
				view.setStringColor(Color.white, 0, view.string.size);
				pos[0] = pos[0] - 1;
				res = res ++ [biome[pos[0]][pos[1]]];

				// Update the map view message
				temp_map = "";
				for(0, 5, {
					arg i;
					for(0, 5, {
						arg j;
						if(i == pos[0] && j == pos[1])
						{
							temp_map = temp_map ++ "* ";
						}
						{temp_map = temp_map ++ "· ";}
					});
					temp_map = temp_map ++ "\n";
				});
				map.string = temp_map;
				map.setFont(Font("Monaco", 40),0, map.string.size);

				// Update the information view message
				case
				{biome[pos[0]][pos[1]] == \C}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in dessert biome. Wanderer, hope you bring enough water with you!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.blue, 0, info.string.size);
					info.background = Color.yellow;
				}
				{biome[pos[0]][pos[1]] == \G}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in forest biome. Wanderer, bring some insect repellents for some forest walk!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.blue, 0, info.string.size);
					info.background = Color.green;
				}
				{biome[pos[0]][pos[1]] == \D}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in ocean biome. Wanderer, today is a beautiful sunny day, you lucky!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.white, 0, info.string.size);
					info.background = Color.blue;
				}
			}
			// If the action fails boundary check, show a warning message
			{
				view.string = "You are in the top of the map! Consider to move in another directions refer to your mini-map.";
				view.setFont(Font("Monaco", 50),0, view.string.size);
				view.setStringColor(Color.red, 0, view.string.size);
			}
		}
		{char.asString == "s"}
		{
			if(pos[0] != 5) {
				// Update the text view message and the current location
				view.string = "You choose to move down. May the wind be always at your back.\nIf you want to finish your journey, press spacebar.";
				view.setFont(Font("Monaco", 50),0, view.string.size);
				view.setStringColor(Color.white, 0, view.string.size);
				pos[0] = pos[0] + 1;
				res = res ++ [biome[pos[0]][pos[1]]];

				// Update the map view message
				temp_map = "";
				for(0, 5, {
					arg i;
					for(0, 5, {
						arg j;
						if(i == pos[0] && j == pos[1])
						{
							temp_map = temp_map ++ "* ";
						}
						{temp_map = temp_map ++ "· ";}
					});
					temp_map = temp_map ++ "\n";
				});
				map.string = temp_map;
				map.setFont(Font("Monaco", 40),0, map.string.size);

				// Update the information view message
				case
				{biome[pos[0]][pos[1]] == \C}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in dessert biome. Wanderer, hope you bring enough water with you!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.blue, 0, info.string.size);
					info.background = Color.yellow;
				}
				{biome[pos[0]][pos[1]] == \G}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in forest biome. Wanderer, bring some insect repellents for some forest walk!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.blue, 0, info.string.size);
					info.background = Color.green;
				}
				{biome[pos[0]][pos[1]] == \D}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in ocean biome. Wanderer, today is a beautiful sunny day, you lucky!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.white, 0, info.string.size);
					info.background = Color.blue;
				}
			}
			// If the action fails boundary check, show a warning message
			{
				view.string = "You are in the bottom of the map! Consider to move in another directions refer to your mini-map.";
				view.setFont(Font("Monaco", 50),0, view.string.size);
				view.setStringColor(Color.red, 0, view.string.size);
			}
		}
		{char.asString == "a"}
		{
			if(pos[1] != 0) {
				// Update the text view message and the current location
				view.string = "You choose to move left. May the wind be always at your back.\nIf you want to finish your journey, press spacebar.";
				view.setFont(Font("Monaco", 50),0, view.string.size);
				view.setStringColor(Color.white, 0, view.string.size);
				pos[1] = pos[1] - 1;
				res = res ++ [biome[pos[0]][pos[1]]];

				// Update the map view message
				temp_map = "";
				for(0, 5, {
					arg i;
					for(0, 5, {
						arg j;
						if(i == pos[0] && j == pos[1])
						{
							temp_map = temp_map ++ "* ";
						}
						{temp_map = temp_map ++ "· ";}
					});
					temp_map = temp_map ++ "\n";
				});
				map.string = temp_map;
				map.setFont(Font("Monaco", 40),0, map.string.size);

				// Update the information view message
				case
				{biome[pos[0]][pos[1]] == \C}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in dessert biome. Wanderer, hope you bring enough water with you!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.blue, 0, info.string.size);
					info.background = Color.yellow;
				}
				{biome[pos[0]][pos[1]] == \G}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in forest biome. Wanderer, bring some insect repellents for some forest walk!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.blue, 0, info.string.size);
					info.background = Color.green;
				}
				{biome[pos[0]][pos[1]] == \D}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in ocean biome. Wanderer, today is a beautiful sunny day, you lucky!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.white, 0, info.string.size);
					info.background = Color.blue;
				}
			}
			// If the action fails boundary check, show a warning message
			{
				view.string = "You are in the leftmost of the map! Consider to move in another directions refer to your mini-map.";
				view.setFont(Font("Monaco", 50),0, view.string.size);
				view.setStringColor(Color.red, 0, view.string.size);
			}
		}
		{char.asString == "d"}
		{
			if(pos[1] != 5) {
				// Update the text view message and the current location
				view.string = "You choose to move right. May the wind be always at your back.\nIf you want to finish your journey, press spacebar.";
				view.setFont(Font("Monaco", 50),0, view.string.size);
				view.setStringColor(Color.white, 0, view.string.size);
				pos[1] = pos[1] + 1;
				res = res ++ [biome[pos[0]][pos[1]]];

				// Update the map view message
				temp_map = "";
				for(0, 5, {
					arg i;
					for(0, 5, {
						arg j;
						if(i == pos[0] && j == pos[1])
						{
							temp_map = temp_map ++ "* ";
						}
						{temp_map = temp_map ++ "· ";}
					});
					temp_map = temp_map ++ "\n";
				});
				map.string = temp_map;
				map.setFont(Font("Monaco", 40),0, map.string.size);

				// Update the information view message
				case
				{biome[pos[0]][pos[1]] == \C}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in dessert biome. Wanderer, hope you bring enough water with you!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.blue, 0, info.string.size);
					info.background = Color.yellow;
				}
				{biome[pos[0]][pos[1]] == \G}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in forest biome. Wanderer, bring some insect repellents for some forest walk!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.blue, 0, info.string.size);
					info.background = Color.green;
				}
				{biome[pos[0]][pos[1]] == \D}
				{
					info = TextView(win, Rect(0, 0, 700, 300));
					info.editable = false;
					info.string = "You are currently in ocean biome. Wanderer, today is a beautiful sunny day, you lucky!";
					info.setFont(Font("Monaco", 50),0, info.string.size);
					info.setStringColor(Color.white, 0, info.string.size);
					info.background = Color.blue;
				}
			}
			// If the action fails boundary check, show a warning message
			{
				view.string = "You are in the rightmost of the map! Consider to move in another directions refer to your mini-map.";
				view.setFont(Font("Monaco", 50),0, view.string.size);
				view.setStringColor(Color.red, 0, view.string.size);
			}
		}
		{char.asString == "1"}
		{
			// Update the text view message and the current location
			view.string = "Wanderer, You just teleport to the dessert biome by pressing 1. Hope you bring enough water!";
			view.setFont(Font("Monaco", 50),0, view.string.size);
			view.setStringColor(Color.white, 0, view.string.size);

			// Update the information view message
			info = TextView(win, Rect(0, 0, 700, 300));
			info.editable = false;
			info.string = "You are currently in dessert biome. Wanderer, hope you bring enough water with you!";
			info.setFont(Font("Monaco", 50),0, info.string.size);
			info.setStringColor(Color.blue, 0, info.string.size);
			info.background = Color.yellow;

			// Update the map view message
			map.editable = false;
			map.string =
			"* · · · · · \n· · · · · · \n· · · · · · \n· · · · · · \n· · · · · · \n· · · · · · ";
			map.setStringColor(Color.red, 0, 1);
			map.setFont(Font("Monaco", 40),0, map.string.size);

			// Update the current position and store the result
			pos[0] = tele1[0];
			pos[1] = tele1[1];
			res = res ++ [biome[pos[0]][pos[1]]];
		}
		{char.asString == "2"}
		{
			// Update the text view message and the current location
			view.string = "Wanderer, You just teleport to the forest biome by pressing 2. Great choice, and bring some insect repellents for some forest walk!";
			view.setFont(Font("Monaco", 50),0, view.string.size);
			view.setStringColor(Color.white, 0, view.string.size);

			// Update the information view message
			info = TextView(win, Rect(0, 0, 700, 300));
			info.editable = false;
			info.string = "You are currently in forest biome. Wanderer, bring some insect repellents for some forest walk!";
			info.setFont(Font("Monaco", 50),0, info.string.size);
			info.setStringColor(Color.blue, 0, info.string.size);
			info.background = Color.green;

			// Update the map view message
			map.editable = false;
			map.string =
			"· · · * · · \n· · · · · · \n· · · · · · \n· · · · · · \n· · · · · · \n· · · · · · ";
			map.setStringColor(Color.red, 6, 1);
			map.setFont(Font("Monaco", 40),0, map.string.size);

			// Update the current position and store the result
			pos[0] = tele2[0];
			pos[1] = tele2[1];
			res = res ++ [biome[pos[0]][pos[1]]];
		}
		// Teleport to location 3
		{char.asString == "3"}
		{
			// Update the text view message
			view.string = "Wanderer, You just teleport to the ocean biome by pressing 3. Today is a beautiful sunny day, you lucky!";
			view.setFont(Font("Monaco", 50),0, view.string.size);
			view.setStringColor(Color.white, 0, view.string.size);

			// Update the location vie message
			info = TextView(win, Rect(0, 0, 700, 300));
			info.editable = false;
			info.string = "You are currently in ocean biome. Wanderer, today is a beautiful sunny day, you lucky!";
			info.setFont(Font("Monaco", 50),0, info.string.size);
			info.setStringColor(Color.white, 0, info.string.size);
			info.background = Color.blue;

			// Update the map view message
			map.editable = false;
			map.string =
			"· · · · · · \n· · · · · · \n· · · · · · \n· · · · · · \n* · · · · · \n· · · · · · ";
			map.setFont(Font("Monaco", 40),0, map.string.size);
			map.setStringColor(Color.red, 52, 1);

			// Update the current position and store the result
			pos[0] = tele3[0];
			pos[1] = tele3[1];
			res = res ++ [biome[pos[0]][pos[1]]];
		}
		// Player indicates the game is over
		{char.asString == " "}
		{
			win.close;
			// Process the user input in the mealy machine
			play.value(evaluate.value(res));
			// Flag true to allow the music to be played
			start_condition.test = true;
			start_condition.signal;
		}
		{
			// Error Handling: If the input keystroke is not legit
			view.string = "Dude what did ya just press? You have one more chance to behave yourself.";
			view.setFont(Font("Monaco", 100),0, view.string.size);
			view.setStringColor(Color.yellow, 0, view.string.size);
		}
	};

	// Display the GUI
	win.front;

	// A routine to start Pattern classes and play the music
	Routine {
		// The condition to make sure the Pattern classes are called AFTER the game is over
		start_condition.wait;

		s.sync;

		p1 = Pbind(\instrument, \piano, \dur, 1, \midinote, Pseq(t1), \amp, 1);
		p2 = Pbind(\instrument, \piano, \dur, 1, \midinote, Pseq(t2), \amp, 1);
		p3 = Pbind(\instrument, \piano, \dur, 1, \midinote, Pseq(t3), \amp, 1);

		Ppar([p1, p2, p3], inf).play;
	}.play;
}
)