

/*

File Reading: this is a FITS file
that uses 32bit Floats
it begins with a 5760 byte header
see below WideSpectrumHeader

*/




WideSpectrum {

	var <amplitudes, <>order;
	var <header, <name, <path;
	var <>frequencyOffset, <>frequencyStep, <>frequencyIndexOffset;

	*read { |path|
		^super.new.read(path)
	}

	signal {
		this.deprecated(thisMethod, \amplitudes)
	}

	// return a new WideSpectrum from a range of frequencies

	subBand { |freq0, freq1|
		var i0 = this.indexForFrequency(freq0);
		var i1 = this.indexForFrequency(freq1);
		^this.subBandFromRange(i0, i1)
	}

	// return a new WideSpectrum from a range of indices

	subBandFromRange { |i0, i1|
		var spectrum = this.class.new;
		if(i0 < 0 or: { i1 > amplitudes.lastIndex }) {
			Error("index out of range: % ... %".format(i0, i1)).throw
		};
		spectrum.amplitudes = amplitudes[i0..i1];
		order !? {
			// choose the faster method
			if(absdif(i0, i1) > 10000) {
				spectrum.order = order.select { |x| x.inclusivelyBetween(i0, i1) }
			} {
				spectrum.calculateOrder
			}
		};
		spectrum.frequencyOffset = frequencyOffset;
		spectrum.frequencyStep = frequencyStep;
		spectrum.frequencyIndexOffset = frequencyIndexOffset;
		^spectrum
	}

	performBinaryOpOnAmplitudes { |selector, otherSpectrum|
		var spectrum = this.class.new;
		if(otherSpectrum.size != this.size) {
			Error("spectra do not match in size").throw
		};
		if(otherSpectrum.frequencyMinimum != this.frequencyMinimum
			or: { otherSpectrum.frequencyMaximum != this.frequencyMaximum }
			or: { otherSpectrum.frequencyStep != this.frequencyStep }
		) {
			Error("spectra do not match in frequency data").throw
		};

		spectrum.amplitudes = this.amplitudes.perform(selector, otherSpectrum.amplitudes);
		spectrum.frequencyOffset = frequencyOffset;
		spectrum.frequencyStep = frequencyStep;
		spectrum.frequencyIndexOffset = frequencyIndexOffset;
		^spectrum
	}

	+ { |spectrum|
		^this.performBinaryOpOnAmplitudes('+', spectrum)
	}

	- { |spectrum|
		^this.performBinaryOpOnAmplitudes('-', spectrum)
	}


	// basic meta information

	size {
		^amplitudes.size
	}

	frequencyMinimum {
		^this.frequencyAt(0)
	}

	frequencyMaximum {
		^this.frequencyAt(this.size - 1)
	}

	amplitudeAt { |index|
		^amplitudes[index]
	}

	frequencyAt { |index|
		^(index - frequencyIndexOffset) * frequencyStep + frequencyOffset
	}

	amplitudeAtFrequency { |freq|
		var index = this.indexForFrequency(freq);
		^amplitudes[index]
	}

	indexForFrequency { |freq|
		var i = (freq - frequencyOffset) / frequencyStep + frequencyIndexOffset;
		^i.round.asInteger
	}

	// return the index of the nearest amplitude maximum

	indexForFrequencyNextMaximum { |freq|
		var i = this.indexForFrequency(freq);
		^amplitudes.indexOfNearestMaximum(i)
	}

	// how many steps (indices) is the given frequency away from the next amplitude maximum?

	deviationFromNextMaximum { |freq|
		var i = this.indexForFrequency(freq);
		var j = amplitudes.indexOfNearestMaximum(i);
		if(i.isNil or: { j.isNil }) { ^nil };
		^j - i
	}

	// given a frequency in the spectrum, return n amplitudes around it [-n/2 ... +n/2]

	amplitudesAroundFrequency { |freq, n|
		var i0, i1, range, index, max;
		max = amplitudes.lastIndex;
		index = this.indexForFrequency(freq);
		if(index.inclusivelyBetween(0, amplitudes.lastIndex).not) {
			"no data for this frequency (%)".format(freq);
			^nil
		};
		range = n div: 2;
		i0 = index - range;
		i1 = index + range;
		if(n.even) { i1 = i1 + 1 };
		i0 = i0.clip(0, max);
		i1 = i1.clip(0, max);
		^amplitudes[i0..i1]
	}


	// frequency ration between two indices of the amplitudes

	ratioBetween { |...indices|
		var basis = this.frequencyAt(indices[0]);
		^this.frequencyAt(indices[1..]) * basis.reciprocal
	}


	// return the indices of the n strongest peaks between from and to, selected by func

	peakIndices { |n, from, to, func|
		var newOrder = order.copy;
		if(newOrder.isNil) { Error("Cannot calculate peaks. Call this.calcOrder first").throw };
		if(from.notNil) { newOrder = newOrder.select { |x| x >= from } };
		if(to.notNil) { newOrder = newOrder.select { |x| x <= to } };
		if(func.notNil) { newOrder = func.(newOrder, this) };
		if(n.notNil) { newOrder = newOrder.keep(n.asInteger) };
		^newOrder.as(Array)
	}


	// n strongest peaks, but separate the indices into contiguous clusters (subarrays)

	peakClusters { |n, from, to, func|
		var i = this.peakIndices(n, from, to, func);
		^i.sort.separate { |a, b| absdif(a, b) > 1 };
	}


	// n strongest peaks, but separate the indices into contiguous clusters of a given size

	peakClustersN { |n, numPeaksPerCluster, from, to, func|
		^this.peakClusters(n, from, to, func).collect { |array|
			array.sort { |x, y| amplitudes[x] <= amplitudes[y] }.keep(numPeaksPerCluster)
		}
	}

	// return the amplitudes of the n strongest peaks between from and to, selected by func

	peakAmps { |n, from, to, func|
		^this.amplitudeAt(this.peakIndices(n, from, to, func))
	}

	// return the frequencies of the n strongest peaks between from and to, selected by func

	peakFreqs { |n, from, to, func|
		^this.frequencyAt(this.peakIndices(n, from, to, func))
	}


	/*

	Display

	*/


	printOn { |stream|
		stream << this.class.name;
		if(name.isNil) { stream << ".new" } { stream << "(" <<< name << ")" }
	}


	/*

	File Reading

	*/


	read { |argPath, headerSize = 5760|

		if(File.exists(argPath).not) {
			Error("no file named '%'\n".format(argPath)).throw
		};

		File.use(argPath, "r", { |file|
			this.readHeader(file, headerSize);
			this.readData(file, file.length - headerSize);
			path = argPath;
			name = argPath.basename.splitext.first.asSymbol;
		})
	}

	readData { |file, size|
		var data = DoubleArray.newClear(size div: 8);
		file.read(data);
		amplitudes = data.as(Array);
	}


	readHeader { |file, headerSize|
		header = WideSpectrumHeader.new;
		header.read(file, headerSize);
		frequencyOffset = header.frequencyOffset;
		frequencyStep = header.frequencyStep;
		frequencyIndexOffset = header.frequencyIndexOffset;
	}

	calculateOrder {
		order = amplitudes.order { |a, b| a >= b }
	}

	readOrder {
		var data = this.readOrderFile;
		if(data.notNil) {
			order = data
		}
	}

	getOrderPath {
		var folder = path.dirname ++ "_" ++ "orders";
		if(File.exists(folder).not) { folder.mkdir };
		^folder +/+ path.basename.splitext[0] ++ "_order.txt"
	}

	writeOrderFile { |argPath|
		var p, data;
		if(order.isNil) {
			("Cannot write order. Call this.calcOrder first").warn
		} {
			p = argPath ?? { this.getOrderPath };
			data = Int32Array.newFrom(order);
			File.use(p, "w", { |f| f.write(data) })
		}
	}

	readOrderFile { |argPath|
		var p, data;
		p = argPath ?? { this.getOrderPath };
		if(File.exists(p).not) {
			("Cannot read order. File not found: %".format(p)).warn
		} {
			File.use(p, "r", { |f|
				data = Int32Array.newClear(f.length);
				f.read(data)
			});
		}
		^data
	}


	infoString {
		^(
			"\n_________________________________________\n\n"
			"\tDataset: %\n"
			"\tSize of Signal: %\n"
			"\tMaximum: %\n"
			"\tMinimum: %\n"
			"\tfreqMinimum: % GHz\n"
			"\tfreqMaximum: % GHz\n"
			"\tstep: % MHz\n"
			"\n_________________________________________\n"
			"\n\n%\n"

		).format(
			name,
			amplitudes.size,
			amplitudes.maxItem,
			amplitudes.minItem,
			frequencyOffset * 1e-9,
			this.frequencyMaximum * 1e-9,
			frequencyStep * 1e-6,
			header !? { header.infoString } ? ""
		)

	}


}




WideSpectrumHeader {

	var <dict;
	var <path, <rawHeaderLines, <>name, <comments;

	init {
		dict = IdentityDictionary.new;
		comments = IdentityDictionary.new;
	}

	frequencyOffset {
		^dict[\CRVAL1]
	}

	frequencyStep {
		^dict[\CDELT1]
	}

	frequencyIndexOffset {
		^dict[\CRPIX1]
	}

	read { |file, headerSize|
		var string, count;
		this.init;
		count = 0;
		string = String.newClear(80);
		while {
			count = count + 80;
			count <= headerSize
		} {
			file.read(string);
			this.addHeaderElement(string);
		};
	}

	addHeaderElement { |chunk|
		var parameterName, value, testFloat, isNumber, commentIndex;

		parameterName = chunk[0..7].reject(_.isSpace);

		//chunk[8..9]; // =
		value = chunk[10..38].reject(_.isSpace);

		// this is a hack for checking types from syntax
		testFloat = value.asFloat;
		isNumber = (value == "0.000000000000E+000") or: { testFloat != 0 } and: { testFloat.notNil };

		if(isNumber) {
			if(value.includes($.)) {
				value = value.asFloat
			} {
				value = value.asInteger
			}
		};

		commentIndex = chunk.indexOf($/); // delimiter. I hope no slash is allowed in numbers :-/

		rawHeaderLines = rawHeaderLines.add(chunk.copy);
		parameterName = parameterName.asSymbol;
		commentIndex !? { comments.put(parameterName, chunk[commentIndex+2..]) };
		dict.put(parameterName, value);
	}


	infoString {
		^rawHeaderLines.collect("\t" ++ _).join("\n")
	}

	/*

	// old integer format method
	// that uses 32bit Integers and adds a BZERO and BSCALE conversion factor
	// it began with a 4400 byte header

	readIntegers { |file, size|
		var data = Int32Array.newClear(size);
		var bzero = dict[\BZERO] ? 0;
		var bscale = dict[\BSCALE] ? 1;
		file.read(data);
		amplitudes = data.as(Signal);
		amplitudes = amplitudes * bscale + bzero;
		amplitudes = data.as(Array);
	}
	*/

}
