

// convert linear frequency relation to logarithmic one
// 1 : 2 : 3 ––> 2 : 4 : 8
// in order to be able to hear deviations from harmonic relationship as rhythm

// problem is that the numbers are very large, obviously,
// so we have to derive a small slot

(
x = ~spectralPeaksF0.collect { |p|
	var emfreqs = p.peakFreqs;
	var g = 2 ** (emfreqs / p.baseFreq);
	g / g.first
}
)

x.maxItem { |y| y.last }.last



(
Ndef(\x, {
//	var a = ~spectralPeaks['E,CO'].peakFreqs;
	var a = ~spectralPeaksF0.choose.postln;
	var g = 2 ** (a.peakFreqs / a.baseFreq);
	g = g / g.first;

	g.collect { |rate, i|
		Blip.ar(rate, 2000)  * (1 / (i+1))
//		* LFDNoise1.kr(1).range(0, 1)
	}.mean

}).play
)
