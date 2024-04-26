
function lt_th = getlifetimes_theory(haz)
% see haz_tester.m
    [T,K]   = size(haz);
    surv    = cumprod([ones(1,K); 1-haz]);
    lt_th   = sum(surv); %duh...
endfunction
