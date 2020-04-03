
// test


//-- INIT

SynthDef(\sinmore, { Out.ar(0, XLine.kr(0.1, 0.001, 0.15, doneAction: 2) * SinOsc.ar(\freq.kr * [1, 1.1])) }).add;


//-- PLAY

(
Tdef(\xmore, {
	loop {
		(instrument: \sinmore, note: rrand(-3, 10), octave: 6).play;
		0.2.rand.wait;
	}
}).play
);




//-- STOP

Tdef(\xmore).stop;

//-- FREE
