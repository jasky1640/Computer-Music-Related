(
~map_array = {|arr, func|
	var result = List();
	arr.do{|item| result.add(func.value(item));};
	result.asArray;
};

~extract_midi = { |filepath|
	var file = SimpleMIDIFile.read(thisProcess.nowExecutingPath.dirname +/+ filepath);

	var seq = file.generatePatternSeqs();
	var notes_h = ~map_array.value(seq[1], {|item| (\midinote: item[0], \dur: item[1].round(0.01));});
	var notes_l = ~map_array.value(seq[2], {|item| (\midinote: item[0], \dur: item[1].round(0.01));});

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
	splits.postln;
	(\midinote: splits[0].asInteger, \dur: splits[1].asFloat);
};
)