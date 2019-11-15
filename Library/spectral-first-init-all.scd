

/////////////////////////////////////////////////////
// only the first time when data files have changed.
// then it is saved in an archive.
//
// calulating the order takes a while ...
// on the long run, we could add a boost primitive
(
"ordering ...".postln;
~spectra.do(_.calculateOrder);
~spectra.do(_.writeOrderFile);
"..done"
);

// normally:
// ~spectra.do(_.readOrder);
/////////////////////////////////////////////////////
