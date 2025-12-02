unit logicalFuncs;

interface
    function max(a,b:single):single;
    function min(a,b:single):single;
    function ifin(a,b,c:single):integer;
    function ifeq(a,b:single):integer;
    function ifge(a,b:single):integer;
    function iflt(a,b:single):integer;

    function checkInt(ss:string; low,high:integer):integer;
    function checkBool(ss:string):boolean;


implementation
uses SysUtils;

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
end.