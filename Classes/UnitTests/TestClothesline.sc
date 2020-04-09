

TestClothesline : UnitTest {

	classvar <>environment, <>current;

	scorepath {
		^this.class.filenameSymbol.asString.dirname +/+ "test-clothesline/"
	}

	setUp {
		environment = Environment.new;
		environment.push;
		~xXX = 9;
		current = Clothesline.new;
		current.addAllScores(this.scorepath);
	}

	tearDown {
		current = nil;
		environment.pop;
		environment = nil;
	}

	test_load {
		this.assert(current.score['test-01'].notNil, "test-01-score.scd should have loaded");
		this.assert(current.score['test-02'].notNil, "test-02-score.scd should have loaded");
	}


	test_jump_play {

		current.sched('test-01', 1, 3);
		current.sched('test-02', 2, 4);

		current.jumpTo(0);
		current.jumpTo(1.5);


		this.assert(~test1_initialized == true, "after having passed INIT, the init code should have been called");
		this.assert(~test2_initialized != true, "before having passed INIT, the init code should not have been called");
		this.assert(~test1_playing == true, "after having passed PLAY, the play code should have been called");

		current.jumpTo(3.5);

		this.assert(~test1_playing != true, "after having passed STOP, the stop code should have been called");
		this.assert(~test2_playing == true, "after having passed PLAY, the play code should have been called");

	}

	test_jump_forward {

		current.sched('test-01', 1, 3);
		current.sched('test-02', 2, 4);

		current.jumpTo(0);
		current.jumpTo(1.5);
		current.jumpTo(3.5);

	//	0.2.wait;
		this.assert(~test1_playing != true, "when jumping after the end time, STOP should have been called");
		this.assert(~test2_playing == true, "after having passed PLAY, the play code should have been called");

	}

	test_jump_backward {

		current.sched('test-01', 1, 3);
		current.sched('test-02', 2, 4);

		current.jumpTo(0);
		current.jumpTo(3);
		current.jumpTo(0);
		//	0.2.wait;

		this.assert(~test1_playing != true, "when jumping back before play time, STOP should have been called");
		this.assert(~test2_playing != true, "when jumping back before play time, STOP should have been called");

	}

	test_breakpoints {
		var b;
		current.sched('test-01', 1.12, 3);
		current.sched('test-02', 100, 400);
		current.sched('test-02', 1.12, 4);
		b = Routine {
			var t = 0;
			0.yield;
			while {
				t = current.getNextBreakpoint(t);
				t.notNil
			} {
				t.yield;
			}
		}.all;
		this.assertEquals(b, [0, 1.12, 3, 4]);
	}

}