
loadRelative("../Library/init-all.scd");


/*

here, we extract naively many peaks from the full spectrum.

- This could be done more accurately in the future
- also, one could use the spectralPeaks to derive amplitudes, and frequency differences to the actual peak in the measured data

The ~findPeaks implementation below is really not very good for noisy data (i.e. the actual measuremets e.g. in ~fullspectrumRaw)

*/


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


//// some variants. run one of them and then rerun the examples

~peakData = ~findPeaks.(~fullspectrum.amplitudes)
~peakData = ~findPeaks.(~fullspectrumRaw.amplitudes)
~peakData = ~findPeaks.(~fullspectrumRawSmooth.amplitudes)
~peakData = ~findPeaks.(~fullspectrumSmooth.amplitudes)
~peakData = ~findPeaks.(~spectra['hifi-bands1-5_E,CO'].amplitudes)
~peakData = ~findPeaks.(~band15.choose.postln.amplitudes);


(
Ndef(\y, {
	var data = ~peakData.keep(128 * 8).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);
	var freqs = ~mapFreqs.(~fullspectrumRawSmooth.frequencyAt(indices), 400, 12000);

	amps = amps * ~balanceAmp.(freqs);

	Klang.ar(`[freqs, amps, {2pi.rand}!data.size], 1) ! 2 * 0.03 * 0.1
}).play
)


(
Ndef(\y, {
	var data = ~peakData.keep(128 * 8).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);

	var freqs = ~mapFreqs.(~fullspectrumRawSmooth.frequencyAt(indices), 200, 3100);
	var exc = Decay2.ar(Dust.ar(2), 0.001, 0.01, WhiteNoise.ar(0.3, 1));

	exc = Pan2.ar(exc, MouseX.kr(-1, 1)); // pan the input noise bursts
	exc = BPF.ar(exc, MouseX.kr(freqs.minItem, freqs.maxItem, 1), 0.4); // filter them

	amps = amps * ~balanceAmp.(freqs);

	Klank.ar(`[freqs, amps, 3], exc, 1) * 0.03 * 0.1
}).play
)


// a more differentiated space
(
Ndef(\y, {
	var peaks, scrambled, exc, clumps, channels;
	clumps = 4;
	peaks = ~peakData.keep(128 * 8);
	scrambled = peaks.scramble.flop.clump(peaks.size div: clumps);

	exc = Decay2.ar(Dust.ar(2), 0.001, 0.01, WhiteNoise.ar(0.3, 1));
	exc = BPF.ar(exc, MouseX.kr(40, 12000, 1), 0.4);

	//exc =  WhiteNoise.ar(0.01) * LFNoise0.kr(5).max(0);

	// distribute random spectral parts in different spatial positions
	channels = scrambled.collect { |data, i|
		var indices, amps, freqs, sig, dts;

		indices = data[0];
		amps = data[1].normalize(0.2, 1);

		freqs = ~mapFreqs.(~fullspectrumRawSmooth.frequencyAt(indices), 200, 8100);

		// delaytimes are large for quiet partials, and also for low freqeuncies
		dts = data[1].normalize(3, 0.5) *  (1000/freqs);

		amps = amps * ~balanceAmp.(freqs);

		sig = Klank.ar(`[freqs, amps, dts], exc, 1);
		Pan2.ar(sig, i / clumps)
	};

	channels.sum * 0.01

}).play
)



// white noise bursts
(
Ndef(\y, {
	var data = ~peakData.keep(128 * 16).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);
	var freqs = ~mapFreqs.(~fullspectrumRawSmooth.frequencyAt(indices), 87, 10000);
	//var exc =  Dust.ar(17, 0.1 * LFNoise1.kr(0.3).max(0)) + WhiteNoise.ar(0.001 ! 2);
	var exc =  WhiteNoise.ar(0.001 ! 2) * LFPulse.kr(0.2, 0, 0.1);
	var sig;
	"min freq: % max freq: %".format(freqs.minItem, freqs.maxItem).postln;

	amps = amps * ~balanceAmp.(freqs);

	sig = Klank.ar(`[freqs, amps, 20], exc, 1);
	LeakDC.ar(sig) * 0.2 * 0.2
}).play;
)




(
Ndef(\y, {
	var data = ~peakData.keep(128 * 16).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);
	var freqs = ~mapFreqs.(~fullspectrumRawSmooth.frequencyAt(indices), 87, 9000);
	//var exc =  Dust.ar(17, 0.1 * LFNoise1.kr(0.3).max(0)) + WhiteNoise.ar(0.001 ! 2);
	var exc =  WhiteNoise.ar(0.001 ! 2) * LFPulse.kr(0.2, 0, 0.1) + Dust.ar(0.2 ! 2, 0.05);
	var sig;
	"min freq: % max freq: %".format(freqs.minItem, freqs.maxItem).postln;

	amps = amps * ~balanceAmp.(freqs);

	sig = Klank.ar(`[freqs, amps, 30], exc, 1);
	LeakDC.ar(sig) * 0.2 * 0.2
}).play;
)

(
Ndef(\y, {
	var trig, exc, sig;
	var density = 14;
	var data = ~peakData.keep(128 * 8).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);
	//var freqs = ~mapFreqs.(~fullspectrum.frequencyAt(indices), 40, 11000);
	var freqs = ~mapFreqs.(~fullspectrumRawSmooth.frequencyAt(indices), 3000);
	// var freqs = ~mapFreqs.(~fullspectrumSmooth.frequencyAt(indices), 3000);
	//var freqs = ~mapFreqs.(~fullspectrum.frequencyAt(indices), 300);

	amps = amps * ~balanceAmp.(freqs);

	//trig = Dust.ar(density ! 2, 0.01 * LFNoise1.kr(0.3, 0.2).max(0));
	trig = Impulse.ar(8, [0, 0.5], 0.1 * LFNoise1.kr(0.9 ! 2, 0.1).max(0));

	exc =  Decay2.ar(trig, 0.001, 0.003, WhiteNoise.ar(0.3, 1)); // + WhiteNoise.ar(0.00002 ! 2);
	exc = BPF.ar(exc, MouseX.kr(freqs.minItem, freqs.maxItem, 1), 0.3) * 20;


	//exc = WhiteNoise.ar(0.0002 ! 2);
	//"min freq: % max freq: %".format(freqs.minItem * f0, freqs.maxItem * f0).postln;
	"----- min freq: % max freq: %".format(freqs.minItem, freqs.maxItem).postln;

	sig = Klank.ar(`[freqs, amps, amps.linexp(0.2, 1, 50, 3)], exc); // emphasize weaker peaks in the decay
	//sig = Klank.ar(`[freqs, amps, 40 * amps], exc);
	Limiter.ar(LeakDC.ar(sig)) * 0.2 * 0.5
}).play
)



 // no need to dither!  1.8 µHz

~fullspectrum.frequencyStep * ~globalFrequencyScaler
~fullspectrum.frequencyMinimum * ~globalFrequencyScaler


