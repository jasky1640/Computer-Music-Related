/*
------------------------------------------------------------------------------------------------------------------------
███╗   ███╗ █████╗ ████████╗██████╗ ██╗██╗  ██╗ ██╗██╗███████╗██╗  ██╗██╗     ██████╗ ███████╗ █████╗ ████████╗███████╗
████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗██║╚██╗██╔╝██╔╝██║██╔════╝██║  ██║╚██╗    ██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔════╝
██╔████╔██║███████║   ██║   ██████╔╝██║ ╚███╔╝ ██║ ██║███████╗███████║ ██║    ██████╔╝█████╗  ███████║   ██║   ███████╗
██║╚██╔╝██║██╔══██║   ██║   ██╔══██╗██║ ██╔██╗ ██║ ██║╚════██║██╔══██║ ██║    ██╔══██╗██╔══╝  ██╔══██║   ██║   ╚════██║
██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║██║██╔╝ ██╗╚██╗██║███████║██║  ██║██╔╝    ██████╔╝███████╗██║  ██║   ██║   ███████║
╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
Jiaqi Yang
CPSC 531: Project 1
------------------------------------------------------------------------------------------------------------------------
*/

(
s.waitForBoot {

	/* --- User input zone --- */

	// Specify the BPM (beat per minutes) here, default is 120 BPM
	~tempoClock = TempoClock.default;
	~tempoClock.tempo = 145/60;

	/*
	  Specify the music sample here. Default is electronic music with 2 diffrent kicks and snares!
	  If you want to customize this, you need to provide 2 kicks, 2 snares, 1 open HH, and 1 closed HH.
	  The order is kick1, kick2, snare1, snare2, open HH, closed HH.
	*/
	~input_samples = [\kick1, \kick2, \snare1, \snare2, \hH1, \hH2].collect{ |val| Buffer.read(s,(val++".wav").resolveRelative) };

	/*
	  Specify the amplitute for the input music samples. The order is kick1, kick2, snare1, snare2, open HH, closed HH for default setting.
	  The default amplitude is 1.0 for all input samples.
	*/
	~amplitude_layer = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0];

	// Specify the preselect pattern (seed), defualt is \h, \H, \k, \s
	~seed = [\h, \H, \k, \s];

	// Specify the starting index of seed, default is 2
	~start_index = 2;

	/*
	  Specify how many rounds of "boots-an'-cats-an'" you want to generate for each transformation.
	  The default is nil, which is randomly choosing from 1 to 5 rounds (by default), you can specify the upper limit below
	  If you want to customize it, you should enter an interger (larger or equal to 1)
	*/
	~generated_rounds = 15;

	// If you choose to randomize generated round, specify the upper limit of generated round here. Default is 5.
	~generated_upper_limit = 5;

	/*
	  Specify what type of transformations you want to have in the form of array.
	  Default is [\f, \i, \bf, \bsi, \f, \i, \bf, \bsi, \f, \i, \bf, \bsi, \f, \i, \bf, \bsi]
	  If it's nil, it will generate one round of \f (normal) beat

	  Pattern Transformation: (These transformation will populate patterns)
	    \f for forward (normal), \i for inverted, \sf for shifted forward, \si for shifted inverted (shifted forward for 1)
	    \bf for backward forward, \bi for backward inverted,
	    \bsf for shifted backward forward, \bsi for backward shifted inverted (shifted forward for 1)

	  Array Transformation: (These transformation will NOT populate patterns)
	    \se for shuffling the seed array, \rl for shifting seed array left by one, \rr for shifting seed array right by one
	    \m for making the seed array palindrome, \p for applying random pyramid algorithm to seed array
	*/
	//~transformation_list = [\f, \i, \bf, \bsi, \f, \i, \bf, \bsi, \f, \i, \bf, \bsi, \f, \i, \bf, \bsi];
	~transformation_list = [\f, \i];
	//~transformation_list = nil;

	/*
	  User input here: Specify the pitch variation for the beat (For the PlayBuf). Default pitch is 1.0.
	  You can later adjust this as well via the GUI. (using the knob OR enter a number from 1.0 - 10.0 in the numberbox)
	*/
	~pitch_rate = 1.0;

	/* --- Pre-defined variables zone --- */

	// Store the generated patterns
	~patterns = [];

	// Stores the output lists for kicks, snares, open hi-hat, and close hi-hat seperately
	~k1 = List[];
	~k2 = List[];
	~s1 = List[];
	~s2 = List[];
	~hH1 = List[];
	~hH2 = List[];

	// Stores the forward and invert order
	~forward_order =[0, -2, 3, -3];
	~invert_order = [0, 2, -3 , 3];

	// The function to output forward (normal) pattern
	~forward_func = {
		var curr_pos = ~start_index;
		var output = [];
		for (0, 3, {
			arg i;
			curr_pos = curr_pos + ~forward_order[i];
			output = output ++ [~seed.wrapAt(curr_pos)];
		});
		output;
	};

	// The function to output invert pattern
	~invert_func = {
		var curr_pos = ~start_index;
		var output = [];
		for (0, 3, {
			arg i;
			curr_pos = curr_pos + ~invert_order[i];
			output = output ++ [~seed.wrapAt(curr_pos)];
		});
		output;
	};

	// The function to perform shift transformation
	~shift_func = {
		if (~start_index == 3,
			{~start_index = 0} ,
			{~start_index = ~start_index + 1});
	};

	/* --- synthdefs and other asynchronous stuff ---*/

	// Some rocket sciences here
	SynthDef(\playBuf,
		{ |buffer, start = 0, dur = 0.25, amp = 1|
			var sig = PlayBuf.ar(2,buffer,startPos: start, loop: 0, rate: ~pitch_rate);
			var env = EnvGen.kr(Env.linen(0.01,dur,0.01,level:amp),doneAction:2);
			Out.ar(0,(sig*env) !2);
		}
	).add;

	/* --- Input Check ---*/

	// Check if at least four music samples are provided
	if(~input_samples.size < 6, {"You need to provide at least six music samples! (2 kicks, 2 snares, 1 open HH, 1 closed HH)".warn});

	// Check if the amplitute layer is legal
	if(~amplitude_layer.size != ~input_samples.size, {"You need to provide legal amplitude layer input!".warn});
	// Check if the seed array is empty
	if(~seed.size == 0, {"The seed array is empty!".warn});

	// Check if the generated_round is legal
	if(~generated_rounds != nil && {~generated_rounds < 1}, {"The generated_round cannot be less than 1!".warn});
	if(~generated_rounds == nil && {~generated_upper_limit < 1}, {"The generated_upper_limit cannot be less than 1!".warn});

	// Check if the pitch rate is legal
	if(~pitch_rate <= 0.0, {"The pitch rate cannot be less than 0.0!".warn});

	// Check if the transformation list is legal
	if(~transformation_list != nil && {~transformation_list.size == 0}, {"You need to provide at least one transformation!".warn});

	/* --- Core Algorithm ---*/

	// Fill the patterns array based on user input
	if (~transformation_list == nil,
		{~patterns = ~forward_func.value()},
		{
			for(0, ~transformation_list.size - 1, {
				arg i;
				case
				/* --- Pattern Transformation: (These transformation will populate patterns) --- */
				// \f for forward (normal)
				{~transformation_list[i] == \f}
				{
					if(~generated_rounds == nil,
						{
							for(1, rrand(1, ~generated_upper_limit),
								{
									~patterns = ~patterns ++ ~forward_func.value();
							});
						},
						{
							for(1, ~generated_rounds,
								{
									~patterns = ~patterns ++ ~forward_func.value();
							});
						}
					);
				}

				// \i for inverted
				{~transformation_list[i] == \i}
				{
					if(~generated_rounds == nil,
						{
							for(1, rrand(1, ~generated_upper_limit),
								{
									~patterns = ~patterns ++ ~invert_func.value();
							});
						},
						{
							for(1, ~generated_rounds,
								{
									~patterns = ~patterns ++ ~invert_func.value();
							});
						}
					);
				}

				// \si for shifted inverted(shifted forward for 1)
				{~transformation_list[i] == \si}
				{
					~shift_func.value();
					if(~generated_rounds == nil,
						{
							for(1, rrand(1, ~generated_upper_limit),
								{
									~patterns = ~patterns ++ ~invert_func.value();
							});
						},
						{
							for(1, ~generated_rounds,
								{
									~patterns = ~patterns ++ ~invert_func.value();
							});
						}
					);
				}


				// \sf for shifted forward (shifted forward for 1)
				{~transformation_list[i] == \sf}
				{
					~shift_func.value();
					if(~generated_rounds == nil,
						{
							for(1, rrand(1, ~generated_upper_limit),
								{
									~patterns = ~patterns ++ ~forward_func.value();
							});
						},
						{
							for(1, ~generated_rounds,
								{
									~patterns = ~patterns ++ ~forward_func.value();
							});
						}
					);
				}

				// \bf for backward forward
				{~transformation_list[i] == \bf}
				{
					if(~generated_rounds == nil,
						{
							for(1, rrand(1, ~generated_upper_limit),
								{
									~patterns = ~patterns ++ ~forward_func.value().reverse();
							});
						},
						{
							for(1, ~generated_rounds,
								{
									~patterns = ~patterns ++ ~forward_func.value().reverse();
							});
						}
					);
				}

				// \bi for backward inverted
				{~transformation_list[i] == \bi}
				{
					if(~generated_rounds == nil,
						{
							for(1, rrand(1, ~generated_upper_limit),
								{
									~patterns = ~patterns ++ ~invert_func.value().reverse();
							});
						},
						{
							for(1, ~generated_rounds,
								{
									~patterns = ~patterns ++ ~invert_func.value().reverse();
							});
						}
					);
				}


				// \bsf for shifted backward forward
				{~transformation_list[i] == \bsf}
				{
					~shift_func.value();
					if(~generated_rounds == nil,
						{
							for(1, rrand(1, ~generated_upper_limit),
								{
									~patterns = ~patterns ++ ~forward_func.value().reverse();
							});
						},
						{
							for(1, ~generated_rounds,
								{
									~patterns = ~patterns ++ ~forward_func.value().reverse();
							});
						}
					);
				}


				// \bsi for backward shifted inverted (shifted forward for 1)
				{~transformation_list[i] == \bsi}
				{
					~shift_func.value();
					if(~generated_rounds == nil,
						{
							for(1, rrand(1, ~generated_upper_limit),
								{
									~patterns = ~patterns ++ ~invert_func.value().reverse();
							});
						},
						{
							for(1, ~generated_rounds,
								{
									~patterns = ~patterns ++ ~invert_func.value().reverse();
							});
						}
					);
				}

				/* --- 	Array Transformation: (These transformation will NOT populate patterns) --- */
				// \se for shuffling the patterns array
				{~transformation_list[i] == \se}
				{
					~patterns = ~patterns.scramble();
				}

				// \rl for shifting patterns array left by one
				{~transformation_list[i] == \rl}
				{
					~patterns = ~patterns.rotate(-1);
				}

				// \rr for shifting patterns array right by one
				{~transformation_list[i] == \rr}
				{
					~patterns = ~patterns.rotate(1);
				}

				// \m for making the patterns array palindrome
				{~transformation_list[i] == \m}
				{
					~patterns = ~patterns.mirror2();
				}

				// \p for applying random pyramid algorithm to patterns array
				{~transformation_list[i] == \p}
				{
					~patterns = ~patterns.pyramid(rrand(1, 10));
				}

				// Default case: error handling
				{
					"Unrecognized transformation: ".warn;
					~transformation_list[i].warn;
					" Please check the input transformation arary!".warn;
				}
			});
		}
	);

	// Fill the output lists for kick, snare, open hi-hat, and close hi-hat seperately. Each beat is followed by a rest round.
	for (0, ~patterns.size - 1, {
		arg i;
		// If it's kick's turn, we randomly choose from one of two input kicks.
		if (~patterns[i] == \k,
			{
				if(rrand(1, 2) == 1,
					{
						~k1.add(0.25);
						~k1.add(Rest(0.25));
						~k2.add(Rest(0.25));
						~k2.add(Rest(0.25));
					},
					{
						~k1.add(Rest(0.25));
						~k1.add(Rest(0.25));
						~k2.add(0.25);
						~k2.add(Rest(0.25));
					}
				);

			},
			{
				~k1.add(Rest(0.25));
				~k1.add(Rest(0.25));
				~k2.add(Rest(0.25));
				~k2.add(Rest(0.25));
			}
		);

		// If it's kick's turn, we randomly choose from one of two snares.
		if (~patterns[i] == \s,
			{
				if(rrand(1, 2) == 1,
					{
						~s1.add(0.25);
						~s1.add(Rest(0.25));
						~s2.add(Rest(0.25));
						~s2.add(Rest(0.25));
					},
					{
						~s1.add(Rest(0.25));
						~s1.add(Rest(0.25));
						~s2.add(0.25);
						~s2.add(Rest(0.25));
					}
				);
			},
			{
				~s1.add(Rest(0.25));
				~s1.add(Rest(0.25));
				~s2.add(Rest(0.25));
				~s2.add(Rest(0.25));
			}
		);

		// If it's open HitHat's turn, we fill the open HitHat's list.
		if (~patterns[i] == \h,
			{
				~hH1.add(0.25);
				~hH1.add(Rest(0.25));

			},
			{
				~hH1.add(Rest(0.25));
				~hH1.add(Rest(0.25));
			}
		);

		// If it's closed HitHat's turn, we fill the closed HitHat's list.
		if (~patterns[i] == \H,
			{
				~hH2.add(0.25);
				~hH2.add(Rest(0.25));

			},
			{
				~hH2.add(Rest(0.25));
				~hH2.add(Rest(0.25));
			}
		);
	});

	// Make some coffee now, and wait for everything to finish
	s.sync;

	// GUI to adjust pitch. Can be used when the music is playing!
	~window = Window.new("Pitch Adjustment!", Rect(700, 700, 400, 400))
	                .front.alwaysOnTop_(true)
	                .background_(Color(0.6,0.6,0.6));

	~numberbox = NumberBox.new(~window, Rect(0, 0, 150, 20))
	                      .value_(~pitch_rate)
                          .decimals_(3)
                          .font_(Font("Monaco", 16))
                          .action_({
		                               ~pitch_rate = ~numberbox.value;
		                               ~knob.value_(LinLin.ar(~pitch_rate, 0.0, 10.0, 0.0, 1.0));
		                               SynthDef(\playBuf,
		                                  { |buffer, start = 0, dur = 0.25, amp = 1|
			                                var sig = PlayBuf.ar(2,buffer,startPos: start, loop: 0, rate: ~pitch_rate);
			                                var env = EnvGen.kr(Env.linen(0.01,dur,0.01,level:amp),doneAction:2);
			                                Out.ar(0,(sig*env) !2);
		                                  }
	                                   ).add;
	                              });

	~knob = Knob.new(~window, Rect(35, 35, 300, 300))
                .background_(Color(1,0.8,0.4))
                .value_(LinLin.ar(~pitch_rate, 0.0, 10.0, 0.0, 1.0))
                .action_({
		                     ~pitch_rate = LinLin.ar(~knob.value, 0.0, 1.0, 0.0, 10.0);
		                     ~numberbox.value_(~pitch_rate);
			                 SynthDef(\playBuf,
		                       { |buffer, start = 0, dur = 0.25, amp = 1|
			                     var sig = PlayBuf.ar(2,buffer,startPos: start, loop: 0, rate: ~pitch_rate);
			                     var env = EnvGen.kr(Env.linen(0.01,dur,0.01,level:amp),doneAction:2);
			                     Out.ar(0,(sig*env) !2);
		                       }
	                         ).add;
	                    });

	/* --- Pattern classes to play your beats --- */

	~kick1 = Pbind(\instrument, \playBuf, \dur, Pseq(~k1, inf), \buffer, ~input_samples[0], \amp, ~amplitude_layer[0]);
	~kick2 = Pbind(\instrument, \playBuf, \dur, Pseq(~k2, inf), \buffer, ~input_samples[1], \amp, ~amplitude_layer[1]);
	~snare1 = Pbind(\instrument, \playBuf, \dur, Pseq(~s1, inf), \buffer, ~input_samples[2], \amp, ~amplitude_layer[2]);
	~snare2 = Pbind(\instrument, \playBuf, \dur, Pseq(~s2, inf), \buffer, ~input_samples[3], \amp, ~amplitude_layer[3]);
	~hatOpen = Pbind(\instrument, \playBuf, \dur, Pseq(~hH1, inf), \buffer, ~input_samples[4], \amp, ~amplitude_layer[4]);
	~hatClosed = Pbind(\instrument, \playBuf, \dur, Pseq(~hH2, inf), \buffer, ~input_samples[5], \amp, ~amplitude_layer[5]);

	Ppar([~kick1, ~kick2, ~snare1, ~snare2, ~hatOpen, ~hatClosed], inf).play;
}
)