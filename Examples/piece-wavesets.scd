
WavesetsEvent.prepareSynthDefs;

~ws = WavesetsEvent.read(~leuchtstoffraum_datapath +/+ "/soundfiles/spectrum-01.aiff").add(\spectrum);
~ws2 = WavesetsEvent.read(~leuchtstoffraum_datapath +/+ "/soundfiles/spectrum-long-nz-02.aiff").add(\spectrumLong);
~ws3 = WavesetsEvent.read(~leuchtstoffraum_datapath +/+ "/soundfiles/spectrum-spread-nz-03.aiff").add(\spectrumSpread);



(
var which = \spectrum;
Pdefn(\repeats, 1);
Ndef(\x,
	Pwavesets(
		Pbind(
			\name, which,
			\start, Pn(Pseries(0, 1, WavesetsEvent.all.at(which).size-1)),
			\num, Pbrown(1, 13, 0.1),
			\rate, 8,
			\repeats, Pdefn(\repeats),
			\legato, Pbrown(0, 1, 0.1).linexp(0, 1, 0.1, 2),
			\amp, 0.1,
			\pan, Pbrown(-0.5, 0.5, 0.001)
		)
	)
)
)

Ndef(\x).play

Pdefn(\repeats, 1);
Pdefn(\repeats, 2);
Pdefn(\repeats, 3);
Pdefn(\repeats, 4);
Pdefn(\repeats, 5);
Pdefn(\repeats, 6);
Pdefn(\repeats, 8);


Pdefn(\repeats, Pseg(Pseq([1, 22, 1], inf), 30, 'lin', inf));



(
var which = \spectrumSpread;
Pdefn(\repeats, 1);
Ndef(\x,
	Pwavesets(
		Pbind(
			\name, which,
			\start, Pn(Pseries(0, 1, WavesetsEvent.all.at(which).size-21)),
			\num, 16, //Pbrown(1, 13, 0.1),
			\rate, 1,
			\repeats, Pdefn(\repeats),
			\legato, 1, //Pbrown(0, 1, 0.1).linexp(0, 1, 0.1, 2),
			\amp, 0.1,
			\pan, Pbrown(-0.5, 0.5, 0.001)
		)
	)
)
)

/*

for multichannel version:
expand
out: 0..7
repeats: ...
rate: ...
(interesting that this works with internal legato -> dur calculation)
this is because if(~dur.isArray) { ~dur = ~dur[0] };

*/


Ndef(\x).play

Ndef(\x).stop;

Ndef(\y) <<> Ndef(\x)


(
Ndef(\y, {
	var src = \in.ar(0 ! 2);
    var rev = Greyhole.ar(
        src,
        \dtime.kr(0.4),
        \damp.kr(0.01),
	//	\size.kr(),
		MouseX.kr(0.1, 30, 1),
        \diff.kr(0.707),
        \fb.kr(0.15),
        \modDepth.kr(0.01),
        \modFreq.kr(2)
    );

	src * MouseY.kr(0, 1) + rev
}).play;
)


~fullspectrum.frequencyAt(0) / ~peaks[\CO].baseFreq




