//  omxmatrix.pas
//
//  OMX/HDF5 Matrix helper routines
//
//  @author Jeff Newman, Cambridge Systematics
//
//  Based on the c++ version, by
//  @author Billy Charlton, PSRC
//  @author Ben Stabler, RSG
//

unit omxmatrix;

interface
{$MACRO ON}
{$DEFINE  MODE_READWRITE:= 0 }
{$DEFINE  MODE_CREATE   := 1 }
{$DEFINE  MAX_TABLES  := 500 }

uses
	fgl, hdf5dll, SysUtils;

type

  PtrDouble = ^double;
  PtrFloat = ^single;
  TMapStringInt = TFPGMap<String,Integer>;
  TMapStringHID = TFPGMap<String,hid_t>;

  FileOpenException = Class(Exception);
  MatrixReadException = Class(Exception);
  InvalidOperationException = Class(Exception);
  OutOfMemoryException = Class(Exception);
  NoSuchTableException = Class(Exception);


TOMXMatrix = class(TObject)

public
    constructor Create();
    constructor CreateNew(tables:Integer;  rows:Integer; cols:Integer; tableNames:array of string; fileName:string; std_type:Integer);
    destructor Destroy(); override;

    procedure openFile(fileName:string);
    procedure closeFile();

    //Read/Open operations
    function  getRows(): Integer;
    function  getCols(): Integer;
    function  getTables(): Integer;
    procedure getRow(table:string; row:Integer; rowptr:Pointer);  // throws InvalidOperationException, MatrixReadException
    procedure getCol(table:string; col:Integer; colptr:Pointer);  // throws InvalidOperationException, MatrixReadException
    function  getTableName(table:Integer): String;

    //Write/Create operations
    procedure createFile(tables:Integer;  rows:Integer; cols:Integer; tableNames:array of string; fileName:string);
    procedure writeRow(table:string;  row:Integer; rowptr:Pointer);




//--------------------------------------------------------------------

//Data
public
    _h5file:hid_t;
    _nRows:Integer;
    _nCols:Integer;
    _nTables:Integer;
    _mode:Integer;
    _fileOpen:Boolean;

    _tableName:array[1..MAX_TABLES] of string;

    _tableLookup:TMapStringInt;
    _dataset:TMapStringHID;
    _dataspace:TMapStringHID;

    _dataset_count:Integer;
    _dataspace_count:Integer;

    _std_dtype:hid_t;
    std_dtype:Integer;
private

	_memspace:hid_t;

    //Methods
    procedure readTableNames();
    //procedure printErrorCode(error:Integer);
    procedure init_tables (tableNames:array of string);
    function  openDataset(table:string):hid_t;  // throws InvalidOperationException

end;

function isOMX(filename:string):Boolean;


implementation
{ the implementation is the code to execute the interface commands above }
var {global}
    h5:THDF5Dll;
    //= THDF5Dll.Create('path/to/dll')  ;



type
    T_FindAttrFunc = function ( loc_id:hid_t; name:PChar; ainfo:PH5A_info_t;
              op_data:Pointer):herr_t; CDecl;


function find_attr( loc_id:hid_t; name:PChar; ainfo:PH5A_info_t;
              op_data:Pointer):herr_t; CDecl;
var
  ret:Integer;
begin

    ret := H5_ITER_CONT;

    //* Shut compiler up */
    //loc_id := loc_id;
    // ainfo := ainfo;

    //* Define a positive value for return value if the attribute was found. This will
    //* cause the iterator to immediately return that positive value,
    //* indicating short-circuit success
    //*/
    if(strcomp(name, op_data) = 0) then
        ret := H5_ITER_STOP;

    result:= ret;
end;







function H5LT_find_attribute(  loc_id:hid_t; attr_name:PChar ):herr_t;
var
  find_attr_ptr : T_FindAttrFunc;
begin
    find_attr_ptr := @find_attr;
    result:= H5.H5Aiterate2(loc_id, H5_INDEX_NAME, H5_ITER_INC, Phsize_t(0), find_attr_ptr, Pointer(attr_name));
end;

function H5LTset_attribute_string(  loc_id:hid_t;
                                    obj_name, attr_name, attr_data:PChar):herr_t   ;
var
    attr_type:hid_t;
    attr_space_id:hid_t;
    attr_id:hid_t;
    obj_id:hid_t;
    has_attr:hid_t;
    attr_size:hid_t;

label
  out;
begin
        //* Open the object */
        obj_id := H5.H5Oopen(loc_id, obj_name, H5P_DEFAULT);
        if (obj_id < 0) then begin
            result := -1; exit;
        end;


        //* Create the attribute */
        attr_type := H5.H5Tcopy( H5.H5T_C_S1 );
        if ( (attr_type) < 0 ) then
            goto out;

        attr_size := strlen( attr_data ) + 1; //* extra null term */

        if ( H5.H5Tset_size( attr_type, size_t(attr_size)) < 0 ) then
            goto out;

        if ( H5.H5Tset_strpad( attr_type, H5T_STR_NULLTERM ) < 0 ) then
            goto out;
        attr_space_id := H5.H5Screate( H5S_SCALAR );
        if ( (attr_space_id) < 0 ) then
            goto out;

        //* Verify if the attribute already exists */
        has_attr := H5LT_find_attribute(obj_id, attr_name);

        //* The attribute already exists, delete it */
        if(has_attr = 1) then
            if(H5.H5Adelete(obj_id, attr_name) < 0) then
                goto out;

        //* Create and write the attribute */
        attr_id := h5.H5Acreate2(obj_id, attr_name, attr_type, attr_space_id, H5P_DEFAULT, H5P_DEFAULT);
        if(attr_id < 0) then
            goto out;

        if(H5.H5Awrite(attr_id, attr_type, attr_data) < 0) then
            goto out;

        if(H5.H5Aclose(attr_id) < 0) then
            goto out;

        if(H5.H5Sclose(attr_space_id) < 0) then
            goto out;

        if(H5.H5Tclose(attr_type) < 0) then
            goto out;

        //* Close the object */
        if(h5.H5Oclose(obj_id) < 0) then begin
            result := -1; exit;
        end;

        result := 0; exit;

    out:

        H5.H5Oclose(obj_id);
        result := -1; exit;
end;

type PInteger = ^Integer;

function H5LT_get_attribute_mem( loc_id:hid_t;
                                         obj_name,
                                         attr_name:PChar;
                                          mem_type_id:hid_t;
                                         data:Pointer) :herr_t;
var
  obj_id, attr_id: hid_t;
label
  out;
begin
        //* identifiers */
        obj_id := -1;
        attr_id:= -1;

        //* Open the object */
        obj_id := H5.H5Oopen(loc_id, obj_name, H5P_DEFAULT);
        if((obj_id) < 0) then
            goto out;
        attr_id := H5.H5Aopen(obj_id, attr_name, H5P_DEFAULT);
        if((attr_id) < 0) then
            goto out;

        if(H5.H5Aread(attr_id, mem_type_id, data) < 0) then
            goto out;

        if(H5.H5Aclose(attr_id) < 0) then
            goto out;
        attr_id := -1;

        //* Close the object */
        if(H5.H5Oclose(obj_id) < 0) then
            goto out;
        obj_id := -1;

        result:= 0;
        exit;

    out:
        if(attr_id > 0) then
            H5.H5Aclose(attr_id);
        result:= -1;

end;



function H5LTget_attribute_int(  loc_id:hid_t;
                             obj_name:PChar;
                             attr_name:PChar;
                             data:PInteger ):herr_t;
begin
    //* Get the attribute */
    if(H5LT_get_attribute_mem(loc_id, obj_name, attr_name, H5.H5T_NATIVE_INT, data) < 0) then begin
        result:= -1;
    end else begin ;
        result:= 0;
    end;
end;

function H5LT_set_attribute_numerical(  loc_id:hid_t;
                                    obj_name:PChar;
                                    attr_name:PChar;
                                     size:size_t;
                                     tid:hid_t;
                                   data:Pointer ):herr_t;
var
    obj_id, sid, attr_id: hid_t;
    dim_size:hsize_t;
    has_attr:Integer;
label
  out;
begin

    dim_size:=size;


    //* Open the object */
    obj_id := H5.H5Oopen(loc_id, obj_name, H5P_DEFAULT);
    if ((obj_id) < 0) then begin
        result := -1;   exit;
    end;

    //* Create the data space for the attribute. */
    sid := H5.H5Screate_simple( 1, @dim_size, Phsize_t(0) );
    if ( sid < 0 ) then
        goto out;

    //* Verify if the attribute already exists */
    has_attr := H5LT_find_attribute(obj_id, attr_name);

    //* The attribute already exists, delete it */
    if(has_attr = 1) then
        if(H5.H5Adelete(obj_id, attr_name) < 0) then
            goto out;

    //* Create the attribute. */
    attr_id :=H5. H5Acreate2(obj_id, attr_name, tid, sid, H5P_DEFAULT, H5P_DEFAULT);
    if((attr_id) < 0) then
        goto out;

    //* Write the attribute data. */
    if(H5.H5Awrite(attr_id, tid, data) < 0) then
        goto out;

    //* Close the attribute. */
    if(H5.H5Aclose(attr_id) < 0) then
        goto out;

    //* Close the dataspace. */
    if(H5.H5Sclose(sid) < 0) then
        goto out;

    //* Close the object */
    if(H5.H5Oclose(obj_id) < 0) then begin
        result := -1; exit;
    end;

    result := 0; exit;

out:
    H5.H5Oclose(obj_id);
    result := -1; exit;
end;



function H5LTset_attribute_int(  loc_id:hid_t;
                             obj_name:PChar;
                             attr_name:PChar;
                             data:PInteger;
                              size:Size_t ):herr_t ;
begin

    if ( H5LT_set_attribute_numerical( loc_id, obj_name, attr_name, size,
        H5.H5T_NATIVE_INT, data ) < 0 ) then begin
        result:= -1;
    end else begin
        result:= 0;
    end;
end;


constructor TOMXMatrix.Create();
begin
    _fileOpen := false;
    _nTables := 0;
    _nRows := 0;
    _nCols := 0;
    _memspace := -1;

    _tableLookup:= TMapStringInt.Create();
    _dataset := TMapStringHID.Create();
    _dataspace := TMapStringHID.Create();

    _dataset_count := 0;
    _dataspace_count := 0;

    _std_dtype := H5.H5T_NATIVE_DOUBLE;
    std_dtype := 64;

end;


constructor TOMXMatrix.CreateNew(tables:Integer;  rows:Integer; cols:Integer; tableNames:array of string; fileName:string; std_type:Integer);
begin
    _fileOpen := false;
    _nTables := 0;
    _nRows := 0;
    _nCols := 0;
    _memspace := -1;

    _tableLookup:= TMapStringInt.Create();
    _dataset := TMapStringHID.Create();
    _dataspace := TMapStringHID.Create();

    _dataset_count := 0;
    _dataspace_count := 0;

    _std_dtype := H5.H5T_NATIVE_DOUBLE;
    std_dtype := 64;
    if (std_type=32) then begin
       _std_dtype := H5.H5T_NATIVE_FLOAT;
       std_dtype := 32;
    end;

    createFile(tables,rows,cols,tableNames,fileName);
end;


destructor TOMXMatrix.Destroy();
begin
    if (_memspace > -1 ) then begin
        H5.H5Sclose(_memspace);
        _memspace := -1;
    end;

    // Close H5 file handles
    if (_fileOpen=true) then begin
        H5.H5Fclose(_h5file);
    end;

    _fileOpen := false;
end;

//Write/Create operations ---------------------------------------------------

procedure TOMXMatrix.createFile( tables:Integer;  rows:Integer;  cols:Integer; tableNames:array of string;  fileName:String);
var
	shape:array[0..1] of Integer;
	plist:hid_t;
begin
    _fileOpen := true;
    _mode := MODE_CREATE;

    _nRows := rows;
    _nCols := cols;
    _nTables := tables;

    // Create the physical file - H5F_ACC_TRUNC = overwrite an existing file
    _h5file := H5.H5Fcreate(PChar(fileName), H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
    if (0 > _h5file) then begin
        writeln(stderr, 'ERROR: Could not create file ', fileName);
    end;


    // Build SHAPE attribute
    shape[0] := rows;
    shape[1] := cols;

    // Write file attributes
    H5LTset_attribute_string(_h5file, '/', 'OMX_VERSION', '0.2');
    H5LTset_attribute_int(_h5file, '/', 'SHAPE', @(shape[0]), 2);

    // save the order that matrices are written
    plist := H5.H5Pcreate (H5.H5P_GROUP_CREATE);
    H5.H5Pset_link_creation_order(plist, H5P_CRT_ORDER_TRACKED);

    // Create folder structure
    H5.H5Gcreate2(_h5file, '/data', 0, plist, 0);
    H5.H5Gcreate2(_h5file, '/lookup', 0, plist, 0);

    H5.H5Pclose(plist);

    // Create the datasets
    init_tables(tableNames);
end;

procedure TOMXMatrix.writeRow( table:String;  row:Integer; rowptr:Pointer);
var
   count, offset:array[0..1] of hsize_t;
begin

	// First see if we've opened this table already
	if (_dataset.IndexOf(table) < 0) then begin
		// Does this table exist?
		if (_tableLookup.IndexOf(table) < 0) then begin
			Raise NoSuchTableException.Create(table);
		end;
		_dataset[table] := openDataset(table);
                Inc(_dataset_count);
	end;



    count[0] := 1;
    count[1] := _nCols;

    offset[0] := row-1;
    offset[1] := 0;

    if (_memspace <0 ) then begin
    	_memspace := H5.H5Screate_simple(2,count,Phsize_t(0));
    end;

    if (_dataspace.IndexOf(table)<0) then begin
        _dataspace[table] := H5.H5Dget_space(_dataset[table]);
        Inc(_dataspace_count);
    end;

    H5.H5Sselect_hyperslab (_dataspace[table], H5S_SELECT_SET, offset, Phsize_t(0), count, Phsize_t(0));

    if (0 > H5.H5Dwrite(_dataset[table], _std_dtype, _memspace, _dataspace[table], H5P_DEFAULT, rowptr)) then begin
        writeln(stderr, 'ERROR: writing table ',table,', row ', row);
        exit;
    end;



end;

//Read/Open operations ------------------------------------------------------

procedure TOMXMatrix.openFile( filename:string);
var
	shape:array[0..1] of Integer;
	status:herr_t;
begin
    // Try to open the existing file
    _h5file := H5.H5Fopen(PChar(filename), H5F_ACC_RDWR, H5P_DEFAULT);
    if (_h5file < 0) then begin
        writeln(stderr, 'ERROR: Cant find or open file ',filename);
        exit;
    end;

    // OK, it's open and it's HDF5;
    // Now query some things about the file.
    _fileOpen := true;
	_mode := MODE_READWRITE;

    status := 0;
    status += H5LTget_attribute_int(_h5file, '/', 'SHAPE', @(shape[0]));
    if (status < 0) then begin
        writeln(stderr, 'ERROR: ',filename,' doesnt have SHAPE attribute');
        exit;
    end;
    _nRows := shape[0];
    _nCols := shape[1];

    readTableNames();
end;

function TOMXMatrix.getRows():Integer;
begin
    result:= _nRows;
end;

function TOMXMatrix.getCols() :Integer;
begin
    result:= _nCols;
end;

function TOMXMatrix.getTables() :Integer;
begin
    result:= _nTables;
end;

function TOMXMatrix.getTableName( table:Integer):String;
begin
    result:= _tableName[table];
end;

procedure TOMXMatrix.getRow ( table:String;  row:Integer; rowptr:Pointer);
var
	data_count:array[0..1] of hsize_t;
	data_offset:array[0..1] of hsize_t;
begin

    // First see if we've opened this table already
    if (_dataset.IndexOf(table)<0) then begin
        // Does this table exist?
        if (_tableLookup.IndexOf(table)<0) then begin
            Raise MatrixReadException.Create('matrix read error') ;
        end;
        _dataset[table] := openDataset(table);
        Inc(_dataset_count);
    end;

    data_count[0] := 1;
    data_count[1] := _nCols;
    data_offset[0] := row-1;
    data_offset[1] := 0;

    // Create dataspace if necessary.  Don't do every time or we'll run OOM.
    if (_dataspace.IndexOf(table)<0) then begin
        _dataspace[table] :=H5. H5Dget_space(_dataset[table]);
        Inc(_dataspace_count);
    end;

    // Define MEMORY slab (using data_count since we don't want to read zones+1 values!)
    if (_memspace < 0) then begin
        _memspace := H5.H5Screate_simple(2, data_count, Phsize_t(0));
    end;

    // Define DATA slab
    if (0 > H5.H5Sselect_hyperslab (_dataspace[table], H5S_SELECT_SET, data_offset, Phsize_t(0), data_count, Phsize_t(0))) then begin
        writeln(stderr, 'ERROR: Couldnt select DATA subregion for table ',table,', subrow ',row);
        exit;
    end;

    // Read the data!
    if (0 > H5.H5Dread(_dataset[table], _std_dtype, _memspace, _dataspace[table],
            H5P_DEFAULT, rowptr)) then begin
        writeln(stderr, 'ERROR: Couldnt read table ',table,', subrow ',row);
        exit;
    end;
end;

procedure TOMXMatrix.getCol( table:String;  col:Integer; colptr:Pointer);
var
	data_count:array[0..1] of hsize_t;
	data_offset:array[0..1] of hsize_t;
begin

	// First see if we've opened this table already
	if (_dataset.IndexOf(table) < 0) then begin
		// Does this table exist?
		if (_tableLookup.IndexOf(table) < 0) then begin
			Raise MatrixReadException.Create('matrix read error');
		end;
		_dataset[table] := openDataset(table);
                Inc(_dataset_count);
	end;

	data_count[0] := _nRows;
	data_count[1] := 1;
	data_offset[0] := 0;
	data_offset[1] := col - 1;

	// Create dataspace if necessary.  Don't do every time or we'll run OOM.
	if (_dataspace.IndexOf(table) < 0) then begin
		_dataspace[table] := H5.H5Dget_space(_dataset[table]);
                Inc(_dataspace_count);
	end;

	// Define MEMORY slab (using data_count since we don't want to read zones+1 values!)
	if (_memspace < 0) then begin
		_memspace := H5.H5Screate_simple(2, data_count, Phsize_t(0));
	end;

	// Define DATA slab
	if (0 > H5.H5Sselect_hyperslab(_dataspace[table], H5S_SELECT_SET, data_offset, Phsize_t(0), data_count, Phsize_t(0))) then begin
		writeln(stderr, 'ERROR: Couldnt select DATA subregion for table ',table,', subcol ',
			col);
		exit;
	end;

	// Read the data!
	if (0 > H5.H5Dread(_dataset[table], _std_dtype, _memspace, _dataspace[table],
		H5P_DEFAULT, colptr)) then begin
		writeln(stderr, 'ERROR: Couldnt read table ',table,', subcol ', col);
		exit;
	end;
end;

procedure TOMXMatrix.closeFile;
var
        j:Integer;
begin
     if (_fileOpen=true) then begin
         if (_dataset_Count > 0) then begin
          for j := 0 to _dataset_Count-1 do begin
              H5.H5Dclose(_dataset.Data[J]);
          end;
        end;

        if (_dataspace_Count > 0) then begin
          for j := 0 to _dataspace_Count-1 do begin
              H5.H5Sclose(_dataspace.Data[J]);
          end;
        end;

        if (_memspace > -1 ) then begin
            H5.H5Sclose(_memspace);
            _memspace := -1;
        end;


        H5.H5Fclose(_h5file);
    end;
    _fileOpen := false;
end;

// ---- Private functions ---------------------------------------------------

function TOMXMatrix.openDataset( table:string):hid_t;
var
        tname: string;
        dataset: hid_t;
begin

     tname := '/data/' + table;

     dataset := H5.H5Dopen2(_h5file, PChar(tname), H5P_DEFAULT);
    if (dataset < 0) then
        raise InvalidOperationException.Create('nope');


    result:= dataset;
end;

//
// Group traversal function. Build list of tablenames from this.
//

type POMXMatrix = ^TOMXMatrix;

type T_LeafInfoFunc = function ( loc_id:hid_t;name:PChar; info:PH5L_info_t; opdata:Pointer):herr_t; CDecl;


function _leaf_info( loc_id:hid_t;name:PChar; info:PH5L_info_t; opdata:Pointer) : herr_t;  CDecl;
var
        m : TOMXMatrix;
begin
    m := POMXMatrix(opdata)^;
    m._nTables := m._nTables +1;
    m._tableName[m._nTables] := name;
    m._tableLookup[name] := m._nTables;
    result:= 0;
end;

// Read table names.  Sets number of tables in file, too.
procedure TOMXMatrix.readTableNames();
var
	datagroup:hid_t;
	info:hid_t;
        flags:Integer;
        p_leaf_info: T_LeafInfoFunc;
begin

    _nTables := 0;
    _tableLookup.clear();
    _dataset.clear();
    _dataspace.clear();
    flags := 0;

    datagroup := H5.H5Gopen2(_h5file, '/data', H5P_DEFAULT);

    // if group has creation-order index, use it
    info := H5.H5Gget_create_plist(datagroup);
    H5.H5Pget_link_creation_order(info, @flags);
    H5.H5Pclose(info);

    p_leaf_info := @_leaf_info;
    if ((flags and H5P_CRT_ORDER_TRACKED) <> 0) then begin
    	// Call _leaf_info() for every child in /data:
        H5.H5Literate(datagroup, H5_INDEX_CRT_ORDER, H5_ITER_INC, Phsize_t(0), p_leaf_info, @self);
    end else begin
    	// otherwise just use name order
    	H5.H5Literate(datagroup, H5_INDEX_NAME, H5_ITER_INC, Phsize_t(0), p_leaf_info, @self);
    end;

    H5.H5Gclose(datagroup);
end;



procedure TOMXMatrix.init_tables (tableNames:array of string);
var
    dims       :array[0..1] of hsize_t ;
    plist      :hid_t   ;
    rtn        :herr_t  ;
    chunksize  :array[0..1] of hsize_t ;
    fillvalue  :array[0..0] of double  ;
    dataspace  :hid_t;
    t:Integer;
    tpath, tname: String;
    ptpath:PChar;
    temp_hid : hid_t;
begin

    dims[0] := _nRows;
    dims[1] := _nCols;

    fillvalue[0] := 0.0;
    chunksize[0] := 5; // a few rows at a time, instead of just one
    chunksize[1] := _nCols;
    //if (_nCols > 5000) then begin
    //   chunksize[1] := 4000;
    //end else begin
    //   chunksize[1] := _nCols;
    //end;

    dataspace := H5.H5Screate_simple(2,dims, nil);

    // Use a row-chunked, zip-compressed data format:
    plist := H5.H5Pcreate(H5.H5P_DATASET_CREATE);
    rtn := H5.H5Pset_chunk(plist, 2, chunksize);
    rtn := H5.H5Pset_deflate(plist, 1);
    rtn := H5.H5Pset_fill_value(plist, _std_dtype, @(fillvalue[0]));

    // Loop on all tables
    for t := 0 to Length(tableNames)-1 do begin
        tpath := '/data/' + tableNames[t];
        tname := tableNames[t];
        ptpath:= PChar(tpath);

        // Create a dataset for each table
        temp_hid := H5.H5Dcreate2(_h5file, ptpath, _std_dtype,
                                  dataspace, H5P_DEFAULT, plist, H5P_DEFAULT);
        if (temp_hid<0) then begin
            writeln(stderr, 'Error creating dataset ',tpath);
            exit;
        end;
        _dataset[tname] := temp_hid;

        // Save the something somewhere
        _tableLookup[tname] := t+1;
        _tableName[t+1] := tname
    end;

    rtn := H5.H5Pclose(plist);
    rtn := H5.H5Sclose(dataspace);
end;

function isOMX(filename:string):Boolean;
var
	answer:htri_t;
	f:hid_t;
	exists:herr_t;
begin
	answer := H5.H5Fis_hdf5(PChar(filename));
	if (answer <= 0) then begin
           result:= false;
           exit;
        end;

	// It's HDF5; is it OMX?
	f := H5.H5Fopen(PChar(filename), H5F_ACC_RDONLY, H5P_DEFAULT);
	exists := H5LT_find_attribute(f, 'OMX_VERSION');

	//don't actually care what OMX version it is, yet...
	//char version[255];
	//int status = H5LTget_attribute_string(f,"/","OMX_VERSION", version);
	H5.H5Fclose(f);

	if (exists = 0)  then begin
		writeln(stderr, '\n** ',filename,' is HDF5, but is not a valid OMX file.' );
		exit;
	end;

	result:= true;
end;



begin
  h5 := THDF5Dll.Create('hdf5.dll');
end.
