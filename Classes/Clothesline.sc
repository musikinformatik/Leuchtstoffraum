

Clothesline {
	var <>score;
	var <currentTime;
	var <>verbose = true;
	var <breakpoints;
	var <>player;
	var <>prefix="-score";

	*new {
		^super.new.init
	}

	init {
		score = IdentityDictionary.new;
		currentTime = 0;
	}

	loadScore { |path|
		var delimiter = "//--";
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

		event = (path: path);

		string.findAll(delimiter).do { |from|
			var part, to, eol, i, j, code;

			eol = string.find("\n", offset: from);
			to = string.find(delimiter, offset: from+1) ?? { string.size };

			if(eol.isNil) { error.("part '%', add a newline at least...".format(string[from..]), from) };
			part = string[from + delimiter.size..eol];
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

	addScore { |path|
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
				if(event[\startTime].isNil) { event[\startTime] = score[name][\startTime] };
				if(event[\endTime].isNil) { event[\endTime] = score[name][\endTime] };
			};
			score[name] = event;
			if(hotSwap) {
				this.updateBreakpoints;
				this.playScore([name])
			};

			if(verbose) { "added event '%' from path %".format(name, path).postln };
		}
	}

	addAllScores { |path|
		var paths;
		path =  "%*%.scd".format(path, prefix);
		paths = path.pathMatch;
		if(paths.isEmpty) { "No files found in this path: \n'%'".format(path.cs).warn };
		paths.do { |path| this.addScore(path) };
	}

	updateFromFiles {
		score.do { |event| this.addScore(event[\path]) }
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

	play { |startTime, endTime = inf, clock, timeStep = 0.1| // todo: do not allow several parallel ones.
		player.stop;
		this.updateFromFiles;
		player = Task {
			var time = startTime ? currentTime;
			var next, dt;
			while {
				next = this.getNextBreakpoint(time);
				next.notNil and: { time < endTime }
			} {
				dt = min(next - time, timeStep);
				time = time + dt;
				this.jumpTo(time);
				dt.wait;
			};

			this.jumpTo(inf); // for now
		}.play(clock ? SystemClock);
		^player

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

	schedAll { |triples|
		triples.clump(3).do(this.sched(*_))
	}

	// navigation

	jumpTo { |time|
		if(time != currentTime) {
			if(time > currentTime) { this.fastForwardTo(time) } { this.rewindTo(time) }
		}
	}

	fastForwardTo { |time|
		var relevantEvents, running, shouldEnd, shouldStart;
		relevantEvents = score;
		relevantEvents = relevantEvents.reject { |e| e[\startTime].isNil }; // not scheduled
		relevantEvents = relevantEvents.reject { |e| e[\startTime] > time }; // haven't begun by the new time
		relevantEvents = relevantEvents.reject { |e| e[\endTime] < currentTime }; // have ended now already


		running = relevantEvents.select { |e| e[\startTime] < currentTime };
		shouldEnd = running.select { |e| e[\endTime] < time };
		shouldStart = relevantEvents.select { |e|
			e[\startTime] > currentTime and: { e[\endTime] > time }
		};

		if(verbose) {

			if(shouldEnd.keys.notEmpty) {
				"stopping: %".format(shouldEnd.keys.asArray.sort).postln
			};
			if(shouldStart.keys.notEmpty) {
				"starting: %".format(shouldStart.keys.asArray.sort).postln
			};
		};

		shouldEnd.keysDo { |name| this.stopScore(name) };
		shouldStart.keysDo { |name| this.playScore(name) };

		currentTime = time;

	}


	rewindTo { |time|
		var relevantEvents, running, shouldEnd, shouldBeRestarted;
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
			if(shouldEnd.keys.notEmpty) {
				"stopping: %".format(shouldEnd.keys.asArray.sort).postln
			};
			if(shouldBeRestarted.keys.notEmpty) {
				"starting: %".format(shouldBeRestarted.keys.asArray.sort).postln
			};
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