program rJourney_1_3;

{$APPTYPE CONSOLE}

uses
  SysUtils;

function max(a,b:single):single;
begin
  if a>b then max:=a else max:=b;
end;

function min(a,b:single):single;
begin
  if a<b then min:=a else min:=b;
end;

function ifin(a,b,c:single):integer;
begin
  if ((a>=b) and (a<=c))
  or ((a>=c) and (a<=b)) then ifin:=1 else ifin:=0;
end;

function ifeq(a,b:single):integer;
begin
  if (a=b) then ifeq:=1 else ifeq:=0;
end;

function ifge(a,b:single):integer;
begin
  if (a>=b) then ifge:=1 else ifge:=0;
end;

function iflt(a,b:single):integer;
begin
  if (a<b) then iflt:=1 else iflt:=0;
end;
function setFileName(dirname,filename:string):string;
begin
  if filename[2]=':'
     then setFileName:=filename
  else if (dirname[length(dirname)]='\') or (filename[1]='\')
       or (dirname[length(dirname)]='/') or (filename[1]='/')
     then setFileName:=dirname+filename
  else setFileName:=dirname+'\'+filename;
end;

{Constants}
const
{user inputs}
 RunTitle:string='National_Long_Distance_Model';
 InputDirectoryName:string='inputs';
 RoadLOSFileName:string='zoneRoadLOS.dat';
 RailLOSFileName:string='zoneRailLOS.dat';
 AirLOSFileName:string='zoneAirLOS.dat';
 ZoneLandUseFileName:string='numa_2010_landuse.dat';
 HouseholdFileName:string='us_synpop_hh2_sorted.dat';
 OutputDirectoryName:string='outputs';
 HouseholdDayFileName:string='household_out_1.csv';
 TourFileName:string='tour_out_1.csv';
 TripMatrixFileName:array[0..4] of string=
 ('auto_vtripmat_1.csv',
  'auto_ptripmat_1.csv',
  'bus_ptripmat_1.csv',
  'rail_ptripmat_1.csv',
  'air_ptripmat_1.csv');
 MonthOfYear:integer = 0;
 EachDayOfTheMonth:boolean = False;
 outDelimCode:integer = 44;
 outDelim:char=',';
 randomSeed:integer = 12345;
 Sample1inX:integer = 1;
 SampleOffset:integer = 0;
 WriteHouseholds:boolean = True;
 WriteTours:boolean = True;
 WriteTripMatrix:array[0..4] of boolean=(True,True,True,True,True);
 WriteProbs:boolean=False;
 WriteADT:boolean=False;
 TripMatrixMinimumDistance:integer=50;
 DaysInMonth:array[0..12] of integer=(365, 31,28,31, 30,31,30, 31,31,30, 31,30,31);
 CoefficientDirectoryName:string = 'coeffcients';
 FrCoefFile:array[1..2] of string =
 ('freqest3a.f12',
  'fsecest3a.f12');
 DCCoefFile:array[1..5] of string =
 ('pbusdest6_bxc.F12',
  'vfardest6_bxc.F12',
  'leisdest6_bxc.F12',
  'commdest6_bxc.F12',
  'ebusdest6_bxc.F12');
 MCCoefFile:array[1..5] of string =
 ('pbusmode13_est.F12',
  'vfarmode13_est.F12',
  'leismode13_est.F12',
  'commmode13_est.F12',
  'ebusmode13_est.F12');
 TDCoefFile:array[1..5] of string =
 ('pbus_dur3.F12',
  'vfar_dur3.F12',
  'leis_dur3.F12',
  'comm_dur3.F12',
  'ebus_dur3.F12');
 PSCoefFile:array[1..5] of string =
 ('pbus_psize3.F12',
  'vfar_psize3.F12',
  'leis_psize3.F12',
  'comm_psize3.F12',
  'ebus_psize3.F12');
  AOCoefFile:string='inputs\carown3.f12';
  scenarioIncomeChange:single=0;
  scenarioAutoCostChange:single=0;
  scenarioAutoTimeChange:single=0;
  scenarioAirFareChange:single=0;
  scenarioRailTimeChange:single=0;
  copercpm:single = 0.2;
  runInBatchMode:boolean = false;
  writeMDLogsums=false;


procedure resetTextFile(var f:text; fn:string);
var i:integer;
begin
  {$I-} assign(f,fn); reset(f); {$I+}
  i:=IOResult;
  if i>0 then begin write('Cannot open text file ',fn,' for input (Press Enter)'); readln; end;
end;

procedure rewriteTextFile(var f:text; fn:string);
var i:integer;
begin
  {$I-} assign(f,fn); rewrite(f); {$I+}
  i:=IOResult;
  if i>0 then begin write('Cannot open text file ',fn,' for output (Press Enter)'); readln; end;
end;

var logFile:text;
procedure GetConfigurationSettings;
var s,key0,key,arg:string; cinf:text; lastpos,m:integer;

function parse(ss:string; var pos:integer): string;
var temp:string;
begin
  temp:='';
  if pos<length(ss) then
  repeat
    pos:=pos+1;
  until (pos>=length(ss)) or (ss[pos]<>' ');
  repeat
    temp:=temp+ss[pos];
    pos:=pos+1;
  until (pos>=length(ss)) or (ss[pos]=' ');
  if (pos<=length(ss)) and (ss[pos]<>' ') then temp:=temp+ss[pos];
  parse:=temp;
end;

function checkInt(ss:string; low,high:integer):integer;
var x,i:integer;
begin
  {$I-} x:=strtoint(ss); {$I+}
  i:=ioResult;
  if i>0 then begin write('Invalid argument for integer value: ',ss,'  (Press Enter)'); readln; end
  else if (x<low) then begin
    write('Integer value ',x,' below valid range: ',low,' - ',high,'  (Press Enter)'); readln;
    checkInt:=low;
  end
  else if (x>high) then begin
    write('Integer value ',x,' below valid range: ',low,' - ',high,'  (Press Enter)'); readln;
    checkInt:=high;
  end
  else checkInt:=x;
end;

function checkBool(ss:string):boolean;
var ss2:string;
begin
  ss2:=lowercase(ss);
  if (ss2='t') or (ss2='true') then checkBool:=True else
  if (ss2='f') or (ss2='false') then checkBool:=False else begin
    write('Invalid argument for boolean variable ',ss,'  (Press Enter)'); readln;
    checkBool:=False;
  end;
end;

const configfname:string='inputs\test3_config.txt';
var nlogs:integer;
begin
  if paramCount>0 then configfname:=paramStr(1) else begin
    writeln('<<<< FHWA National Long Distance Passenger Model: rJourney V.1.3 >>>> (c) 2018 RSG');
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
        if key='householdfilename' then  HouseholdFileName  :=arg else
        if key='coefficientdirectoryname' then CoefficientDirectoryName:=arg else
        if key='destchoicecoefficientfile_1' then DCCoefFile[1]:=arg else
        if key='destchoicecoefficientfile_2' then DCCoefFile[2]:=arg else
        if key='destchoicecoefficientfile_3' then DCCoefFile[3]:=arg else
        if key='destchoicecoefficientfile_4' then DCCoefFile[4]:=arg else
        if key='destchoicecoefficientfile_5' then DCCoefFile[5]:=arg else
        if key='modechoicecoefficientfile_1' then MCCoefFile[1]:=arg else
        if key='modechoicecoefficientfile_2' then MCCoefFile[2]:=arg else
        if key='modechoicecoefficientfile_3' then MCCoefFile[3]:=arg else
        if key='modechoicecoefficientfile_4' then MCCoefFile[4]:=arg else
        if key='modechoicecoefficientfile_5' then MCCoefFile[5]:=arg else
        if key='partysizecoefficientfile_1' then PSCoefFile[1]:=arg else
        if key='partysizecoefficientfile_2' then PSCoefFile[2]:=arg else
        if key='partysizecoefficientfile_3' then PSCoefFile[3]:=arg else
        if key='partysizecoefficientfile_4' then PSCoefFile[4]:=arg else
        if key='partysizecoefficientfile_5' then PSCoefFile[5]:=arg else
        if key='nightsawaycoefficientfile_1' then TDCoefFile[1]:=arg else
        if key='nightsawaycoefficientfile_2' then TDCoefFile[2]:=arg else
        if key='nightsawaycoefficientfile_3' then TDCoefFile[3]:=arg else
        if key='nightsawaycoefficientfile_4' then TDCoefFile[4]:=arg else
        if key='nightsawaycoefficientfile_5' then TDCoefFile[5]:=arg else
        if key='tourfreqcoefficientsfile_1' then  FrCoefFile[1] :=arg else
        if key='tourfreqcoefficientsfile_2' then  FrCoefFile[2] :=arg else
        if key='autoowncoefficientsfile' then  AOCoefFile :=arg else
        if key='outputdirectoryname' then OutputDirectoryName:=arg else
        if key='householdoutputfilename' then  HouseholdDayFileName :=arg else
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
        if key='sample1inx' then    Sample1inX :=checkint(arg,1,1000000) else
        if key='sampleoffset' then  SampleOffset :=checkint(arg,0,99999) else
        if key='writehouseholdrecords' then  WriteHouseholds  :=checkbool(arg) else
        if key='writetourrecords' then  WriteTours  :=checkbool(arg) else
        if key='writeautovehicletripmatrix' then  WriteTripMatrix[0] :=checkbool(arg) else
        if key='writeautopersontripmatrix' then  WriteTripMatrix[1] :=checkbool(arg) else
        if key='writebuspersontripmatrix' then  WriteTripMatrix[2] :=checkbool(arg) else
        if key='writerailpersontripmatrix' then  WriteTripMatrix[3] :=checkbool(arg) else
        if key='writeairpersontripmatrix' then  WriteTripMatrix[4] :=checkbool(arg) else
        if key='useprobabilitiesinmatrices' then  WriteProbs:= checkbool(arg) else
        if key='useadtunitsinmatrices' then  WriteADT :=checkbool(arg) else
        if key='runinbatchmode' then  runInBatchMode :=checkbool(arg) else
        if key='autooperatingcentspermile' then copercpm:=checkint(arg,0,1000)/100.0 else
        if key='tripmatrixminimumdistance' then TripMatrixMinimumDistance:=checkint(arg,50,5000) else
        if key='scenariopercentincomechange' then  scenarioIncomeChange :=checkint(arg,-100,100) else
        if key='scenariopercentautocostchange' then  scenarioAutoCostChange :=checkint(arg,-100,100) else
        if key='scenariopercentautotimechange' then  scenarioAutoTimeChange :=checkint(arg,-100,100) else
        if key='scenariopercentairfarechange' then  scenarioAirFareChange :=checkint(arg,-100,100) else
        if key='scenariopercentrailtimechange' then  scenarioRailTimeChange :=checkint(arg,-100,100) else
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

{array dimensions}
const
 nTracts = 73057;
 mZones =  4700;
 maxZone = 99999;
 nCensDivs = 10;
 censDivLabel:array[1..nCensDivs] of string=('New Eng','Mid Atl','NE Cent','NW Cent','Sou Atl','SE Cent','SW Cent','Mountn ','Pacific','AK & HI');
 stateCensDiv:array[1..56] of integer=
 (6,10,0,8,7,9,0,8,1,5,
  5,5,5,0,10,8,3,3,4,4,
  6,7,1,5,1, 3,4,6,4,8,
  4,8,1,2,8, 2,5,4,3,7,
  9,2,0,1,5, 4,6,7,8,1,
  5,0,9,5,3, 8);

{array types}
type
 zoneInt = array[1..mZones] of integer;
 zoneSingle = array[1..mZones] of single;
 zoneDouble = array[1..mZones] of double;
 zoneMatrix = array[1..mZones,1..mZones] of word;
 zoneMatrixOut = array[1..mZones,1..mZones] of single;

{***  CODE to declare and load zone-level land use data ***}
var
zoneIndex:array[0..maxZone] of integer;
nZones:integer;

{land use variables}
 zoneId      :zoneInt;
 zoneTracts  :zoneInt;
 landSqm     :zoneSingle;
 zoneLat     :zoneSingle;
 zoneLong    :zoneSingle;
 zoneState   :zoneInt;
 parkSqm     :zoneSingle;
 totHH       :zoneSingle;
 univEnr     :zoneSingle;
 totalEmp    :zoneSingle;
 agricEmp    :zoneSingle;
 mininEmp    :zoneSingle;
 utiliEmp    :zoneSingle;
 constEmp    :zoneSingle;
 manufEmp    :zoneSingle;
 wholeEmp    :zoneSingle;
 retaiEmp    :zoneSingle;
 transEmp    :zoneSingle;
 inforEmp    :zoneSingle;
 finanEmp    :zoneSingle;
 realeEmp    :zoneSingle;
 profeEmp    :zoneSingle;
 managEmp    :zoneSingle;
 adminEmp    :zoneSingle;
 educaEmp    :zoneSingle;
 medicEmp    :zoneSingle;
 enterEmp    :zoneSingle;
 accomEmp    :zoneSingle;
 oservEmp    :zoneSingle;
 pubadEmp    :zoneSingle;
 stateEmp    :zoneSingle;
 federEmp    :zoneSingle;
 nBusStats   :zoneSingle;
 nRailStats  :zoneSingle;
 minSTDist   :zoneSingle;
 nAirports   :zoneSingle;
 minAPDist   :zoneSingle;

 zUrban,zSuburb,zRural:zoneInt;
 leishosp,othemp,totDens,zLogDens,zParkFrac:zoneSingle;

procedure loadZoneLandUseData(filename:string);
var inf:text; index:integer;
begin
  filename:=setFileName(InputDirectoryName,filename);
  writeln(logFile,'Loading Zone Land Use Data from ',filename);
  writeln('Loading Zone Land Use Data from ',filename);
  resetTextFile(inf,filename);
  readln(inf); {header}
  index:=0;
  repeat
    index:=index+1;
    readln(inf,
    zoneId   [index],
    zoneTracts[index],
    landSqm  [index],
    zoneLat  [index],
    zoneLong [index],
    zoneState[index],
    parkSqm  [index],
    totHH    [index],
    univEnr  [index],
    totalEmp [index],
    agricEmp [index],
    mininEmp [index],
    utiliEmp [index],
    constEmp [index],
    manufEmp [index],
    wholeEmp [index],
    retaiEmp [index],
    transEmp [index],
    inforEmp [index],
    finanEmp [index],
    realeEmp [index],
    profeEmp [index],
    managEmp [index],
    adminEmp [index],
    educaEmp [index],
    medicEmp [index],
    enterEmp [index],
    accomEmp [index],
    oservEmp [index],
    pubadEmp [index],
    stateEmp [index],
    federEmp [index],
    nBusStats[index],
    nRailStats[index],
    minSTDist[index],
    nAirports[index],
    minAPDist[index]);

    zoneIndex[zoneId[index]]:=index;

    {transformations}
    leishosp[index]:=accomEmp[index]+enterEmp[index];
    othemp[index]:=max(0,totalEmp[index]-leisHosp[index]-retaiEmp[index]-oservEmp[index]);
    totDens[index]:=(totalEmp[index]+totHH[index])/landSqm[index];
    zLogDens[index]:=ln(max(1.0,totDens[index]));

    zUrban[index]:= integer(totdens[index]>=1000);
    zRural[index]:= integer(totdens[index]<30);
    zSuburb[index]:= 1-zurban[index]-zrural[index];

    zParkFrac[index]:=parkSqm[index]/landSqm[index];

  until eof(inf);
  nZones:=index;
end;

{**** Code to declare and load road LOS matrices ****}

var carDist,carTime,carToll,busTime,busFare:zoneMatrix;

procedure loadRoadLOSMatrices(filename:string);
var inf:text; o,d,oIndex,dIndex:integer; var zonesConnected, ldZonesConnected:zoneInt;
begin
  filename:=setFileName(InputDirectoryName,filename);
  writeln(logFile,'Loading Road LOS Matrices from ',filename);
  writeln('Loading Road LOS Matrices from ',filename);
  {empty matrices}
  for o:=1 to nZones do zonesConnected[o]:=0;
  ldZonesConnected:=zonesConnected;
  for o:=1 to nZones do for d:=1 to nZones do carTime[o][d]:=0;
  carDist := carTime;
  carToll := carTime;
  busTime := carTime;
  busFare := carTime;
  resetTextFile(inf,filename);
  repeat
    read(inf,o,d);
    oIndex:=zoneIndex[o];
    dIndex:=zoneIndex[d];
    readln(inf,
      carTime[oIndex][dIndex],
      carDist[oIndex][dIndex],
      carToll[oIndex][dIndex],
      busTime[oIndex][dIndex],
      busFare[oIndex][dIndex]);
    if carDist[oindex][dindex]>0 then zonesConnected[oindex]:=zonesConnected[oindex]+1;
    if carDist[oindex][dindex]>=50 then ldZonesConnected[oindex]:=ldZonesConnected[oindex]+1;
    carTime[oindex][dindex]:=round(carTime[oindex][dindex]*(1.0+scenarioAutoTimeChange/100.0));
    carToll[oIndex][dIndex]:=round(min(65000,carToll[oIndex][dIndex]*(1.0+scenarioAutoCostChange/100.0)));


  until eof(inf);
  {for oindex:=1 to nZones do
  if (ldZonesConnected[oindex]=0) or (zoneState[oindex]=2) or (zoneState[oindex]=15) then begin
    write(' zone ',zoneId[oindex],' in state ',zoneState[oindex],' car connections/LD connnections = ',zonesConnected[oindex]:5,ldZonesConnected[oindex]:5); readln;
  end;}
  copercpm:=copercpm*(1.0+scenarioAutoCostChange/100.0);

end;

var railTime, railXfer, railFreq, railEconFare, railBusiFare, railAcEgDist, railOrigStation, railDestStation :zoneMatrix;

procedure loadRailLOSMatrices(filename:string);
var inf:text; o,d,oIndex,dIndex,temp1,temp2:integer;
begin
  filename:=setFileName(InputDirectoryName,filename);
  writeln(logFile,'Loading Rail LOS Matrices from ',filename);
  writeln('Loading Rail LOS Matrices from ',filename);
  {empty matrices}
  for o:=1 to nZones do for d:=1 to nZones do RailTime[o][d]:=0;
  railXfer := railTime;
  railFreq := railTime;
  railEconFare := railTime;
  railBusiFare := railTime;
  railAcEgDist := railTime;
  resetTextFile(inf,filename);
  repeat
    read(inf,o,d);
    oIndex:=zoneIndex[o];
    dIndex:=zoneIndex[d];
    readln(inf,
      railTime[oIndex][dIndex],
      railXfer[oIndex][dIndex],
      railFreq[oIndex][dIndex],
      railEconFare[oIndex][dIndex],
      railBusiFare[oIndex][dIndex],
      temp1,temp2,
      railOrigStation[oindex][dindex],
      railDestStation[oindex][dindex]);
    railAcEgDist[oIndex][dIndex]:=temp1+temp2;
    railTime[oindex][dindex]:=round(min(650000,railTime[oindex][dindex]*(1.0+scenarioRailTimeChange/100.0)));
  until eof(inf);
end;

var airTime, airXfer, airFreqDirect, airFreq1Stop, airFreq2Stop, airReli30, airEconFare, airBusiFare, airAcEgDist, airOrigAirport, airDestAirport, airOnlyAKHI:zoneMatrix;

procedure loadAirLOSMatrices(filename:string);
var inf:text; o,d,oIndex,dIndex,temp1,temp2:integer;  var zonesConnected, ldZonesConnected:zoneInt;
begin
  filename:=setFileName(InputDirectoryName,filename);
  writeln(logFile,'Loading Air LOS Matrices from ',filename);
  writeln('Loading Air LOS Matrices from ',filename);
  {empty matrices}
  for o:=1 to nZones do zonesConnected[o]:=0;
  ldZonesConnected:=zonesConnected;
  for o:=1 to nZones do for d:=1 to nZones do airTime[o][d]:=0;
  airXfer := airTime;
  airFreqDirect := airTime;
  airFreq1Stop  := airTime;
  airFreq2Stop  := airTime;
  airReli30    := airTime;
  airEconFare := airTime;
  airBusiFare := airTime;
  airAcEgDist := airTime;
  airOnlyAKHI := airTime;
  resetTextFile(inf,filename);
  repeat
    read(inf,o,d);
    oIndex:=zoneIndex[o];
    dIndex:=zoneIndex[d];
    readln(inf,
      airTime[oIndex][dIndex],
      airXfer[oIndex][dIndex],
      airFreqDirect[oIndex][dIndex],
      airFreq1Stop [oIndex][dIndex],
      airFreq2Stop [oIndex][dIndex],
      airReli30[oIndex][dIndex],
      airEconFare[oIndex][dIndex],
      airBusiFare[oIndex][dIndex],
      temp1,temp2,
      airOrigAirport[oindex][dindex],
      airDestAirport[oindex][dindex]);
    airAcEgDist[oIndex][dIndex]:=temp1+temp2;
    airBusiFare[oIndex][dIndex]:=round((airBusiFare[oIndex][dIndex]+airEconFare[oIndex][dIndex])/2.0);
    airEconFare[oindex][dindex]:=round(min(65000,airEconFare[oindex][dindex]*(1.0+scenarioAirFareChange/100.0)));
    airBusiFare[oindex][dindex]:=round(min(65000,airBusiFare[oindex][dindex]*(1.0+scenarioAirFareChange/100.0)));

    {if there is an air connection for alaska and hawaii to 48 estimate car distance, but leave car time at 0}
    if (carDist[oIndex][dIndex]=0)
    and (((zoneState[oIndex]= 2) and (zoneState[dIndex]<> 2))   {alaska-non-alaska}
     or  ((zoneState[oIndex]=15) and (zoneState[dIndex]<>15))   {hawaii-non-hawaii}
     or  ((zoneState[dIndex]= 2) and (zoneState[oIndex]<> 2))   {non-alaska-alaska}
     or  ((zoneState[dIndex]=15) and (zoneState[oIndex]<>15)))  {non-hawaii-hawaii} then begin
      airOnlyAKHI[oIndex][dIndex]:=1;
      temp1:=round(
      sqrt((zoneLat [oIndex]-zoneLat [dIndex])*(zoneLat [oIndex]-zoneLat [dIndex])*69.0*69.0
          +(zoneLong[oIndex]-zoneLong[dIndex])*(zoneLong[oIndex]-zoneLong[dIndex])*65.0*65.0));
      carDist[oIndex][dIndex]:=temp1;
    end;

    if airtime[oindex][dindex]>0 then zonesConnected[oindex]:=zonesConnected[oindex]+1;
  until eof(inf);
  {for oindex:=1 to nZones do
  if (zonesConnected[oindex]=0) or (zoneState[oindex]=2) or (zoneState[oindex]=15) then begin
    write(' zone ',zoneId[oindex],' in state ',zoneState[oindex],' air connections = ',zonesConnected[oindex]:5); readln;
  end;}
end;

var ouf:text;

{ *** CODE TO DECLARE AND LOAD HOUSEHOLD SAMPLE VARIABLES *** }
var hhId, hhZone, hhSize, hhWorkers, hhNonWkrs, hhHasKids, hhHeadAge, hhIncome: integer; hhExpFactor, hhExpOut:single;
    hhLogIncome, hhZoneDensity, hhLogDensity, hhWorkerRatio, hhWorkerRatio2:single;
    hhZoneIndex, hhRural, hhUrban, hhHeadUnder35, hhHeadOver65, hhAdults, hh1Adult, hh3Adults, hh4PlusAdults,
    hhVehicles, hhHas1Vehicle, hhHas2Vehicles, hhHas3PlusVehicles, hhHas0Vehicles, hhHasCarCompetition,
    hhIncSeg,hhModeDestSeg:integer;  hhTract:double;

    hhInFile:text;

procedure openHouseholdInputFile(filename:string);
begin
  filename:=setFileName(InputDirectoryName,filename);
  resetTextFile(hhInFile,filename);
  readln(hhInFile); {header}
end;

procedure closeHouseholdInputFile;
begin
  close(hhInFile);
end;


procedure loadNextHouseholdRecord (var lastRecord:boolean);
begin
  repeat
    readln(hhInFile, hhId, hhTract, hhZone, hhSize, hhWorkers, hhNonWkrs, hhHasKids, hhHeadAge, hhIncome, hhExpFactor);
    lastRecord:=eof(hhInFile);
  until (lastRecord) or (hhHeadAge>0);
  {transformation variables}
  hhIncome:=round(hhIncome*(1.0+scenarioIncomeChange/100.0));
  hhLogIncome:=ln(max(1.0,hhIncome/1000.0));
  hhZoneIndex:= zoneIndex[hhZone];
  hhZoneDensity:=totDens[hhZoneIndex];
  hhLogDensity:=zLogDens[hhZoneIndex];
  hhRural:= zRural[hhZoneIndex];
  hhUrban:= zUrban[hhZoneIndex];
  hhAdults:=hhWorkers+hhNonWkrs;
  if (hhAdults>hhSize) then hhAdults:=hhSize;
  if hhAdults<1 then hhAdults:=1;
  hhHasKids:=integer(hhSize>hhAdults);
  hhWorkerRatio:= hhWorkers*1.0/hhSize;
  hhWorkerRatio2:= hhWorkers*1.0/hhAdults;
  hh1Adult:=integer(hhAdults=1);
  hh3Adults:=integer(hhAdults=3);
  hh4PlusAdults:=integer(hhAdults>=4);
  if hhHeadAge<35 then hhHeadUnder35:=1 else hhHeadUnder35:=0;
  if hhHeadAge>=65 then hhHeadOver65:=1 else hhHeadOver65:=0;
  hhExpOut := hhExpFactor * Sample1inX;
  if hhIncome>=150000 then hhIncseg:=5 else
  if hhIncome>=100000 then hhIncseg:=4 else
  if hhIncome>= 65000 then hhIncseg:=3 else
  if hhIncome>= 35000 then hhIncseg:=2 else hhIncseg:=1;

end;

{ *** CODE TO DECLARE AND WRITE HOUSEHOLD OUTPUT VARIABLES *** }

const nTourPurposes = 5;
      PersBusPurp = 1;
      VisitPurp = 2;
      LeisurePurp = 3;
      CommutePurp = 4;
      EmplBusPurp = 5;
      hhVehCats=5;
      hhIncCats=5;
      trPurposeLabel:array[0..nTourPurposes] of string=('Total  ','PersBus','VisitFR','Leisure','Commute','EmplBus');
      hhIncLabel:array[0..hhIncCats] of string=        ('Total  ','0-35 $k','35-65$k','65-100k','100-150','Over150');
      hhVehLabel:array[1..hhVehCats] of string=        ('0 cars ','1 car  ','2 cars ','3 cars ','4+ cars');


var hhTours:array[1..nTourPurposes] of integer;
    hhDayOutFile:text;
    hhSimulated:array[0..hhIncCats] of double;
    hhVehiclesPred:array[0..hhIncCats,1..hhVehCats] of double;
    hhToursPred:array[0..hhIncCats,1..nTourPurposes] of double;


procedure openHouseholdDayOutputFile(filename:string);
begin
  if WriteHouseholds then begin
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
  end;
end;

procedure closeHouseholdDayOutputFile;
begin
  if WriteHouseholds then close(hhDayOutFile);
end;

procedure writeHouseholdDayRecord;
var purpose:integer;
begin
  if WriteHouseholds then begin
    write(hhDayOutFile, hhId,
    outDelim,hhZone,
    outDelim,zoneState[zoneIndex[hhZone]],
    outDelim,hhSize,
    outDelim,hhWorkers,
    outDelim,hhNonWkrs,
    outDelim,hhHasKids,
    outDelim,hhHeadAge,
    outDelim,hhIncome,
    outDelim,hhVehicles);
    for purpose:=1 to nTourPurposes do write(hhDayOutFile,
      outDelim,hhTours[purpose]);
    writeln(hhDayOutFile,
      outDelim,hhExpOut:3:2);
  end;
end;


{ *** CODE TO DECLARE AND WRITE TOUR OUTPUT VARIABLES *** }

const nTourModes = 4;
      carMode = 1;
      busMode = 2;
      railMode = 3;
      airMode = 4;
      nTrDistBands = 7;
      trDistBandLowLimit:array[1..nTrDistBands] of integer = (50,100,150,250,500,1000,2000);
      trDistLabel:array[1..nTrDistBands] of string=('50-99 m','100-149','150-249','250-499','500-999','-1999 m','2000+ m');
      nTrPartySizes = 4;
      trPSizeLabel:array[1..nTrPartySizes] of string=('1 pers ','2 pers ','3 pers ','4+ pers');
      nTrNightsAway = 4;
      trNAwayLabel:array[1..nTrNightsAway] of string=('Daytrip','1-2 nts','3-6 nts','7+ nts ');
      trModeLabel:array[1..nTourModes] of string=      ('Car    ','Bus    ','Rail   ','Air    ');

var trNo, trPurpose, trPartySize, trNightsCategory, trMode, trOZone, trOState, trDZone, trDState, trMonth,
    trJanToMar,trJunToAug,trNovToDec, trAprToJun,trJulToSep,trOctToDec,
    trDayTrip,tr1or2Nights,tr3to6Nights,tr7PlusNights,
    trSinglePerson, trGroup3Plus,
    trOrigStation, trDestStation,
    trAutoDistance, trTravelTime, trTravelCost:integer; trExpFactor:single;
    tourOutFile:text;
    trSimulated:array[0..nTourPurposes] of double;
    trModePred:array[0..nTourPurposes,1..nTourModes] of double;
    trDistPred:array[0..nTourPurposes,1..nTrDistBands] of double;
    trModeDist:array[0..nTourPurposes,1..nTourModes,1..nTrDistBands] of double;
    trPSizePred:array[0..nTourPurposes,1..nTrPartySizes] of double;
    trNAwayPred:array[0..nTourPurposes,1..nTrNightsAway] of double;
    trDivODPred:array[1..nTourModes,1..nCensDivs,1..nCensDivs] of double;

procedure openTourOutputFile(filename:string);
begin
  if writeTours then begin
    filename:=setFileName(OutputDirectoryName,filename);
    rewriteTextFile(tourOutFile,filename);
    writeln(tourOutFile,'hhId',
    outDelim,'trNo',
    outDelim,'trMonth',
    outDelim,'trPurpose',
    outDelim,'trPartySize',
    outDelim,'trNightsCategory',
    outDelim,'trMode',
    outDelim,'trOState',
    outDelim,'trDState',
    outDelim,'trOZone',
    outDelim,'trDZone',
    outDelim,'trAutoDistance',
    outDelim,'trTravelTime',
    outDelim,'trTravelCost',
    outDelim,'trExpFactor',
    outDelim,'trOrigStation',
    outDelim,'trDestStation'); {header}
  end;
end;

procedure closeTourOutputFile;
begin
  if writeTours then close(tourOutFile);
end;

procedure writeTourRecord;
var purpose:integer;
begin
  if writeTours then begin
    writeln(tourOutFile, hhId,
    outDelim,trNo,
    outDelim,trMonth,
    outDelim,trPurpose,
    outDelim,trPartySize,
    outDelim,trNightsCategory,
    outDelim,trMode,
    outDelim,trOState,
    outDelim,trDState,
    outDelim,trOZone,
    outDelim,trDZone,
    outDelim,trAutoDistance,
    outDelim,trTravelTime,
    outDelim,trTravelCost,
    outDelim,trExpFactor:1:0,
    outDelim,trOrigStation,
    outDelim,trDestStation);
  end;
end;

var tripMats:array[0..nTourModes] of zoneMatrixOut;
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
    for i:=1 to nZones do
    for j:=1 to nZones do
      tripMats[m][i][j]:=0.0;
  end;
end;

procedure writeAndCloseTripMatrixOutputFile(m:integer);
var i,j:integer;
begin
  if writeTripMatrix[m] then begin
    for i:=1 to nZones do
    for j:=1 to nZones do
    if (tripMats[m][i][j]>0) then begin
      writeln(tripMatOutFile[m], zoneId[i],
      outdelim,zoneId[j],
      outdelim,tripMats[m][i][j]:6:5);
    end;
    close(tripMatOutFile[m]);
  end;
end;


procedure initializeSummaryOutput;
var i,j,k:integer;
begin
  for i:=0 to hhIncCats do begin
    hhSimulated[i]:=0;
    for j:=1 to hhVehCats do hhVehiclesPred[i,j]:=0;
    for j:=1 to nTourPurposes do hhToursPred[i,j]:=0;
  end;
  for i:=0 to nTourPurposes do begin
    trSimulated[i]:=0;
    for j:=1 to nTrNightsAway do trNAwayPred[i,j]:=0;
    for j:=1 to nTrPartySizes do trPSizePred[i,j]:=0;
    for j:=1 to nTrDistBands do trDistPred[i,j]:=0;
    for j:=1 to nTourModes do begin
      trModePred[i,j]:=0;
      for k:=1 to nTrDistBands do trModeDist[i,j,k]:=0;
    end;
  end;
  for i:=1 to nTourModes do
  for j:=1 to nCensDivs do
  for k:=1 to nCensDivs do trDivODPred[i,j,k]:=0;
end;

procedure writeSummaryOutput;
var i,j,k:integer;
begin
  {get totals by income and purpose}
  for i:=1 to hhIncCats do begin
    hhSimulated[0]:=hhSimulated[0]+hhSimulated[i];
    for j:=1 to hhVehCats do hhVehiclesPred[0,j]:=hhVehiclesPred[0,j]+hhVehiclesPred[i,j];
    for j:=1 to nTourPurposes do hhToursPred[0,j]:=hhToursPred[0,j]+hhToursPred[i,j];
  end;
  for i:=1 to nTourPurposes do begin
    trSimulated[0]:=trSimulated[0]+trSimulated[i];
    for j:=1 to nTrNightsAway do trNAwayPred[0,j]:=trNAwayPred[0,j]+trNAwayPred[i,j];
    for j:=1 to nTrPartySizes do trPSizePred[0,j]:=trPSizePred[0,j]+trPSizePred[i,j];
    for j:=1 to nTrDistBands do trDistPred[0,j]:=trDistPred[0,j]+trDistPred[i,j];
    for j:=1 to nTourModes do begin
      trModePred[0,j]:=trModePred[0,j]+trModePred[i,j];
      for k:=1 to nTrDistBands do trModeDist[0,j,k]:=trModeDist[0,j,k]+trModeDist[i,j,k];
    end;
  end;
  writeln(logFile);
  writeln(logFile,'Total expanded households simulated = ',hhSimulated[0]:1:0);
  writeln(logFile);
  writeln(logFile,'Household car ownership distribution by income group');
  write(logFile,'Income>'); for i:=0 to hhIncCats do write(logFile,'  ',hhIncLabel[i]); writeln(logFile);
  for j:=1 to hhVehCats do begin
    write(logFile,hhVehLabel[j]); for i:=0 to hhIncCats do write(logFile,'  ',hhVehiclesPred[i,j]/max(hhSimulated[i],1)*100.0:6:2,'%'); writeln(logFile);
  end;
  writeln(logFile);
  writeln(logFile,'Household tour rates by purpose and income group (for simulated period)');
  write(logFile,'Income>'); for i:=0 to hhIncCats do write(logFile,'  ',hhIncLabel[i]); writeln(logFile);
  for j:=1 to nTourPurposes do begin
    write(logFile,trPurposeLabel[j]); for i:=0 to hhIncCats do write(logFile,'  ',hhToursPred[i,j]/max(hhSimulated[i],1):7:4); writeln(logFile);
  end;
  writeln(logFile);
  writeln(logFile,'Total expanded tours simulated = ',trSimulated[0]:1:0);
  writeln(logFile);
  writeln(logFile,'Tour nights away distribution by purpose');
  write(logFile,'Purpose'); for i:=0 to nTourPurposes do write(logFile,'  ',trPurposeLabel[i]); writeln(logFile);
  for j:=1 to nTrNightsAway do begin
    write(logFile,trNAwayLabel[j]); for i:=0 to nTourPurposes do write(logFile,'  ',trNAwayPred[i,j]/max(trSimulated[i],1)*100.0:6:2,'%'); writeln(logFile);
  end;
  writeln(logFile);
  writeln(logFile,'Tour party size distribution by purpose');
  write(logFile,'Purpose'); for i:=0 to nTourPurposes do write(logFile,'  ',trPurposeLabel[i]); writeln(logFile);
  for j:=1 to nTrPartySizes do begin
    write(logFile,trPSizeLabel[j]); for i:=0 to nTourPurposes do write(logFile,'  ',trPSizePred[i,j]/max(trSimulated[i],1)*100.0:6:2,'%'); writeln(logFile);
  end;
  writeln(logFile);
  writeln(logFile,'Tour distance band distribution by purpose');
  write(logFile,'Purpose'); for i:=0 to nTourPurposes do write(logFile,'  ',trPurposeLabel[i]); writeln(logFile);
  for j:=1 to nTrDistBands do begin
    write(logFile,trDistLabel[j]); for i:=0 to nTourPurposes do write(logFile,'  ',trDistPred[i,j]/max(trSimulated[i],1)*100.0:6:2,'%'); writeln(logFile);
  end;
  writeln(logFile);
  writeln(logFile,'Tour mode choice distribution by purpose');
  write(logFile,'Purpose'); for i:=0 to nTourPurposes do write(logFile,'  ',trPurposeLabel[i]); writeln(logFile);
  for j:=1 to nTourModes do begin
    write(logFile,trModeLabel[j]); for i:=0 to nTourPurposes do write(logFile,'  ',trModePred[i,j]/max(trSimulated[i],1)*100.0:6:2,'%'); writeln(logFile);
  end;
  writeln(logFile);
  writeln(logFile,'Tour distance band distribution by mode and purpose');
  for j:=1 to nTourModes do begin
    writeln(logFile,'Mode = ',trModeLabel[j]);
    write(logFile,'Purpose'); for i:=0 to nTourPurposes do write(logFile,'  ',trPurposeLabel[i]); writeln(logFile);
    for k:=1 to ntrDistBands do begin
      write(logFile,trDistLabel[k]); for i:=0 to nTourPurposes do write(logFile,'  ',trModeDist[i,j,k]/max(trModePred[i,j],1)*100.0:6:2,'%'); writeln(logFile);
    end;
  end;
  writeln(logFile);
  writeln(logFile,'Daily tours by mode and O-D Census divisions (thousands)');
  for i:=1 to nTourModes do begin
    writeln(logFile,'Mode = ',trModeLabel[i]);
    write(logFile,'O / D>>'); for j:=1 to nCensDivs do write(logFile,'  ',censDivLabel[j]); writeln(logFile);
    for k:=1 to nCensDivs do begin
      write(logFile,censDivLabel[k]); for j:=1 to nCensDivs do write(logFile,'  ',trDivODPred[i,j,k]/1000.0:7:1); writeln(logFile);
    end;
  end;
end;




const nHHSegs=15; nPSSegs=3; nNASegs=3; nMOSegs=1; nDistBands=4;
     maxmccoef=499;
     maxdccoef=99;
     firstsizevar=21;
     lastsizevar=24;
     logsizemult=25;

var  accessibilityLogsums:array[1..nHHSegs,1..nTourPurposes,1..nDistBands] of double;
     modeProb:array[1..nHHSegs,1..nTourPurposes,1..nPSSegs,1..nNASegs,1..nMOSegs,1..mZones,0..nTourModes] of double;
     destProb:array[1..nHHSegs,1..nTourPurposes,1..nPSSegs,1..nNASegs,1..nMOSegs,0..mZones] of double;
     hhsegLogIncome,hhsegIncomeFac:array[1..nHHSegs] of single;
     pssegCostFac:array[1..nPSSegs,1..nTourPurposes] of single;
     sizeFunction,destutil:array[1..nTourPurposes,1..mZones] of double;
     logsumsInitialized:boolean=false;
     modeCoeffsRead:boolean=false;
     MCCoef:array[1..nTourPurposes,1..maxmccoef] of single;
     destCoeffsRead:boolean=false;
     DCCoef:array[1..nTourPurposes,1..maxdccoef] of single;

procedure calculateModeDestinationProbabilities(otaz:integer);
const coefplabel:array[1..nTourPurposes] of string=('pbus','vfar','leis','comm','ebus');
      dbandlowlimit :array[1..nDistBands] of integer= ( 0, 50,150,500);
      dbandhighlimit:array[1..nDistBands] of integer= (50,150,500,999999);
      hhSegIncome:array[1..nHHSegs] of integer=(22,50,80,125,210, 22,50,80,125,210, 22,50,80,125,210);
      hhSegNocars:array[1..nHHSegs] of integer=( 1, 1, 1,  1,  1,  0, 0, 0,  0,  0,  0, 0, 0,  0,  0);
      hhSegCarlta:array[1..nHHSegs] of integer=( 0, 0, 0,  0,  0,  1, 1, 1,  1,  1,  0, 0, 0,  0,  0);
      psSegSingle:array[1..nPSSegs] of integer=( 1, 0, 0);
      psSegGroup3:array[1..nPSSegs] of integer=( 0, 0, 1);
      nasegDaytrip :array[1..nNASegs] of integer=(1, 0, 0);
      nasegNights12:array[1..nNASegs] of integer=(0, 1, 0);
      nasegWeekTrip:array[1..nNASegs] of single =(0, 0, 0.5);
      moSegSummer  :array[1..nMOSegs] of integer=(0);
      avgPartysize :array[1..nPSSegs,1..NTourPurposes] of single=((1.0,1.0,1.0,1.0,1.0),
                                                                  (2.0,2.0,2.0,2.0,2.0),
                                                                  (4.0,4.0,4.0,4.0,4.0));
      logsumPSSeg :array[1..nTourPurposes] of integer=(2, 2, 2, 1, 1);
      logsumNASeg :array[1..nTourPurposes] of integer=(2, 2, 3, 1, 2);
      logsumMOSeg :array[1..nTourPurposes] of integer=(1, 1, 1, 1, 1);

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
    purp,hhseg,psseg,naseg,moseg,dtaz,z,cnum,dband,mode:integer;
    siz0,siz1,siz2,siz3,siz4:single;
    railfare,airfare,railfreqx,airfreqx,
    carutilx,busutilx,railutilx,airutilx,
    carutil,busutil,railutil,airutil,lncdist,cdistsq,modeChoiceLogsum,destsum:double;
    mexputil:array[0..nTourModes] of double;
    cinf:text;

begin
  {writeln('Calculating accessibility logsums. Zones processed..');}
  if not(logsumsInitialized) then begin
    logsumsInitialized:=true;
  {if first zone, initialize coefficients and other global vars}

    if not(modeCoeffsRead) then begin
      for purp:=1 to nTourPurposes do begin
        {read coefficients}
        resetTextFile(cinf,setFileName(CoefficientDirectoryName,mccoeffile[purp]));
        repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
        repeat
          read(cinf,cnum);
          {write(purp,' ',cnum); readln;}
          if (cnum>=0) and (cnum<=maxmccoef) then readln(cinf,xstr,MCCoef[purp,cnum]) else readln(cinf);
        until cnum<0;
        close(cinf);
      end;
      modeCoeffsRead:=true;
    end;
    if not(destCoeffsRead) then begin
      for purp:=1 to nTourPurposes do begin
        {read coefficients}
        resetTextFile(cinf,setFileName(CoefficientDirectoryName,dccoeffile[purp]));
        repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
        repeat
          read(cinf,cnum);
          {write(purp,' ',cnum); readln;}
          if (cnum>=0) and (cnum<=maxdccoef) then readln(cinf,xstr,DCCoef[purp,cnum]) else readln(cinf);
          {exponentiate size coefficients}
          if (cnum>=firstsizevar) and (cnum<=lastsizevar) then DCCoef[purp,cnum]:=exp(DCCoef[purp,cnum]);
        until cnum<0;
        close(cinf);
      end;
      destCoeffsRead:=true;
    end;

    for hhseg:=1 to nHHSegs do begin
      hhsegLogIncome[hhseg]:=ln(hhsegIncome[hhseg]);
      hhsegIncomefac[hhseg]:= exp(0.6 * ln(hhsegIncome[hhseg]/30.0));
    end;

    for psseg:=1 to nPSSegs do
      for purp:=1 to nTourPurposes do begin
      pssegCostfac[psseg,purp] := exp(0.7 * ln(1.0*avgPartysize[psseg,purp]));
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

      end;
    end;
  end;

  {for otaz:=1 to nzones do} begin
    {if (otaz mod 100=0) or (otaz=nzones) then write(otaz:8);}

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

      lncdist:=ln(max(1.0,min(carDist[otaz][dtaz],3000)));
      cdistsq:=(min(carDist[otaz][dtaz],3000)/100.0)*(min(carDist[otaz][dtaz],3000)/100.0); {cap at 3000 to deal with new HI and AK destinations}

      dband:=0;
      repeat
        dband:=dband+1;
      until (carDist[otaz][dtaz]>=dbandlowlimit[dband])
        and (carDist[otaz][dtaz]< dbandhighlimit[dband]);

      for purp:=1 to nTourPurposes do begin

        destutil[purp,dtaz]:= sizeFunction[purp,dtaz]
         + DCCoef[purp,2] * lncdist
         + DCCoef[purp,3] * cdistsq
         + DCCoef[purp,7] * ifin(carDist[otaz][dtaz],50,99.99)
         + DCCoef[purp,8] * ifin(cardist[otaz][dtaz],100,149.99)
         + DCCoef[purp,9] * ifin(cardist[otaz][dtaz],150,249.99)
         + DCCoef[purp,10]* ifin(cardist[otaz][dtaz],250,499.99)
         + DCCoef[purp,11]* ifin(cardist[otaz][dtaz],500,999.99)
         + DCCoef[purp,12]* ifin(cardist[otaz][dtaz],1000,1499.99)
         + DCCoef[purp,13]* ifin(cardist[otaz][dtaz],1500,1999.99)
         + DCCoef[purp,14]* ifge(cardist[otaz][dtaz],2000)*(1-airOnlyAKHI[otaz][dtaz])
         + DCCoef[purp,19]* airOnlyAKHI[otaz][dtaz]
         + DCCoef[purp,15]* zUrban[dtaz]
         + DCCoef[purp,16]* zRural[dtaz]
         + DCCoef[purp,17]* (zUrban[dtaz]*zUrban[otaz])
         + DCCoef[purp,18]* (zRural[dtaz]*zRural[otaz]);

        if purp<5 then railfare:=railEconFare[otaz][dtaz]+ railEconFare[dtaz][otaz]
                  else railfare:=railBusiFare[otaz][dtaz]+ railBusiFare[dtaz][otaz];

        if purp<5 then airfare:=airEconFare[otaz][dtaz]+ airEconFare[dtaz][otaz]
                     else airfare:=airBusiFare[otaz][dtaz]+ airBusiFare[dtaz][otaz];
        if airfare>maxairfare[purp] then airfare:=maxairfare[purp];

        railfreqx:= railFreq[otaz][dtaz]+ railFreq[dtaz][otaz];
        if railfreqx<1 then railfreqx:=1;

        airfreqx:= (airFreqDirect[otaz][dtaz]+ airFreqDirect[dtaz][otaz])
                +(airFreq1Stop [otaz][dtaz]+ airFreq1Stop [dtaz][otaz])/2.0
                +(airFreq2Stop [otaz][dtaz]+ airFreq2Stop [dtaz][otaz])/10.0;
        if airfreqx<1 then airfreqx:=1;

        if (carTime[otaz][dtaz]<=0) or (carTime[dtaz][otaz]<=0) then carutilx:=-999 else
        carutilx:= MCCoef[purp,11]* (carTime[otaz][dtaz]+ carTime[dtaz][otaz]);

        if (busTime[otaz][dtaz]<=0) or (busTime[dtaz][otaz]<=0) then busutilx:=-999 else
        busutilx:= MCCoef[purp,21]*(busTime[otaz][dtaz]+ busTime[dtaz][otaz]);

        if (railTime[otaz][dtaz]<=0) or (railTime[dtaz][otaz]<=0) then railutilx:=-999 else
        railutilx:= MCCoef[purp,31]*(railTime[otaz][dtaz]+ railTime[dtaz][otaz])
                 +  MCCoef[purp,32]*(railXfer[otaz][dtaz]/100.0+ railXfer[dtaz][otaz]/100.0)
                 +  MCCoef[purp,33]*sqrt(railfreqx)
                 +  MCCoef[purp,34]*(railAcEgDist[otaz][dtaz]+ railAcEgDist[dtaz][otaz]);
        if carDist[otaz][dtaz]>0 then railutilx:=railutilx
                 +  MCCoef[purp,35]*((railAcEgDist[otaz][dtaz]+ railAcEgDist[dtaz][otaz])/
                                           (carDist[otaz][dtaz]+ carDist[dtaz][otaz]) - 0.33);

        if (airTime[otaz][dtaz]<=0) or (airTime[dtaz][otaz]<=0)
        or ((carDist[otaz][dtaz]>0) and (carDist[otaz][dtaz]<50)) then airutilx:=-999 else  {don't include air connections for car dist 1-49}
        airutilx:=  MCCoef[purp,41]*(airTime[otaz][dtaz]+ airTime[dtaz][otaz])
                 +  MCCoef[purp,42]*(airXfer[otaz][dtaz]/100.0+ airXfer[dtaz][otaz]/100.0)
                 +  MCCoef[purp,43]*sqrt(airfreqx)
                 +  MCCoef[purp,46]*(airReli30[otaz][dtaz]+ airReli30[dtaz][otaz])
                 +  MCCoef[purp,44]*(airAcEgDist[otaz][dtaz]+ airAcEgDist[dtaz][otaz]);
        if carDist[otaz][dtaz]>0 then airutilx:=airutilx
                 +  MCCoef[purp,45]*((airAcEgDist[otaz][dtaz]+ airAcEgDist[dtaz][otaz])/
                                          (carDist[otaz][dtaz]+ carDist[dtaz][otaz]) - 0.67);

        for hhseg:=1 to nhhSegs do begin
          if busutilx>-900 then busutil:=busutilx+
             MCCoef[purp,10]* (busFare[otaz][dtaz]+ busFare[dtaz][otaz])/hhsegIncomefac[hhseg]
          else busutil:=busutilx;

          if railutilx>-900 then railutil:=railutilx+
             MCCoef[purp,10]* railfare/hhsegIncomefac[hhseg]
          else railutil:=railutilx;

         if airutilx>-900 then airutil:=airutilx+
             MCCoef[purp,10]* airfare/hhsegIncomefac[hhseg]
         else airutil:=airutilx;

         for psseg:=1 to nPSSegs do begin
           if carutilx>-900 then carutil:=carutilx+
             MCCoef[purp,10]* copercpm * (carDist[otaz][dtaz]+ carDist[dtaz][otaz])/(pssegCostfac[psseg,purp]*hhsegIncomefac[hhseg])+
             MCCoef[purp,10]*(carToll[otaz][dtaz]/100.0+ carToll[dtaz][otaz]/100.0)/(pssegCostfac[psseg,purp]*hhsegIncomefac[hhseg])
           else carutil:=carutilx;

            for naseg:=1 to nNASegs do begin

              for moseg:=1 to nMOSegs do begin

                if (carutil<-900) then mexputil[1]:=0 else
                mexputil[1]:= exp(0
                 + MCCoef[purp,  1]*carutil
                 + MCCoef[purp,101]*hhsegNocars[hhseg]
                 + MCCoef[purp,102]*hhsegCarlta[hhseg]
                 + MCCoef[purp,103]*pssegSingle[psseg]
                 + MCCoef[purp,104]*pssegGroup3[psseg]
                 + MCCoef[purp,105]*nasegDaytrip[naseg]
                 + MCCoef[purp,106]*nasegWeektrip[naseg]
                 + MCCoef[purp,110]*mosegSummer[moseg]
                 + MCCoef[purp,112]*ifge(cardist[otaz][dtaz],500));

                if (busutil<-900) then mexputil[2]:=0 else
                mexputil[2]:= exp(0
                 + MCCoef[purp,  1]*busutil
                 + MCCoef[purp,200]
                 + MCCoef[purp,208]*hhsegLogincome[hhseg]
                 + MCCoef[purp,209]*zLogdens[otaz]
                 + MCCoef[purp,210]*zLogdens[dtaz]
                 + MCCoef[purp,215]*iflt(cardist[otaz][dtaz],150));

                if (railutil<-900) then mexputil[3]:=0 else
                mexputil[3]:= exp(0
                 + MCCoef[purp,  1]*railutil
                 + MCCoef[purp,300]
                 + MCCoef[purp,308]*hhsegLogincome[hhseg]
                 + MCCoef[purp,309]*zLogdens[otaz]
                 + MCCoef[purp,310]*zLogdens[dtaz]
                 + MCCoef[purp,315]*iflt(cardist[otaz][dtaz],150));

                if (airutil<-900) then mexputil[4]:=0 else
                mexputil[4]:= exp(0
                 + MCCoef[purp,  1]*airutil
                 + MCCoef[purp,400]
                 + MCCoef[purp,408]*hhsegLogincome[hhseg]
                 + MCCoef[purp,409]*zLogdens[otaz]
                 + MCCoef[purp,410]*zLogdens[dtaz]
                 + MCCoef[purp,411]*nasegDaytrip[naseg]
                 + MCCoef[purp,412]*nasegNights12[naseg]
                 + MCCoef[purp,414]*pssegSingle[psseg]
                 + MCCoef[purp,415]*iflt(cardist[otaz][dtaz],150));

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
                   + DCCoef[purp,1]* modeChoiceLogsum
                   + DCCoef[purp,4]* nasegDaytrip[naseg]*cdistsq
                   + DCCoef[purp,5]* nasegNights12[naseg]*cdistsq);

                  if  (psseg=logsumPSSeg[purp])
                  and (naseg=logsumNASeg[purp])
                  and (moseg=logsumMOSeg[purp]) then begin
                    accessibilityLogsums[hhseg,purp,dband]:=accessibilityLogsums[hhseg,purp,dband]
                      +destProb[hhseg,purp,psseg,naseg,moseg,dtaz];
                  end;

                  if (carDist[otaz][dtaz]>=50) then begin
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

 end; {o zone loop}
end;

const maxaocoef = 99;
var autownCoeffsRead:boolean=false;
    AOCoef:array[1..maxaocoef] of single;

procedure applyAutoOwnershipModel;
const nAlts=5;

var alt:integer; target,expusum:double; util,expu:array[1..nAlts] of double; cinf:text; cnum:integer; xstr:string[13];

begin
  if not(autownCoeffsRead) then begin
        {read coefficients}
        resetTextFile(cinf,setFileName(CoefficientDirectoryName,aocoeffile));
        repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
        repeat
          read(cinf,cnum);
          {write(purp,' ',cnum); readln;}
          if (cnum>=0) and (cnum<=maxaocoef) then readln(cinf,xstr,AOCoef[cnum]) else readln(cinf);
        until cnum<0;
        close(cinf);
        autownCoeffsRead:=true;
  end;

  expusum:=0;
  for alt:=1 to nAlts do begin
    if alt=3 then util[alt]:=0 else begin
      util[alt]:=0
        + AOCoef[10*alt+0] {constant}
        + AOCoef[10*alt+1]*hh1Adult
        + AOCoef[10*alt+2]*hh3Adults
        + AOCoef[10*alt+3]*hh4PlusAdults
        + AOCoef[10*alt+4]*hhWorkerRatio2
        + AOCoef[10*alt+5]*hhHasKids
        + AOCoef[10*alt+6]*hhHeadOver65
        + AOCoef[10*alt+7]*hhHeadUnder35
        + AOCoef[10*alt+8]*hhLogDensity
        + AOCoef[10*alt+9]*hhLogIncome;
    end;
    expu[alt]:=exp(util[alt]);
    expusum:=expusum+expu[alt];
  end;
  target:=random*expusum;
  alt:=0;
  repeat
    alt:=alt+1;
    target:=target-expu[alt];
  until (target<0) or (alt>=nAlts);

  hhVehicles:=alt-1;
  hhHas0Vehicles:=integer(hhVehicles=0);
  hhHas1Vehicle:=integer(hhVehicles=1);
  hhHas2Vehicles:=integer(hhVehicles=2);
  hhHas3PlusVehicles:=integer(hhVehicles>=3);
  hhHasCarCompetition:=integer((hhVehicles>0) and (hhVehicles<hhAdults));

 if hhVehicles=0 then hhModeDestseg:=hhIncseg else
 if hhVehicles<hhAdults then hhModeDestseg:=hhIncseg+5 else hhModeDestseg:=hhIncseg+10;

 hhSimulated[hhIncseg]:=hhSimulated[hhIncseg]+ hhExpOut;
 hhVehiclesPred[hhIncseg,hhVehicles+1]:=hhVehiclesPred[hhIncseg,hhVehicles+1]+ hhExpOut;
end;

const maxtdcoef=99;
var  durationCoeffsRead:boolean=false;
     TDCoef:array[1..nTourPurposes,1..maxtdcoef] of single;

procedure applyTourNightsAwayModel;
const nAlts=4;

var alt:integer; target,expusum:double; util,expu:array[1..nAlts] of double; cinf:text; cnum,purp:integer; xstr:string[13];
begin
  if not(durationCoeffsRead) then begin
      for purp:=1 to nTourPurposes do begin
        {read coefficients}
        resetTextFile(cinf,setFileName(CoefficientDirectoryName,tdcoeffile[purp]));
        repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
        repeat
          read(cinf,cnum);
          {write(purp,' ',cnum); readln;}
          if (cnum>=0) and (cnum<=maxtdcoef) then readln(cinf,xstr,TDCoef[purp,cnum]) else readln(cinf);
        until cnum<0;
        close(cinf);
      end;
      durationCoeffsRead:=true;
  end;

  expusum:=0;
  for alt:=1 to nAlts do begin
    if alt=1 then util[alt]:=0 else begin
      util[alt]:=0
        + TDCoef[trPurpose,10*alt+0] {constant}
        + TDCoef[trPurpose,10*alt+1]*hhSize
        + TDCoef[trPurpose,10*alt+3]*hhLogIncome
        + TDCoef[trPurpose,10*alt+4]*hhHeadOver65
        + TDCoef[trPurpose,10*alt+5]*hhHeadUnder35
        + TDCoef[trPurpose,10*alt+6]*hhLogDensity
        + TDCoef[trPurpose,10*alt+7]*trJunToAug
        + TDCoef[trPurpose,10*alt+8]*trJanToMar
        + TDCoef[trPurpose,10*alt+9]*trNovToDec;
    end;
    expu[alt]:=exp(util[alt]);
    expusum:=expusum+expu[alt];
  end;
  target:=random*expusum;
  alt:=0;
  repeat
    alt:=alt+1;
    target:=target-expu[alt];
  until (target<0) or (alt>=nAlts);

  trNightsCategory:=alt;
  trDayTrip:= integer(trNightsCategory=1);
  tr1or2Nights:= integer(trNightsCategory=2);
  tr3to6Nights:= integer(trNightsCategory=3);
  tr7PlusNights:= integer(trNightsCategory=4);
  trNAwayPred[trPurpose,trNightsCategory]:=trNAwayPred[trPurpose,trNightsCategory]+trExpFactor;
end;

const maxpscoef=699;
var  partysizeCoeffsRead:boolean=false;
     PSCoef:array[1..nTourPurposes,1..maxpscoef] of single;

procedure applyTourPartySizeModel;
const nAlts=4;


var alt:integer; target,expusum:double; util,expu:array[1..nAlts] of double; cinf:text; cnum,purp:integer; xstr:string[13];
begin
  if not(partysizeCoeffsRead) then begin
      for purp:=1 to nTourPurposes do begin
        {read coefficients}
        resetTextFile(cinf,setFileName(CoefficientDirectoryName,pscoeffile[purp]));
        repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
        repeat
          read(cinf,cnum);
          {write(purp,' ',cnum); readln;}
          if (cnum>=0) and (cnum<=maxpscoef) then readln(cinf,xstr,PSCoef[purp,cnum]) else readln(cinf);
        until cnum<0;
        close(cinf);
      end;
      partysizeCoeffsRead:=true;
  end;

  expusum:=0;
  for alt:=1 to nAlts do begin
    if alt=min(hhSize,nAlts) then util[alt]:=PScoef[trPurpose,1]
                  else util[alt]:=0;
    if alt=min(hhAdults,nAlts) then util[alt]:=util[alt]+PScoef[trPurpose,2];
    if alt>1 then begin
      util[alt]:=util[alt]
        + PScoef[trPurpose,100*alt+1] {constant}
        + PScoef[trPurpose,100*alt+2]*hhWorkerRatio2
        + PScoef[trPurpose,100*alt+3]*hhLogIncome
        + PScoef[trPurpose,100*alt+5]*hhHas0Vehicles
        + PScoef[trPurpose,100*alt+6]*hhHasCarCompetition
        + PScoef[trPurpose,100*alt+7]*trDaytrip
        + PScoef[trPurpose,100*alt+8]*tr1or2Nights
        + PScoef[trPurpose,100*alt+9]*tr7PlusNights
        + PScoef[trPurpose,100*alt+11]*trJunToAug
        + PScoef[trPurpose,100*alt+12]*trJanToMar
        + PScoef[trPurpose,100*alt+13]*trNovToDec
        + PScoef[trPurpose,100*alt+15]*hhHeadOver65
        + PScoef[trPurpose,100*alt+16]*hhHeadUnder35;
    end;
    expu[alt]:=exp(util[alt]);
    expusum:=expusum+expu[alt];
  end;
  target:=random*expusum;
  alt:=0;
  repeat
    alt:=alt+1;
    target:=target-expu[alt];
  until (target<0) or (alt>=nAlts);

  trPartySize:= alt;
  trSinglePerson:= integer(trPartySize=1);
  trGroup3Plus:= integer(trPartySize>=3);
  trPSizePred[trPurpose,trPartySize]:=trPSizePred[trPurpose,trPartySize]+trExpFactor;
end;

procedure applyTourModeDestinationModel;
var target:double; otaz,hhseg,purp,psseg,naseg,moseg,mode,dtaz,lowLimit,highLimit,index,xmode,mode2,dtaz2,dband:integer;
 done:boolean; dprob,mprob:double; tripExp,tripExp2:double;
const avgPartySize:array[1..4] of single=(1,2,3,5.0);
begin
 tripExp:=trExpFactor;
 if WriteADT then tripExp:=tripExp/DaysInMonth[MonthOfYear];

 otaz:=hhZoneIndex;
 purp:=trPurpose;
 hhseg:=hhModeDestSeg;
 psseg:=trPartySize; if psseg>nPSSegs then psseg:=nPSSegs;
 naseg:=trNightsCategory; if naseg>nNASegs then naseg:=nNASegs;
 moseg:=1;

 if (writeProbs) then begin
   for dtaz:=1 to nZones do
   if (carDist[otaz,dtaz]>=TripMatrixMinimumDistance) then begin
     dprob:=DestProb[hhseg,purp,psseg,naseg,moseg,dtaz]-DestProb[hhseg,purp,psseg,naseg,moseg,dtaz-1];
     if dprob>1.0E-50 then begin
       for mode:=0 to nTourModes do if (writeTripMatrix[mode]) then begin
         if mode=0 then tripExp2:=tripExp else tripExp2:=tripExp * avgPartySize[trPartySize];
         if mode=0 then xmode:=1 else xmode:=mode;
         mprob:=ModeProb[hhseg,purp,psseg,naseg,moseg,dtaz,xmode]-ModeProb[hhseg,purp,psseg,naseg,moseg,dtaz,xmode-1];
         if mprob>1.0E-50 then begin
           tripMats[mode][otaz][dtaz]:=tripMats[mode][otaz][dtaz]+dprob*mprob*tripExp2;
           tripMats[mode][otaz][dtaz]:=tripMats[mode][otaz][dtaz]+dprob*mprob*tripExp2;
         end;
       end;
     end;
   end;
 end;

 if (writeTours) or not(writeProbs)  then begin
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
  target:=random;
  mode:=0;
  repeat
    mode:=mode+1;
  until ModeProb[hhseg,purp,psseg,naseg,moseg,dtaz,mode]>target;

  if (writeTripMatrix[mode])
  and (carDist[otaz][dtaz]>=TripMatrixMinimumDistance) then begin
      tripMats[mode][otaz][dtaz]:=tripMats[mode][otaz][dtaz]+tripExp * avgPartySize[trPartySize];
      tripMats[mode][dtaz][otaz]:=tripMats[mode][dtaz][otaz]+tripExp * avgPartySize[trPartySize];
  end;
  if (writeTripMatrix[0]) and (mode=1)
  and (carDist[otaz][dtaz]>=TripMatrixMinimumDistance) then begin
      tripMats[0][otaz][dtaz]:=tripMats[0][otaz][dtaz]+tripExp;
      tripMats[0][dtaz][otaz]:=tripMats[0][dtaz][otaz]+tripExp;
  end;

  dband:=0;
  while (dband<nTrDistBands) and (carDist[otaz,dtaz]>=trDistBandLowLimit[dband+1]) do dband:=dband+1;
  if dband=0 then dband:=nTrDistBands; {AK or HI}

  trDistPred[trPurpose,dband]:=trDistPred[trPurpose,dband]+trExpFactor;
  trModePred[trPurpose,mode]:=trModePred[trPurpose,mode]+trExpFactor;
  trModeDist[trPurpose,mode,dband]:=trModeDist[trPurpose,mode,dband]+trExpFactor;
  trDivODPred[mode,stateCensDiv[zoneState[otaz]],stateCensDiv[zoneState[dtaz]]]:=
  trDivODPred[mode,stateCensDiv[zoneState[otaz]],stateCensDiv[zoneState[dtaz]]]+trExpfactor;

  if writeTours then begin
    trMode:=mode;
    trOZone:=zoneId[otaz];
    trOState:=zoneState[otaz];
    trDZone:=zoneId[dtaz];
    trDState:=zoneState[dtaz];
    trAutoDistance:=carDist[otaz,dtaz]+carDist[dtaz,otaz];
    if trMode=1 then begin
      trTravelTime:=carTime[otaz,dtaz]+carTime[dtaz,otaz];
      trTravelCost:=round(carToll[otaz,dtaz]+carToll[dtaz,otaz]/100.0
         + trAutoDistance*copercpm);
      trOrigStation:=0;
      trDestStation:=0;
    end else
    if trMode=2 then begin
      trTravelTime:=busTime[otaz,dtaz]+busTime[dtaz,otaz];
      trTravelCost:=busFare[otaz,dtaz]+busFare[dtaz,otaz];
      trOrigStation:=0;
      trDestStation:=0;
    end else
    if trMode=3 then begin
      trTravelTime:=railTime[otaz,dtaz]+railTime[dtaz,otaz]
              {+ 2 *(railAcEgDist[otaz,dtaz]+railAcEgDist[dtaz,otaz])};
      if trPurpose<5
        then trTravelCost:=railEconFare[otaz,dtaz]+railEconFare[dtaz,otaz]
        else trTravelCost:=railBusiFare[otaz,dtaz]+railBusiFare[dtaz,otaz];
      trOrigStation:=railOrigStation[otaz,dtaz];
      trDestStation:=railDestStation[otaz,dtaz];
    end else
    if trMode=4 then begin
      trTravelTime:=AirTime[otaz,dtaz]+airTime[dtaz,otaz]
            + round(90/100*0*(AirXfer[otaz,dtaz]+airXfer[dtaz,otaz]))
            {+ 2 *(airAcEgDist[otaz,dtaz]+airAcEgDist[dtaz,otaz])};
      if trPurpose<5
        then trTravelCost:=airEconFare[otaz,dtaz]+airEconFare[dtaz,otaz]
        else trTravelCost:=airBusiFare[otaz,dtaz]+airBusiFare[dtaz,otaz];
      trOrigStation:=airOrigAirport[otaz,dtaz];
      trDestStation:=airDestAirport[otaz,dtaz];
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

procedure simulateNewTour(num,purp,month:integer);
var target:double;
begin
  trNo:=num;
  trPurpose:=purp;
  trMonth:= month;
  {transformations}
  trJanToMar:=integer((trMonth>=1) and (trMonth<=3));
  trJunToAug:=integer((trMonth>=6) and (trMonth<=8));
  trNovToDec:=integer((trMonth>=11) and (trMonth<=12));
  trAprToJun:=integer((trMonth>=4) and (trMonth<=6));
  trJulToSep:=integer((trMonth>=7) and (trMonth<=9));
  trOctToDec:=integer((trMonth>=10) and (trMonth<=12));

  trExpFactor := hhExpFactor * Sample1inX;
  if not(EachDayOfTheMonth) then trExpFactor:=trExpFactor*DaysInMonth[month];
  {if WriteADT then trExpFactor:=trExpFactor/DaysInMonth[MonthOfYear]; don't use adt in tour file or tables}

  trSimulated[trPurpose]:=trSimulated[trPurpose]+trExpFactor;
  hhToursPred[hhIncseg,trPurpose]:=hhToursPred[hhIncseg,trPurpose]+trExpFactor;

  applyTourNightsAwayModel;
  applyTourPartySizeModel;
  applyTourModeDestinationModel;
  writeTourRecord;
 end;


const maxfrcoef=599;
      freqCoeffsRead:boolean = false;
var   FrCoef:array[1..2,1..maxfrcoef] of single;


procedure applyTourGenerationModel;


var alt,f,ls,cnum:integer;  cinf:text; xstr:string[13];
  target:double;
  expusum:array[1..2] of double;
  util,expu:array[1..2,0..nTourPurposes] of double;
 hasAccess:boolean;
 accLogsum:array[1..nDistBands] of double;
 noLogsum1:integer;
 nTours, simMonth, firstMonth, lastMonth, simDay, lastDay, firstPurp:integer;

const logsumlimit=-30;
begin
 if not(freqCoeffsRead) then begin
    for f:=1 to 2 do begin
        {read coefficients}
        resetTextFile(cinf,setFileName(CoefficientDirectoryName,frcoeffile[f]));
        repeat readln(cinf,xstr) until (copy(xstr,1,3)='END');
        repeat
          read(cinf,cnum);
          {write(f,' ',cnum); readln;}
          if (cnum>=0) and (cnum<=maxfrcoef) then readln(cinf,xstr,FrCoef[f,cnum]) else readln(cinf);
        until cnum<0;
        close(cinf);
    end;
    freqCoeffsRead:=true;
 end;

 nTours:=0;
 for alt:=1 to nTourPurposes do hhTours[alt]:=0;
 hasAccess:=false;
 for ls:=2 to nDistBands do if accessibilityLogsums[hhModeDestSeg,1,ls]>-50 then hasAccess:=true;
 if hasAccess then begin
  {set utilities with everything except month}
  for f:=1 to 2 do begin
    util[f,0]:=0;
    expu[f,0]:=exp(util[f,0]);
    for alt:=1 to nTourPurposes do begin

      for ls:=1 to nDistBands do accLogsum[ls]:=
          max(logsumlimit,accessibilityLogsums[hhModeDestSeg,alt,ls]);
      noLogsum1:=integer( accessibilityLogsums[hhModeDestSeg,alt,1]<-90);


      util[f,alt]:=0
            + FrCoef[f,100*alt+ 0] {constant}
            + FrCoef[f,100*alt+22]*hhLogIncome
            + FrCoef[f,100*alt+24]*hhHas0Vehicles
            + FrCoef[f,100*alt+25]*hhHasCarCompetition
            + FrCoef[f,100*alt+26]*hhHasKids
            + FrCoef[f,100*alt+27]*hhWorkerRatio2
            + FrCoef[f,100*alt+28]*hh1Adult
            + FrCoef[f,100*alt+29]*hhHeadUnder35
            + FrCoef[f,100*alt+30]*hhHeadOver65
            + FrCoef[f,100*alt+31]*hhSize
            + FrCoef[f,100*alt+13]*accLogsum[1]*(1-noLogsum1)
            + FrCoef[f,100*alt+14]*accLogsum[2]
            + FrCoef[f,100*alt+15]*accLogsum[3]
            + FrCoef[f,100*alt+16]*accLogsum[4]
            + FrCoef[f,100*alt+17]*noLogsum1;
    end;
  end;

  if MonthOfYear=0 then firstMonth:=1 else firstMonth:=MonthOfYear;
  if MonthOfYear=0 then lastMonth:=12 else lastMonth:=MonthOfYear;

  {loop on months}
  for simMonth:=firstMonth to lastMonth do begin

    for f:=1 to 2 do begin
      expusum[f]:=expu[f,0];
      for alt:=1 to nTourPurposes do begin
        if (alt>=4) and (hhWorkers=0) then expu[f,alt]:=0 else {commute and business require workers}
        if f=1 then expu[f,alt]:=exp(util[f,alt]+FrCoef[f,100*alt+simMonth])
               else expu[f,alt]:=exp(util[f,alt]);
        expusum[f]:=expusum[f] + expu[f,alt];
      end;
    end;

    {loop on days}
    if EachDayOfTheMonth then lastDay:=DaysInMonth[simMonth] else lastDay:=1;
    for simDay:=1 to lastDay do begin
      target:=random*expusum[1];
      alt:=-1;
      repeat
        alt:=alt+1;
        target:=target-expu[1,alt];
      until (target<0) or (alt>=nTourPurposes);

      if (alt>0) then begin
        hhTours[alt]:=hhTours[alt]+1;
        nTours:=nTours+1;
        simulateNewTour(nTours,alt,simMonth);
        firstPurp:=alt;

        {apply second tour model}
        target:=random*expusum[2];
        alt:=-1;
        repeat
          alt:=alt+1;
          target:=target-expu[2,alt];
        until (target<0) or (alt>=nTourPurposes);
        if (alt>0) then begin
          hhTours[alt]:=hhTours[alt]+1;
          nTours:=nTours+1;
          simulateNewTour(nTours,alt,simMonth);
        end;
      end; {run for second tour}
    end; {loop on days}
  end; {loop on months}
 end; {has access}
end;


var lastHH:boolean; nHHRecs, lastHHZoneIndex, purpose,hhseg,dband,mode:integer; lsfile:text;

{Main program}

begin
  GetConfigurationSettings;
  initializeSummaryOutput;

  randseed:=randomSeed;

  writeln(logFile,'Run started at ',DateTimetoStr(now));
  writeln('Run started at ',DateTimetoStr(now));
 {load input files}
  loadZoneLandUseData(ZoneLandUseFileName);
  loadRoadLOSMatrices(RoadLOSFileName);
  loadRailLOSMatrices(RailLOSFileName);
  loadAirLOSMatrices(AirLOSFileName);

  {loop on sample households}
  openHouseholdInputFile(HouseholdFileName);
  openHouseholdDayOutputFile(HouseholdDayFileName);
  openTourOutputFile(TourFileName);
  for mode:=0 to nTourModes do
    openTripMatrixOutputFile(mode);

  if writeMDLogsums then begin
    assign(lsfile,'mdlogsums3.dat'); rewrite(lsfile);
  end;
  writeln('Millions of households read ....');
  nHHRecs:=0;
  lasthhZoneIndex:=0;
  repeat
    nHHRecs:=nHHRecs+1;
    if nHHrecs mod 1000000=0 then write(nHHRecs div 1000000:8);
    loadNextHouseholdRecord(lastHH);
    if hhZoneIndex>lasthhZoneIndex then begin
      calculateModeDestinationProbabilities(hhZoneIndex);

      if writeMDLogsums then begin
        for hhseg:=1 to nhhsegs do begin
          write(lsfile,hhZoneIndex,' ',ZoneId[hhZoneIndex],' ',hhseg);
          for purpose:=1 to nTourPurposes do
          for dband:=1 to nDistBands do
            write(lsfile,' ',accessibilityLogsums[hhseg,purpose,dband]:6:5);
          writeln(lsfile);
        end;
      end;

      lasthhZoneIndex:=hhZoneIndex;
    end;
    if (nHHRecs mod Sample1inX = SampleOffset) then begin
      applyAutoOwnershipModel;
      applyTourGenerationModel;
      writeHouseholdDayRecord;
    end;
  until(lastHH);
  closeHouseholdInputFile;
  closeHouseholdDayOutputFile;
  closeTourOutputFile;
  for mode:=0 to nTourModes do
   writeAndCloseTripMatrixOutputFile(mode);
  writeSummaryOutput;
  if writeMDLogsums then close(lsfile);
  writeln(logFile); writeln(logFile,'Run finished at ',DateTimetoStr(now),' with ',nHHrecs,' households processed');
  close(logFile);
  writeln; writeln('Run finished at ',DateTimetoStr(now),' with ',nHHrecs,' households processed');
  if not(runInBatchMode) then begin
    write('Press Enter to exit'); readln;
  end;
end.


