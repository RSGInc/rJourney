unit modeDestinationModel;

interface
uses household, tour, defaults;



    var accessibilityLogsums:   array[  
                                        1..nHHSegs,
                                        1..nTourPurposes,
                                        1..nDistBands
                                    ] of double;

    function calculateModeDestinationProbabilities(
        hhRecord: hhObject
        ): integer;

    function applyTourModeDestinationModel(
            hhRecord: hhObject;
            var tourRecord: tourObject
            ): integer;

implementation
uses los, zones, logicalFuncs, fileIO, randomSync;

   const 
        //coefplabel:array[1..nTourPurposes] of string=('pbus','vfar','leis','comm','ebus');
        dbandlowlimit : array[1..nDistBands] of integer= ( 0, 50,150,500);
        dbandhighlimit: array[1..nDistBands] of integer= (50,150,500,999999);
        hhSegIncome:    array[1..nHHSegs] of integer=(22,50,80,125,210, 22,50,80,125,210, 22,50,80,125,210);
        hhSegNocars:    array[1..nHHSegs] of integer=( 1, 1, 1,  1,  1,  0, 0, 0,  0,  0,  0, 0, 0,  0,  0);
        hhSegCarlta:    array[1..nHHSegs] of integer=( 0, 0, 0,  0,  0,  1, 1, 1,  1,  1,  0, 0, 0,  0,  0);
        psSegSingle:    array[1..nPSSegs] of integer=( 1, 0, 0);
        psSegGroup3:    array[1..nPSSegs] of integer=( 0, 0, 1);

        nasegDaytrip :  array[1..nNASegs] of integer=(1, 0, 0);
        nasegNights12:  array[1..nNASegs] of integer=(0, 1, 0);
        nasegWeekTrip:  array[1..nNASegs] of single =(0, 0, 0.5);

        moSegSummer  :  array[1..nMOSegs] of integer=(0);
        avgPartysize :  array[  1..nPSSegs,
                                1..NTourPurposes
                            ] of single=(   (1.0,1.0,1.0,1.0,1.0),
                                            (2.0,2.0,2.0,2.0,2.0),
                                            (4.0,4.0,4.0,4.0,4.0));

        logsumPSSeg :   array[1..nTourPurposes] of integer=(2, 2, 2, 1, 1);
        logsumNASeg :   array[1..nTourPurposes] of integer=(2, 2, 3, 1, 2);
        logsumMOSeg :   array[1..nTourPurposes] of integer=(1, 1, 1, 1, 1);

        { These are now read from the mode choice coefficient file so they can be edited by the user
        Costcoef:array[1..NTourPurposes] of single=(	-0.006,	-0.006,	-0.006,	-0.006,	-0.0025);
        Cartimecoef:array[1..NTourPurposes] of single=(	-0.002,	-0.002,	-0.002,	-0.002,	-0.002);
        Bustimecoef:array[1..NTourPurposes] of single=(	-0.0015,-0.0015,-0.0012,-0.0015,-0.0015 );
        Railtimecoef:array[1..NTourPurposes] of single=(	-0.002 ,-0.0015,-0.0012,-0.0015,-0.0015);
        Airtimecoef:array[1..NTourPurposes] of single=(	-0.0015,-0.0015,-0.0015,-0.0015,-0.0015);
        Railtransfercoef:array[1..NTourPurposes] of single=(-0.3,	-0.3 ,	-0.3 ,	-0.3 ,	-0.5);
        Airtransfercoef:array[1..NTourPurposes] of single=( -0.3 , -0.3 ,	-0.15,	-0.3 ,	-0.5);
        Railfrequencycoef:array[1..NTourPurposes] of single=(0.06, 0.06 ,	0.06 ,	0.06 ,	0.06);
        Airfrequencycoef:array[1..NTourPurposes] of single=( 0.06, 0.06 ,	0.06 ,	0.06 ,	0.12);
        Railacegdistcoef:array[1..NTourPurposes] of single=(-0.025,-0.015,-0.020,	-0.025,-0.015);
        Airacegdistcoef:array[1..NTourPurposes] of single=( -0.005,-0.005,-0.009 ,-0.005,-0.006);
        Railacegfraccoef:array[1..NTourPurposes] of single=( -1.16 ,-3.04 ,-2.36 ,-1.16, -1.69);
        Airacegfraccoef:array[1..NTourPurposes] of single=(  -1.86, -3.30 ,-0.46 ,-1.86 ,-4.93 );
        Airpontimecoef:array[1..NTourPurposes] of single=(  0.015,  0.03  , 0.015 ,0.03  ,0.03);
        }
        maxairfare:array[1..NTourPurposes] of integer= (4000,4000,4000,2000,8000);
    var xstr:string[13];

        purpadd,
        purp,
        hhseg,
        psseg,
        naseg,
        moseg,
        dtaz,
        nmsegs,
        mseg,
        cnum,
        dband,
        mode:   integer;

        siz0, 
        siz1,
        siz2, 
        siz3, 
        siz4:   single;

        railfare,
        airfare,
        railfreqx,
        airfreqx,
        carutilx,
        busutilx,
        railutilx,
        airutilx,

        carutil,
        busutil,
        railutil,
        airutil,
        lncdist,
        cdistsq,
        modeChoiceLogsum,
        destsum,
        carDist1way:    double;

        mexputil:   array[0..nTourModes] of double;
        cinf:   textFile;



        modeProb:   array[  
                            1..nHHSegs,
                            1..nTourPurposes,
                            1..nPSSegs,
                            1..nNASegs,
                            1..nMOSegs,
                            1..mZones,
                            0..nTourModes
                        ] of double;

        destProb:   array[  
                            1..nHHSegs,
                            1..nTourPurposes,
                            1..nPSSegs,
                            1..nNASegs,
                            1..nMOSegs,
                            0..mZones
                        ] of double;
        
        hhsegLogIncome,
        hhsegIncomeFac: array[1..nHHSegs] of single;
        
        pssegCostFac:   array[
                            1..nPSSegs,
                            1..nTourPurposes
                        ] of single;
        
        sizeFunction,
        destutil:   array[ 
                        1..nCoefPurposes,
                        1..mZones
                    ] of double;
        
        logsumsInitialized: boolean=false;
        modeCoeffsRead:     boolean=false;
        destCoeffsRead:     boolean=false;
        
        MCCoef:     array[
                            1..nCoefPurposes,
                            1..maxmccoef
                        ] of single;

        DCCoef:     array[
                            1..nCoefPurposes,
                            1..maxdccoef
                        ] of single;

        carVOT:     array[
                            1..nHHSegs,
                            1..nTourPurposes,
                            1..nPSSegs
                        ] of double;

        dmaConstRead:   boolean=false;
        DMA2DMA_Con:    array[1..maxDMA] of single;

        target: double; 
        
        
        otaz,
        lowLimit,
        highLimit,
        index:  integer;
        
        done:boolean; 
        //tripExp:double;
        // const avgPartySize:  array[1..4] of single=(1,2,3,5.0);

    function calculateModeDestinationProbabilities(
        hhRecord: hhObject
        ): integer;
    begin
        otaz := hhRecord.hhZoneIndex;
        if (StateToSubsampleZoneModeDestCalcs<>zoneState[otaz]) or
        ((StateToSubsampleZoneModeDestCalcs =zoneState[otaz]) and
            (StateZoneSubsample1inX>0) and (otaz mod StateZoneSubsample1inX=1)) then begin

        if (StateToSubsampleZoneModeDestCalcs>0) and (StateZoneSubsample1inX>0) then
            writeln('Calculationg mode/dest probabilities for zone ',otaz);

        {writeln('Calculating accessibility logsums. Zones processed..');}
        if not(logsumsInitialized) then begin
            logsumsInitialized:=true;
            {if first zone, initialize coefficients and other global vars}

            for cnum:=1 to maxDMA do DMA2DMA_Con[cnum]:=0;
            if (useDmaConstants) and not(dmaConstRead) then begin
                {read dma-to-dma constants}
                resetTextFile(cinf,setFileName(CoefficientDirectoryName,DMAConstFile));
                repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
                repeat
                    read(cinf,cnum);
                    {write(purp,' ',cnum); readln;}
                    if (cnum>=0) and (cnum<=maxDMA) then readln(cinf,xstr,DMA2DMA_Con[cnum]) else readln(cinf);
                    {if (cnum>=0) and (cnum<=maxDMA) then write(cnum,' ',xstr);}
                until cnum<0;
                close(cinf);
                dmaConstRead:=true;
            end;

            if not(modeCoeffsRead) then begin
                if UseSegmentedModels then nmsegs:=10 else nmsegs:=5;
                for mseg:=1 to nmsegs do begin
                    {read coefficients}
                    resetTextFile(cinf,setFileName(CoefficientDirectoryName,mccoeffile[mseg]));
                    repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
                    repeat
                    read(cinf,cnum);
                    {write(purp,' ',cnum); readln;}
                    if (cnum>=0) and (cnum<=maxmccoef) then readln(cinf,xstr,MCCoef[mseg,cnum]) else readln(cinf);
                    until cnum<0;
                    close(cinf);
                end;
                modeCoeffsRead:=true;
            end;

            if not(destCoeffsRead) then begin
                if UseSegmentedModels then nmsegs:=10 else nmsegs:=5;
                for mseg:=1 to nmsegs do begin
                    {read coefficients}
                    resetTextFile(cinf,setFileName(CoefficientDirectoryName,dccoeffile[mseg]));
                    repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
                    repeat
                    read(cinf,cnum);
                    {write(purp,' ',cnum); readln;}
                    if (cnum>=0) and (cnum<=maxdccoef) then readln(cinf,xstr,DCCoef[mseg,cnum]) else readln(cinf);
                    {exponentiate size coefficients}
                    if (cnum>=firstsizevar) and (cnum<=lastsizevar) then DCCoef[mseg,cnum]:=exp(DCCoef[mseg,cnum]);
                    until cnum<0;
                    close(cinf);
                end;
                destCoeffsRead:=true;
            end;

            for hhseg:=1 to nHHSegs do begin
                hhsegLogIncome[hhseg]:=ln(hhsegIncome[hhseg]);
                hhsegIncomefac[hhseg]:= exp(0.6 * ln(hhsegIncome[hhseg]/VOTIncomeDivisor));
            end;

            for psseg:=1 to nPSSegs do
                for purp:=1 to nTourPurposes do begin
                    pssegCostfac[psseg,purp] := exp(0.7 * ln(1.0*avgPartysize[psseg,purp]));
                    for hhseg:=1 to nHHSegs do begin
                        carVOT[hhseg,purp,psseg]:=(60* MCCoef[purp,11])/
                        (MCCoef[purp,10]/(hhsegIncomefac[hhseg]*pssegCostfac[psseg,purp]));

                    end;
                end;

            for dtaz:= 1 to nZones do begin
                for purp:=1 to nTourPurposes do begin
                    if purp=1 then begin
                    siz0:=medicemp[dtaz];
                    siz1:=enteremp[dtaz];
                    siz2:=oservemp[dtaz];
                    siz3:=totalemp[dtaz]-siz0-siz1-siz2;
                    siz4:=univenr [dtaz];
                    end else
                    if purp=2 then begin
                    siz0:=accomemp[dtaz];
                    siz1:=enteremp[dtaz];
                    siz2:=medicemp[dtaz];
                    siz3:=totalemp[dtaz]-siz0-siz1-siz2;
                    siz4:=tothh   [dtaz];
                    end else
                    if purp=3 then begin
                    siz0:=accomemp[dtaz];
                    siz1:=enteremp[dtaz];
                    siz2:=oservemp[dtaz];
                    siz3:=totalemp[dtaz]-siz0-siz1-siz2;
                    siz4:=parksqm [dtaz];
                    end else
                    if purp=4 then begin
                    siz0:=oservemp[dtaz];
                    siz1:=enteremp[dtaz];
                    siz2:=retaiemp[dtaz]+wholeemp[dtaz];
                    siz3:=totalemp[dtaz]-siz0-siz1-siz2;
                    siz4:=univenr [dtaz];
                    end else
                    if purp=5 then begin
                    siz1:=accomemp[dtaz];
                    siz2:=enteremp[dtaz];
                    siz2:=retaiemp[dtaz]+wholeemp[dtaz];
                    siz3:=totalemp[dtaz]-siz0-siz1-siz2;
                    siz4:=univenr [dtaz];
                    end;

                    sizeFunction[purp,dtaz]:=DCCoef[purp,logsizemult]*ln(max(1E-10,siz0
                    + DCCoef[purp,21]*siz1
                    + DCCoef[purp,22]*siz2
                    + DCCoef[purp,23]*siz3
                    + DCCoef[purp,24]*siz4));

                    if useSegmentedModels then
                    sizeFunction[purp+nTourPurposes,dtaz]:=DCCoef[purp+nTourPurposes,logsizemult]*ln(max(1E-10,siz0
                    + DCCoef[purp+nTourPurposes,21]*siz1
                    + DCCoef[purp+nTourPurposes,22]*siz2
                    + DCCoef[purp+nTourPurposes,23]*siz3
                    + DCCoef[purp+nTourPurposes,24]*siz4));

                end;
            end;
        end;

        {if hh zone is for model segment 2, add NTourPurposes to all coefficient purpose indices}
        if hhRecord.hhModelSegment=2 then purpAdd:=NTourPurposes else purpAdd:=0;

        {for otaz:=1 to nzones do} begin
            for hhseg:=1 to nHHSegs do
            for purp:=1 to nTourPurposes do begin
            for dband:=1 to nDistBands do accessibilityLogsums[hhseg,purp,dband]:=0;
            for psseg:=1 to nPSSegs do
            for naseg:=1 to nNASegs do
            for moseg:=1 to nMOSegs do begin
                DestProb[hhseg,purp,psseg,naseg,moseg,0]:=0;
            end;
            end;

            for dtaz:=1 to nZones do begin
            {write(dtaz:5); readln;}
            carDist1way:=carDist[dtaz]/2.0;
            lncdist:=ln(max(1.0,min(carDist1way,3000)));
            cdistsq:=(min(carDist1way,3000)/100.0)*(min(carDist1way,3000)/100.0); {cap at 3000 to deal with new HI and AK destinations}

            dband:=0;
            repeat
                dband:=dband+1;
            until (carDist1way>=dbandlowlimit[dband])
                and (carDist1way< dbandhighlimit[dband]);

            for purp:=1 to nTourPurposes do begin

                destutil[purp,dtaz]:= sizeFunction[purp+purpAdd,dtaz]
                + DCCoef[purp+purpAdd,2] * lncdist
                + DCCoef[purp+purpAdd,3] * cdistsq
                + DCCoef[purp+purpAdd,7] * ifin(carDist1way,50,99.99)
                + DCCoef[purp+purpAdd,8] * ifin(cardist1way,100,149.99)
                + DCCoef[purp+purpAdd,9] * ifin(cardist1way,150,249.99)
                + DCCoef[purp+purpAdd,10]* ifin(cardist1way,250,499.99)
                + DCCoef[purp+purpAdd,11]* ifin(cardist1way,500,999.99)
                + DCCoef[purp+purpAdd,12]* ifin(cardist1way,1000,1499.99)
                + DCCoef[purp+purpAdd,13]* ifin(cardist1way,1500,1999.99)
                + DCCoef[purp+purpAdd,14]* ifge(cardist1way,2000)*(1-airOnlyAKHI[dtaz])
                + DCCoef[purp+purpAdd,19]* airOnlyAKHI[dtaz]
                + DCCoef[purp+purpAdd,15]* zUrban[dtaz]
                + DCCoef[purp+purpAdd,16]* zRural[dtaz]
                + DCCoef[purp+purpAdd,17]* (zUrban[dtaz]*zUrban[otaz])
                + DCCoef[purp+purpAdd,18]* (zRural[dtaz]*zRural[otaz]);

                {VisitFL DMA out of state constant for Florida residents}
                if  (zonestate[otaz] =StateToUseSeparateCoefficientFiles)
                and (zonestate[dtaz]<>StateToUseSeparateCoefficientFiles) then
                    destutil[purp,dtaz]:=destutil[purp,dtaz]+ DCCoef[purp+purpAdd,20];

                {VisitFL DMA region-specific specific calibration factors for Florida destinations}
                if (zonestate[dtaz]=StateToUseSeparateCoefficientFiles) then
                destutil[purp,dtaz]:=destutil[purp,dtaz] + DCCoef[purp+purpAdd,30+zoneTracts[dtaz]];

                {Add FL residents crossborder to AL / GA constants - IE Control}
                {110, 210 and 210 implies origin DMA <1/2/3> times(x) 100 plus(+) destination DMA 10 <AL/GA TAZ near the FL border>}
                if  (zonestate[otaz] = StateToUseSeparateCoefficientFiles)
                and ((zonestate[dtaz] = FLBorderState[1]) or (zonestate[dtaz] = FLBorderState[2])) then
                    destutil[purp,dtaz]:=destutil[purp,dtaz] + DMA2DMA_Con[100 * zoneTracts[otaz] + zoneTracts[dtaz]];

                {Add DMA to DMA Constants for FL residents to address Panhandle to Jacksonville overestimation - II Control}
                {103 implies origin DMA 1 times(x) 100 plus(+) destination DMA 3}
                if  (zonestate[otaz] = StateToUseSeparateCoefficientFiles)
                and (zonestate[dtaz] = StateToUseSeparateCoefficientFiles) then
                    destutil[purp,dtaz]:=destutil[purp,dtaz] + DMA2DMA_Con[100 * zoneTracts[otaz] + zoneTracts[dtaz]];


                if purp<5 then railfare:=railEconFare[dtaz]
                        else railfare:=railBusiFare[dtaz];

                if purp<5 then airfare:=airEconFare[dtaz]
                        else airfare:=airBusiFare[dtaz];
                if airfare>maxairfare[purp] then airfare:=maxairfare[purp];

                railfreqx:= railFreq[dtaz];
                if railfreqx<1 then railfreqx:=1;

                airfreqx:= airFreqDirect[dtaz]
                        +airFreq1Stop [dtaz]/2.0
                        +airFreq2Stop [dtaz]/10.0;
                if airfreqx<1 then airfreqx:=1;

                if (carTime[dtaz]<=0) then carutilx:=-999 else
                carutilx:= MCCoef[purp+purpAdd,11]* carTime[dtaz];

                if (busTime[dtaz]<=0) then busutilx:=-999 else
                busutilx:= MCCoef[purp+purpAdd,21]* busTime[dtaz];

                if (railTime[dtaz]<=0) then railutilx:=-999 else
                railutilx:= MCCoef[purp+purpAdd,31]*railTime[dtaz]
                        +  MCCoef[purp+purpAdd,32]*railXfer[dtaz]/100.0
                        +  MCCoef[purp+purpAdd,33]*sqrt(railfreqx)
                        +  MCCoef[purp+purpAdd,34]*railAcEgDist[dtaz];
                if carDist[dtaz]>0 then railutilx:=railutilx
                        +  MCCoef[purp+purpAdd,35]*(railAcEgDist[dtaz]/carDist[dtaz] - 0.33);

                if (airTime[dtaz]<=0) or (carDist[dtaz]/2.0<50) then airutilx:=-999 else  {don't include air connections for car dist 1-49}
                airutilx:=  MCCoef[purp+purpAdd,41]*airTime[dtaz]
                        +  MCCoef[purp+purpAdd,42]*airXfer[dtaz]/100.0
                        +  MCCoef[purp+purpAdd,43]*sqrt(airfreqx)
                        +  MCCoef[purp+purpAdd,46]*airReli30[dtaz]
                        +  MCCoef[purp+purpAdd,44]*airAcEgDist[dtaz];
                if carDist[dtaz]>0 then airutilx:=airutilx
                        +  MCCoef[purp+purpAdd,45]*(airAcEgDist[dtaz]/carDist[dtaz] - 0.67);

                for hhseg:=1 to nhhSegs do begin
                if busutilx>-900 then busutil:=busutilx+
                    MCCoef[purp+purpAdd,10]* busFare[dtaz]/hhsegIncomefac[hhseg]
                else busutil:=busutilx;

                if railutilx>-900 then railutil:=railutilx+
                    MCCoef[purp+purpAdd,10]* railfare/hhsegIncomefac[hhseg]
                else railutil:=railutilx;

                if airutilx>-900 then airutil:=airutilx+
                    MCCoef[purp+purpAdd,10]* airfare/hhsegIncomefac[hhseg]
                else airutil:=airutilx;

                for psseg:=1 to nPSSegs do begin
                if carutilx>-900 then carutil:=carutilx+
                    MCCoef[purp+purpAdd,10]* copercpm * carDist[dtaz]/(pssegCostfac[psseg,purp]*hhsegIncomefac[hhseg])+
                    MCCoef[purp+purpAdd,10]* carToll[dtaz]/100.0/(pssegCostfac[psseg,purp]*hhsegIncomefac[hhseg])
                else carutil:=carutilx;

                    for naseg:=1 to nNASegs do begin

                    for moseg:=1 to nMOSegs do begin

                        if (carutil<-900) then mexputil[1]:=0 else
                        mexputil[1]:= exp(0
                        + MCCoef[purp+purpAdd,  1]*carutil
                        + MCCoef[purp+purpAdd,101]*hhsegNocars[hhseg]
                        + MCCoef[purp+purpAdd,102]*hhsegCarlta[hhseg]
                        + MCCoef[purp+purpAdd,103]*pssegSingle[psseg]
                        + MCCoef[purp+purpAdd,104]*pssegGroup3[psseg]
                        + MCCoef[purp+purpAdd,105]*nasegDaytrip[naseg]
                        + MCCoef[purp+purpAdd,106]*nasegWeektrip[naseg]
                        + MCCoef[purp+purpAdd,110]*mosegSummer[moseg]
                        + MCCoef[purp+purpAdd,112]*ifge(cardist[dtaz]/2.0,500));

                        if (busutil<-900) then mexputil[2]:=0 else
                        mexputil[2]:= exp(0
                        + MCCoef[purp+purpAdd,  1]*busutil
                        + MCCoef[purp+purpAdd,200]
                        + MCCoef[purp+purpAdd,208]*hhsegLogincome[hhseg]
                        + MCCoef[purp+purpAdd,209]*zLogdens[otaz]
                        + MCCoef[purp+purpAdd,210]*zLogdens[dtaz]
                        + MCCoef[purp+purpAdd,215]*iflt(cardist[dtaz]/2.0,150));

                        if (railutil<-900) then mexputil[3]:=0 else
                        mexputil[3]:= exp(0
                        + MCCoef[purp+purpAdd,  1]*railutil
                        + MCCoef[purp+purpAdd,300]
                        + MCCoef[purp+purpAdd,308]*hhsegLogincome[hhseg]
                        + MCCoef[purp+purpAdd,309]*zLogdens[otaz]
                        + MCCoef[purp+purpAdd,310]*zLogdens[dtaz]
                        + MCCoef[purp+purpAdd,315]*iflt(cardist[dtaz]/2.0,150));

                        if (airutil<-900) then mexputil[4]:=0 else
                        mexputil[4]:= exp(0
                        + MCCoef[purp+purpAdd,  1]*airutil
                        + MCCoef[purp+purpAdd,400]
                        + MCCoef[purp+purpAdd,408]*hhsegLogincome[hhseg]
                        + MCCoef[purp+purpAdd,409]*zLogdens[otaz]
                        + MCCoef[purp+purpAdd,410]*zLogdens[dtaz]
                        + MCCoef[purp+purpAdd,411]*nasegDaytrip[naseg]
                        + MCCoef[purp+purpAdd,412]*nasegNights12[naseg]
                        + MCCoef[purp+purpAdd,414]*pssegSingle[psseg]
                        + MCCoef[purp+purpAdd,415]*iflt(cardist[dtaz]/2.0,150));

                        mexputil[0]:=mexputil[1]+mexputil[2]+mexputil[3]+mexputil[4];

                        modeProb[hhseg,purp,psseg,naseg,moseg,dtaz,0]:=0;

                        if mexputil[0]<1.0E-50 then modeChoiceLogsum:=-999.0 else begin
                        modeChoiceLogsum:=ln(mexputil[0]);

                        for mode:=1 to nTourModes do
                        modeProb[hhseg,purp,psseg,naseg,moseg,dtaz,mode] :=
                            mexputil[mode]/mexputil[0]+
                            modeProb[hhseg,purp,psseg,naseg,moseg,dtaz,mode-1];
                        end;

                        if modeChoiceLogsum<-900 then
                        destProb[hhseg,purp,psseg,naseg,moseg,dtaz]:=0 else begin
                        destProb[hhseg,purp,psseg,naseg,moseg,dtaz]:=exp(destutil[purp,dtaz] +
                        + DCCoef[purp+purpAdd,1]* modeChoiceLogsum
                        + DCCoef[purp+purpAdd,4]* nasegDaytrip[naseg]*cdistsq
                        + DCCoef[purp+purpAdd,5]* nasegNights12[naseg]*cdistsq);

                        if  (psseg=logsumPSSeg[purp])
                        and (naseg=logsumNASeg[purp])
                        and (moseg=logsumMOSeg[purp]) then begin
                            accessibilityLogsums[hhseg,purp,dband]:=accessibilityLogsums[hhseg,purp,dband]
                            +destProb[hhseg,purp,psseg,naseg,moseg,dtaz];
                        end;

                        if (carDist[dtaz]/2.0>=50) then begin
                            destProb[hhseg,purp,psseg,naseg,moseg,0]:=
                            destProb[hhseg,purp,psseg,naseg,moseg,0] +
                            destProb[hhseg,purp,psseg,naseg,moseg,dtaz];
                        end else begin
                            destProb[hhseg,purp,psseg,naseg,moseg,dtaz]:=0;
                        end;
                        end; {any modes available}
                    end; {moseg}
                    end; {naseg}
                end; {psseg}
                end; {hhseg}
            end; {purp loop}
            end; {dtaz loop}

            for hhseg:=1 to nHHSegs do
            for purp:=1 to nTourPurposes do
            for dband:=1 to nDistBands do begin
            if accessibilityLogsums[hhseg,purp,dband]< 1.0E-30
                then accessibilityLogsums[hhseg,purp,dband]:=-99.0
                else accessibilityLogsums[hhseg,purp,dband]:=ln(accessibilityLogsums[hhseg,purp,dband]);
            end;

        for hhseg:=1 to nHHSegs do
        for purp:=1 to nTourPurposes do
        for psseg:=1 to nPSSegs do
        for naseg:=1 to nNASegs do
        for moseg:=1 to nMOSegs do begin
            destsum:=destProb[hhseg,purp,psseg,naseg,moseg,0];
            destProb[hhseg,purp,psseg,naseg,moseg,0]:=0;
            if destsum>1.0E-50 then begin
            for dtaz:=1 to nZones do begin
                destProb[hhseg,purp,psseg,naseg,moseg,dtaz]:=
                destProb[hhseg,purp,psseg,naseg,moseg,dtaz]/destsum +
                destProb[hhseg,purp,psseg,naseg,moseg,dtaz-1];
            end;
            end;
        end;

        end; {o zone- no longer a loop}

        end; {subsampling on o zones}
    end;

    function applyTourModeDestinationModel(
            hhRecord: hhObject;
            var tourRecord: tourObject
            ): integer;
    begin
        //tripExp:=trExpFactor;
        {if WriteADT then tripExp:=tripExp/DaysInMonth[MonthOfYear];}

        otaz:=hhRecord.hhZoneIndex;
        purp:=tourRecord.trPurpose;
        hhseg:=hhRecord.hhModeDestSeg;
        
        psseg:=tourRecord.trPartySize; 
        if psseg>nPSSegs then psseg:=nPSSegs;
        
        naseg:=tourRecord.trNightsCategory; 
        if naseg>nNASegs then naseg:=nNASegs;

        moseg:=1;
        tourRecord.trVOT:=carVOT[hhseg,purp,psseg];
        (*
        if (writeProbs) then begin
        for dtaz:=1 to nZones do
        if (carDist[dtaz]/2.0>=TripMatrixMinimumDistance) then begin
            dprob:=DestProb[hhseg,purp,psseg,naseg,moseg,dtaz]-DestProb[hhseg,purp,psseg,naseg,moseg,dtaz-1];
            if dprob>1.0E-50 then begin
            for mode:=0 to nTourModes do if (writeTripMatrix[mode]) then begin
                if mode=0 then tripExp2:=tripExp else tripExp2:=tripExp * avgPartySize[trPartySize];
                if mode=0 then xmode:=1 else xmode:=mode;
                mprob:=ModeProb[hhseg,purp,psseg,naseg,moseg,dtaz,xmode]-ModeProb[hhseg,purp,psseg,naseg,moseg,dtaz,xmode-1];
                {
                if mprob>1.0E-50 then begin
                tripMats[mode][otaz][dtaz]:=tripMats[mode][otaz][dtaz]+dprob*mprob*tripExp2;
                tripMats[mode][otaz][dtaz]:=tripMats[mode][otaz][dtaz]+dprob*mprob*tripExp2;
                end;
                }
            end;
            end;
        end;
        end;
        *)
        if (writeTours) {or not(writeProbs)}  then begin
            
            if useRandomNumberSynchronization then
                target:=getNextRandom(hhRecord.generator) else
                target:=random;
            {binary search on destination}
            lowLimit:=1;
            highLimit:=nZones;
            index:=nZones div 2;
            done:=false;
            repeat
                dtaz:=index;
                if (DestProb[hhseg,purp,psseg,naseg,moseg,dtaz-1]<=target) and (DestProb[hhseg,purp,psseg,naseg,moseg,dtaz]>target) then begin
                done:=true;
                end else
                if (target<DestProb[hhseg,purp,psseg,naseg,moseg,dtaz]) then begin
                highLimit:=index;
                index:=(index + LowLimit) div 2;
                end else begin
                lowLimit:=index+1;
                index:=(index + HighLimit) div 2;
                end;
                {write(target:9:8,DestProb[hhseg,purp,psseg,naseg,moseg,dtaz-1]:11:8,DestProb[hhseg,purp,psseg,naseg,moseg,dtaz]:11:8,index:7,lowLimit:6,highLimit:6);
                readln;}
            until (done) or (lowLimit=highLimit);

            {now get mode}
            if useRandomNumberSynchronization then
                target:=getNextRandom(hhRecord.generator) else
                target:=random;
            mode:=0;
            repeat
                mode:=mode+1;
            until ModeProb[hhseg,purp,psseg,naseg,moseg,dtaz,mode]>target;
            {
            if (writeTripMatrix[mode])
            and (carDist[dtaz]/2.0>=TripMatrixMinimumDistance) then begin
                tripMats[mode][otaz][dtaz]:=tripMats[mode][otaz][dtaz]+tripExp * avgPartySize[trPartySize];
                tripMats[mode][dtaz][otaz]:=tripMats[mode][dtaz][otaz]+tripExp * avgPartySize[trPartySize];
            end;
            if (writeTripMatrix[0]) and (mode=1)
            and (carDist[dtaz]/2.0>=TripMatrixMinimumDistance) then begin
                tripMats[0][otaz][dtaz]:=tripMats[0][otaz][dtaz]+tripExp;
                tripMats[0][dtaz][otaz]:=tripMats[0][dtaz][otaz]+tripExp;
            end;
            }

            { //Vehicle choice, if auto 
            if mode <> 1 then vehicleChoice:=-1 //TODO address rental cars
            else begin    // Choose vehicle from inventory

                // get probabilities for each vehicle in inventory
                

                // generate random draw

                if useRandomNumberSynchronization then
                target:=getNextRandom(generator) else
                target:=random;
                // simulate choice: loop over vehicle types until cumulative probability > random draw
                vehicleChoice:=0;
                repeat
                vehicleChoice:=vehicleChoice+1;
                until vehicleProb[vehicleChoice] > target; // TODO how do we want to stratify this?
            end;
            }

            dband:=0;
            while (dband<nTrDistBands) and (carDist[dtaz]/2.0>=trDistBandLowLimit[dband+1]) do dband:=dband+1;
            if dband=0 then dband:=nTrDistBands; {AK or HI}

            trDistPred[tourRecord.trPurpose,dband]:=trDistPred[tourRecord.trPurpose,dband]+tourRecord.trExpFactor;
            trModePred[tourRecord.trPurpose,mode]:=trModePred[tourRecord.trPurpose,mode]+tourRecord.trExpFactor;
            trModeDist[tourRecord.trPurpose,mode,dband]:=trModeDist[tourRecord.trPurpose,mode,dband]+tourRecord.trExpFactor;
            // if vehicleChoice >= 0 then begin //FIXME get vehicle type info for choice from hh inventory
                // trVehiclePred[trPurpose,vehicleType]:=trVehiclePred[trPurpose,vehicleType]+trExpFactor;
                // trVehicleDist[trPurpose,vehicleType,dband]:=trVehicleDist[trPurpose,vehicleType,dband]+trExpFactor;
            // end;
            trDivODPred[mode,stateCensDiv[zoneState[otaz]],stateCensDiv[zoneState[dtaz]]]:=
            trDivODPred[mode,stateCensDiv[zoneState[otaz]],stateCensDiv[zoneState[dtaz]]]+tourRecord.trExpfactor;

            if writeTours then begin
                tourRecord.trMode:=mode;
                // trVehicle:=vehicleType;
                tourRecord.trOZone:=zoneId[otaz];
                tourRecord.trOState:=zoneState[otaz];
                tourRecord.trDZone:=zoneId[dtaz];
                tourRecord.trDState:=zoneState[dtaz];
                tourRecord.trAutoDistance:=carDist[dtaz];
                if tourRecord.trMode=1 then begin
                    tourRecord.trTravelTime:=carTime[dtaz];
                    tourRecord.trTravelCost:=round(carToll[dtaz]/100.0
                        + tourRecord.trAutoDistance*copercpm);
                    tourRecord.trOrigStation:=0;
                    tourRecord.trDestStation:=0;
                end 
                else if tourRecord.trMode=2 then begin
                    tourRecord.trTravelTime:=busTime[dtaz];
                    tourRecord.trTravelCost:=busFare[dtaz];
                    tourRecord.trOrigStation:=0;
                    tourRecord.trDestStation:=0;
                end 
                else if tourRecord.trMode=3 then begin
                    tourRecord.trTravelTime:=railTime[dtaz]
                            {+ 2 *(railAcEgDist[otaz,dtaz]+railAcEgDist[dtaz,otaz])};
                    if tourRecord.trPurpose<5
                        then tourRecord.trTravelCost:=railEconFare[dtaz]
                        else tourRecord.trTravelCost:=railBusiFare[dtaz];
                    tourRecord.trOrigStation:=railOrigStation[dtaz];
                    tourRecord.trDestStation:=railDestStation[dtaz];
                end 
                else if tourRecord.trMode=4 then begin
                    tourRecord.trTravelTime:=airTime[dtaz]
                            + round(90/100*0*airXfer[dtaz])
                            {+ 2 *(airAcEgDist[otaz,dtaz]+airAcEgDist[dtaz,otaz])};
                    if tourRecord.trPurpose<5
                        then tourRecord.trTravelCost:=airEconFare[dtaz]
                        else tourRecord.trTravelCost:=airBusiFare[dtaz];
                    tourRecord.trOrigStation:=airOrigAirport[dtaz];
                    tourRecord.trDestStation:=airDestAirport[dtaz];
                end;
                {if trAutoDistance=0 then begin
                trAutoDistance:=100;
                trMode:=1;
                trTravelTime:=100;
                trTravelCost:=0;
                trOrigStation:=0;
                trDestStation:=0;
                end;}
            end;
        end;
    end;

end.