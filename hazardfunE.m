% assumed relation between hazard and reserve.
function h = hazardfunE(E,p)
    h= exp(-p.ch*max(E,0));
    % note changing this necessitates recalibration of EspentLTM (Emax, cLTM)
end
