
// test


//-- INIT

SynthDef(\sawwas, { Out.ar(0, XLine.kr(0.1, 00001, 0.2, doneAction: 2) * Saw.ar(\freq.kr)) }).add;
s.sync;

//-- PLAY

(
Tdef(\xtest, {
	loop {
		(instrument: \sawwas, note: 8, octave: 4).play;
		0.2.rand.wait;
	}
}).play
);




//-- STOP

Tdef(\xtest).stop;

//-- FREE
