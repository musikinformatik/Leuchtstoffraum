
// compare specific lines
(
f = { |emfreq|
	var ampsRaw, ampsFits, ampsFitsSmooth, ampsRawSmooth;
	ampsRaw = ~fullspectrumRaw.amplitudesAroundFrequency(emfreq, 1024);
	ampsFits = ~fullspectrum.amplitudesAroundFrequency(emfreq, 1024);
	ampsRawSmooth = ~fullspectrumRawSmooth.amplitudesAroundFrequency(emfreq, 1024);
	ampsFitsSmooth = ~fullspectrumSmooth.amplitudesAroundFrequency(emfreq, 1024);
	if(ampsRaw.isNil) { "Frequency (% THz) outside range of data".format(emfreq * 1e-12).throw };
	[
		ampsRaw,
		ampsFits,
		ampsRawSmooth,
		ampsFitsSmooth,
		ampsFits - ampsRaw,
		ampsRaw - ampsRawSmooth

	].plot(separately: false);
};
)



f.(~spectralPeaks['E,CO'].peakFreqs[6]);
f.(~spectralPeaks['CH3OH-E'].peakFreqs[31]);


f.(~spectralPeaks['CH3OH-E'].peakFreqs[2090]);
f.(~spectralPeaks['CH3OH-E'].peakFreqs[2087]);

~spectralPeaks.keys

a = ~spectralPeaks['E,CO'].peakFreqs[4];


// compare whole parts of the spectrum
(
g = { |i0, i1|
	var ampsRaw, ampsFits;
	ampsRaw = ~fullspectrumRaw.amplitudes[i0..i1];
	ampsFits = ~fullspectrum.amplitudes[i0..i1];
	[ampsRaw, ampsFits, ampsFits - ampsRaw].plot(separately: false);
};
)

~fullspectrumRaw.amplitudes.lastIndex


k = ~fullspectrumRaw.frequencyAt(~fullspectrumRaw.size - 2000)
m = ~spectralPeaks['CH3OH-E'].peakFreqs.selectIndices { |x| x > k && (x < ~fullspectrumRaw.frequencyMaximum) };
m.size


1280300000000.0

g.(800999 - 1000, 800999);


///////////////////////////////////////////////////////////////////////

(
~findPeaks = { |array|
	var map = List[];
	var prev = 0;
	var diff = array.differentiate;
	diff.do { |x, i|
		var found =
		prev > 0 and: { x <= 0 }
		and: { array[i] > 0.01 }
		//and: { diff.clipAt(i - 30) > 0 }
		//and: { diff.clipAt(i + 30) < 0 }
		;
		prev = x;
		if(found) {
			map.add([i, array[i]])
		};
	};
	map.sort { |a, b| a[1] > b[1] }
};
)



~peakData = ~findPeaks.(~fullspectrum.amplitudes)
~peakDataRaw = ~findPeaks.(~fullspectrumRaw.amplitudes)

~peakDataRaw.sort { |a, b| a[0] < b[0] };
~peakData.sort { |a, b| a[0] < b[0] };
i = ~peakData.flop[0]
j = ~peakDataRaw.flop[0]


