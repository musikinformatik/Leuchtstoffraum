+ SequenceableCollection {

	indexOfNearestMaximum { |index|
		var i1 = this.indexOfNextMaximum(index);
		var i2 = this.indexOfPreviousMaximum(index);
		if(i1.isNil) {
			^if(i2.notNil) { i2 } { nil }
		};
		^if(this[i1] > this[i2]) { i1 } { i2 }
	}

	indexOfNextMaximum { |index|
		var val, prev = this[index];
		if(prev.isNil) { ^nil };
		while {
			index = index + 1;
			val = this[index];
			val.notNil and: { prev < val }
		} {
			prev = val;

		};
		^index - 1
	}

	indexOfPreviousMaximum { |index|
		var val, prev = this[index];
		if(prev.isNil) { ^nil };
		index = index - 1;
		while {
			index = index - 1;
			val = this[index];
			val.notNil and: { prev < val }
		} {
			prev = val;

		};
		^index + 1
	}




}