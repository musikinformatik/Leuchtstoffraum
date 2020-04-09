

Clothesline {
	var <>score;
	var <currentTime;
	var <>verbose = true;
	var <breakpoints;

	*new {
		^super.new.init
	}

	init {
		score = IdentityDictionary.new;
		currentTime = 0;
	}

	loadScore { |path, prefix = "//--"|
		var string, error, event;

		string = File.readAllString(path);

		error = { |errorString, i|
			var lineNumber;
			errorString = "%\nin score file with the path:\n%".format(errorString, path);
			if(i.notNil) {
				lineNumber = string[..i].count { |x| x == Char.nl } + 1;
				errorString = errorString ++ "\nLine Number: " ++  lineNumber
			};
			Error(errorString).throw
		};

		event = ();

		string.findAll(prefix).do { |from|
			var part, to, eol, i, j, code;

			eol = string.find("\n", offset: from);
			to = string.find("//-- ", offset: from+1) ?? { string.size };

			if(eol.isNil) { error.("part '%', add a newline at least...".format(string[from..]), from) };
			part = string[from + prefix.size..eol];
			i = part.detectIndex { |x| x.isAlpha };
			if(i.isNil) { error.("no part name: '%'".format(part), from) };
			part = part[i..];
			i = part.detectIndex { |x| x.isAlphaNum.not };
			if(i.isNil) { error.("part '%', add at least one newline".format(part), from) };
			part = part[..i-1];
			code = string[from..to-1];
			event[part.asSymbol] = code.compile;
			if(verbose) {
				//		code.postln;
			};
		};

		^event
	}

	addScore { |path, prefix="-score"|
		var event = this.loadScore(path);
		var name, prevEvent, hotSwap = false;
		if(event.notNil) {
			name = path.basename;
			name = name.replace(prefix ++ ".scd", "");
			name = name.asSymbol;

			prevEvent = score[name];

			// maybe it would be better to have two separate collections,
			// one for the score elements and the other of teh score itself

			if(prevEvent.notNil) {
				hotSwap = this.eventIsRunning(prevEvent, currentTime);
				if(hotSwap) { this.stopScore([name]) };
				if(event[\startTime].isNil) { event[\startTime] = ~score[name][\startTime] };
				if(event[\endTime].isNil) { event[\endTime] = ~score[name][\endTime] };
			};
			score[name] = event;
			if(hotSwap) {
				this.updateBreakpoints;
				this.playScore([name])
			};

			if(verbose) { "added event '%' from path %".format(name, path).postln };
		}
	}

	addAllScores { |path, prefix = "-score"|
		var paths;
		path =  "%*%.scd".format(path, prefix);
		paths = path.pathMatch;
		if(paths.isEmpty) { "No files found in this path: \n'%'".format(path.cs).warn };
		paths.do { |path| this.addScore(path, prefix) };
	}


	// analysis

	timeInRange { |atTime, startTime, endTime|
		^startTime.notNil and: { atTime > startTime }
		and: {
			endTime.isNil or: { atTime < endTime }
		}
	}

	eventIsRunning { |event, time|
		^this.timeInRange(time, event[\startTime], event[\endTime])
	}

	getRunningEvents { |time|
		^score.select(_.eventIsRunning(time))
	}

	getScheduledEvents {
		^score.select { |e| e[\startTime].notNil }
	}


	// breakpoints

	getNextBreakpoint { |time|
		var i;
		^breakpoints !? {
			i = breakpoints.indexOfGreaterThan(time);
			i !? { breakpoints[i] }
		}
	}

	getPreviousBreakpoint { |time|
		var i;
		^breakpoints !? {
			i = breakpoints.indexOfGreaterThan(time);
			i !? { if(i > 0) { breakpoints[i - 1] } }
		}
	}

	updateBreakpoints {
		var b = IdentitySet.new;
		[\startTime, \endTime].do { |key|
			score.do { |event|
				var val = event[key];
				val !? { b.add(val) };
			}
		};
		breakpoints = b.as(Array).sort
	}

	// scheduling

	play { |startTime = 0, endTime = inf, clock, timeStep = 0.5| // todo: do not allow several parallel ones.

		^Task {
			var time = startTime;
			var next, dt;
			while {
				next = this.getNextBreakpoint(time);
				[\next, next].postln;
				next.notNil and: { time < endTime }
			} {
				dt = if(next - time < timeStep) { next - time } { timeStep };
				time = time + dt;
				this.jumpTo(time);
				dt.wait;
			}
		}.play(clock ? SystemClock)

	}

	sched { |name, startTime, endTime|
		var isRunning, shouldBeRunning;
		var event = score[name];
		if(event.isNil) { Error("event with name '%' not found".format(name)).throw };

		isRunning = this.eventIsRunning(event, currentTime);
		shouldBeRunning = this.timeInRange(currentTime, startTime, endTime);

		event[\startTime] = startTime;
		event[\endTime] = endTime;

		if(shouldBeRunning and: { isRunning.not }) { this.playScore(name) };
		if(isRunning and: { shouldBeRunning.not }) { this.stopScore(name) };

		this.updateBreakpoints;

		^event

	}

	// navigation

	jumpTo { |time|
		if(time != currentTime) {
			if(time > currentTime) { this.fastForwardTo(time) } { this.rewindTo(time) }
		}
	}

	fastForwardTo { |time|
		var relevantEvents, running, willEnd, willStartButNotEnd;
		relevantEvents = score;
		relevantEvents = relevantEvents.reject { |e| e[\startTime].isNil }; // not scheduled
		relevantEvents = relevantEvents.reject { |e| e[\startTime] > time }; // haven't begun by the new time
		relevantEvents = relevantEvents.reject { |e| e[\endTime] < currentTime }; // have ended now already


		running = relevantEvents.select { |e| e[\startTime] < currentTime };
		willEnd = running.select { |e| e[\endTime] < time };
		willStartButNotEnd = relevantEvents.select { |e|
			e[\startTime] > currentTime and: { e[\endTime] > time }
		};

		if(verbose) {
			[\willEnd, willEnd.keys].postln;
			[\willStartButNotEnd, willStartButNotEnd.keys].postln;
		};

		willEnd.keysDo { |name| this.stopScore(name) };
		willStartButNotEnd.keysDo { |name| this.playScore(name) };

		currentTime = time;

	}


	rewindTo { |time|
		var relevantEvents, running, shouldEnd, willStartButNotEnd, shouldBeRestarted;
		relevantEvents = score;
		relevantEvents = relevantEvents.reject { |e| e[\startTime].isNil }; // not scheduled
		relevantEvents = relevantEvents.reject { |e| e[\startTime] > currentTime }; // haven't begun
		relevantEvents = relevantEvents.reject { |e| e[\endTime] < time }; // already ended

		running = relevantEvents.select { |e| e[\startTime] <= currentTime };
		shouldEnd = running.select { |e|
			e[\startTime] > time and: { e[\endTime] > currentTime }
		};

		shouldBeRestarted = relevantEvents.select { |e|
			e[\endTime] < currentTime and: { e[\startTime] <= time }
		};

		if(verbose) {
			[\rewindTo, \shouldBeRestarted, shouldBeRestarted.keys].postln;
			[\rewindTo, \shouldEnd, shouldEnd.keys].postln;
		};

		shouldBeRestarted.keysDo { |name| this.playScore(name) };
		shouldEnd.keysDo { |name| this.stopScore(name) };

		currentTime = time;

	}


	getEvents { |names|
		var events = Array.new;
		// for now, not so precise.
		names.do { |name|
			var event = score[name];
			if(event.isNil) { "event with name '%' not found".format(name).postln };
			events = events.add(event);
		};
		^events
	}

	playScore { |...names|
		var events = this.getEvents(names);

		events.sort { |e| e[\startTime] };
		events.do { |event|
			forkIfNeeded {
				event[\INIT].value;
				event[\PLAY].value;
			}
		}
	}

	stopScore { |...names|
		var events = this.getEvents(names);
		events.sort { |e| e[\endTime] };
		events.do { |event|
			event[\STOP].value;
			event[\FREE].value;
		}
	}

}