function lt = getlifetimes(haz_ar)
    [T,K]= size(haz_ar);
    dieQ =  (rand(T,K)<haz_ar);
    
    killatTQ = 1; % whether to kill all flies at T+1; if not, assume haz is constant from T onwards, exp dist.
    if killatTQ
        dieQ=[dieQ; ones(1,K)];
    end
    
    for k=1:K  % for all flies
        ltk = find(dieQ(:,k),1);
        if isempty(ltk)
            ltk=T + 1./haz_ar(T,k)*rande(); % assume haz is constant after T
        end
        lt(k) =ltk;
    end
endfunction
