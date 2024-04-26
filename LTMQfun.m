function LTMQ= LTMQfun(thrparams, E, dR, R)
    % threshold function
    switch (thrparams.name) % such string comparison is slow ...
        case('Ethr') % original model
            LTMQ = (E> thrparams.c0);
        case('dRthr') %
            LTMQ = (abs(dR) > thrparams.c0);
        case('Rthr') %
            LTMQ = (abs(R) > thrparams.c0);

        case('MT') % Jiamu's moving threshold
            LTMQ = (E> 1-thrparams.c0*abs(dR));
        case('2par')
            LTMQ = (1 + thrparams.c0*E + thrparams.c1*abs(dR) < 0);
        case('2par_var') % more natural variant
            LTMQ = (E + thrparams.c1*abs(dR) > thrparams.c0  );
        case('2par_final') % even more natural variant
            LTMQ = (E*thrparams.c0 +abs(dR)*thrparams.c1 > 1  );
        case('2par_final_flip') % even more natural variant
            LTMQ = (E*thrparams.c0 +abs(dR)*thrparams.c1 < 1  );
        case('3par')
            LTMQ = (1 + thrparams.c0*E + thrparams.c1*abs(dR) + thrparams.c2*E.*abs(dR) >0);
        case('2ANDpar') % don't use && or || !
            LTMQ = (E >  thrparams.c0) & (abs(dR) > thrparams.c1);
        case('2ORpar')
            LTMQ = (E >  thrparams.c0) | (abs(dR) > thrparams.c1);

        case('2parR')
            LTMQ = (1 + thrparams.c0*E + thrparams.c1*abs(R) < 0);
        case('2parR_var') % more natural variant
            LTMQ = (E + thrparams.c1*abs(R) > thrparams.c0  );

        otherwise
            error('LTMQfun. No such fun')
        endswitch    
endfunction
