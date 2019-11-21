
/*

Reading all modeled molecule data
based on the measured HEXOS spectrum



The order data should be in a folder with the ending _order
if not, you can generate it
loadRelative("init-all.scd");
But this takes a while!

*/

/*
Ich habe gemerkt, dass am oberen Ende des Bands 6a
auch eine kleine Lücke ist, so dass es einen Bereich für
Band 1-5 gibt (480-1250GHz), dann Band 6a (1420-1480GHz) und
Band 6b-7 (bis 1900 GHz). Insbesondere im großen Bereich (1-5)
sieht man die Harmonien der einzelnen Moleküle recht gut.
*/

/*

for now, we mainly use the lower 5 bands

*/


var paths;

// you can override this path by setting ~datapath before running this
~leuchtstoffraum_datapath = ~leuchtstoffraum_datapath ?? { "../data".resolveRelative };

// read modeled full molecule spectra, plus measured full spectrum
~spectra = IdentityDictionary.new;

paths = (~leuchtstoffraum_datapath +/+ "/fits/*.fits").pathMatch;
if(paths.isEmpty) {
	Error("Trying to read FITS: No /fits/ files found in path: %".format(~datapath)).throw
};
~readData = { |path|
	var spectrum = WideSpectrum.read(path);
	spectrum.readOrder; // we keep the order in files
	~spectra[spectrum.name] = spectrum;
	spectrum.name.postcs;
};

paths.do { |path| ~readData.(path) };


~allNames = ~spectra.keys.as(Array).sort;
~fullspectrum = ~spectra['hifi-bands1-5_allmols']; // the fits spectrum of all molecules
~fullspectrumRaw = ~spectra['hifi-bands1-5_ORION_KL(H5)_resampled']; // the  spectrum measured by Herschel
~fullspectrumRawSmooth = ~spectra['hifi-bands1-5_5_ORION_KL(H5)_smooth'];
~fullspectrumSmooth = ~spectra['hifi-bands1-5_5_allmols_smooth'];

~band15 = ~spectra.select { |x| x.name.asString.find("bands1-5").notNil }; // lower 5 bands
~band6a = ~spectra.select { |x| x.name.asString.find("band6a").notNil }; // middle
~band67 = ~spectra.select { |x| x.name.asString.find("bands6b-7").notNil }; // high two bands
~minFrequency = ~spectra['hifi-bands1-5_allmols'].frequencyMinimum; // lowest frequency measured
~maxFrequency = ~spectra['hifi-bands1-5_allmols'].frequencyMaximum; // highest frequency measured in lower bands
~maxFrequency6a = ~spectra['hifi-bands6b-7_allmols'].frequencyMaximum; // highest frequency measured

~globalFrequencyScaler = ~minFrequency.nextPowerOfTwo.reciprocal;
//~globalFrequencyScaler = 2 ** (~maxFrequency6a.log2 - 16000.log2).ceil.neg;

"==========================\n"
"~globalFrequencyScaler = %.\n"
"Ratio for ~minFrequency = %\n"
"==========================\n"
.format(
	~globalFrequencyScaler,
	~globalFrequencyScaler * ~minFrequency
).postln;
