
loadRelative("../Library/init-all.scd");


/*

peak frequencies interpreted as base frequencies of strings
cursor x-coordinate determines which string is hit

*/


(
//var peaks = ~spectralPeaks['C-13-O'];
//var peaks = ~spectralPeaks['E,H2O'];
var peaks = ~spectralPeaks.choose;
var freqs = ~mapFreqs.(peaks.peakFreqs[peaks.temperatureOrder], 220);
var amps = peaks.amplitudes[peaks.temperatureOrder].normalize;
var maxParallel = 80;


amps = amps.normalize(0.2, 1);

if(freqs.size > maxParallel) {
	"=== this spectrum (%) has too many partials for this method (%), keeping % ====".format(peaks.name, freqs.size, maxParallel).postln;
	freqs = freqs.keep(maxParallel);
};

Ndef(\x, {
	var which, strings, signal;
	which = MouseX.kr(0, freqs.size).trunc;
	strings = freqs.collect { |freq, i|
		var trig = (absdif(which, i) < 1);
		var env = Decay.ar(T2A.ar(trig), 0.2);
		var exc = Dust.ar(2000 * env, env) + trig;
		freq.poll(trig);
		// CombL sounds better than CombC, which has too much head
		CombL.ar(exc, 0.5, 1/freq, 9) * amps[i]
	};

	signal = Splay.ar(strings);
	LeakDC.ar(signal)

}).play;
)


/*

several strings stroken at once
cursor y-coordinate determines distance
cursor x-coordinate determines first string

*/


(
//var peaks = ~spectralPeaks['C-13-O'];
//var peaks = ~spectralPeaks['E,H2O'];
var peaks = ~spectralPeaks.choose.postln;
var freqs = ~mapFreqs.(peaks.peakFreqs[peaks.temperatureOrder], 300);
var amps = peaks.amplitudes.normalize;
var maxParallel = 80;
amps = amps.normalize(0.2, 1);

if(freqs.size > maxParallel) {
	"=== this spectrum (%) has too many partials for this method (%), keeping % ====".format(peaks.name, freqs.size, maxParallel).postln;
	freqs = freqs.keep(maxParallel);
};


Ndef(\x, {
	var signal;
	var n = freqs.size.min(maxParallel);
	var which = MouseX.kr(0, n).trunc;
	var extendedStrings = 2;
	var dist = MouseY.kr(0, n div: (extendedStrings + 1));
	var dampen = MouseButton.kr();
	var strings = freqs.collect { |freq, i|
		var trig = HPZ2.kr((absdif(which + ((0..extendedStrings) * dist), i) < 1).sum) > 0;
		var exc, env, sig, lfreq;
		trig = T2A.ar(trig);
		env = Decay.ar(trig, 0.2);
		exc = Dust.ar(2000 * env, env) + trig;
		sig = CombL.ar(exc, 0.5, 1/freq, 3) * amps[i];
		lfreq = dampen.lag(*LFNoise0.kr(2!2).range(0.001, 0.1)).linexp(0, 1, 2e4, freq * 2.3);
		LPF.ar(sig, lfreq)
	};

	signal = Splay.ar(strings, levelComp: false);
	LeakDC.ar(signal)

}).play;
)
