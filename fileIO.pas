unit fileIO;
interface

    type inputFile = text;

    function setFileName(dirname,filename:string):string;
    function fileIsOmx(filename:string):boolean;
    function parse(ss:string; var pos:integer): string;


    procedure resetTextFile(var f:text; fn:string);
    procedure rewriteTextFile(var f:text; fn:string);

implementation
uses sysutils;

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

    function setFileName(dirname,filename:string):string;
    begin
        if (filename[2]=':') or (filename='/')
            then setFileName:=filename
        else if (dirname[length(dirname)]='\') or (filename[1]='\')
            or (dirname[length(dirname)]='/') or (filename[1]='/')
            then setFileName:=SetDirSeparators(dirname+filename)
        else setFileName:=SetDirSeparators(dirname+'\'+filename);
    end;

    function fileIsOmx(filename:string):boolean;
    begin
        fileIsOmx:= pos('.omx', filename) > 0
    end;

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
end.