// todo: \partial
(
Pdef(\x,
	Pbind(*[
		\type: \lsr_klang,
		\name: Pseq([\CO, \HCO, \HCN], inf),
		\partial: Pwhite(0, 70, inf), // should wrap
		\freq: 420,
		\amp, 0.1,
		\dur, 0.1,
		\maxFreq, 12000,
		\sustain, 0.2
	])
).play;
)


// not yet:
(
Pdef(\lsr_test2,
	Pbind(*[
		\type: \lsr_klang,
		\name: Pseq([\CO, \HCO, \HCN], inf),
		\from_partial: Pwhite(0, 70, inf), // should wrap
		\numPartials: 64,
		\freq: 220,
		\sustain, 1
	])
).play
);
