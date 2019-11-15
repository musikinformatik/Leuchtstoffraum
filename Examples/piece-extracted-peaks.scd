
loadRelative("../Library/init-all.scd");


/*

here, we extract naively many peaks from the full spectrum.

- This could be done more accurately in the future
- also, one could use the spectralPeaks to derive amplitudes, and frequency differences to the actual peak in the measured data

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
~peakData = ~findPeaks.(~spectra['hifi-bands1-5_E,CO'].amplitudes)
~peakData = ~findPeaks.(~band15.choose.postln.amplitudes);


(
Ndef(\x, {
	var data = ~peakData.keep(128 * 8).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);
	var freqs = ~mapFreqs.(~fullspectrum.frequencyAt(indices), 400);
	Klang.ar(`[freqs, amps, {2pi.rand}!data.size], 1) * 0.03 * 0.1
}).play
)


(
Ndef(\x, {
	var data = ~peakData.keep(128 * 8).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);
	var exc = BPF.ar(Dust.ar(3 ! 8), MouseX.kr(20, 10000, 1), 0.2) * 2;
	var freqs = ~mapFreqs.(~fullspectrum.frequencyAt(indices), 400, 3100);
	Klank.ar(`[freqs, amps, 3], exc, 1) * 0.03 * 0.1
}).play
)




(
Ndef(\x, {
	var data = ~peakData.keep(128 * 16).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);
	var freqs = ~mapFreqs.(~fullspectrum.frequencyAt(indices), 87, 10000);
	//var exc =  Dust.ar(17, 0.1 * LFNoise1.kr(0.3).max(0)) + WhiteNoise.ar(0.001 ! 2);
	var exc =  WhiteNoise.ar(0.001 ! 2) * LFPulse.kr(0.2, 0, 0.1);
	var sig;
	"min freq: % max freq: %".format(freqs.minItem, freqs.maxItem).postln;

	sig = Klank.ar(`[freqs, amps, 30], exc, 1);
	LeakDC.ar(sig) * 0.2 * 0.2
}).playN([0, 4])
)




(
Ndef(\x, {
	var data = ~peakData.keep(128 * 16).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);
	var freqs = ~mapFreqs.(~fullspectrum.frequencyAt(indices), 87, 9000);
	//var exc =  Dust.ar(17, 0.1 * LFNoise1.kr(0.3).max(0)) + WhiteNoise.ar(0.001 ! 2);
	var exc =  WhiteNoise.ar(0.001 ! 2) * LFPulse.kr(0.2, 0, 0.1) + Dust.ar(0.2 ! 2, 0.05);
	var sig;
	"min freq: % max freq: %".format(freqs.minItem, freqs.maxItem).postln;

	sig = Klank.ar(`[freqs, amps, 30], exc, 1);
	LeakDC.ar(sig) * 0.2 * 0.2
}).playN([0, 4])
)

(
Ndef(\x, {
	var trig, exc, sig;
	var density = 14;
	var data = ~peakData.keep(128 * 8).flop;
	var indices = data[0];
	var amps = data[1].normalize(0.2, 1);
	//var freqs = ~mapFreqs.(~fullspectrum.frequencyAt(indices), 40, 11000);
	var freqs = ~mapFreqs.(~fullspectrum.frequencyAt(indices), 3000);
	//var freqs = ~mapFreqs.(~fullspectrum.frequencyAt(indices), 300);

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

