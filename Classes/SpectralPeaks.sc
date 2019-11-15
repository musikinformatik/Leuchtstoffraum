SpectralPeaks {

	/*
	Die Tabelle ist sortiert nach der Länge der roten Pfeile [beobachtete Übergänge zwischen Energielevels]
	Die dritte Spalte ist das absolute Level deren Ursprungs. Die Einheiten
	sind nur nicht die gleichen. Die erste Spalte ist eine Energiedifferenz
	in MHz, d.h. Delta E/Plancksches Wirkungsquantum, die dritte Spalte
	die absolute Energie in Temperatureinheiten, d.h. E/Boltzmannkonstante.
	*/

	var <>peakFreqs;    // Energiedifferenz in MHz, d.h. Delta E/Plancksches Wirkungsquantum
	var <>transitionFreqs;
	var <>temperatures; // absolute Energie in Temperatureinheiten, d.h. Kelvin = E/Boltzmann-Konstante
	var <>amplitudes;


	var <>baseFreq;
	var <path, <name;
	var <temperatureOrder;

	classvar <>defaultBaseFreq = 12162979000.0; // just using the minimal baseFreq

	*read { |path|
		^super.new.read(path).init
	}

	init {
		temperatureOrder = temperatures.order
	}

	peakIndices { |n, from, to, func|
		^temperatureOrder.keep(n)
	}

	frequencyMaximum {
		^max(peakFreqs.maxItem, transitionFreqs.maxItem)
	}

	frequencyMinimum {
		^min(peakFreqs.minItem, transitionFreqs.minItem)
	}

	peakRatios {
		if(baseFreq.isNil) {
			"--- %: calculating ratios without known base frequency, "
			"using defaultBaseFreq".format(this).postln;
		};
		^peakFreqs * (baseFreq ? defaultBaseFreq).reciprocal
	}

	transitionRatios {
		^transitionFreqs * baseFreq.reciprocal
	}

	read { |argPath|

		if(File.exists(argPath).not) {
			Error("no file named '%'\n".format(argPath)).throw
		};

		File.use(argPath, "r", { |file|
			this.parseData(file.readAllString);
			path = argPath;
			name = argPath.basename.splitext.first.asSymbol;
		})

	}

	parseData { |string|
		var lines = string.split(Char.nl);
		var data, maybeComment;

		lines = lines.reject(_.isEmpty);

		baseFreq = nil;
		maybeComment = lines.first;
		if(maybeComment.find("#").notNil) {
			baseFreq = lines.first.split(Char.space).last.asFloat;
			lines = lines.drop(1);
		};

		data = lines.collect { |line|
			line.separate { |a, b|
				a.isSpace.not and: { b.isSpace }
			}
			.collect { |x|
				x.replace(" ", "").asFloat
			}
		};
		//data.postcs;

		#peakFreqs, transitionFreqs, temperatures, amplitudes = data.flop;

		this.checkData;

		// convert from MHz to Hz
		peakFreqs = peakFreqs * 1e6;
		transitionFreqs = transitionFreqs * 1e6;
		baseFreq !? { baseFreq = baseFreq * 1e6 };

	}

	checkData {
		var func = { |list| var i;
			i = list.indexOf(nil);
			if(i.notNil) { "found nil value in file %\n%\nvalue: %".format(name, list, list[i]).postln };
			i = list.indexOf(0);
			if(i.notNil) { "found 0 value in file %\n%\nvalue: %".format(name, list, list[i]).postln;
			};
		};
		[peakFreqs, transitionFreqs, temperatures, amplitudes].do { |x, i|
			func.(x);
		};
	}

	printOn { |stream|
		stream << this.class.name;
		stream << "(" <<< name << ")"
	}



}