unit defaults;

interface

{Constants}
const
    {user inputs}
    baseYear=2018;

    RunTitle:string='National_Long_Distance_Model';
    InputDirectoryName:string='inputs';
    RoadLOSFileName:string='zoneRoadLOS.dat';
    RailLOSFileName:string='zoneRailLOS.dat';
    AirLOSFileName:string='zoneAirLOS.dat';
    ZoneLandUseFileName:string='numa_2010_landuse.dat';
    VehicleAltsFilename:string='vehicle_type_alts.csv';
    HouseholdFileName:string='us_synpop_hh3_sorted.dat';
    numberOfHouseholds:integer = 114736858;
    OutputDirectoryName:string='outputs';
    HouseholdDayFileName:string='household_out_1.csv';
    HouseholdVehicleFilename:string='household_vehicles.csv';
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
    UseRandomNumberSynchronization:boolean = True;
    Sample1inX:integer = 1;
    SampleOffset:integer = 0;
    WriteHouseholds:boolean = True;
    WriteTours:boolean = True;
    WriteExtraTourVars = True;
    WriteLOSSummaryFile = True;
    WriteSkimsEveryXZones: integer = 0;
    {
    WriteTripMatrix:array[0..4] of boolean=(False,False,False,False);
    WriteProbs:boolean=False;
    WriteADT:boolean=False;
    TripMatrixMinimumDistance:integer=50;
    }
    nDays = 366;
    DaysInMonth:array[0..12] of integer=(365, 31,28,31, 30,31,30, 31,31,30, 31,30,31);
    useSegmentedModels:boolean=False;
    stateToUseSeparateCoefficientFiles:integer=0;
    StateToSubsampleZoneModeDestCalcs:integer=0;
    StateZoneSubsample1inX:integer=0;
    StateToWriteTourRecords:integer=0;
    sampFactor:single=1.0;
    AirFareFactor:single=2.0;
    VOTIncomeDivisor:single=80.0;

    CoefficientDirectoryName:string = 'coeffcients';
    vehicleOwnershipCoefFile:string = 'vehicleOwnership.f12';
    vehicleAllocationCoefFile: string='vehicleAllocation.f12';
    FrCoefFile:array[1..4] of string =
        ('freqest3b.f12',
        'fsecest3b.f12',
        'freqest3b.f12',
        'fsecest3b.f12');
    DCCoefFile:array[1..10] of string =
        ('pbusdest6_bxc.F12',
        'vfardest6_bxc.F12',
        'leisdest6_bxc.F12',
        'commdest6_bxc.F12',
        'ebusdest6_bxc.F12',
        'pbusdest6_bxc.F12',
        'vfardest6_bxc.F12',
        'leisdest6_bxc.F12',
        'commdest6_bxc.F12',
        'ebusdest6_bxc.F12');
    MCCoefFile:array[1..10] of string =
        ('pbusmode13_est.F12',
        'vfarmode13_est.F12',
        'leismode13_est.F12',
        'commmode13_est.F12',
        'ebusmode13_est.F12',
        'pbusmode13_est.F12',
        'vfarmode13_est.F12',
        'leismode13_est.F12',
        'commmode13_est.F12',
        'ebusmode13_est.F12');
    TDCoefFile:array[1..10] of string =
        ('pbus_dur3.F12',
        'vfar_dur3.F12',
        'leis_dur3.F12',
        'comm_dur3.F12',
        'ebus_dur3.F12',
        'pbus_dur3.F12',
        'vfar_dur3.F12',
        'leis_dur3.F12',
        'comm_dur3.F12',
        'ebus_dur3.F12');
    PSCoefFile:array[1..10] of string =
        ('pbus_psize3.F12',
        'vfar_psize3.F12',
        'leis_psize3.F12',
        'comm_psize3.F12',
        'ebus_psize3.F12',
        'pbus_psize3.F12',
        'vfar_psize3.F12',
        'leis_psize3.F12',
        'comm_psize3.F12',
        'ebus_psize3.F12');
    AOCoefFile:array[1..2] of string=
        ('carown3.f12',
        'carown3.f12');
    useDMAConstants:boolean=false;
    DMAConstFile:string='DMAtoDMA_Const.F12';
    FLBorderState:array[1..2] of integer=(1, 13);
    stateToReadCarOwnershipFromHHFile:integer=0;
    scenarioIncomeChange:single=0;
    scenarioAutoCostChange:single=0;
    scenarioAutoTimeChange:single=0;
    scenarioAirFareChange:single=0;
    scenarioRailTimeChange:single=0;
    copercpm:single = 0.2;
    runInBatchMode:boolean = false;
    writeMDLogsums=false;


    // tour constants
    nTourPurposes = 5;
    nCoefPurposes = 10;
    PersBusPurp = 1;
    VisitPurp = 2;
    LeisurePurp = 3;
    CommutePurp = 4;
    EmplBusPurp = 5;
    nTourModes = 4;
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


    // zone constants
    nTracts = 73057;
    mZones =  12000;
    maxZoneNum = 99999;
    nCensDivs = 10;
    {array dimensions}
    censDivLabel:array[1..nCensDivs] of string=('New Eng','Mid Atl','NE Cent','NW Cent','Sou Atl','SE Cent','SW Cent','Mountn ','Pacific','AK & HI');
    stateCensDiv:array[1..56] of integer=
    (6,10,0,8,7,9,0,8,1,5,
    5,5,5,0,10,8,3,3,4,4,
    6,7,1,5,1, 3,4,6,4,8,
    4,8,1,2,8, 2,5,4,3,7,
    9,2,0,1,5, 4,6,7,8,1,
    5,0,9,5,3, 8);

    // household constants
    hhVehCats=5;
    hhIncCats=5;
    trPurposeLabel:array[0..nTourPurposes] of string=('Total  ','PersBus','VisitFR','Leisure','Commute','EmplBus');
    hhIncLabel:array[0..hhIncCats] of string=        ('Total  ','0-35 $k','35-65$k','65-100k','100-150','Over150');
    hhVehLabel:array[1..hhVehCats] of string=        ('0 cars ','1 car  ','2 cars ','3 cars ','4+ cars');

    // los constants
    nodstypes=5;


    // mode destination constants
    nHHSegs=15; 
    nPSSegs=3; 
    nNASegs=3; 
    nMOSegs=1; 
    nDistBands=4;
    maxmccoef=499;
    maxdccoef=99;
    firstsizevar=21;
    lastsizevar=24;
    logsizemult=25;
    maxDMA = 1000;

    // auto ownership constants
    nAOAlts=5;
    maxVehicleAlternatives = 250;

implementation
begin
end.