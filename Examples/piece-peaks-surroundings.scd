loadRelative("../Library/init-all.scd");

/*

we look around the places where we expect peaks

*/


(
~somePeaks = ~spectralPeaks.choose.postln; // choose some random molecule
~emfreqs = ~somePeaks.peakFreqs[~somePeaks.temperatureOrder];
// keep only those peaks which are in the fullspectrum
~emfreqs = ~emfreqs.select { |freq| ~fullspectrumRawSmooth.amplitudeAtFrequency(freq).notNil };
)




(
var clusters, emfreqs, numPartials = 32, numFreqsPerPartial = 128;
var minFreq = 370;
var maxFreq = 8000;

clusters = ~emfreqs.keep(numPartials).collect { |freq|
	~fullspectrumRawSmooth.amplitudesAroundFrequency(freq, numFreqsPerPartial)
};

clusters = clusters.collect { |x| x.normalize(0.2, 1) }; // here, normalize each separately

Ndef(\x, {

	var sweepers, filters, d = MouseY.kr(0, 0.1);
	var ratio = MouseX.kr().range(1 - d, 1 + d).poll(2, "ratio of deviation");
	var freqs = ~mapFreqs.(~emfreqs, minFreq, maxFreq);
	sweepers = SinOsc.ar(ratio * freqs) * 1e-6; // * LFNoise0.kr(20 ! freqs.size).max(0);

	filters = clusters.collect { |amps, i|
		var xfreqs, freqs;
		var n = numFreqsPerPartial div: 2;
		var dfreqs = (n.neg..n);
		xfreqs = dfreqs * ~fullspectrumRawSmooth.frequencyStep + ~emfreqs[i];
		freqs = ~mapFreqs.(xfreqs, minFreq, maxFreq);
		Klank.ar(`[freqs, amps.normalize(0.2, 1), 4], sweepers[i])
	};


	Splay.ar(filters)

}).play

)
