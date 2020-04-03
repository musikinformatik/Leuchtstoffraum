
loadRelative("../Library/init-all.scd");


/*
alle Information steht in der CDMS, aber eine Zuordnung zu einer
klassischen Rotationsgeschwindigkeit wird dort natürlich nicht gemacht,
da das für ein Quantensystem immer nur eine Analogie und damit
etwas unsauber ist.

Wenn man die Rotationsdauer klassisch ausrechnen würde, käme man
auf T=sqrt(Pi/2*h_quer/(E*B)) mit E=h*c*E(CDMS)=1.9864479e-23 J/cm-1*E(CDMS),
wobei E die Rotationsenergie aus der
CDMS in kg m^2/s^2 wäre und B die Rotationskonstante des Moleküls
in Hz. Alternativ kann ich die Rotationsquantenzahl des oberen
Niveaus aus der hinteren Spalte der CDMS nehmen und bekomme
T=sqrt(1/(4*B^2*J*(J+1)). Gilt so einfach natürlich nur für
den linearen Rotor. Bei komplizierteren Molekülen, muss man die
jeweilige Quantenzahl und das zugehörige B suchen.


=============================================================================

Die richtigen Formeln lauten
T=sqrt(Pi/2*h_quer/(E*B)) mit E=h*c*E(CDMS)=1.9864479e-23 J/cm-1*E(CDMS)
T=sqrt(1/(4*B^2*J*(J+1))

CO-Beispiel:

hBar
1.054572669125102e-34
h*c
1.986447461038579e-25

math.sqrt(math.pi/2.*hBar/(h*c* 100. * 3.845 * 57.635968e9))
6.134295388820468e-12

math.sqrt(1./(4.*57.635968e9**2*2.))
6.134249199966135e-12

Entspricht einer Rotationsfrequenz von 163.019 GHz, also einer
etwas krummen Zahl im Vergleich zur Übergangsfrequenz von
115.271 GHz.


*/



// klassisch aus dem Energielevel

t = { |e, b| sqrt(0.5pi * 1.054572669125102e-34 / (1.9864479e-23 * e * b)) };
t.(3.8450, 57635.968e6);


// aus der Quantenzahl

k = { |j, b| sqrt(1 / (4 * b.squared * j * (j + 1))) };
k.(1, 57635.968e6);


// Vergleich:


// v = 0: https://cdms.astro.uni-koeln.de/cgi-bin/cdmsinfo?file=e028503.cat
// B / MHz = 57635.968
// https://cdms.astro.uni-koeln.de/cgi-bin/cdmssearch?file=w028503.cat
// E_0 = 3.8450
// In der Tabelle ist die Energie in cm^(-1) angegeben. Um
// auf J zu kommen, muss man dann mit 1.9864e-23 multiplizieren.

t.(3.8450, 57635.968e6);
k.(1, 57635.968e6);

// => 6.1342491999661e-12 sec (rotation period)


x = ~spectralPeaks['E,CO'].baseFreq * t.(3.8450, 57635.968e6) //  0.70710752353789 == sqrt(0.5)


// return the ratios between emission frequency and rotation frequency for each line

x = ~spectralPeaks['E,CO'].peakFreqs.collect { |x, i| x * k.(i + 1, 56061.9e6) };
x = ~spectralPeaks['CO-18'].peakFreqs.collect { |x, i| x * k.(i + 1, 56061.9e6) };
x = ~spectralPeaks['C-13-O'].peakFreqs.collect { |x, i| x * k.(i + 1, 56061.9e6) };
x = ~spectralPeaks['OH'].peakFreqs.collect { |x, i| x * k.(i + 1, 56061.9e6) };

~spectralPeaks.keys

// Q: should we use the function k to account for more complex rotations from CMS data?


///////////////////////////////////////////////////////////////////


(
Ndef(\x, {
	var exc, emfreq, rfreq, a, b;
	var freq = MouseX.kr(1, 1000, 1);
	exc = Trig1.ar(Dust.ar(1), 0.03) * WhiteNoise.ar(0.1);
	emfreq = ~spectralPeaks['E,CO'].peakFreqs * ~globalFrequencyScaler;
	rfreq = k.((1..emfreq.size), 56061.9e6)  * ~globalFrequencyScaler;
	a = exc;
	emfreq.do { |x| a = AllpassC.ar(a, 1, 1/freq, 20) };

	b = exc;
	rfreq.do { |x| b = AllpassC.ar(a, 1, 0.1/freq, 20) };
	[a, b]

}).play
)


(
Ndef(\x, {
	var exc, pfreq, rfreq, p, r;
	var freq = 470; //MouseY.kr(100, 8000, 1).poll;
	var m, n, a, b;


	pfreq = ~spectralPeaks['E,CO'].peakFreqs * ~globalFrequencyScaler;
	n = pfreq.size;
	rfreq = k.((1..n), 56061.9e6).reciprocal  * ~globalFrequencyScaler;
	m = MouseX.kr(0, n-1);

	p = Select.kr(m, pfreq);
	r = Select.kr(m, rfreq);

	a = SinOsc.ar(p * freq);
	b = SinOsc.ar(r * freq);
	[a, b] * 0.1

}).play
)



(
Ndef(\x, {
	var exc, pfreq, rfreq, p, r;
	var freq = MouseY.kr(100, 8000, 1).poll;
	var m, n, a, b;


	pfreq = ~spectralPeaks['E,CO'].peakFreqs * ~globalFrequencyScaler;
	n = pfreq.size;
	rfreq = k.((1..n), 56061.9e6).reciprocal  * ~globalFrequencyScaler;
	m = MouseX.kr(0, n-1);


	b = pfreq.size.collect { |i|
		SinOsc.ar(pfreq[i] * freq, SinOsc.ar(rfreq[i] * freq))
	};

	Splay.ar(b) * 0.1

//	[a, b] * 0.1
//	Pan2.ar(a, b) * 0.1
//	Pan2.ar(a, SinOsc.ar(r)) * Pan2.ar(b, SinOsc.ar(p)) * 0.1

}).play
)








