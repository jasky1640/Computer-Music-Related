(
s.waitForBoot {
	// Input midi file: Butterfly lovers
	var bf_midi;
	// Function that record the sections within their boundaries
	var process_midi;
	// Arrays stores midi informations for each track and each section
	var	track1_section1_original, track1_section2_original, track1_section3_original, track1_section4_original, track1_section5_original;
	var track2_section1_original, track2_section2_original, track2_section3_original, track2_section4_original, track2_section5_original;
	var track3_section1_original, track3_section2_original, track3_section3_original, track3_section4_original, track3_section5_original;
	// Function that extract midi, amplitude, duration from the raw midi information
	var extract_midi;
	// Arrays sotores extracted midi, amplitude, duraction for each track and each section
	var	track1_section1_extract, track1_section2_extract, track1_section3_extract, track1_section4_extract, track1_section5_extract;
	var track2_section1_extract, track2_section2_extract, track2_section3_extract, track2_section4_extract, track2_section5_extract;
	var track3_section1_extract, track3_section2_extract, track3_section3_extract, track3_section4_extract, track3_section5_extract;
	// Function that performs first-order Markov Chain algorithm
	var first_order_mc;
	// Arrays stores first-order MC generated midi array
	var track1_section1_mc_pitch, track1_section2_mc_pitch, track1_section3_mc_pitch, track1_section4_mc_pitch, track1_section5_mc_pitch;
	var track2_section1_mc_pitch, track2_section2_mc_pitch, track2_section3_mc_pitch, track2_section4_mc_pitch, track2_section5_mc_pitch;
	var track3_section1_mc_pitch, track3_section2_mc_pitch, track3_section3_mc_pitch, track3_section4_mc_pitch, track3_section5_mc_pitch;
	// Function to fetch amplitude/duration from extracted midi information
	var fetch;
	// Arrays stores full-length (including all sections) pitch, amplitude, duration array
	var track1_midi, track1_amplitude, track1_duration;
	var track2_midi, track2_amplitude, track2_duration;
	var track3_midi, track3_amplitude, track3_duration;
	// Patterns
	var p_track1, p_track2, p_track3;

	// Read midi file of Butterfly Lovers, track 0 - 2
	bf_midi = SimpleMIDIFile.read("Butterfly_Lovers.mid".resolveRelative);

	// Record down the sections within their time boundaries
	process_midi = {|track, section|
		var curr_recording, curr_track;

		curr_track = bf_midi.midiTrackEvents(track);
		curr_recording = [];

		// First section
		if(section == 1) {
			for(0, curr_track.size - 1, {
				arg i;
				if((curr_track[i][1] > 33000) && (curr_track[i][1] <= 36000)) {
					curr_recording = curr_recording.add(curr_track[i]);
				}

			});
		};

		// Second section
		if(section == 2) {
			for(0, curr_track.size - 1, {
				arg i;
				if((curr_track[i][1] > 36000) && (curr_track[i][1] <= 39000)) {
					curr_recording = curr_recording.add(curr_track[i]);
				}

			});
		};

		// Third section
		if(section == 3) {
			for(0, curr_track.size - 1, {
				arg i;
				if((curr_track[i][1] > 39000) && (curr_track[i][1] <= 42000)) {
					curr_recording = curr_recording.add(curr_track[i]);
				}

			});
		};

		// Fourth section
		if(section == 4) {
			for(0, curr_track.size - 1, {
				arg i;
				if((curr_track[i][1] > 42000) && (curr_track[i][1] <= 45000)) {
					curr_recording = curr_recording.add(curr_track[i]);
				}

			});
		};

		// Fifth section
		if(section == 5) {
			for(0, curr_track.size - 1, {
				arg i;
				if((curr_track[i][1] > 45000) && (curr_track[i][1] <= 50000)) {
					curr_recording = curr_recording.add(curr_track[i]);
				}

			});
		};

		curr_recording;
	};

	// Now we have all the midi segments we need in arrays
	track1_section1_original = process_midi.value(0, 1);
	track1_section2_original = process_midi.value(0, 2);
	track1_section3_original = process_midi.value(0, 3);
	track1_section4_original = process_midi.value(0, 4);
	track1_section5_original = process_midi.value(0, 5);

	track2_section1_original = process_midi.value(1, 1);
	track2_section2_original = process_midi.value(1, 2);
	track2_section3_original = process_midi.value(1, 3);
	track2_section4_original = process_midi.value(1, 4);
	track2_section5_original = process_midi.value(1, 5);

	track3_section1_original = process_midi.value(2, 1);
	track3_section2_original = process_midi.value(2, 2);
	track3_section3_original = process_midi.value(2, 3);
	track3_section4_original = process_midi.value(2, 4);
	track3_section5_original = process_midi.value(2, 5);

	// Extract format: midi, amplitude, duration
	extract_midi = {|original_array|
		var extract_info, prev_time, time, status, midi, amplitude;

		prev_time = original_array[0][1];
		extract_info = [];

		// midi file: [1] time, [2] status, [4] midi, [5] amplitude
		for(1, original_array.size - 1, {
			arg i;

			time = original_array[i][1];
			status = original_array[i][2];
			midi = original_array[i][4];
			amplitude = original_array[i][5];

			if(status == \noteOn) {
				if(amplitude == 0) {
					extract_info = extract_info.add([\rest, 0.5, 0.5]);
				}
				{
					if(time - prev_time > 1) {prev_time = time - rrand(0, 1);};
					extract_info = extract_info.add([midi, amplitude, time - prev_time]);
				};
			};

			prev_time = time;
		});

		extract_info;
	};

	// Now we have nice and neat information in arrays extracted
	track1_section1_extract = extract_midi.value(track1_section1_original);
	track1_section2_extract = extract_midi.value(track1_section2_original);
	track1_section3_extract = extract_midi.value(track1_section3_original);
	track1_section4_extract = extract_midi.value(track1_section4_original);
	track1_section5_extract = extract_midi.value(track1_section5_original);

	track2_section1_extract = extract_midi.value(track2_section1_original);
	track2_section2_extract = extract_midi.value(track2_section2_original);
	track2_section3_extract = extract_midi.value(track2_section3_original);
	track2_section4_extract = extract_midi.value(track2_section4_original);
	track2_section5_extract = extract_midi.value(track2_section5_original);

	track3_section1_extract = extract_midi.value(track3_section1_original);
	track3_section2_extract = extract_midi.value(track3_section2_original);
	track3_section3_extract = extract_midi.value(track3_section3_original);
	track3_section4_extract = extract_midi.value(track3_section4_original);
	track3_section5_extract = extract_midi.value(track3_section5_original);

	// Generate pitch array using first order MC algorithm
	first_order_mc = { |input_array|
		var midi_arr, midi_set, dict, collections_arr, prob_arr, output_arr, start;

		dict = Dictionary.new;
		midi_arr = [];
		for(0, input_array.size - 1, {
			arg i;
			midi_arr = midi_arr.add(input_array[i][0]);
		});

		midi_set = midi_arr.asSet.asArray.sort;

		// List of list of elements appears after each value
		collections_arr =  Array.fill(midi_set.size, { [] });
		for(0, midi_set.size - 1, {
			arg i;
			collections_arr.put(i, midi_arr.wrapAt(midi_arr.indicesOfEqual(midi_set[i]) + 1));
		});

		// Dictionary mapping value with a set of values appears after it and their probability (weighting)
		prob_arr = Array.fill(midi_set.size, { [] });
		for(0, midi_set.size - 1, {
			arg i;
			var curr_arr, curr_set, curr_prob;

			curr_arr = collections_arr.at(i).sort;
			curr_set = curr_arr.asSet.asArray.sort;

			if(midi_set[i] == \rest) {curr_set.remove(\rest);};

			curr_prob = List[];

			for(0, curr_set.size - 1, {
				arg j;
				curr_prob.add(curr_arr.indicesOfEqual(curr_set[j]).size);
			});

			curr_prob = curr_prob.asArray.normalizeSum;

			dict.put(midi_set[i], [curr_set, curr_prob]);
		});

		// Generate midi array with the same lenght of input midi array
		output_arr = [];
		start = midi_arr[0];
		for(0, input_array.size - 1, {
			start = dict.at(start)[0].wchoose(dict.at(start)[1]);
			output_arr = output_arr.add(start);
		});

		output_arr;
	};

	// Generate pitch array using first order MC algorithm
	track1_section1_mc_pitch = first_order_mc.value(track1_section1_extract);
	track1_section2_mc_pitch = first_order_mc.value(track1_section2_extract);
	track1_section3_mc_pitch = first_order_mc.value(track1_section3_extract);
	track1_section4_mc_pitch = first_order_mc.value(track1_section4_extract);
	track1_section5_mc_pitch = first_order_mc.value(track1_section5_extract);

	track2_section1_mc_pitch = first_order_mc.value(track2_section1_extract);
	track2_section2_mc_pitch = first_order_mc.value(track2_section2_extract);
	track2_section3_mc_pitch = first_order_mc.value(track2_section3_extract);
	track2_section4_mc_pitch = first_order_mc.value(track2_section4_extract);
	track2_section5_mc_pitch = first_order_mc.value(track2_section5_extract);

	track3_section1_mc_pitch = first_order_mc.value(track3_section1_extract);
	track3_section2_mc_pitch = first_order_mc.value(track3_section2_extract);
	track3_section3_mc_pitch = first_order_mc.value(track3_section3_extract);
	track3_section4_mc_pitch = first_order_mc.value(track3_section4_extract);
	track3_section5_mc_pitch = first_order_mc.value(track3_section5_extract);

	// Function to fetch amplitude/duration from extracted midi information (amplitude 1, duration 2)
	fetch = { |input_array, index|
		var output_array;

		output_array = [];
		for(0, input_array.size - 1, {
			arg i;
			output_array = output_array.add(input_array[i][index]);
		});

		output_array;
	};

	// Combine all sections together
	track1_midi = track1_section1_mc_pitch ++ track1_section2_mc_pitch ++ track1_section3_mc_pitch ++ track1_section4_mc_pitch ++ track1_section5_mc_pitch;
	track1_amplitude = fetch.value(track1_section1_extract, 1) ++ fetch.value(track1_section2_extract, 1) ++ fetch.value(track1_section3_extract, 1)
	++ fetch.value(track1_section4_extract, 1) ++ fetch.value(track1_section5_extract, 1);
	track1_duration = fetch.value(track1_section1_extract, 2) ++ fetch.value(track1_section2_extract, 2)
	++ fetch.value(track1_section3_extract, 2) ++ fetch.value(track1_section4_extract, 2) ++ fetch.value(track1_section5_extract, 2);


	track2_midi = track2_section1_mc_pitch ++ track2_section2_mc_pitch ++ track2_section3_mc_pitch ++ track2_section4_mc_pitch ++ track2_section5_mc_pitch;
	track2_amplitude = fetch.value(track2_section1_extract, 1) ++ fetch.value(track2_section2_extract, 1) ++ fetch.value(track2_section3_extract, 1)
	++ fetch.value(track2_section4_extract, 1) ++ fetch.value(track2_section5_extract, 1);
	track2_duration = fetch.value(track2_section1_extract, 2) ++ fetch.value(track2_section2_extract, 2)
	++ fetch.value(track2_section3_extract, 2) ++ fetch.value(track2_section4_extract, 2) ++ fetch.value(track2_section5_extract, 2);


	track3_midi = track3_section1_mc_pitch ++ track3_section2_mc_pitch ++ track3_section3_mc_pitch ++ track3_section4_mc_pitch ++ track3_section5_mc_pitch;
	track3_amplitude = fetch.value(track3_section1_extract, 1) ++ fetch.value(track3_section2_extract, 1) ++ fetch.value(track3_section3_extract, 1)
	++ fetch.value(track3_section4_extract, 1) ++ fetch.value(track3_section5_extract, 1);
	track3_duration = fetch.value(track3_section1_extract, 2) ++ fetch.value(track3_section2_extract, 2)
	++ fetch.value(track3_section3_extract, 2) ++ fetch.value(track3_section4_extract, 2) ++ fetch.value(track3_section5_extract, 2);

	// https://github.com/everythingwillbetakenaway/Synthdefs/blob/master/solo.scd
	SynthDef(\track1, { | out=0 gate=1 freq=90 |
		var aEnv, fEnv, osc, flt;
		aEnv = EnvGen.kr(Env.asr(0.2, 1, 2), gate);
		fEnv = EnvGen.kr(Env.adsr(0.4, 1.2, 0.7, 2), gate, 800);
		osc = Saw.ar(Lag.kr(freq, 0.1) * [1, 1.005]);
		flt = LPF.ar(osc, fEnv + 600, aEnv);
		Out.ar(out, flt);
	}).add;

	SynthDef(\track2,{|freq|Out.ar([0,2], SinOsc.ar(freq) * EnvGen.kr(Env.perc, doneAction:2));}).add;

	s.sync;

	p_track1 = Pbind(\instrument, \track2, \dur, Pseq(track1_duration), \midinote, Pseq(track1_midi), \amp, Pseq(track1_amplitude));
	p_track2 = Pbind(\instrument, \track1, \dur, Pseq(track2_duration), \midinote, Pseq(track2_midi), \amp, Pseq(track2_amplitude));
	p_track3 = Pbind(\instrument, \track2, \dur, Pseq(track3_duration), \midinote, Pseq(track3_midi), \amp, Pseq(track3_amplitude));

	Ppar([p_track1, p_track2, p_track3], inf).play;
}
)