
// read molecule peaks
// the frequency range starts with ~minFrequency slightly lower
// than the minimal peakFreq from ~spectralPeaks
// but their baseFreq can be much lower (~maxBaseFreq * ~globalFrequencyScaler =~ 0.21)

(
~spectralPeaks = ();
~leuchtstoffraum_datapath = ~leuchtstoffraum_datapath ?? { "../data".resolveRelative };

(~leuchtstoffraum_datapath +/+ "peaks/*").resolveRelative.pathMatch.do { |path|
	var x = SpectralPeaks.read(path);
	"--- SpectralPeaks % ---".format(x.name).postln;
	~spectralPeaks[x.name] = x;
};

~spectralPeaksF0 = ~spectralPeaks.select {|x| x.baseFreq.notNil };
~allPeakNames = ~spectralPeaks.keys.as(Array).sort;
);


(
{
	var maxValueOf;
	maxValueOf = { |all, f| f.(all.maxItem(f)) };
	~maxGlobalFreq = maxValueOf.(~spectralPeaks, { |x| x.peakFreqs.maxItem }); // 1901167.5
	~maxGlobalAmplitude = maxValueOf.(~spectralPeaks, { |x| x.amplitudes.maxItem });
	~maxBaseFreq = maxValueOf.(~spectralPeaksF0, { |x| x.baseFreq });
}.value;

~gauss = { |x, a = 1.0, b = 0.0, c = 1.0| a * (exp(squared(x - b) / (-2.0 * squared(c)))) };
~spectralPeaks
);


(
~postPeaks = {
	var pad = { |str, n|
		str.asString.extend(n, $ );
	};
	~spectralPeaks.keys.asArray.sort.do { |x|
		var peaks = ~spectralPeaks.at(x);
		var freqs = peaks.peakFreqs;
		"% n:%  (%..%) THz".format(
			pad.(x, 16),
			pad.(freqs.size, 4),
			(freqs.minItem * 1e-12).round(0.001),
			(freqs.maxItem * 1e-12).round(0.001)
		).postln;

	}
}
);
