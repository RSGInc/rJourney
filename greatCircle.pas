unit greatCircle;

interface
    function gcdist(th1,ph1,th2,ph2:double):double;

implementation
uses math;

    function gcdist(th1,ph1,th2,ph2:double):double;
        const
            {diameter = 2 * 6372800.0; in meters}
            diameter = 7917.5; {in miles}
        var
            dx, dy, dz: double;
        begin
            ph1 := degtorad(ph1 - ph2);
            th1 := degtorad(th1);
            th2 := degtorad(th2);

            dz := sin(th1) - sin(th2);
            dx := cos(ph1) * cos(th1) - cos(th2);
            dy := sin(ph1) * cos(th1);
            gcdist := arcsin(sqrt(dx**2 + dy**2 + dz**2) / 2) * diameter;
    end;
end.