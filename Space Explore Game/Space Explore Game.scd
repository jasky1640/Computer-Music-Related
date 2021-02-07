(
s.waitForBoot {
	var win, com, info, info_label,view, view_label, knob, knob_label;
	var yellowChoices, purpleChoices, greenChoices, blueChoices, colorChoices;
	var numGrid, viewGrid, updateGrid, rPos, cPos, speed;
	var output, start_condition;
	var markov2D, markov1D, hiddenMarkov1D;

	// MIDI processing section
	~map_array = {|arr, func|
		var result = List();
		arr.do{|item| result.add(func.value(item));};
		result.asArray;
	};

	~extract_midi = { |filepath|
		var file = SimpleMIDIFile.read(thisProcess.nowExecutingPath.dirname +/+ filepath);

		var seq = file.generatePatternSeqs();
		var notes_h = ~map_array.value(seq[1], {|item| item[0].asString + item[1].round(0.01).asString;});
		var notes_l = ~map_array.value(seq[2], {|item| item[0].asString + item[1].round(0.01).asString;});

		Dictionary.newFrom(List[\notes_h, notes_h, \notes_l, notes_l]);
	};

	~midi_notes = ~map_array.value([
		"Sword Art Online - A Tender Feeling (Lisbeth's Theme)",
		"Legend of Zelda - Overworld",
		"Super Mario 64 - Medley",
		"The Elder Scrolls V - Skyrim - Main Theme"
	], {
		|item| (\title: item, \notes: ~extract_midi.value("MIDIs/" ++ item ++ ".mid"))
	});

	~event_to_key = { |event|
		event[\midinote].asString + event[\dur].asString;
	};

	~key_to_event = { |key|
		var splits = key.split($ );
		if (splits[0] == "rest") {
			(\midinote: \rest, \dur: splits[1].asFloat);
		} {
			(\midinote: splits[0].asInteger, \dur: splits[1].asFloat);
		}
	};

	// markov calculator section

	/*
	Given an array of midi notes, calculate all the possible midis with probs given its preceding two notes.
	For example, given an array 1,2,3, then Prob(3|1,2) will be 1.
	Note that in the above case the key we should use is '1.2' (two numbers are concatenated with a dot)
	*/
	markov2D = {
		|midiArray|

		var d2;

		d2 = Dictionary.new;

		(midiArray.size-2).do {
			arg i;

			var first = midiArray.wrapAt(i);
			var second = midiArray.wrapAt(i+1);
			var third = midiArray.wrapAt(i+2);
			var key = first + "." + second;
			var values = d2.at(key);

			if (values == nil, {
				values = List[];
			});
			values.add(third);
			d2.put(key, values);
		};

		d2.keys.do {
			arg key;

			var vs, vSet, vProb;

			// all the notes with current key
			vs = d2.at(key).sort;

			// eliminate all the duplicates
			vSet = vs.asSet.asArray.sort;

			// calculate and normalize the probability
			vProb = List[];
			vSet.do {
				|v|
				vProb.add(vs.indicesOfEqual(v).size);
			};
			vProb = vProb.asArray.normalizeSum;

			// update the dictionary
			d2.put(key, [vSet, vProb]);
		};

		d2;
	};
	~data_2D = ~map_array.value(~midi_notes, {|item| markov2D.value(item[\notes][\notes_h])});

	/*
	Given an array of midi notes, calculate all the possible midis with probs given its preceding note.
	For example, given an array 1,2, then Prob(2 | 1) will be 1.
	Note that in the above case the key we should use is '1'.
	This is used for the senario where there is no elements in the set given its preceding two notes.
	*/
	markov1D = {
		|midiArray|

		var d1;

		d1 = Dictionary.new;

		(midiArray.size-1).do {
			arg i;

			var key = midiArray.wrapAt(i);
			var value = midiArray.wrapAt(i+1);
			var values = d1.at(key);

			if (values == nil, {
				values = List[];
			});
			values.add(value);
			d1.put(key, values);
		};

		d1.keys.do {
			arg key;

			var vs, vSet, vProb;

			// all the notes with current key
			vs = d1.at(key).sort;

			// eliminate all the duplicates
			vSet = vs.asSet.asArray.sort;

			// calculate and normalize the probability
			vProb = List[];
			vSet.do {
				|v|
				vProb.add(vs.indicesOfEqual(v).size);
			};
			vProb = vProb.asArray.normalizeSum;

			// update the dictionary
			d1.put(key, [vSet, vProb]);

		};

		d1;
	};
	~data_1D = ~map_array.value(~midi_notes, {|item| markov1D.value(item[\notes][\notes_h])});

	/*
	Given an array of main midi notes and an array of harmony midi notes, calculate all the possible
	harmony midis with probability given the main midi note.
	*/
	hiddenMarkov1D = {
		arg mArr, hArr;

		var hd, len;

		hd = Dictionary.new;
		if (mArr.size < hArr.size, {
			len = mArr.size;
		}, {
			len = hArr.size;
		});

		len.do {
			arg i;

			var key, value, values;

			// get key and value
			key = mArr[i];
			value = hArr[i];

			// record in the dictionary
			values = hd.at(key);
			if (values == nil, {
				values = List[];
			});
			values.add(value);
			hd.put(key, values);
		};

		// normalize the prob
		hd.keys.do {
			arg key;

			var vs, vSet, vProb;

			// all the notes with current key
			vs = hd.at(key).sort;

			// eliminate all the duplicates
			vSet = vs.asSet.asArray.sort;

			// calculate and normalize the probability
			vProb = List[];
			vSet.do {
				|v|
				vProb.add(vs.indicesOfEqual(v).size);
			};
			vProb = vProb.asArray.normalizeSum;

			// update the dictionary
			hd.put(key, [vSet, vProb]);
		};

		// return the result
		hd;
	};
	~data_hidden1D = ~map_array.value(~midi_notes, {|item| hiddenMarkov1D.value(item[\notes][\notes_h], item[\notes][\notes_l])});

	// end markov calculator section

	// GUI Portion

	// The condition to make sure the Pattern classes are called AFTER the game is over
	start_condition = Condition.new(false);

	// Main window that contains all views
	Window.closeAll();
	win = Window("Space Traveler", Rect(128, 64, 1000, 1300));

	// Composite window that contains all views
	com = CompositeView(win, Rect(0, 0, 1000, 1300));

	// Textview that is the label of info view
	info_label = TextView(com, Rect(0, 1000, 350, 50));

	// Textview that describes the current nebula info
	info = TextView(com, Rect(0, 1050, 350, 250));

	// Textview that describes the current stats
	view = TextView(com, Rect(650, 1050, 350, 250));

	// Textview that is the label of view view
	view_label = TextView(com, Rect(650, 1000, 350, 50));

	// Textview that is the label of knob view
	knob_label = TextView(com, Rect(350, 1000, 300, 50));

	// Knob that adjusts the speed of the spaceship
	knob = Knob(com, Rect(400, 1050, 200, 250));

	// Initial position and speed of the spaceship
	rPos = 24;
	cPos = 24;
	speed = 1;

	// The output of the game (crafttable-mode)
	output = [];

	// Six different blue choices randomly choose from
	blueChoices =
	[
		Color.fromHexString("#5CACEE"), Color.fromHexString("#1C86EE"),
		Color.fromHexString("#104E8B"), Color.fromHexString("#6495ED"),
		Color.fromHexString("#2E37FE"), Color.fromHexString("#27408B")
	];

	// Six different green choices randomly choose from
	greenChoices =
	[
		Color.fromHexString("#5A6351"), Color.fromHexString("#7FFF00"),
		Color.fromHexString("#458B00"), Color.fromHexString("#66CD00"),
		Color.fromHexString("#8CDD81"), Color.fromHexString("#37BC61")
	];

	// Six different purple choices randomly choose from
	purpleChoices =
	[
		Color.fromHexString("#2E0854"), Color.fromHexString("#7F00FF"),
		Color.fromHexString("#9B30FF"), Color.fromHexString("#BF5FFF"),
		Color.fromHexString("#5E2D79"), Color.fromHexString("#CD96CD")
	];

	// Six different yellow choices randomly choose from
	yellowChoices =
	[
		Color.fromHexString("#FCDC3B"), Color.fromHexString("#D6C537"),
		Color.fromHexString("#FFD700"), Color.fromHexString("#EEDD82"),
		Color.fromHexString("#EEB422"), Color.fromHexString("#FFE303")
	];

	// The array that contains all color choice arrays
	colorChoices = [blueChoices, greenChoices, purpleChoices, yellowChoices];

	// Randomly adjust the transparency of all the colors
	for(0, 3, {
		arg i;
		for(0, 5, {
			arg j;
			colorChoices[i][j].alpha = rrand(0.3, 0.8);
		});
	});

	// The function that initialize the grid for GUI
	updateGrid = {
		// The grid is a 50 * 50 rectangle space
		numGrid = Array2D.new(50, 50);
		viewGrid = Array2D.new(50, 50);
		for(0, 49, {
			arg r;
			for(0, 49, {
				arg c;
				var isShip;

				isShip = (rPos == r && cPos == c);

				// Randomly choose the color for current grid
				numGrid[r, c] = 4.rand;
				viewGrid[r, c] = StaticText(com, Rect(r * 20, c * 20, 20, 20));
				viewGrid[r, c].background = colorChoices[numGrid[r, c]][6.rand];

				viewGrid[r, c].enabled = true;
				viewGrid[r, c].acceptsMouse = true;
				viewGrid[r, c].acceptsMouseOver = true;

				viewGrid[r, c].mouseOverAction = {
					case
					{numGrid[r, c] == 0}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This blue nebula is rich with oxygen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[r, c].background, 0, info.string.size);
					}
					{numGrid[r, c] == 1}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This green nebula is rich with hydrogen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[r, c].background, 0, info.string.size);
					}
					{numGrid[r, c] == 2}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This purple nebula is rich with helium.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[r, c].background, 0, info.string.size);
					}
					{numGrid[r, c] == 3}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This yellow nebula is rich with sulfur.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[r, c].background, 0, info.string.size);

					}
				};

				viewGrid[r, c].mouseLeaveAction = {
					info.editable = false;
					info.hasVerticalScroller = false;
					info.hasHorizontalScroller = false;
					info.string = "Move mouse over any nebula to see its information";
					info.setFont(Font("Monaco", 30),0, info.string.size);
					info.setStringColor(Color.black, 0, info.string.size);
				};

				// Mark the initial position of the spaceship as red
				if(isShip == true)
				{
					viewGrid[r, c].background = Color.red;
					viewGrid[r, c].mouseOverAction = {
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "Your spaceship is currently here.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[r, c].background, 0, info.string.size);
					};
				};

			});
		});
	};

	// Allow the mouse over actions for the GUI
	win.acceptsMouseOver = true;
	com.acceptsMouse = true;
	com.acceptsMouseOver = true;

	// Initialize the knob view
	knob.color = [Color.fromHexString("#808080"), Color.white, Color.black, Color.fromHexString("#696969")];
	knob.background = Color.fromHexString("#C0C0C0");
	knob.value = 0.0;
	knob.action = {
		var new_speed;
		new_speed = LinLin.ar(knob.value, 0.0, 1.0, 1.0, 10.0);
		speed = new_speed.round();
		view.editable = false;
		view.hasVerticalScroller = false;
		view.hasHorizontalScroller = false;
		view.string = "Your current position is labeled as red.\n\nYour current speed is " ++ speed.asString ++ ".\n\nScroll Down For more: \n\nTo move up/down/left/right, press W/S/A/D.\n\nTo adjust speed, adjust the knob.\n\nTo exit, press space.";	view.setFont(Font("Monaco", 30),0, view.string.size);
		view.setStringColor(Color.black, 0, view.string.size);
		view.background = Color.fromHexString("#C0C0C0");
	};

	// Initialize the knob label view
	knob_label.editable = false;
	knob_label.hasVerticalScroller = false;
	knob_label.hasHorizontalScroller = false;
	knob_label.string = "  Ion thruster Setting";
	knob_label.setFont(Font("Monaco", 30),0, knob_label.string.size);
	knob_label.setStringColor(Color.white, 0, knob_label.string.size);
	knob_label.background = Color.fromHexString("#C0C0C0");

	// Initialize the view label view
	view_label.editable = false;
	view_label.hasVerticalScroller = false;
	view_label.hasHorizontalScroller = false;
	view_label.string = "         Dashboard";
	view_label.setFont(Font("Monaco", 30),0, view_label.string.size);
	view_label.setStringColor(Color.white, 0, view_label.string.size);
	view_label.background = Color.fromHexString("#C0C0C0");

	// Initialize the view view
	view.editable = false;
	view.hasVerticalScroller = false;
	view.hasHorizontalScroller = false;
	view.string = "Your current position is labeled as red.\n\nYour current speed is " ++ speed.asString ++ ".\n\nScroll Down For more: \n\nTo move up/down/left/right, press W/S/A/D.\n\nTo adjust speed, adjust the knob.\n\nTo exit, press space.";
	view.setFont(Font("Monaco", 30),0, view.string.size);
	view.setStringColor(Color.black, 0, view.string.size);
	view.background = Color.fromHexString("#C0C0C0");

	// Initialize the info label view
	info_label.editable = false;
	info_label.hasVerticalScroller = false;
	info_label.hasHorizontalScroller = false;
	info_label.string = "       Nebula Detector";
	info_label.setFont(Font("Monaco", 30),0, info_label.string.size);
	info_label.setStringColor(Color.white, 0, info_label.string.size);
	info_label.background = Color.fromHexString("#C0C0C0");

	// Initialize the info view
	info.editable = false;
	info.hasVerticalScroller = false;
	info.hasHorizontalScroller = false;
	info.string = "Move mouse over any nebula to see its information";
	info.setFont(Font("Monaco", 30),0, info.string.size);
	info.setStringColor(Color.black, 0, info.string.size);
	info.background = Color.fromHexString("#C0C0C0");

	// Initialize the 50 * 50 grid in the GUI
	updateGrid.value();

	// Populate the output array with current position
	output = output ++ numGrid[rPos, cPos].asSymbol;

	// Configure the keyDownAction W/S/A/D/Space
	com.keyDownAction = {
		arg view, char, modifiers, unicode, keycode;
		var new_rPos, new_cPos;

		case
		// The spaceship moves up
		{char.asString == "w"}
		{
			new_cPos = cPos - speed;

			// Out-of-boundary check
			if(new_cPos >= 0)
			{
				cPos = new_cPos;

				// Reocver Original grid
				viewGrid[rPos, cPos + speed].background = colorChoices[numGrid[rPos, cPos + speed]][6.rand];
				viewGrid[rPos, cPos + speed].mouseOverAction = {
					case
					{numGrid[rPos, cPos + speed] == 0}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This blue nebula is rich with oxygen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos, cPos + speed].background, 0, info.string.size);
					}
					{numGrid[rPos, cPos + speed] == 1}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This green nebula is rich with hydrogen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos, cPos + speed].background, 0, info.string.size);
					}
					{numGrid[rPos, cPos + speed] == 2}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This purple nebula is rich with helium.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos, cPos + speed].background, 0, info.string.size);
					}
					{numGrid[rPos, cPos + speed] == 3}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This yellow nebula is rich with sulfur.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos, cPos + speed].background, 0, info.string.size);

					}
				};

				// Modify the new grid to mark the spaceship
				viewGrid[rPos, cPos].background = Color.red;
				viewGrid[rPos, cPos].mouseOverAction = {
					info.editable = false;
					info.hasVerticalScroller = false;
					info.hasHorizontalScroller = false;
					info.string = "Your spaceship is currently here.";
					info.setFont(Font("Monaco", 30), 0, info.string.size);
					info.setStringColor(viewGrid[rPos, cPos].background, 0, info.string.size);
				};
				output = output ++ numGrid[rPos, cPos].asSymbol;
			};
		}

		// The spaceship moves down
		{char.asString == "s"}
		{
			new_cPos = cPos + speed;

			// Out-of-boundary check
			if(new_cPos <= 49)
			{
				cPos = new_cPos;

				// Reocver Original grid
				viewGrid[rPos, cPos - speed].background = colorChoices[numGrid[rPos, cPos - speed]][6.rand];
				viewGrid[rPos, cPos - speed].mouseOverAction = {
					case
					{numGrid[rPos, cPos - speed] == 0}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This blue nebula is rich with oxygen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos, cPos - speed].background, 0, info.string.size);
					}
					{numGrid[rPos, cPos - speed] == 1}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This green nebula is rich with hydrogen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos, cPos - speed].background, 0, info.string.size);
					}
					{numGrid[rPos, cPos - speed] == 2}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This purple nebula is rich with helium.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos, cPos - speed].background, 0, info.string.size);
					}
					{numGrid[rPos, cPos - speed] == 3}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This yellow nebula is rich with sulfur.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos, cPos - speed].background, 0, info.string.size);

					}
				};

				// Modify the new grid to mark the spaceship
				viewGrid[rPos, cPos].background = Color.red;
				viewGrid[rPos, cPos].mouseOverAction = {
					info.editable = false;
					info.hasVerticalScroller = false;
					info.hasHorizontalScroller = false;
					info.string = "Your spaceship is currently here.";
					info.setFont(Font("Monaco", 30), 0, info.string.size);
					info.setStringColor(viewGrid[rPos, cPos].background, 0, info.string.size);
				};
				output = output ++ numGrid[rPos, cPos].asSymbol;
			};
		}

		// The spaceship moves left
		{char.asString == "a"}
		{
			new_rPos = rPos - speed;

			// Out-of-boundary check
			if(new_rPos >= 0)
			{
				rPos = new_rPos;

				// Reocver Original grid
				viewGrid[rPos + speed, cPos].background = colorChoices[numGrid[rPos + speed, cPos]][6.rand];
				viewGrid[rPos + speed, cPos].mouseOverAction = {
					case
					{numGrid[rPos + speed, cPos] == 0}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This blue nebula is rich with oxygen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos + speed, cPos].background, 0, info.string.size);
					}
					{numGrid[rPos + speed, cPos] == 1}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This green nebula is rich with hydrogen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos + speed, cPos].background, 0, info.string.size);
					}
					{numGrid[rPos + speed, cPos] == 2}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This purple nebula is rich with helium.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos + speed, cPos].background, 0, info.string.size);
					}
					{numGrid[rPos + speed, cPos] == 3}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This yellow nebula is rich with sulfur.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos + speed, cPos].background, 0, info.string.size);

					}
				};

				// Modify the new grid to mark the spaceship
				viewGrid[rPos, cPos].background = Color.red;
				viewGrid[rPos, cPos].mouseOverAction = {
					info.editable = false;
					info.hasVerticalScroller = false;
					info.hasHorizontalScroller = false;
					info.string = "Your spaceship is currently here.";
					info.setFont(Font("Monaco", 30), 0, info.string.size);
					info.setStringColor(viewGrid[rPos, cPos].background, 0, info.string.size);
				};
				output = output ++ numGrid[rPos, cPos].asSymbol;
			};
		}

		// The spaceship moves right
		{char.asString == "d"}
		{
			new_rPos = rPos + speed;

			// Out-of-boundary check
			if(new_rPos <= 49)
			{
				rPos = new_rPos;

				// Reocver Original grid
				viewGrid[rPos - speed, cPos].background = colorChoices[numGrid[rPos - speed, cPos]][6.rand];
				viewGrid[rPos - speed, cPos].mouseOverAction = {
					case
					{numGrid[rPos, cPos + speed] == 0}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This blue nebula is rich with oxygen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos - speed, cPos].background, 0, info.string.size);
					}
					{numGrid[rPos, cPos + speed] == 1}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This green nebula is rich with hydrogen.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos - speed, cPos].background, 0, info.string.size);
					}
					{numGrid[rPos, cPos + speed] == 2}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This purple nebula is rich with helium.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos - speed, cPos].background, 0, info.string.size);
					}
					{numGrid[rPos, cPos + speed] == 3}
					{
						info.editable = false;
						info.hasVerticalScroller = false;
						info.hasHorizontalScroller = false;
						info.string = "This yellow nebula is rich with sulfur.";
						info.setFont(Font("Monaco", 30), 0, info.string.size);
						info.setStringColor(viewGrid[rPos - speed, cPos].background, 0, info.string.size);

					}
				};

				// Modify the new grid to mark the spaceship
				viewGrid[rPos, cPos].background = Color.red;
				viewGrid[rPos, cPos].mouseOverAction = {
					info.editable = false;
					info.hasVerticalScroller = false;
					info.hasHorizontalScroller = false;
					info.string = "Your spaceship is currently here.";
					info.setFont(Font("Monaco", 30), 0, info.string.size);
					info.setStringColor(viewGrid[rPos, cPos].background, 0, info.string.size);
				};
				output = output ++ numGrid[rPos, cPos].asSymbol;
			};
		}

		// Player indicates the game is over
		{keycode == 36}
		{
			win.close;
			// Do something with the output here
			~output_notes_h = List[];
			~output_notes_l = List[];
			~map_array.value(output, { |num|
				var notes_h = List[];
				var random_index = rrand(0, ~midi_notes[num.asInteger][\notes][\notes_h].size-1);
				notes_h.add(~midi_notes[num.asInteger][\notes][\notes_h][random_index]);
				notes_h.add(~midi_notes[num.asInteger][\notes][\notes_h][random_index + 1]);
				8.do({ |i|
					var distribution = ~data_2D[num.asInteger][notes_h[i] + '.' + notes_h[i + 1]];
					if (distribution == nil) {
						distribution = ~data_1D[num.asInteger][notes_h[i + 1]];
					};
					if (distribution == nil) {
						notes_h.add("rest 0.5");
					} {
						notes_h.add(distribution[0].wchoose(distribution[1]));
					};
				});
				~output_notes_h.addAll(notes_h);
				notes_h.do({|note|
					var distribution = ~data_hidden1D[num.asInteger][note];
					if (distribution == nil) {
						~output_notes_l.add("rest" + ~key_to_event.value(note)[\dur]);
					} {
						~output_notes_l.add(distribution[0].wchoose(distribution[1]));
					};
				});
			});

			~output_notes_h.postln;
			~output_notes_l.postln;

			// Flag true to allow the music to be played
			start_condition.test = true;
			start_condition.signal;
		};
	};

	win.front;

	// A routine to start Pattern classes and play the music
	Routine {
		// The condition to make sure the Pattern classes are called AFTER the game is over
		start_condition.wait;

		s.sync;

		Ppar([
			Pseq(~map_array.value(~output_notes_h, {|key| ~key_to_event.value(key)})),
			Pseq(~map_array.value(~output_notes_l, {|key| ~key_to_event.value(key)})),
		]).play;
	}.play;
}
)