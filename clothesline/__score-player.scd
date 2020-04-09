/*

todo:

move to a class Clothesline
method Clothesline.readCurrentDocument

check INIT-FREE pairing. If there was no FREE, no new INIT?

*/

c.verbose

(
c = Clothesline.new;
c.addAllScores("".resolveRelative);


c.schedAll([
	\test, 1.0, 4,
	\more, 2.5, 5.0,
]);
c.score.postcs;

c.play;
)

c.breakpoints




// schedule events and then jump around
c.sched(\test, 1, 7);
c.sched(\more, 2.5, 10);
c.score;

c.getNextBreakpoint(0);
c.getNextBreakpoint(1);
c.getNextBreakpoint(2.5);
c.getNextBreakpoint(7);
c.getNextBreakpoint(10);

c.play

c.jumpTo(0);
c.jumpTo(2.1);
c.jumpTo(2.6);
c.jumpTo(8);
c.jumpTo(18);
c.jumpTo(2.6);
c.jumpTo(2.1);
c.jumpTo(18);
c.jumpTo(0);



// play individual events
c.playScore(\test);
c.stopScore(\test);

// separately play different parts
e = c.loadScore("test-score.scd".resolveRelative);

fork { e[\INIT].value };
e[\PLAY].value;
e[\STOP].value;
e[\FREE].value;


