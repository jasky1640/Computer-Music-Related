~markov2D = {
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

~markov1D = {
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

~hiddenMarkov1D = {
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
}