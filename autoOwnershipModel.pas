unit autoOwnershipModel;

interface
uses household;

    function applyAutoOwnershipModel(
        var hhRecord: hhObject
        ): integer;



implementation
uses defaults, zones, randomSync, fileIO;

    const maxaocoef = 99;

    var alt,
        nmsegs,
        mseg,
        cnum:    integer; 
        
        target,
        expusum,
        totalProbability:    double; 
        
        util,
        expu:array[1..nAOAlts] of double; 
        
        cinf:textFile; 
        
        xstr:string[13]; 

        
        autownCoeffsRead:   boolean=false;
        AOCoef:array[1..2,1..maxaocoef] of single;



    function applyAutoOwnershipModel(
        var hhRecord: hhObject
        ): integer;
    begin
        if (stateToReadCarOwnershipFromHHFile<>999) and (stateToReadCarOwnershipFromHHFile<>zoneState[hhRecord.hhZoneIndex]) then begin

        if not(autownCoeffsRead) then begin
            if UseSegmentedModels then nmsegs:=2 else nmsegs:=1;
            {read coefficients}
            for mseg:=1 to nmsegs do begin
            resetTextFile(cinf,setFileName(CoefficientDirectoryName,aocoeffile[mseg]));
                repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
                repeat
                read(cinf,cnum);
                {write(purp,' ',cnum); readln;}
                if (cnum>=0) and (cnum<=maxaocoef) then readln(cinf,xstr,AOCoef[mseg,cnum]) else readln(cinf);
                until cnum<0;
                close(cinf);
                autownCoeffsRead:=true;
            end;
        end;

        mseg:=hhRecord.hhModelSegment;
        expusum:=0;
        for alt:=1 to nAOAlts do begin
            if alt=3 then util[alt]:=0 else begin
            util[alt]:=0
                + AOCoef[mseg,10*alt+0] {constant}
                + AOCoef[mseg,10*alt+1]*hhRecord.hh1Adult
                + AOCoef[mseg,10*alt+2]*hhRecord.hh3Adults
                + AOCoef[mseg,10*alt+3]*hhRecord.hh4PlusAdults
                + AOCoef[mseg,10*alt+4]*hhRecord.hhWorkerRatio2
                + AOCoef[mseg,10*alt+5]*hhRecord.hhHasKids
                + AOCoef[mseg,10*alt+6]*hhRecord.hhHeadOver65
                + AOCoef[mseg,10*alt+7]*hhRecord.hhHeadUnder35
                + AOCoef[mseg,10*alt+8]*hhRecord.hhLogDensity
                + AOCoef[mseg,10*alt+9]*hhRecord.hhLogIncome;
            end;
            expu[alt]:=exp(util[alt]);
            expusum:=expusum+expu[alt];
        end;
        target:=random*expusum;
        alt:=0;
        repeat
            alt:=alt+1;
            target:=target-expu[alt];
        until (target<0) or (alt>=nAOAlts);

        hhRecord.hhVehicles:=alt-1;
        end;
        hhRecord.hhHas0Vehicles:=integer(hhRecord.hhVehicles=0);
        // hhHas1Vehicle:=integer(hhRecord.hhVehicles=1);
        // hhHas2Vehicles:=integer(hhRecord.hhVehicles=2);
        // hhHas3PlusVehicles:=integer(hhRecord.hhVehicles>=3);
        hhRecord.hhHasCarCompetition:=integer((hhRecord.hhVehicles>0) and (hhRecord.hhVehicles<hhRecord.hhAdults));

        // // add additional choices if random sync is turned on
        // if useRandomNumberSynchronization then begin
        //     setLength(randomArray,nRandomArray + hhRecord.hhVehicles);
        //     drawIdx := nRandomArray;
        //     repeat
        //     randomArray[drawIdx] := random;
        //     drawIdx := drawIdx + 1;
        //     until drawIdx = nRandomArray + hhRecord.hhVehicles;
        //     nRandomArray := nRandomArray + hhRecord.hhVehicles;
        // end;



        if hhRecord.hhVehicles=0 then hhRecord.hhModeDestseg:=hhRecord.hhIncseg else 
        begin
            if hhRecord.hhVehicles<hhRecord.hhAdults 
                then hhRecord.hhModeDestseg:=hhRecord.hhIncseg+5 
            else hhRecord.hhModeDestseg:=hhRecord.hhIncseg+10;

        end;

        hhSimulated[hhRecord.hhIncseg]:=hhSimulated[hhRecord.hhIncseg]+ hhRecord.hhExpOut;
        hhVehiclePred[hhRecord.hhIncseg,hhRecord.hhVehicles+1]:=hhVehiclePred[hhRecord.hhIncseg,hhRecord.hhVehicles+1]+ hhRecord.hhExpOut;
    end;


end.