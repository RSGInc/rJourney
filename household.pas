unit household;

interface
uses defaults, randomSync;

    type hhObject = record
            hhID,
            hhZone,
            hhSize,
            hhWorkers,
            hhNonWkrs,
            hhHasKids,
            hhHeadAge,
            hhIncome,
            hhState,
            hhZoneIndex, 
            hhRural, 
            {hhSuburb, 
            hhUrban,} 
            hhHeadUnder35, 
            hhHeadOver65, 
            hhAdults, 
            hh1Adult, 
            hh3Adults, 
            hh4PlusAdults,
            hhVehicles,
            {hhHas1Vehicle, 
            hhHas2Vehicles, 
            hhHas3PlusVehicles,} 
            hhHas0Vehicles, 
            hhHasCarCompetition,
            hhIncSeg,
            hhModeDestSeg,
            hhModelSegment,

            hhNumVans, 
            hhNumSUVs, 
            hhNumPickups, 
            hhNumMotorcycles, 
            hhNumHybrids, 
            hhNumEVs, 
            hhNumBEVs: integer;
            
            hhExpFactor,
            hhExpOut,
            hhLogIncome, 
            hhZoneDensity, 
            hhLogDensity, 
            // hhWorkerRatio, 
            hhWorkerRatio2: single;
            
            hhTract, 
            hhAvgWorkDist, 
            hhTotalWorkDist:double;

            vehiclesChosen: boolean;

            hhTours:array[1..nTourPurposes] of integer;
            hhVehicleBody: array[0..nAOAlts-1] of integer;
            hhVehicleFuel: array[0..nAOAlts-1] of integer;
            hhVehicleAge: array[0..nAOAlts-1] of integer;
            hhVehicleAlt: array[0..nAOAlts-1] of integer;
        
            generator: rng;
        end;
    
    function loadNextHouseholdRecord(
        var lastRecord: boolean;
            
        var hhInFile: text;
            
            scenarioIncomeChange: single;

            sample1inx,
            stateToUseSeparateCoefficientFiles,
            stateToReadCarOwnershipFromHHFile: integer;

            zoneIndex: array of integer

            ): hhObject;

    function writeHouseholdDayRecord(
        hhRecord: hhObject;
        outDelim: string;
        var hhDayOutFile: textFile
        ): integer;

    function writeHouseholdVehicleRecord(
            hhID: integer;
            hhVehicles: integer;

            hhVehicleBody: array of integer;
            hhVehicleFuel: array of integer;
            hhVehicleAge: array of integer;
            hhVehicleAlt: array of integer;
            var hhVehicleOutFile: textFile

        ): integer;
    
    function openHouseholdDayOutputFile(
        filename:string;
        var hhDayOutFile: textFile
        ): integer;

    function openHouseholdVehicleOutputFile(
        filename:string;
        var hhVehicleOutFile: textFile
        ): integer;
        
    function openHouseholdInputFile(
        filename:string;
        var hhInFile: textFile
        ): integer;

    var 
        hhDayOutFile,hhVehicleOutFile:text;
        hhSimulated:array[0..hhIncCats] of double;
        hhVehiclePred:array[0..hhIncCats,1..hhVehCats] of double;
        hhToursPred:array[0..hhIncCats,1..nTourPurposes] of double;


implementation
uses fileIO, logicalFuncs, zones;

    var hhRecord: hhObject;
        purpose: integer;


    function loadNextHouseholdRecord (
        var lastRecord: boolean;

        var hhInFile: text;

            scenarioIncomeChange: single;

            sample1inx,
            stateToUseSeparateCoefficientFiles,
            stateToReadCarOwnershipFromHHFile: integer;


            zoneIndex: array of integer
            ): hhObject;
    begin
    repeat
        readln(hhInFile, 
            hhRecord.hhId, 
            hhRecord.hhTract,
            hhRecord.hhZone,
            hhRecord.hhSize,
            hhRecord.hhWorkers,
            hhRecord.hhNonWkrs,
            hhRecord.hhHasKids,
            hhRecord.hhHeadAge,
            hhRecord.hhIncome,
            hhRecord.hhExpFactor,
            hhRecord.hhVehicles,
            hhRecord.hhAvgWorkDist,
            hhRecord.hhTotalWorkDist);

        hhRecord.vehiclesChosen := false;
        // readln(hhInFile);

        lastRecord:=eof(hhInFile);

    until (lastRecord) or (hhRecord.hhHeadAge>0);

    {transformation variables}
    hhRecord.hhIncome:=round(hhRecord.hhIncome*(1.0+scenarioIncomeChange/100.0));
    hhRecord.hhLogIncome:=ln(max(1.0,hhRecord.hhIncome/1000.0));
    hhRecord.hhZoneIndex:= zoneIndex[hhRecord.hhZone];
    hhRecord.hhZoneDensity:=totDens[hhRecord.hhZoneIndex];
    hhRecord.hhLogDensity:=zLogDens[hhRecord.hhZoneIndex];
    hhRecord.hhRural:= zRural[hhRecord.hhZoneIndex];
    hhRecord.hhState:= zoneState[hhRecord.hhZoneIndex];
    // hhSuburb := zSuburb[hZoneIndex];
    // hhUrban:= zUrban[hhZoneIndex];
    hhRecord.hhAdults:=hhRecord.hhWorkers+hhRecord.hhNonWkrs;
    if (hhRecord.hhAdults>hhRecord.hhSize) then hhRecord.hhAdults:=hhRecord.hhSize;
    if hhRecord.hhAdults<1 then hhRecord.hhAdults:=1;
    hhRecord.hhHasKids:=integer(hhRecord.hhSize>hhRecord.hhAdults);
    // hhWorkerRatio:= hhWorkers*1.0/hhSize;
    hhRecord.hhWorkerRatio2:= hhRecord.hhWorkers*1.0/hhRecord.hhAdults;
    hhRecord.hh1Adult:=integer(hhRecord.hhAdults=1);
    hhRecord.hh3Adults:=integer(hhRecord.hhAdults=3);
    hhRecord.hh4PlusAdults:=integer(hhRecord.hhAdults>=4);
    if hhRecord.hhHeadAge<35 then hhRecord.hhHeadUnder35:=1 else hhRecord.hhHeadUnder35:=0;
    if hhRecord.hhHeadAge>=65 then hhRecord.hhHeadOver65:=1 else hhRecord.hhHeadOver65:=0;
    hhRecord.hhExpOut := hhRecord.hhExpFactor * Sample1inX;
    
    if hhRecord.hhIncome>=150000 
        then hhRecord.hhIncseg:=5 
    else if hhRecord.hhIncome>=100000 
        then hhRecord.hhIncseg:=4 
    else if hhRecord.hhIncome>= 65000 
        then hhRecord.hhIncseg:=3 
    else if hhRecord.hhIncome>= 35000 
        then hhRecord.hhIncseg:=2 
    else hhRecord.hhIncseg:=1;

    if (stateToUseSeparateCoefficientFiles>0) 
        and (stateToUseSeparateCoefficientFiles=zoneState[hhRecord.hhZoneIndex])
    then begin
        hhRecord.hhModelSegment:=2;
        end else begin
        hhRecord.hhModelSegment:=1;
        end;
    
    loadNextHouseholdRecord := hhRecord;
    end;


    function writeHouseholdDayRecord(
        hhRecord: hhObject;
        outDelim: string;
        var hhDayOutFile: textFile
        ): integer;
    begin
        write(
            hhDayOutFile,hhRecord.hhId,
            outDelim,hhRecord.hhZone,
            outDelim,zoneState[zoneIndex[hhRecord.hhZone]],
            outDelim,hhRecord.hhSize,
            outDelim,hhRecord.hhWorkers,
            outDelim,hhRecord.hhNonWkrs,
            outDelim,hhRecord.hhHasKids,
            outDelim,hhRecord.hhHeadAge,
            outDelim,hhRecord.hhIncome,
            outDelim,hhRecord.hhVehicles);
        for purpose:=1 to nTourPurposes do 
            write(hhDayOutFile,
            outDelim,hhRecord.hhTours[purpose]);
        writeln(hhDayOutFile,
            outDelim,hhRecord.hhExpOut*sampFactor:3:2);
        writeHouseholdDayRecord := 0;
    end;

    function writeHouseholdVehicleRecord(
            hhID: integer;
            hhVehicles: integer;
            hhVehicleBody: array of integer;
            hhVehicleFuel: array of integer;
            hhVehicleAge: array of integer;
            hhVehicleAlt: array of integer;
            var hhVehicleOutFile: textFile
        ): integer;
    var vehicle:integer;
    begin
        for vehicle:=0 to hhVehicles-1 do
        writeln(hhVehicleOutFile,hhId,
            outDelim,vehicle,
            outDelim,hhVehicleAlt[vehicle],
            outDelim,hhVehicleBody[vehicle],
            outDelim,hhVehicleFuel[vehicle],
            outDelim,hhVehicleAge[vehicle]
        );
        writeHouseholdVehicleRecord := 0;
    end;

    function openHouseholdDayOutputFile(
        filename:string;
        var hhDayOutFile: textFile
        ): integer;
    begin
        filename:=setFileName(OutputDirectoryName,filename);
        rewriteTextFile(hhDayOutFile,filename);
        writeln(hhDayOutFile,'hhId',
        outDelim,'hhZone',
        outDelim,'hhState',
        outDelim,'hhSize',
        outDelim,'hhWorkers',
        outDelim,'hhNonWkers',
        outDelim,'hhHasKids',
        outDelim,'hhHeadAge',
        outDelim,'hhIncome',
        outDelim,'hhVehicles',
        outDelim,'hhPersBusTours',
        outDelim,'hhVisitTours',
        outDelim,'hhLeisureTours',
        outDelim,'hhCommuteTours',
        outDelim,'hhEmplBusTours',
        outDelim,'hhExpOut'); {header}

        openHouseholdDayOutputFile := 0;
    end;

    function openHouseholdVehicleOutputFile(
        filename:string;
        var hhVehicleOutFile: textFile

        ): integer;
    begin
        filename:=setFileName(OutputDirectoryName,filename);
        rewriteTextFile(hhVehicleOutFile,filename);
        writeln(hhVehicleOutFile,'hhId',
        outDelim,'hhVehicle',
        outDelim,'hhVehicleAlt',
        outDelim,'hhVehicleBody',
        outDelim,'hhVehicleFuel',
        outDelim,'hhVehicleAge'
        );
        openHouseholdVehicleOutputFile := 0;
    end;

    function openHouseholdInputFile(
        filename:string;
        var hhInFile: textFile
        ): integer;
    begin
        filename:=setFileName(InputDirectoryName,filename);
        resetTextFile(hhInFile,filename);
        readln(hhInFile); {header}
    end;


end.