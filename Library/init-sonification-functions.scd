
/*
== playSpectrumClumped ==

takes an event with freqs, amps, dts (defaults are 1 for all of them)
and an instrument, and distributes the partials over several synths in parallel

// example, play 345 partials using 8-partial synths
(
~playSpectrumClumped.(
(
instrument:\spectrum_8,
freqs: { exprand(300, 1e4) } ! 345,
), 8)
)

*/

~verbose = true; // set this to false to stop posting

// indices of spectrum are mapped to frequency
// if to is given, the indices are linearly mapped to the boundaries of the spectrum [from..to]
// if only from is given, to is derived from the actual ratio in the spectrum

~defaultFreq = 50;

~hydrogenline = 1420405751.7667; //  21-cm line, from H ground state

~indices2Freqs = { |spectrum, indices, from, to|
	from = from ? ~defaultFreq;
	if(to.isNil) {
		to = from * spectrum.frequencyMaximum / spectrum.frequencyMinimum;
	};

	indices.linlin(
		0,
		spectrum.size-1,
		from,
		to,
		\noclip
	)


};

// electromagnetic frequencies are mapped with respect to the fullspectrum
~mapFreqs = { |emFreqs, from, to|
	from = from ? ~defaultFreq;
	if(to.isNil) {
		emFreqs * (~fullspectrum.frequencyMinimum / from).reciprocal
	} {
		emFreqs.linlin(
			~fullspectrum.frequencyMinimum,
			~fullspectrum.frequencyMaximum,
			from,
			to,
			\noclip
		)
	}
};

~mapFreqsProportionally = { |emFreqs, from, ratio = 1|
	from = from ? ~defaultFreq;
	emFreqs.linlin(
		~fullspectrum.frequencyMinimum,
		~fullspectrum.frequencyMaximum,
		from,
		~fullspectrum.frequencyMaximum / ~fullspectrum.frequencyMinimum * ratio * from,
		\noclip
	)

};



~mapFreqsBelow = { |emFreqs, minFreq|
	var first = emFreqs.first;
	emFreqs * (minFreq.nextPowerOfTwo / first.nextPowerOfTwo)
};

~mapFreqsAbove = { |emFreqs, minFreq|
	var first = emFreqs.first;
	emFreqs * (minFreq.nextPowerOfTwo / first.nextPowerOfTwo * 2)
};

~mapOctaveBelow = { |freq, minFreq = 1|
	var ratio = minFreq.nextPowerOfTwo / freq.nextPowerOfTwo;
	//"ratio: %".format(ratio).postln;
	ratio * freq
};

~mapOctaveAbove = { |freq, minFreq = 1|
	var ratio = minFreq.nextPowerOfTwo / freq.nextPowerOfTwo * 2;
	//"ratio: %".format(ratio).postln;
	 ratio * freq
};


~spectralBandsFor = { |name|
	var bands = #["hifi-bands1-5_%", "hifi-band6a_%", "hifi-bands6b-7_%"];
	bands.collect { |x| ~spectra.at(x.format(name).asSymbol) }
};

~balanceAmp = { |freq|
	var k =  3.5041384e16;
	var c1 = 424.31867740601;
	var c2 = 11589.093052022;
	var c3 = 544440.67046057;
	var c4 = 148698928.24309;
	var r = squared(freq);
	var m1 = pow(r,4);
	var n1 = squared(c1 + r);
	var n2 = c2 + r;
	var n3 = c3 + r;
	var n4 = squared(c4 + r);
	var level = k * m1 / (n1 * n2 * n3 * n4);
	sqrt(level)

};

~findPeaks = { |array, thresh = 0.01| // returns array of pairs [index, value]
	var map = List[];
	var prev = 0;
	var diff = array.differentiate;
	diff.do { |x, i|
		var found =
		prev > 0 and: { x <= 0 } // difference crosses zero
		and: { array[i] > thresh } // only include high enough values
		//and: { diff.clipAt(i - 30) > 0 }
		//and: { diff.clipAt(i + 30) < 0 }
		;
		if(found) {
			map.add([i, array[i]])
		};
		prev = x;
	};
	map.sort { |a, b| a[1] > b[1] } // sort by value
};



~playSpectrumClumped = { |event, partialsPerSynth = 512|
	var freqs, amps, dts, numPartials, allEvents, allArgs;

	event.copy.use {
		freqs = ~freqs.value ? 1;
		amps = ~amps.value ? 1;
		dts = ~dts.value ? 1;
	};

	allArgs = [freqs, amps, dts]
	.flop
	.clump(partialsPerSynth)
	.collect(_.flop);

	allEvents = allArgs.collect { |triple|
		var partEvent = event.copy;

		partEvent.use {
			~numPartials = triple[0].size;
			~freqs = [triple[0]];
			~amps = [triple[1]];
			~dts = [triple[2]];
		};

		partEvent
	};

	allEvents.do { |x| x.play };


};

(
~playPeakBand = { |spectrum, minFreq, maxFreq, from = 0, to, numPartials = 512, event|
	var indices, signal, balancedIndices;
	var emfreqs, freqs, amps, dts;

	// some defaults
	numPartials = numPartials.asInteger;
	to = to ?? { spectrum.signal.lastIndex };
	//emfreqs = spectrum.frequencyAt((from..to));
	minFreq = minFreq ?? { spectrum.frequencyAt(from) * ~globalFrequencyScale * 440 };
	maxFreq = maxFreq ?? { spectrum.frequencyAt(to) * ~globalFrequencyScale * 440 };
	event = event ?? { (instrument: \spectrum_512, amp: 0.1, sustain: 1) };

	// find peaks and original amplitudes ("signal")
	indices = spectrum.peakIndices(numPartials, from, to);
	signal = spectrum.signal.at(indices);

	balancedIndices = indices.collect { |x| x + 0.2.rand2 }; // avoid common multples in frequencies


	// frequencies are linearly mapped, so that
	// harmonics remain audible even if the base frequency is changed
	freqs = balancedIndices.linlin(from, to, minFreq, maxFreq, \none);


	// amps and delta times are exponentially mapped, so that
	// the lower values are not consumed by the peaks
	amps = signal.expexp(0.001, 100, 0.001, 1, \none);
	dts = signal.expexp(0.001, 100, 1/8, 1, \none);



	event = event.copy.putAll(
		(
			freqs: freqs,
			amps:amps,
			dts: dts
		)
	);

	event.postcs;

	~playSpectrumClumped.(event, 512);

	//spectrum.infoString;
	spectrum.name

}
);


