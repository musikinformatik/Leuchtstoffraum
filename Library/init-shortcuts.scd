

~shortnames = (

	H2O: 'E,H2O',
	H2O_18: 'H2O-18',
	CO: 'E,CO',
	CO_18: 'CO-18',
	C_13_O: 'C-13-O',
	CN: 'CN,v=0,1',
	CCH: 'CCH,v=0',
	HCN: 'M,HCN',
	HNC: 'M,HNC',
	OH: 'OH',
	SO2: 'M,SO2',
	CS: 'CS,v=0-4',
	H2CO: 'H2CO',
	OCS: 'OCS,v=0',
	SO: 'M,SO',
	HCO: 'M,HCO+',
	NH3_o: 'NH3-o',
	NH3_p: 'NH3-p',
	CH3OH: 'CH3OH-E',

);

~peaks = ~shortnames.collect { |x| ~spectralPeaks[x] };
~spect = ~shortnames.collect { |x| ~spectra[('hifi-bands1-5_' ++ x).asSymbol ] };
~spect2 = ~shortnames.collect { |x| ~spectra[('hifi-band6a_' ++ x).asSymbol ] };
~spect3 = ~shortnames.collect { |x| ~spectra[('hifi-bands6b-7_' ++ x).asSymbol ] };



/*
// this should become possible

Pdef(\lsr_test,
	Pbind(*[
		\type: \lsr_1,
		\name: Pseq([\CO, \HCO, \HCN], inf),
		\partial: Pwhite(0, 70, inf), // should wrap
		\freq: 220,
		\maxFreq, 12000,
		\sustain, 1
	])
);

Pdef(\lsr_test2,
	Pbind(*[
		\type: \lsr_1,
		\name: Pseq([\CO, \HCO, \HCN], inf),
		\from_partial: Pwhite(0, 70, inf), // should wrap
		\numPartials: 64,
		\freq: 220,
		\sustain, 1
	])
);
*/