/*

todo:

move to a class Clothesline
method Clothesline.readCurrentDocument

check INIT-FREE pairing. If there was no FREE, no new INIT?

*/


(

~score = ();

~loadScore = { |filename, prefix = "//--"|
	var string, error, path, event;

	path = filename.resolveRelative;
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
		var part, to, eol, i, j;

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
		event[part.asSymbol] = string[from..to-1].compile;
	};

	event

};

~addScore = { |path, prefix="-score"|
	var event = ~loadScore.(path);
	var name;
	if(event.notNil) {
		name = path.basename;
		name = name.replace(prefix ++ ".scd", "");
		name = name.asSymbol;
		// keep old scheduling
		// todo: update if running.
		// currently, we can only update stuff that is not live
		if(~score[name].notNil) {
			if(event[\startTime].isNil) { event[\startTime] = ~score[name][\startTime] };
			if(event[\endTime].isNil) { event[\endTime] = ~score[name][\endTime] };
		};
		~score[name] = event;
		"added event '%' from path %".format(name, path).postln;
	}
};

~addAllScores = { |prefix="-score"|
	var paths = "*%.scd".format(prefix).resolveRelative.pathMatch;
	paths.do { |path| ~addScore.(path, prefix) };
};

~eventIsRunning = { |startTime, endTime, atTime|
	startTime.notNil and: { atTime > startTime }
	and: {
		endTime.isNil or: { atTime < endTime }
	}
};

~scheduleScore = { |name, startTime, endTime|
	var isRunning, shouldBeRunning;
	var event = ~score[name];
	if(event.isNil) { Error("event with name '%' not found".format(name)).throw };

	isRunning = ~eventIsRunning.(event[\startTime], event[\endTime], ~currentTime);
	shouldBeRunning = ~eventIsRunning.(startTime, endTime, ~currentTime);

	event[\startTime] = startTime;
	event[\endTime] = endTime;

	if(shouldBeRunning and: { isRunning.not }) { ~playScore.(name) };
	if(isRunning and: { shouldBeRunning.not }) { ~stopScore.(name) };
	event

};


~currentTime = 0;

~fastForwardTo = { |time|
	var relevantEvents, running, willEnd, willStartButNotEnd;
	relevantEvents = ~score;
	relevantEvents = relevantEvents.reject { |e| e[\startTime].isNil }; // not scheduled
	relevantEvents = relevantEvents.reject { |e| e[\startTime] > time }; // haven't begun by the new time
	relevantEvents = relevantEvents.reject { |e| e[\endTime] < ~currentTime }; // have ended now already


	running = relevantEvents.select { |e| e[\startTime] < ~currentTime };
	willEnd = running.select { |e| e[\endTime] < time };
	willStartButNotEnd = relevantEvents.select { |e|
		e[\startTime] > ~currentTime and: { e[\endTime] > time }
	};

	[\willEnd, willEnd.keys].postln;
	[\willStartButNotEnd, willStartButNotEnd.keys].postln;

	willEnd.keysDo { |name| ~stopScore.(name) };
	willStartButNotEnd.keysDo { |name| ~playScore.(name) };

	~currentTime = time;

};

~rewindTo = { |time|
	var relevantEvents, running, shouldEnd, willStartButNotEnd, shouldBeRestarted;
	relevantEvents = ~score;
	relevantEvents = relevantEvents.reject { |e| e[\startTime].isNil }; // not scheduled
	relevantEvents = relevantEvents.reject { |e| e[\startTime] > ~currentTime }; // haven't begun
	relevantEvents = relevantEvents.reject { |e| e[\endTime] < time }; // already ended

	running = relevantEvents.select { |e| e[\startTime] <= ~currentTime };
	shouldEnd = running.select { |e|
		e[\startTime] > time and: { e[\endTime] > ~currentTime }
	};

	shouldBeRestarted = relevantEvents.select { |e|
		e[\endTime] < ~currentTime and: { e[\startTime] <= time }
	};

	[\rewindTo, \shouldBeRestarted, shouldBeRestarted.keys].postln;
	[\rewindTo, \shouldEnd, shouldEnd.keys].postln;

	shouldBeRestarted.keysDo { |name| ~playScore.(name) };
	shouldEnd.keysDo { |name| ~stopScore.(name) };

	~currentTime = time;

};

~jumpTo = { |time|
	if(time != ~currentTime) {
		if(time > ~currentTime) { ~fastForwardTo.(time) } { ~rewindTo.(time) }
	}
};

~getEvents =  { |names|
	var events = Array.new;
	// for now, not so precise.
	names.do { |name|
		var event = ~score[name];
		if(event.isNil) { "event with name '%' not found".format(name).postln };
		events = events.add(event);
	};
	events
};

~playScore = { |...names|
	var events = ~getEvents.(names);

	events.sort { |e| e[\startTime] };
	events.do { |event|
		// for now, not so precise starting points, delayed by sync
		fork {
			event[\INIT].value;
			s.sync;
			event[\PLAY].value;
		}
	};
};

~stopScore = { |...names|
	var events = ~getEvents.(names);
	events.sort { |e| e[\endTime] };
	events.do { |event|
		event[\STOP].value;
		event[\FREE].value;
	}
};


)



// update everything from files
~addAllScores.value;


// schedule events and then jump around
~scheduleScore.(\test, 1, 7);
~scheduleScore.(\more, 2.5, 10);
~jumpTo.(0);
~jumpTo.(2.1);
~jumpTo.(2.6);
~jumpTo.(8);
~jumpTo.(18);
~jumpTo.(2.6);
~jumpTo.(2.1);
~jumpTo.(18);
~jumpTo.(0);



// play individual events
~playScore.(\test);
~stopScore.(\test);

// separately play different parts
e = ~loadScore.("test-score.scd");

e[\INIT].value;
e[\PLAY].value;
e[\STOP].value;
e[\FREE].value;





