unit randomSync;

interface

    const   nChoicesPerTour = 5; 
            { 
                2 tours *
                    - purpose
                    - mode
                    - destination
                    - nights away
                    - party size
            }

            nToursPerDay = 2;
            nDays = 366;

            nChoicesPerDay = nChoicesPerTour * nToursPerDay;
            nChoicesPerHH = nChoicesPerDay * nDays;

    type rng = record
        randomArray : array[0..nChoicesPerHH-1] of double;
        choiceIdx : integer;

    end;



    function generateRandomDraws(hhID: integer): rng;

    function getNextRandom(generator: rng): double;

implementation
uses defaults;

    var generator: rng;
        dseed, f: integer;

    function generateRandomDraws(
        hhID: integer
    ): rng;
    begin
        {if seed synchronization is on, set randseed to a deterministic value}
        generator.choiceIdx := -1;

        // generate all random numbers at once 

        dseed:= randomSeed + hhID;
        if dseed>=2147483647 then dseed:=dseed - 2147483647;
        randseed:=trunc(dseed);

        {set random number array}

        for f:=0 to nChoicesPerHH-1 do generator.randomArray[f]:=random;
        {for f:=1 to 3 do writeln(randomArray[f]:8:6);  readln;}

        generateRandomDraws := generator;
    end;


{for random seed syncronization}

    function getNextRandom(generator: rng): double;
    begin
        generator.choiceIdx := generator.choiceIdx+1;
        getNextRandom := generator.randomArray[generator.choiceIdx]

    end;


end.