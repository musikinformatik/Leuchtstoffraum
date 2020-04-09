
// test


//-- INIT

SynthDef(\sawwas, { Out.ar(0, XLine.kr(0.1, 00001, 0.1, doneAction: 2) * Saw.ar(\freq.kr) * 0.1) }).add;
s.sync;

//-- PLAY

(
Tdef(\xtest, {
	loop {
		(instrument: \sawwas, note: 8.rand, octave: 5).play;
		0.1.wait;
	}
}).play
);




//-- STOP

Tdef(\xtest).stop;

//-- FREE
