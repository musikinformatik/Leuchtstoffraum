

SynthDef(\grain, { |out, freq = 440, amp = 0.1, sustain = 0.1, width = 0.02, pan|
	var env, sig;
	env = LFGauss.ar(sustain, width, loop: 0, doneAction: 2).range(0, 1);
	amp = AmpCompA.kr(freq) * amp;
	sig = FSinOsc.ar(freq, 0.5pi, amp);
	OffsetOut.ar(out,
		Pan2.ar(
			sig,
			pan,
			env
		)
	)
}).add;


(2 ** (3..9)).do { |n|
	var name = \spectrum_ ++ n.asInteger;
	name.postln;
	SynthDef(name, { |out, amp = 0.1, sustain = 1, numPartials = 128, pan = 0, attack = 0.01, decay = 0.03, phase = 0|
		var freqs, amps, dts, sig;

		freqs = \freqs.ir(200 ! n);
		amps = \amps.ir(1 ! n);
		dts = \dts.ir(1 ! n);

		amps = amps.collect { |x, i| (i < numPartials) * x };

		sig = [freqs, amps, dts].flop.sum { |triple|
			var env, dt, amp, freq, sig;
			#freq, amp, dt = triple;
			env = EnvGen.kr(
				Env([0, 1, 1, 0], [attack, dt * sustain, decay], -4),
				levelScale: amp * AmpCompA.ir(freq)
			);
			sig = SinOsc.ar(freq, phase) * env
		};

		sig = sig * (amp * numPartials.reciprocal ** 0.3);

		DetectSilence.ar(sig, doneAction: 2);

		sig = Pan2.ar(sig, pan);

		OffsetOut.ar(out, sig)

	}, \ir ! 8).add
};

(2 ** (3..10)).do { |n|
	var name = \spectrum_klang_ ++ n.asInteger;
	name.postln;
	SynthDef(name, { |out, amp = 0.1, sustain = 1, numPartials = 128, pan = 0, attack = 0.01, decay = 0.03, phase = 0|
		var freqs, amps, dts, sig, env;

		freqs = \freqs.ir(200 ! n);
		amps = \amps.ir(1 ! n);

		amps = amps.collect { |x, i| (i < numPartials) * x * AmpCompA.ir(freqs[i]) };

		env = EnvGen.kr(
			Env([0, 1, 1, 0], [attack, sustain, decay], -4),
			levelScale: amp,
			doneAction: 2
		);

		sig = Klang.ar(`[freqs, amps, 1]);
		sig = sig * env;
		sig = Pan2.ar(sig, pan);

		OffsetOut.ar(out, sig)

	}, \ir ! 8).add
};


(2 ** (3..10)).do { |n|
	var name = \spectrum_klank_ ++ n.asInteger;
	name.postln;
	SynthDef(name, { |out, amp = 0.1, sustain = 1, numPartials = 128, pan = 0|
		var freqs, amps, dts, sig, exciter;

		freqs = \freqs.ir(200 ! n);
		amps = \amps.ir(1 ! n);
		dts = \dts.ir(1 ! n);
		amps = amps.collect { |x, i| (i < numPartials) * x };

		amps = amps * AmpCompA.ir(freqs);
		dts = dts.max(10/freqs);

		exciter = Impulse.ar(0);
		exciter = Decay2.ar(Impulse.ar(0), 0.0002, 0.001, WhiteNoise.ar(0.2, 1));

		sig = Klank.ar(`[freqs, amps, dts], exciter, decayscale: sustain);
		sig = HPF.ar(sig, 20);
		sig = sig * amp;

		DetectSilence.ar(sig, doneAction: 2);

		sig = Pan2.ar(sig, pan);

		OffsetOut.ar(out, sig)

	}, [\ir, \ir, \ir, \ir]).add
};

(2 ** (3..10)).do { |n|
	var name = \spectrum_klank_filter_ ++ n.asInteger;
	name.postln;
	SynthDef(name, { |out, gate = 1, amp = 0.1, sustain = 1, numPartials = 128, pan = 0|
		var freqs, amps, dts, sig, exciter;

		exciter = \in.ar(0);
		freqs = \freqs.ir(200 ! n);
		amps = \amps.ir(1 ! n);
		dts = \dts.ir(1 ! n);
		amps = amps.collect { |x, i| (i < numPartials) * x };

		//amps = amps * AmpCompA.ir(freqs); // no compensation here.
		dts = dts.max(10/freqs);

		sig = Klank.ar(`[freqs, amps, dts], exciter, decayscale: sustain);
		sig = HPF.ar(sig, 20);
		sig = sig * amp;

		DetectSilence.ar(sig.abs + (gate * 10), doneAction: 2);

		OffsetOut.ar(out, sig)

	}, [\ir, \ir, \ir, \ir]).add
};

(2 ** (3..8)).do { |n|
	var name = \spectrum_dynklank_filter_ ++ n.asInteger;
	name.postln;
	SynthDef(name, { |out, gate = 1, amp = 0.1, sustain = 1, numPartials = 128, pan = 0|
		var freqs, amps, dts, sig, exciter, f0;

		exciter = \in.ar(0);
		f0 = \f0.kr(1, \lag.kr(0.1));
		freqs = \freqs.ir(200 ! n);
		amps = \amps.ir(1 ! n);
		dts = \dts.ir(1 ! n);
		amps = amps.collect { |x, i| (i < numPartials) * x };

		//amps = amps * AmpCompA.ir(freqs); // no compensation here.
		dts = dts.max(10/freqs);

		sig = DynKlank.ar(`[freqs, amps, dts], exciter, freqscale: f0, decayscale: sustain);
		sig = sig * amp;

		DetectSilence.ar(sig.abs + (gate * 10), doneAction: 2);

		OffsetOut.ar(out, sig)

	}, [\ir, \ir, \ir, \ir]).add
};

