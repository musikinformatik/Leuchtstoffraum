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
var maxFreq = nil;

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





~buf = Buffer.sendCollection(s, ~fullspectrum.amplitudes);



(
Ndef(\x, {
	var index = MouseX.kr(0, 1);
	var amp = BufRd.ar(1, ~buf, K2A.ar(index) * BufFrames.kr(~buf), interpolation: 4);
	var f0 = ~mapFreqs.(~fullspectrum.frequencyMinimum, 50.midicps);
	var f1 = ~mapFreqs.(~fullspectrum.frequencyMaximum, 70.midicps);
	SinOsc.ar(f1 * index + f0, 0, amp * (1/~fullspectrum.amplitudes.maxItem) * 0.3)
}).play
)



(
Ndef(\x, {
	var n = 110;
	var timeScale = MouseX.kr(0.001, 2, 1);
	var changeRate = { timeScale * LFNoise1.kr(0.05).exprange(1, 2) } ! n;
	var index = LFDNoise1.ar(changeRate).range(0, 1);
	var data = BufRd.ar(1, ~buf, K2A.ar(index) * BufFrames.kr(~buf), interpolation: 4);
	var f0 = ~mapFreqs.(~fullspectrum.frequencyMinimum, 50.midicps);
	var f1 = ~mapFreqs.(~fullspectrum.frequencyMaximum, 80.midicps);
	var freq = f1 * index + f0;
	var amp = AmpCompA.kr(freq) * data.linlin(0, ~fullspectrum.amplitudes.maxItem, 0.0, 1);
	var sig = SinOsc.ar(freq, 0, amp) * 2;
	Splay.ar(sig)
}).play
)

~band15.collect { |x| x.size }.as(Set) // all same size

~buf.sendCollection(~fullspectrum.amplitudes);
~buf.sendCollection(~band15.choose.postln.amplitudes);

(
var x = ~band15.as(Array).removing(~fullspectrum);
var y = x.scramble.keep(5).postln.reduce('+');
~buf.sendCollection(y.amplitudes);
)

(
var x = ~spect.as(Array);
var y = x.scramble.keep(3).postln.reduce('+');
~buf.sendCollection(y.amplitudes, action: { "---- ok ----".postln });
)




~buffers = ~spect.collect { |x| Buffer.sendCollection(s, x.amplitudes) };

(
Ndef(\x, {
	var fmin = 200;
	var fmax = fmin * MouseY.kr(1, 100, 1);
	var buf = \buf.kr(~buf);
	var n = 110;
	var timeScale = MouseX.kr(0.0001, 2, 1);
	var changeRate = { timeScale * LFNoise1.kr(0.05).exprange(1, 2) } ! n;
	var index = LFDNoise1.ar(changeRate).range(0, 1);
	var data = BufRd.ar(1, buf, K2A.ar(index) * BufFrames.kr(buf), interpolation: 4);
	var f0 = ~mapFreqs.(~fullspectrum.frequencyMinimum, fmin);
	var f1 = ~mapFreqs.(~fullspectrum.frequencyMaximum, fmin * 2);
	var freq = f1 * index + f0;
	var amp = AmpCompA.kr(freq) * data.linlin(0, ~fullspectrum.amplitudes.maxItem, 0.0, 1);
	var sig = SinOsc.ar(freq, 0, amp);
	Splay.ar(sig) * 8
}).play
)

Ndef(\x).set(\buf, ~buffers[~buffers.keys.choose.postln]);
Ndef(\x).set(\buf, ~buffers[~buffers.keys.choose.postln]);
Ndef(\x).set(\buf, ~buffers[~buffers.keys.choose.postln]);

