
loadRelative("../Library/init-all.scd");


/*

peak frequencies interpreted as base frequencies of strings
cursor x-coordinate determines which string is hit


MAYBE: use ~fullspectrum.amplitudeAtFrequency(freqs) to derive the actual amplitudes in the spectrum
note that the freqs may exceed the range, so we have to check for nils.

*/

~postPeaks.value;

~spectralPeaks.maxItem { |x| x.amplitudes.size }

~spectralPeaks['CH3OH-E'];





// simple harp with detune drift
(
//var peaks = ~spectralPeaks['C-13-O'];
//var peaks = ~spectralPeaks['E,CO'];
//var peaks = ~spectralPeaks['E,H2O'];
var peaks = ~spectralPeaks['M,HNC'];
//var peaks = ~spectralPeaks.choose.postln;
//var peaks = ~spectralPeaks['CH3OH-E'];
var freqs = ~mapFreqs.(peaks.peakFreqs[peaks.temperatureOrder], 200);
var amps = peaks.amplitudes[peaks.temperatureOrder].normalize;
var maxParallel = 280;


amps = amps.normalize(0.2, 1);

if(freqs.size > maxParallel) {
	"=== this spectrum (%) has too many partials for this method (%), keeping % ====".format(peaks.name, freqs.size, maxParallel).postln;
	freqs = freqs.keep(maxParallel);
} { "=== (%) number of partials: %".format(peaks.name, freqs.size).postln };

Ndef(\x, { |drift = 0|
	var which, strings, signal, detune;
	//which = MouseX.kr(0, freqs.size).trunc;
	which = Duty.kr(0.1, 0, Dbrown(0, freqs.size, 1));
	detune = 2 ** (LFNoise1.kr(0.1) * drift);
	strings = freqs.collect { |freq, i|
		var trig = (absdif(which, i) < 1);
		var env = Decay.ar(T2A.ar(trig), 0.2);
		var exc = Dust.ar(2000 * env, env) + trig;
		freq.poll(trig);
		// CombL sounds better than CombC, which has too much head
		CombL.ar(exc, 0.5, 1/freq * detune, 1.9) * amps[i]
	};

	signal = Splay.ar(strings);
	LeakDC.ar(signal)

}).play;
)

Ndef(\x).set(\drift, 1);
Ndef(\x).set(\drift, 0);

/*

several strings stroken at once
cursor y-coordinate determines distance
cursor x-coordinate determines first string

*/


(
//var peaks = ~spectralPeaks['C-13-O'];
var peaks = ~spectralPeaks['E,H2O'];
//var peaks = ~spectralPeaks.choose.postln;
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
		sig = CombL.ar(exc, 0.5, 1/freq, 13) * amps[i];
		lfreq = dampen.lag(*LFNoise0.kr(2!2).range(0.001, 0.1)).linexp(0, 1, 2e4, freq * 2.3);
		LPF.ar(sig, lfreq)
	};

	signal = Splay.ar(strings, levelComp: false);
	LeakDC.ar(signal)

}).play;
)




/*

recreating each string on the fly allows for more partials

*/

(
SynthDef(\peakharp, { |out, freq=440, amp=0.1, damp=0, pan = 0, sustain = 1|

	var trig = Impulse.ar(0);
	var env, exc, sig, ffreq;
	env = Decay.ar(trig, 0.02);
	//exc = Dust.ar(2000 * env, env) + trig;
	exc = PinkNoise.ar(env) + trig;
	freq = freq.lag(Rand(0.07, 0.1));

	sig = CombL.ar(exc, 0.5, 1/freq, sustain);

	damp = K2A.ar(damp).lagud(Rand(0.07, 0.1), Rand(0.07, 0.1));
	ffreq = damp.linexp(0, 1, 2e4, freq * 2.3);
	sig = HPF.ar(LPF.ar(sig, ffreq), 20);
	sig = LeakDC.ar(sig);

	DetectSilence.ar(sig, doneAction: Done.freeSelf);
	sig = Pan2.ar(sig, pan, amp * 10);


	Out.ar(out, sig)
}).add;
)


(instrument:\peakharp, freq: 700, sustain: 1).play;
(instrument:\peakharp, freq: 700, sustain: 10).play;


(
//var peaks = ~spectralPeaks['CH3OH-E'];
var peaks = ~spectralPeaks.choose.postln;
//var freqs = ~mapFreqs.(peaks.peakFreqs[peaks.temperatureOrder], 60.midicps, 80.midicps);
var freqs = ~mapFreqs.(peaks.peakFreqs[peaks.temperatureOrder], 60.midicps);
var amps = peaks.amplitudes.normalize(0.03, 0.2);
var stepsize = 1/amps.size;

amps = amps.normalize(0.2, 1);

p = Pbind(
	\instrument, \peakharp,
	\index, Pbrown(0, 1, stepsize, inf) + Pn(Pshuf([0, 0, 0, 1, 2, 3, 4, 4] * stepsize, 8)),
	\freq, Pindex(freqs, Pkey(\index) * freqs.lastIndex),
	\amp, Pindex(amps, Pkey(\index) * freqs.lastIndex) * 0.1,
	\dur, 0.14, //* Pbrown(0.8, 1.2, 0.01),
	\legato, 9.2 *  Pindex(amps, Pkey(\index)).linlin(0.03, 0.2, 1, 0.6),
	\pan, Pstutter(inf, Pfunc { 1.0.rand2 })
);

Pdef(\x, Ppar(p ! 3)).play;
)


(

~getPattern = { |name, pan|


	var peaks = ~spectralPeaks[name];
	var order = peaks.temperatureOrder;
	var freqs = ~mapFreqs.(peaks.peakFreqs[order], 60.midicps);
	var amps = peaks.amplitudes[order].normalize(0.03, 0.2);
	var stepsize = 1/amps.size;

	amps = amps.normalize(0.2, 1);

	Pbind(
		\instrument, \peakharp,
		//\index, Pbrown(0, 1, stepsize, inf) + Pn(Pshuf([0, 0, 0, 1, 2, 3, 4, 4] * stepsize, 8)),
		\index, Pseries(0, stepsize, inf) % 1,
		\freq, Pindex(freqs, Pkey(\index) * freqs.lastIndex),
		\amp, Pindex(amps, Pkey(\index) * freqs.lastIndex) * 0.1,
		\dur, 10 / freqs.size, //* Pbrown(0.8, 1.2, 0.01),
		//\legato, 9.2 *  Pindex(amps, Pkey(\index)).linlin(0.03, 0.2, 1, 0.6),
		\sustain, Pkey(\dur).max(0.2) * 2,
		\pan, pan
	);
};

~pats = ['C-13-O', 'M,SO'].collect { |x, i| ~getPattern.(x, i.linlin(0, 1, -1, 1)) };
//~pats = ['C-13-O', 'CH3OH-E'].collect { |x, i| ~getPattern.(x, i.linlin(0, 1, -1, 1)) };
//~pats = ['CO-18', 'E,CO'].collect { |x, i| ~getPattern.(x, i.linlin(0, 1, -1, 1)) };

//Pdef(\x, Pswitch1(~pats, Penv([0, 0, 1, 1], [2, 2], \step).loop)).play;
Pdef(\x, Ppar(~pats)).play;
)



~spectralPeaks.keys


// first play at one note ...
(
var peaks = ~spectralPeaks['CH3OH-E'];
//var peaks = ~spectralPeaks.choose.postln;
var freqs = ~mapFreqs.(peaks.peakFreqs[peaks.temperatureOrder], 60.midicps);
var amps = peaks.amplitudes.normalize(0.03, 0.2);
var stepsize = 1/amps.size;

amps = amps.normalize(0.2, 1);

p = Pbind(
	\instrument, \peakharp,
	\index, Pdefn(\index),
	\freq, Pindex(freqs, Pkey(\index) * freqs.lastIndex),
	\amp, Pindex(amps, Pkey(\index) * freqs.lastIndex) * 0.1,
	\dur, Pshuf([1, 2, 1, 3, 1, 2, 9, 9, 8, 16, 32], inf) * 0.1,
	\legato, 9.2 *  Pindex(amps, Pkey(\index)).linlin(0.03, 0.2, 1, 0.6),
	\damp, Prand([0, 0, 1], inf),
	\pan, Pstutter(inf, Pfunc { 1.0.rand2 })
);

Pdef(\x, Ppar(p ! 16)).stop.play;
)



// ... then control index
Pdefn(\index, Pbrown(0, 1, 0.001, inf));
Pdefn(\index, Pbrown(0, 1, 0.03, inf));
Pdefn(\index, Pbrown(0, 1, 0.1, inf));
Pdefn(\index, Pn(Pseries(0, 1, 10)/10));
Pdefn(\index, Pseq([0, 4, 8, 1, [0, 2, 17], 3, Pwhite(0, 1.0, 2)] / 20, inf));


Pdef(\x, Ppar(p ! 2)).play;





////////////// event




(
var allPeaks = ~peaks;
var convert = ~mapFreqs.inEnvir;
Event.addEventType(\lsr_harp, { |server|
	var peaks, which;
	peaks = allPeaks[~name];
	which = ~partial ? 0;
	if(peaks.notNil) {
		~freq = convert.(peaks.peakFreqs[which], ~freq.value, ~maxFreq);
		~amp = peaks.amplitudes[which]; // todo: normalize
		~instrument = \peakharp;
		~server = server;
		~type = \note;
		currentEnvironment.play
	}
})
)



Pdefn(\index, Pbrown(0, 1, 0.001, inf));
Pdefn(\index, Pn(Pseries(0, 1, 10)/10));
Pdefn(\index, Pseq([0, 4, 8, 1, [0, 2, 17], 3, Pwhite(0, 1.0, 2)] / 20, inf));


(
Pdef(\x,
	Pbind(
		\type, \lsr_harp,
		\name, Prand([\CO, \H2O], inf),
		\partial, Pdefn(\index) + (0..10),
		\dur, Pshuf([1, 2, 1, 3, 1, 2, 9, 9, 8, 16, 32], inf) * 0.1,
		\legato, 1,
		\damp, Prand([0, 0, 1], inf),
		\pan, Pstutter(inf, Pfunc { 1.0.rand2 })
	)
).play;
)






//////////////// towards a continuous version


(
SynthDef(\peakharpC, { |out, gate = 1, amp=0.1, damp=0, sin = 0, pan = 0, sustain = 1|

	var freq = \freq.ir(440); // don't rearticulate on retrigger
	var ktrig = \trig.tr(0);
	var trig = T2A.ar(ktrig);
	var env, exc, sig, sig2, ffreq;
	env = Decay.ar(trig, 0.2);
	exc = Dust.ar(2000 * env, env) + trig;
	freq = freq.lag(Rand(0.07, 0.1));
	// CombL sounds better than CombC, which has too much head
	sig = CombL.ar(exc, 0.5, 1/freq, sustain) * amp;

	damp = K2A.ar(damp).lagud(Rand(0.07, 0.1), Rand(0.07, 0.1));
	ffreq = damp.linexp(0, 1, 2e4, freq * 2.3);
	sig = HPF.ar(LPF.ar(sig, ffreq), 20);
	sig2 = SinOsc.ar(freq * (damp.neg * 0.01 + 1))
	* Env.linen(0, min(sustain * 0.2, 0.3), 0.05, amp * 0.5).kr(0, trig);
	sig = XFade2.ar(sig, sig2, sin * 2 - 1);
	DetectSilence.ar(sig.abs + (gate * 10), doneAction: Done.freeSelf);
	//sig = sig * EnvGen.kr(Env.asr(0, 1, 0.1), gate, doneAction: Done.freeSelf);
	sig = Pan2.ar(sig, pan);

	Out.ar(out, sig)
}).add;
)

(
SynthDef(\peakharpC, { |out, gate = 1, amp=0.1, damp=0, sin = 0, pan = 0, sustain = 1|

	var freq = \freq.ir(440); // don't rearticulate on retrigger
	var ktrig = \trig.tr(0);
	var trig = T2A.ar(ktrig);
	var env, exc, sig, sig2, ffreq;
	env = Decay2.ar(trig, 0.002, 0.2);
	exc = PinkNoise.ar(env); // + trig;
	// CombL sounds better than CombC, which has too much head
	sig = CombC.ar(exc, 0.5, 1/freq, sustain) * amp;
	sig = LeakDC.ar(sig);
	damp = K2A.ar(damp).lagud(Rand(0.07, 0.1), Rand(0.07, 0.1));
	ffreq = damp.linexp(0, 1, 2e4, freq * 2.3);
	sig = HPF.ar(LPF.ar(sig, ffreq), 20);
	sig2 = SinOsc.ar(freq * (damp.neg * 0.01 + 1))
	* Env.linen(0, min(sustain * 0.2, 0.3), 0.05, amp * 0.5).kr(0, trig);
	sig = XFade2.ar(sig, sig2, sin * 2 - 1);
	DetectSilence.ar(sig.abs + (gate * 10), doneAction: Done.freeSelf);
	//sig = sig * EnvGen.kr(Env.asr(0, 1, 0.1), gate, doneAction: Done.freeSelf);
	sig = Pan2.ar(sig, pan);

	Out.ar(out, sig)
}).add;
)


(instrument: \peakharpC, freq: `[200, 892, 882], sustain: 3).play;


(
//var peaks = ~spectralPeaks.choose.postln;
var peaks = ~spectralPeaks['E,CO'];
//var peaks = ~spectralPeaks['CS,v=0-4'];

var freqs = ~mapFreqs.(peaks.peakFreqs[peaks.temperatureOrder], 48.midicps);
var amps = peaks.amplitudes.normalize;

amps = amps.normalize(0.2, 1);
//freqs = freqs.keep(9);

p = Plazy {

	var prevFreq;
	var r = { |e|
		e.use {
			var freq = ~freq.value;
			var rearticulate = (prevFreq != freq);
			//if(rearticulate) { "============== rearticulated % -> %".format(prevFreq, freq).postln };
			prevFreq = freq;
			rearticulate
		}
	};

	PmonoVoicer(
		\peakharpC,
		\freq, Pindex(freqs, Pbrown(0, freqs.size, Pwhite().linexp(0, 1, 0.2, 7), inf)),
		\dur, Pn(Pshuf([1, 2, 1, 3, 1, 2, 8, 16, Rest(32), Rest(3), Rest(4)], 8), inf) * 0.15,
		\legato, 4.2,
		\trig, 1,
		\damp, Prand([0, 0, 0, 0, 1], inf),
		\sin, Prand([0, 0, 0, 0, 0.5, 0.1], inf),
		\pan, Pstutter(inf, Pfunc { 1.0.rand2 }),
		\rearticulate, Pfunc(r)
	)
};

Pdef(\x, Ppar(p ! 8)).play;
)


// check freeing

(
SynthDef(\peakharp_128, { |out, gate = 1, amp=0.1, damp=0, sin = 0, pan = 0, sustain = 1, numPartials = 256|

	var freq = \freq.ir(440); // don't rearticulate on retrigger
	var amps = \amps.ir(0 ! 256);
	var ratios = \ratios.ir(1 ! 256);
	var ktrig = \trig.tr(0);
	var trig = T2A.ar(ktrig);
	var env, exc, sig, sig2, ffreq, freqs;
	env = Decay2.ar(trig, 0.002, 0.02);
	exc = PinkNoise.ar(env); // + trig;

	freqs = freq * ratios;
	amps = amps.collect { |x, i| (i < numPartials) * x * AmpCompA.ir(freqs[i]) };

	sig = Klank.ar(`[freqs, amps, 1], exc, decayscale: sustain);
	sig = LeakDC.ar(sig);

	damp = K2A.ar(damp).lagud(Rand(0.07, 0.1), Rand(0.07, 0.1));
	ffreq = damp.linexp(0, 1, 2e4, freq * 2.3);
	sig = HPF.ar(LPF.ar(sig, ffreq), 20);



	DetectSilence.ar(sig.abs + (gate * 10), doneAction: Done.freeSelf);
	//sig = sig * EnvGen.kr(Env.asr(0, 1, 0.1), gate, doneAction: Done.freeSelf);
	sig = Pan2.ar(sig, pan, amp);

	Out.ar(out, sig)
}).add;
)


(
var peaks = ~spectralPeaks.choose.postln;
var freqs = ~mapFreqs.(peaks.peakFreqs[peaks.temperatureOrder], 70.midicps);
var amps = peaks.amplitudes.normalize;
var ratios = freqs / freqs[0];
var ampOrder = amps.order;

amps = amps.normalize(0.2, 1);

p = Plazy {

	var prevFreq;
	var r = { |e|
		e.use {
			var freq = ~freq.value;
			var rearticulate = (prevFreq != freq);
			//if(rearticulate) { "============== rearticulated % -> %".format(prevFreq, freq).postln };
			prevFreq = freq;
			rearticulate
		}
	};

	PmonoVoicer(
		\peakharp_256,
		\ratios, [ratios[ampOrder.keep(128)]],
		\amps, [amps[ampOrder.keep(128)]],
		\numPartials, freqs.size,
		\freq, Pindex(freqs, Pbrown(0, freqs.size, 0.2, inf)),
		\dur, Pshuf([1, 2, 1, 3, 1, 2, 8, 16, Rest(32), Rest(3), Rest(4)], inf) * 0.15,
		\legato, 1.2,
		\trig, 1,
		\damp, Prand([0, 0, 0, 0, 1], inf),
		\sin, Prand([0, 0, 0, 0, 0.5, 0.1], inf),
		\pan, Pstutter(inf, Pfunc { 1.0.rand2 }),
		\amp, 0.1,
		\rearticulate, Pfunc(r)
	)
};

Pdef(\x, Ppar(p ! 8)).play;
)

/*

--- SpectralPeaks C-13-O ---
--- SpectralPeaks CCH,v=0 ---
--- SpectralPeaks CH3OH-A ---
--- SpectralPeaks CH3OH-E ---
--- SpectralPeaks CN,v=0,1 ---
--- SpectralPeaks CO-18 ---
--- SpectralPeaks CS,v=0-4 ---
--- SpectralPeaks E,CO ---
--- SpectralPeaks E,H2O ---
--- SpectralPeaks H2CO ---
--- SpectralPeaks H2O-18 ---
--- SpectralPeaks M,HCN ---
--- SpectralPeaks M,HCO+ ---
--- SpectralPeaks M,HNC ---
--- SpectralPeaks M,SO ---
--- SpectralPeaks M,SO2 ---
--- SpectralPeaks NH3-o ---
--- SpectralPeaks NH3-p ---
--- SpectralPeaks OCS,v=0 ---
--- SpectralPeaks OH ---
*/



// closely related molecules.
(
~compareGroups = [
//	['CH3OH-A', 'CH3OH-E'],
	['NH3-o', 'NH3-p'],
	['E,CO', 'C-13-O', 'CO-18'],
	['H2O-18', 'E,H2O'],
	['M,HNC', 'M,HCN', 'CN,v=0,1'], // ?
//	['H2CO', 'M,HCO+'],
	['M,SO', 'M,SO2'], // very different
	['CS,v=0-4', 'OCS,v=0'],
	['H2CO', 'M,HCO+']
];
);



(
var maxParallel = 80;
var makeStrings = { |freqs, amps, which|
	freqs.collect { |freq, i|
		var trig = (absdif(which, i) < 1);
		var env = Decay.ar(T2A.ar(trig), 0.2);
		var exc = Dust.ar(2000 * env, env) + trig;
		var sig;
		freq.poll(trig);
		// CombL sounds better than CombC, which has too much head
		sig = CombL.ar(exc, 0.5, 1/freq, 9) * amps[i];
		//sig * SinOsc.ar(freq) * Decay2.ar(K2A.ar(HPZ2.kr(trig)>0), 0.01, 0.3)
		//RLPF.ar(sig, SinOsc.kr(3).linexp(0, 3, freqs.maxItem, freqs.maxItem * 3), 0.1)
	};
};

Ndef(\x, {
	~compareGroups.choose.keep(2).postln.collect { |name|
		var which, strings, signal;
		var peaks = ~spectralPeaks[name];
		var freqs = ~mapFreqs.(peaks.peakFreqs[peaks.temperatureOrder], 220);
		var amps = peaks.amplitudes[peaks.temperatureOrder].normalize;
		which = MouseX.kr(0, freqs.size).trunc;
		amps = amps.normalize(0.2, 1);
		if(freqs.size > maxParallel) {
			"=== this spectrum (%) has too many partials for this method (%), keeping % ====".format(peaks.name, freqs.size, maxParallel).postln;
			freqs = freqs.keep(maxParallel);
		};
		strings = makeStrings.(freqs, amps, which);
		signal = strings.sum;
		LeakDC.ar(signal)
	}
}).play;
)
