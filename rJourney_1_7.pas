program rJourney_1_7;

{$APPTYPE CONSOLE}

uses
  {$ifdef unix}cthreads,{$endif} // must be first import
  SysUtils, hdf5dll, math,

  // project modules
  modeDestinationModel,
  tourGenerationModel,
  autoOwnershipModel,
  vehicleAllocationModel,
  household, 
  logicalFuncs,
  fileIO,
  defaults,
  zones,
  vehicleAlts,
  tour,
  los,
  summary,
  randomSync;

type integer = longint;

var logFile:text;
    hhRecord: hhObject;

procedure GetConfigurationSettings;
var s,key0,key,arg:string; cinf:text; lastpos:integer;

const configfname:string='rJourney_example_config.txt';
var nlogs:integer;
begin
  if paramCount>0 then configfname:=paramStr(1) else begin
    writeln('<<<< FHWA National Long Distance Passenger Model >>>> (c) 2015-2020  RSG');
    write('Enter the configuration settings filename : '); readln(configfname);
  end;
  nlogs:=0;
  repeat
    nlogs:=nlogs+1;
    {$I-} assign(logFile,copy(configfname,1,length(configfname)-4)+'_'+chr(48+(nlogs div 10))+chr(48+(nlogs mod 10))+'.log'); reset(logFile); {$I+}
  until (IOResult <>0);
  rewrite(logFile);

  resetTextFile(cinf,configfname);
  writeln('Reading configuration file ',configfname);
  writeln(logFile,'Reading configuration file ',configfname);
  repeat
    readln(cinf,s);
    writeln(s);
    writeln(logFile,s);
    lastpos:=0;
    key0:=parse(s,lastpos);
    if key0<>'' then begin
      key:=key0;
      key:=lowercase(key0);
      arg:=parse(s,lastpos);
      if arg='' then begin writeln;
        writeln(LogFile,'Fatal error: No argument for configuration key : ',key); close(logFile);
        write('Fatal error: No argument for configuration key : ',key,'  (Press Enter)'); readln;
      end else begin
        if key='runtitle' then runTitle:=arg else
        if key='inputdirectoryname' then InputDirectoryName:=arg else
        if key='roadlosfilename' then RoadLOSFileName:=arg else
        if key='raillosfilename' then  RailLOSFileName:=arg else
        if key='airlosfilename' then  AirLOSFileName:=arg else
        if key='zonelandusefilename' then  ZoneLandUseFileName   :=arg else
        if key='vehicletypealtsfilename' then VehicleAltsFilename :=arg else
        if key='householdfilename' then  HouseholdFileName  :=arg else
        if key='coefficientdirectoryname' then CoefficientDirectoryName:=arg else
        if key='destchoicecoefficientfile_1' then DCCoefFile[1]:=arg else
        if key='destchoicecoefficientfile_2' then DCCoefFile[2]:=arg else
        if key='destchoicecoefficientfile_3' then DCCoefFile[3]:=arg else
        if key='destchoicecoefficientfile_4' then DCCoefFile[4]:=arg else
        if key='destchoicecoefficientfile_5' then DCCoefFile[5]:=arg else
        if key='destchoicecoefficientfile_1x' then DCCoefFile[6]:=arg else
        if key='destchoicecoefficientfile_2x' then DCCoefFile[7]:=arg else
        if key='destchoicecoefficientfile_3x' then DCCoefFile[8]:=arg else
        if key='destchoicecoefficientfile_4x' then DCCoefFile[9]:=arg else
        if key='destchoicecoefficientfile_5x' then DCCoefFile[10]:=arg else
        if key='modechoicecoefficientfile_1' then MCCoefFile[1]:=arg else
        if key='modechoicecoefficientfile_2' then MCCoefFile[2]:=arg else
        if key='modechoicecoefficientfile_3' then MCCoefFile[3]:=arg else
        if key='modechoicecoefficientfile_4' then MCCoefFile[4]:=arg else
        if key='modechoicecoefficientfile_5' then MCCoefFile[5]:=arg else
        if key='modechoicecoefficientfile_1x' then MCCoefFile[6]:=arg else
        if key='modechoicecoefficientfile_2x' then MCCoefFile[7]:=arg else
        if key='modechoicecoefficientfile_3x' then MCCoefFile[8]:=arg else
        if key='modechoicecoefficientfile_4x' then MCCoefFile[9]:=arg else
        if key='modechoicecoefficientfile_5x' then MCCoefFile[10]:=arg else
        if key='usedmatodmaconstants'        then UseDMAConstants:= checkbool(arg) else
        if key='dmatodmaconstantsfile'       then DMAConstFile:= arg else
        if key='flborderstate_1'            then FLBorderState[1]:= checkint(arg,1,13) else
        if key='flborderstate_2'            then FLBorderState[2]:= checkint(arg,1,13) else
        if key='partysizecoefficientfile_1' then PSCoefFile[1]:=arg else
        if key='partysizecoefficientfile_2' then PSCoefFile[2]:=arg else
        if key='partysizecoefficientfile_3' then PSCoefFile[3]:=arg else
        if key='partysizecoefficientfile_4' then PSCoefFile[4]:=arg else
        if key='partysizecoefficientfile_5' then PSCoefFile[5]:=arg else
        if key='partysizecoefficientfile_1x' then PSCoefFile[6]:=arg else
        if key='partysizecoefficientfile_2x' then PSCoefFile[7]:=arg else
        if key='partysizecoefficientfile_3x' then PSCoefFile[8]:=arg else
        if key='partysizecoefficientfile_4x' then PSCoefFile[9]:=arg else
        if key='partysizecoefficientfile_5x' then PSCoefFile[10]:=arg else
        if key='nightsawaycoefficientfile_1' then TDCoefFile[1]:=arg else
        if key='nightsawaycoefficientfile_2' then TDCoefFile[2]:=arg else
        if key='nightsawaycoefficientfile_3' then TDCoefFile[3]:=arg else
        if key='nightsawaycoefficientfile_4' then TDCoefFile[4]:=arg else
        if key='nightsawaycoefficientfile_5' then TDCoefFile[5]:=arg else
        if key='nightsawaycoefficientfile_1x' then TDCoefFile[6]:=arg else
        if key='nightsawaycoefficientfile_2x' then TDCoefFile[7]:=arg else
        if key='nightsawaycoefficientfile_3x' then TDCoefFile[8]:=arg else
        if key='nightsawaycoefficientfile_4x' then TDCoefFile[9]:=arg else
        if key='nightsawaycoefficientfile_5x' then TDCoefFile[10]:=arg else
        if key='tourfreqcoefficientsfile_1' then  FrCoefFile[1] :=arg else
        if key='tourfreqcoefficientsfile_2' then  FrCoefFile[2] :=arg else
        if key='tourfreqcoefficientsfile_1x' then  FrCoefFile[3] :=arg else
        if key='tourfreqcoefficientsfile_2x' then  FrCoefFile[4] :=arg else
        if key='autoowncoefficientsfile' then  AOCoefFile[1] :=arg else
        if key='autoowncoefficientsfilex' then  AOCoefFile[2] :=arg else
        if key='outputdirectoryname' then OutputDirectoryName:=arg else
        if key='householdoutputfilename' then  HouseholdDayFileName :=arg else
        if key='vehicleoutputfilename' then  HouseholdVehicleFileName :=arg else
        if key='vehicletypecoefficientfile' then vehicleOwnershipCoefFile := arg else
        if key='vehicleallocationcoeficientfile' then vehicleAllocationCoefFile := arg else
        if key='touroutputfilename' then  TourFileName :=arg else
        if key='autovehicletripmatrixfilename' then TripMatrixFileName[0] :=arg else
        if key='autopersontripmatrixfilename' then TripMatrixFileName[1] :=arg else
        if key='buspersontripmatrixfilename' then TripMatrixFileName[2] :=arg else
        if key='railpersontripmatrixfilename' then TripMatrixFileName[3] :=arg else
        if key='airpersontripmatrixfilename' then TripMatrixFileName[4] :=arg else
        if key='outputfiledelimeter' then  OutDelimCode :=checkint(arg,9,44) else
        if key='monthofyear' then   MonthOfYear :=checkint(arg,0,12) else
        if key='eachdayofthemonth' then  EachDayOfTheMonth :=checkbool(arg) else
        if key='randomseed' then    RandomSeed :=checkint(arg,1,99999) else
        if key='userandomsynchronization' then    UseRandomNumberSynchronization :=checkbool(arg) else
        if key='sample1inx' then    Sample1inX :=checkint(arg,1,1000000) else
        if key='sampleoffset' then  SampleOffset :=checkint(arg,0,99999) else
        if key='numberofhouseholds' then  numberOfHouseholds :=checkint(arg,0,200000000) else
        if key='writehouseholdrecords' then  WriteHouseholds  :=checkbool(arg) else
        if key='writetourrecords' then  WriteTours  :=checkbool(arg) else
{       if key='writeautovehicletripmatrix' then  WriteTripMatrix[0] :=checkbool(arg) else
        if key='writeautopersontripmatrix' then  WriteTripMatrix[1] :=checkbool(arg) else
        if key='writebuspersontripmatrix' then  WriteTripMatrix[2] :=checkbool(arg) else
        if key='writerailpersontripmatrix' then  WriteTripMatrix[3] :=checkbool(arg) else
        if key='writeairpersontripmatrix' then  WriteTripMatrix[4] :=checkbool(arg) else
        if key='useprobabilitiesinmatrices' then  WriteProbs:= checkbool(arg) else
        if key='tripmatrixminimumdistance' then TripMatrixMinimumDistance:=checkint(arg,50,5000) else
        if key='useadtunitsinmatrices' then  WriteADT :=checkbool(arg) else
}       if key='runinbatchmode' then  runInBatchMode :=checkbool(arg) else
        if key='statetoreadcarownershipfromhhfile' then stateToReadCarOwnershipFromHHFile :=checkint(arg,0,99) else
        if key='statetosubsamplezonemodedestcalcs' then StateToSubsampleZoneModeDestCalcs :=checkint(arg,0,99) else
        if key='statezonesubsample1inx' then StateZoneSubsample1inX:=checkint(arg,0,999) else
        if key='statetowritetourrecords' then StateToWriteTourRecords:=checkint(arg,0,999) else
        if key='statetouseseparatecoefficientfiles' then begin
            stateToUseSeparateCoefficientFiles:=checkint(arg,0,99);
            if (stateToUseSeparateCoefficientFiles > 0) then useSegmentedModels:=True;
        end else
        if key='autooperatingcentspermile' then copercpm:=checkint(arg,0,1000)/100.0 else
        if key='scenariopercentincomechange' then  scenarioIncomeChange :=checkint(arg,-100,100) else
        if key='scenariopercentautocostchange' then  scenarioAutoCostChange :=checkint(arg,-100,100) else
        if key='scenariopercentautotimechange' then  scenarioAutoTimeChange :=checkint(arg,-100,100) else
        if key='scenariopercentairfarechange' then  scenarioAirFareChange :=checkint(arg,-100,100) else
        if key='scenariopercentrailtimechange' then  scenarioRailTimeChange :=checkint(arg,-100,100) else
        if key='choosevehicles' then chooseVehicles := checkBool(arg) else
        if key='allocatevehicles' then allocateVehicles := checkBool(arg) else
        begin
          writeln(logFile,'Fatal error:Invalid configuration key : ',key); close(logFile);
          writeln; write('Fatal error:Invalid configuration key : ',key,'  (Press Enter)'); readln;
        end;
      end;
    end;
  until eof(cinf);
  close(cinf);
  outDelim:=chr(outDelimCode);
end;



{ *** CODE TO DECLARE AND LOAD HOUSEHOLD SAMPLE VARIABLES *** }
var 
    hhInFile:text;

(*
var {tripMats:array[0..nTourModes] of zoneMatrixOut;}
    tripMatOutFile:array[0..nTourModes] of text;

procedure openTripMatrixOutputFile(m:integer);
var i,j:integer; filename:string;
begin
  if writeTripMatrix[m] then begin
    filename:=setFileName(OutputDirectoryName,tripMatrixFilename[m]);
    rewriteTextFile(tripMatOutFile[m],filename);
    writeln(tripMatOutFile[m],'origZone',
    outDelim,'destZone',
    outDelim,'trips'); {header}
   { for i:=1 to nZones do
    for j:=1 to nZones do
      tripMats[m][i][j]:=0.0;
   }
  end;
end;

procedure writeAndCloseTripMatrixOutputFile(m:integer);
var i,j:integer;
begin
  if writeTripMatrix[m] then begin
  {  for i:=1 to nZones do
    for j:=1 to nZones do
    if (tripMats[m][i][j]>0) then begin
      writeln(tripMatOutFile[m], zoneId[i],
      outdelim,zoneId[j],
      outdelim,tripMats[m][i][j]:6:5);
    end;
    }
    close(tripMatOutFile[m]);
  end;
end;

*)

var lastHH:boolean;             
    nHHinZone, 

    nHHRecs, lastHHZoneIndex, purpose,hhseg,dband: integer; 
    percent:single; 
    lsfile:text; 

{Main program}

begin
  randseed:=randomSeed;

  GetConfigurationSettings;
  initializeSummaryOutput;

  writeln(logFile,'Run started at ',DateTimetoStr(now));
  writeln('Run started at ',DateTimetoStr(now));
 {load input files}
  loadZoneLandUseData(ZoneLandUseFileName, logfile);
  openRoadLOSMatrices(RoadLOSFileName, logfile);
  openRailLOSMatrices(RailLOSFileName, logfile);
  openAirLOSMatrices(AirLOSFileName, logfile);
  loadVehicleAltsData(VehicleAltsFilename, logfile);

  {loop on sample households}
  writeln('Reading Households from ', HouseholdFileName, ' ....');
  openHouseholdInputFile(HouseholdFileName, hhInFile);
  if writeHouseholds then begin
    openHouseholdDayOutputFile(HouseholdDayFileName, hhDayOutFile);
    openHouseholdVehicleOutputFile(HouseholdVehicleFilename, hhVehicleOutFile);
  end;
  openTourOutputFile(TourFileName, tourOutFile);

  {for mode:=0 to nTourModes do
    openTripMatrixOutputFile(mode);}

  if writeMDLogsums then begin
    assign(lsfile,'mdlogsums3.dat'); rewrite(lsfile);
  end;
  nHHRecs:=0;
  nHHinZone:=0;
  lasthhZoneIndex:=0;
  lastHH:=False;
  repeat //for each household
    nHHRecs:=nHHRecs+1;
    nHHinZone:=nHHinZone+1;
    if nHHRecs mod (numberOfHouseholds div 1000) = 0 then begin
      percent:=nHHRecs/numberOfHouseholds * 100.0;
      writeln('Households read: ', nHHRecs:9, '/', numberOfHouseholds:9, percent:6:1, '%');
    end;
    hhRecord := loadNextHouseholdRecord(
      lastHH,
      hhInFile,
      scenarioIncomeChange,
      sample1inx,
      stateToUseSeparateCoefficientFiles,
      stateToReadCarOwnershipFromHHFile,
      zoneIndex
      );
    if (hhRecord.hhzoneIndex<lasthhZoneIndex) then begin
     writeln('Household file out of zone sort order - zone ',zoneId[hhRecord.hhzoneIndex],
       ' is after zone ',zoneId[lasthhZoneIndex],'. Abort the run!');
     readln;
    end;

    if (nHHRecs mod Sample1inX = SampleOffset) or (writeMDLogsums) then begin
      // if moving on to next zone, get new LOSs
      if (hhRecord.hhZoneIndex>lasthhZoneIndex) then begin
        readRoadLosMatrices(hhRecord.hhZoneIndex);
        readRailLosMatrices(hhRecord.hhZoneIndex);
        readAirLosMatrices(hhRecord.hhZoneIndex);

        calculateModeDestinationProbabilities(
          hhRecord);

        if (writeMDLogsums) then begin
          for hhseg:=1 to nhhsegs do begin
            write(lsfile,hhRecord.hhZoneIndex,' ',ZoneId[hhRecord.hhZoneIndex],' ',hhseg);
            for purpose:=1 to nTourPurposes do
            for dband:=1 to nDistBands do
              write(lsfile,' ',accessibilityLogsums[hhseg,purpose,dband]:6:5);
            writeln(lsfile);
          end;
        end;
        lasthhZoneIndex:=hhRecord.hhZoneIndex;
        nHHinZone:=1;
      end;
      
      if (nHHRecs mod Sample1inX = SampleOffset) then begin

        if useRandomNumberSynchronization then hhRecord.generator := generateRandomDraws(hhRecord.hhID);

        applyAutoOwnershipModel(hhRecord);
        applyTourGenerationModel(hhRecord);
        if writeHouseholds then begin
          writeHouseholdDayRecord(hhRecord, outDelim, hhDayOutFile);
        end;
      end;
    end;
  until(lastHH);
  closeRoadLosMatrices;
  closeRailLosMatrices;
  closeAirLosMatrices;
  if writeHouseholds then begin
    close(hhInFile);
    close(hhDayOutFile);
    close(hhVehicleOutFile);
  end;
  if writeTours then close(tourOutFile);
  {for mode:=0 to nTourModes do
   writeAndCloseTripMatrixOutputFile(mode);}
  writeSummaryOutput(logfile);
  
  if (WriteSkimsEveryXZones>0) then closeSkimExtract();

  if writeMDLogsums then close(lsfile);
  writeln(logFile); writeln(logFile,'Run finished at ',DateTimetoStr(now),' with ',nHHrecs,' households processed');
  close(logFile);
  writeln; writeln('Run finished at ',DateTimetoStr(now),' with ',nHHrecs,' households processed');
  if not(runInBatchMode) then begin
    write('Press Enter to exit'); readln;
  end;
end.
