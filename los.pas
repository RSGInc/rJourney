unit los;

interface
uses omxmatrix, zones, fileIO, defaults, logicalFuncs, greatCircle;

    var

        carDist,
        carTime,
        carToll,
        busTime,
        busFare,

        railTime, 
        railXfer, 
        railFreq, 
        railEconFare, 
        railBusiFare, 
        railAcEgDist, 
        railOrigStation, 
        railDestStation,

        airTime, 
        airXfer,
        airFreqDirect,
        airFreq1Stop, 
        airFreq2Stop, 
        airReli30, 
        airEconFare, 
        airBusiFare, 
        airAcEgDist, 
        airOrigAirport, 
        airDestAirport, 
        airOnlyAKHI:    zoneMatrix;
        
    
        // car/bus arrays
        cconnect,
        cunconnect,
        cavdist,
        cavtime,
        cavtoll,
        bavtime,
        bavfare,

        // rail arrays
        rconnect,
        runconnect,
        ravxfer,
        ravtime,
        ravfreq,
        ravefare,
        ravbfare,
        ravaedist,

        // air arrays
        aconnect,
        aunconnect,
        aavxfer,
        aavtime,
        aavfreqd,
        aavfreq1,
        aavfreq2,
        aavreli,
        aavefare,
        aavbfare,
        aavaedist:      array[1..nodstypes] of double;

    function openRoadLOSMatrices(
        filename: string;
        var logFile: textFile
        ): integer;

    function openRailLOSMatrices(
        filename: string;
        var logFile: textFile
        ): integer;

    function openAirLOSMatrices(
        filename:string;
        var logFile: textFile
        ): integer;

    function readRoadLOSMatrices(hzone:integer): integer;

    function readRailLOSMatrices(hzone:integer): integer;

    function readAirLOSMatrices(hzone:integer): integer;

    function closeRoadLOSMatrices(): integer;

    function closeRailLOSMatrices(): integer;

    function closeAirLOSMatrices(): integer;

    function closeSkimExtract(): integer;


implementation
{**** Code to declare and load LOS matrices ****}


    var 
        skimExtF,
        roadLosInf: textfile;
        omxRoad: TOMXMatrix;
        
        useOMXroad: boolean=False;
        odstype: integer;

        omxDataBuffer:zoneDouble; 
        matrixRow:zoneMatrix; 
        zindex:integer;

    var 
        raillosinf: textFile; 
        omxRail: TOMXMatrix;

        useOMXrail: boolean=False;
        d,oIndex,dIndex:integer;


    function closeSkimExtract(): integer;
    begin
        close(SkimExtF)
    end;
        

    function getOMXrow(omx:TOMXMatrix; tablename:string; row:integer):zoneMatrix;
    begin
        omx.getRow(tablename, zoneId[row], @(omxDataBuffer[1]));
        for zindex:=1 to nZones do matrixRow[zindex]:=round(omxDataBuffer[zoneId[zindex]]);
        getOMXrow:=matrixRow;
    end;


    function openRoadLOSMatrices(
        filename: string;
        var logFile: textFile
        ): integer;
    begin
        filename:=setFileName(InputDirectoryName,filename);
        writeln(logFile,'Opening Road LOS Matrices file ',filename);
        writeln('Opening Road LOS Matrices file ',filename);
        if fileIsOmx(filename) then begin
            omxRoad:=TOMXMatrix.Create();
            omxRoad.openFile(filename);
            useOMXroad:=True;
        end else resetTextFile(roadlosinf,filename);
        copercpm:=copercpm*(1.0+scenarioAutoCostChange/100.0);

        if WriteLOSSummaryFile then
        for odstype:=1 to nodstypes do begin
            cconnect[odstype]:=0;
            cunconnect[odstype]:=0;
            cavdist[odstype]:=0;
            cavtime[odstype]:=0;
            cavtoll[odstype]:=0;
            bavtime[odstype]:=0;
            bavfare[odstype]:=0;
        end;

        if (WriteSkimsEveryXZones > 0) and (useOMXroad) then begin
            assign(skimExtF,'SkimExtract.csv'); rewrite(skimExtF);
            writeln(skimExtF,'otaz,dtaz,xyDist,carDist,carTime,carToll,busTime,busFare,',
            'railTime,railXFer,railFreq,railEFare,railBFare,railAEDist,',
            'airTime,airXFer,airFreqD,airFreq1,airFreq2,airReli,airEFare,airBFare,airAEDist');
        end;
    end;

    function readRoadLOSMatrices(hzone:integer): integer;
    {var zonesConnected, ldZonesConnected:integer;}
    begin
        {empty arrays}
        {zonesConnected:=0;}
        // ldZonesConnected:=0;
        if useOMXroad then begin
            carTime:=getOMXrow(omxRoad, 'carTime', hzone);
            carDist:=getOMXrow(omxRoad, 'carDist', hzone);
            carToll:=getOMXrow(omxRoad, 'carToll', hzone);
            busTime:=getOMXrow(omxRoad, 'busTime', hzone);
            busFare:=getOMXrow(omxRoad, 'busFare', hzone);
            oIndex:=hzone;
        end else repeat
            for dindex:=1 to nZones do begin
            readln(roadlosinf, oIndex,d,
            carTime[dIndex],
            carDist[dIndex],
            carToll[dIndex],
            busTime[dIndex],
            busFare[dIndex]);
            end;
        until (oIndex=hzone);


        for dindex:=1 to nZones do begin
            (*{temporary fix for car dist and car time outside of Florida}
            if (zoneState[oindex]<>12) or (zoneState[dindex]<>12) then begin
            carDist[dindex]:=trunc(gcdist(zoneLat[oindex],zoneLong[oindex],zoneLat[dindex],zoneLong[dindex]) *2.5);
            carTime[dindex]:=carDist[dindex]; {1 minute/mile}
            busTime[dindex]:=trunc(carTime[dindex]*1.25); {1.25 minute/mile}
            end;
            *)
            // if carDist[dindex]>0 then zonesConnected:=zonesConnected+1;
            // if carDist[dindex]/2.0>=50 then ldZonesConnected:=ldZonesConnected+1;
            carTime[dindex]:=round(carTime[dindex]*(1.0+scenarioAutoTimeChange/100.0));
            carToll[dIndex]:=round(min(65000,carToll[dIndex]*(1.0+scenarioAutoCostChange/100.0)));

            if WriteLOSSummaryFile then begin
            odstype:=1;
            if zoneState[oindex]<>12 then odstype:=odstype+1;
            if zoneState[dindex]<>12 then odstype:=odstype+2;
            if carDist[dindex]/2.0<50 then odstype:=5;

            if carTime[dindex]>0 then begin
            cconnect[odstype]:=cconnect[odstype]+1;
            cavdist[odstype]:=cavdist[odstype]+carDist[dindex];
            cavtime[odstype]:=cavtime[odstype]+carTime[dindex];
            cavtoll[odstype]:=cavtoll[odstype]+carToll[dindex];
            bavtime[odstype]:=bavtime[odstype]+busTime[dindex];
            bavfare[odstype]:=bavfare[odstype]+busFare[dindex];
            end else
            cunconnect[odstype]:=cunconnect[odstype]+1;
            end;
        end;
    end;

    function closeRoadLOSMatrices(): integer;
    begin
        if useOMXroad then
            omxRoad.closeFile
        else
            close(roadlosinf);
    end;




    function openRailLOSMatrices(
        filename: string;
        var logFile: textFile
        ): integer;
    begin
        filename:=setFileName(InputDirectoryName,filename);
        writeln(logFile,'Opening Rail LOS Matrices file ',filename);
        writeln('Opening Rail LOS Matrices file ',filename);
        if fileIsOmx(filename) then begin
            omxRail:=TOMXMatrix.Create();
            omxRail.openFile(filename);
            useOMXrail:=True;
        end else resetTextFile(raillosinf,filename);

        if WriteLOSSummaryFile then
        for odstype:=1 to nodstypes do begin
            rconnect[odstype]:=0;
            runconnect[odstype]:=0;
            ravtime[odstype]:=0;
            ravxfer[odstype]:=0;
            ravfreq[odstype]:=0;
            ravefare[odstype]:=0;
            ravbfare[odstype]:=0;
            ravaedist[odstype]:=0;
        end;

    end;

    function readRailLOSMatrices(hzone:integer): integer;
    begin
        if useOMXrail then begin
            railTime:=        getOMXrow(omxRail, 'railTime', hzone);
            railXfer:=        getOMXrow(omxRail, 'railXfer', hzone);
            railFreq:=        getOMXrow(omxRail, 'railFreq', hzone);
            railEconFare:=    getOMXrow(omxRail, 'railEconFare', hzone);
            railBusiFare:=    getOMXrow(omxRail, 'railBusiFare', hzone);
            railAcEgDist:=    getOMXrow(omxRail, 'railAcEgDist', hzone);
            railOrigStation:= getOMXrow(omxRail, 'railOrigStation', hzone);
            railDestStation:= getOMXrow(omxRail, 'railDestStation', hzone);
            oIndex:=hzone;
        end else repeat
            for dindex:=1 to nZones do begin
            readln(raillosinf,oIndex,d,
            railTime[dIndex],
            railXfer[dIndex],
            railFreq[dIndex],
            railEconFare[dIndex],
            railBusiFare[dIndex],
            railAcEgDist[dIndex],
            railOrigStation[dindex],
            railDestStation[dindex]);
            end;
        until (oIndex=hzone);

        for dindex:=1 to nZones do begin

            railTime[dindex]:=round(min(650000,railTime[dindex]*(1.0+scenarioRailTimeChange/100.0)));

            if WriteLOSSummaryFile then begin
            odstype:=1;
            if zoneState[oindex]<>12 then odstype:=odstype+1;
            if zoneState[dindex]<>12 then odstype:=odstype+2;
            if carDist[dindex]/2.0<50 then odstype:=5;
            if railTime[dindex]>0 then begin
            rconnect[odstype]:=rconnect[odstype]+1;
            ravtime[odstype]:=ravtime[odstype]+railTime[dindex];
            ravxfer[odstype]:=ravxfer[odstype]+railXfer[dindex];
            ravfreq[odstype]:=ravfreq[odstype]+railFreq[dindex];
            ravefare[odstype]:=ravefare[odstype]+railEconFare[dindex];
            ravbfare[odstype]:=ravbfare[odstype]+railBusiFare[dindex];
            ravaedist[odstype]:=ravaedist[odstype]+railAcEgDist[dindex];
            end else
            runconnect[odstype]:=runconnect[odstype]+1;
            end;

        end;
    end;

    function closeRailLOSMatrices(): integer;
    begin
        if useOMXrail then
            omxRail.closeFile
        else
            close(raillosinf);
    end;

    var 
    
        airlosinf:      textFile;
        omxAir:         TOMXMatrix;
        
        useOMXair:      boolean=False;

    function openAirLOSMatrices(
        filename:string;
        var logFile: textFile
        ): integer;
    begin
        filename:=setFileName(InputDirectoryName,filename);
        writeln(logFile,'Opening Air LOS Matrices file ',filename);
        writeln('Opening Air LOS Matrices file ',filename);
        if fileIsOmx(filename) then begin
            omxAir:=TOMXMatrix.Create();
            omxAir.openFile(filename);
            useOMXair:=True;
        end else resetTextFile(airlosinf,filename);

        if WriteLOSSummaryFile then
        for odstype:=1 to nodstypes do begin
            aconnect[odstype]:=0;
            aunconnect[odstype]:=0;
            aavxfer[odstype]:=0;
            aavtime[odstype]:=0;
            aavfreqd[odstype]:=0;
            aavfreq1[odstype]:=0;
            aavfreq2[odstype]:=0;
            aavreli[odstype]:=0;
            aavefare[odstype]:=0;
            aavbfare[odstype]:=0;
            aavaedist[odstype]:=0;
        end;

    end;

    function readAirLOSMatrices(hzone:integer): integer;
    var temp1,temp2:integer;  {var zonesConnected, ldZonesConnected:integer;}
    begin
        {empty matrices}
        // zonesConnected:=0;
        // ldZonesConnected:=0;

        if useOMXair then begin
            oIndex:=hzone;
            airTime:=         getOMXrow(omxAir, 'airTime', hzone);
            airXfer:=         getOMXrow(omxAir, 'airXfer', hzone);
            airFreqDirect:=   getOMXrow(omxAir, 'airFreqDirect', hzone);
            airFreq1Stop:=    getOMXrow(omxAir, 'airFreq1Stop', hzone);
            airFreq2Stop:=    getOMXrow(omxAir, 'airFreq2Stop', hzone);
            airReli30:=       getOMXrow(omxAir, 'airReli30', hzone);
            airEconFare:=     getOMXrow(omxAir, 'airEconFare', hzone);
            airBusiFare:=     getOMXrow(omxAir, 'airBusiFare', hzone);
            airAcEgDist:=     getOMXrow(omxAir, 'airAcEgDist', hzone);
            airOrigAirport:=  getOMXrow(omxAir, 'airOrigAirport', hzone);
            airDestAirport:=  getOMXrow(omxAir, 'airDestAirport', hzone);
            oIndex:=hzone;
        end else repeat
            for dindex:=1 to nZones do begin
            readln(airlosinf,oIndex,d,
            airTime[dIndex],
            airXfer[dIndex],
            airFreqDirect[dIndex],
            airFreq1Stop [dIndex],
            airFreq2Stop [dIndex],
            airReli30[dIndex],
            airEconFare[dIndex],
            airBusiFare[dIndex],
            airAcEgDist[dIndex],
            airOrigAirport[dindex],
            airDestAirport[dindex]);
            end;
        until (oIndex=hzone);

        (*
        write(zoneId[oindex]:8);

        if zoneId[oindex] mod 100=0 then begin
            write('!');
        end;
        *)
        for dindex:=1 to nZones do begin
            if AirFareFactor<>1.0 then begin
            airEconFare[dindex]:=round(airEconFare[dindex]*AirFareFactor);
            airBusiFare[dindex]:=round(airBusiFare[dindex]*AirFareFactor);
            end else begin
            airBusiFare[dIndex]:=round((airBusiFare[dIndex]+airEconFare[dIndex])/2.0);
            end;
            airEconFare[dindex]:=round(min(65000,airEconFare[dindex]*(1.0+scenarioAirFareChange/100.0)));
            airBusiFare[dindex]:=round(min(65000,airBusiFare[dindex]*(1.0+scenarioAirFareChange/100.0)));

            {if there is an air connection for alaska and hawaii to 48 estimate car distance, but leave car time at 0}
            if (carDist[dIndex]=0)
            and (((zoneState[oIndex]= 2) and (zoneState[dIndex]<> 2))   {alaska-non-alaska}
            or  ((zoneState[oIndex]=15) and (zoneState[dIndex]<>15))   {hawaii-non-hawaii}
            or  ((zoneState[dIndex]= 2) and (zoneState[oIndex]<> 2))   {non-alaska-alaska}
            or  ((zoneState[dIndex]=15) and (zoneState[oIndex]<>15)))  {non-hawaii-hawaii} then begin
            airOnlyAKHI[dIndex]:=1;
            temp1:=round(
            sqrt((zoneLat [oIndex]-zoneLat [dIndex])*(zoneLat [oIndex]-zoneLat [dIndex])*69.0*69.0
                +(zoneLong[oIndex]-zoneLong[dIndex])*(zoneLong[oIndex]-zoneLong[dIndex])*65.0*65.0));
            carDist[dIndex]:=temp1*2;
            end;

            // if airTime[dindex]>0 then zonesConnected:=zonesConnected+1;

            if WriteLOSSummaryFile then begin
            odstype:=1;
            if zoneState[oindex]<>12 then odstype:=odstype+1;
            if zoneState[dindex]<>12 then odstype:=odstype+2;
            if carDist[dindex]/2.0<50 then odstype:=5;

            if airTime[dindex]>0 then begin
            aconnect[odstype]:=aconnect[odstype]+1;
            aavtime[odstype]:=aavtime[odstype]+airTime[dindex];
            aavxfer[odstype]:=aavxfer[odstype]+airXfer[dindex];
            aavfreqd[odstype]:=aavfreqd[odstype]+airFreqDirect[dindex];
            aavfreq1[odstype]:=aavfreq1[odstype]+airFreq1stop[dindex];
            aavfreq2[odstype]:=aavfreq2[odstype]+airFreq2stop[dindex];
            aavreli[odstype]:=aavreli[odstype]+airReli30[dindex];
            aavefare[odstype]:=aavefare[odstype]+airEconFare[dindex];
            aavbfare[odstype]:=aavbfare[odstype]+airBusiFare[dindex];
            aavaedist[odstype]:=aavaedist[odstype]+airAcEgDist[dindex];
            end else
            aunconnect[odstype]:=aunconnect[odstype]+1;
            end;

            if (WriteSkimsEveryXZones>0)
            and (oindex mod WriteSkimsEveryXZones=0)
            and (dindex mod WriteSkimsEveryXZones=0) then begin
            writeln(SkimExtF,
            zoneId[oindex],',',
            zoneId[dindex],',',
            gcdist(zoneLat[oindex],zoneLong[oindex],zoneLat[dindex],zoneLong[dindex]):2:1,',',
            carDist[dindex],',',
            carTime[dindex],',',
            carToll[dindex],',',
            busTime[dindex],',',
            busFare[dindex],',',
            railTime[dindex],',',
            railXfer[dindex],',',
            railFreq[dindex],',',
            railEconFare[dindex],',',
            railBusiFare[dindex],',',
            railAcEgDist[dindex],',',
            airTime[dindex],',',
            airXfer[dindex],',',
            airFreqDirect[dindex],',',
            airFreq1stop[dindex],',',
            airFreq2stop[dindex],',',
            airReli30[dindex],',',
            airEconFare[dindex],',',
            airBusiFare[dindex],',',
            airAcEgDist[dindex]);
            end;
        end;
    end;

    function closeAirLOSMatrices(): integer;
    begin
        if useOMXair then
            omxAir.closeFile
        else
            close(airlosinf);

        closeAirLOSMatrices := 0
    end;

end.