% simulate learning protocol. Noisy WTA action choice
% Input: p are parameters
% Output:  hazard (T,K), and various traces all averaged over pop

% updates:
%   2023/11/23: 
%     sequence get R; R-Rexp; update w; update Rexp; decay Rexp;
%     learn; hazard
% 2023/12/21: bug: pR was not included in hs
% 2024/1/18: wARM decay
% 2024/1/19: single stim turns off ARM decay for t<=2,
%   so that first trial is right after training as in Tully 94
%

function [haz, hE_tr, hs_tr, d_tr, wARM1_tr, wARM2_tr, ...
  wLTM1_tr, wLTM2_tr, E_tr, R_tr] = runsim(p,thrp)

    global EdRhist EdRmeshx EdRmeshy
    
    T=p.T; % timesteps.
    K=p.K; %# flies
    % the traces (_tr) reflect the values at the morning of day 't'
    % but hazards are after expts. Bit weird...
    wARM        = zeros(2,K);
    wLTM        = p.wLTM0*ones(2,K);
    Rexpect_arm = zeros(2,K); % per arm
    h           = zeros(T,K);
    d_tr =R_tr  = zeros(T,1); % decisions matrix
    hE_tr=hs_tr = zeros(T,1);
    wARM1_tr = wARM2_tr = wLTM1_tr = wLTM2_tr = zeros(T,1);
    E_tr        = zeros(T,1);
    ltm_tr      = zeros(T,1);
    EspentLTM   = zeros(T,1);

    % initial energy; spaced out regularly min.. max
    E = linspace(p.E_init_min, p.E_init_max, K);
    for t=1:T
        if !p.singlestimQ || t>2 % don't decay for first trial
          wARM   *= p.decayARM; %exp(-1/p.tauARM); % moved here 2024-1-18
        else
          printf("runsim: Single stim, No ARM decay for t=2\n")
        end
        E_tr(t)     = mean(E);
        wLTM1_tr(t) = mean(wLTM(1,:));
        wLTM2_tr(t) = mean(wLTM(2,:));
        wARM1_tr(t) = mean(wARM(1,:));
        wARM2_tr(t) = mean(wARM(2,:));

        % input, indep noise on +/- and ARM/LTM. ARM and LTM could be made same
        xARM    = p.si_x*randn(K,2)+p.mu_x;
        xLTM    = p.si_x*randn(K,2)+p.mu_x;
        y       = wARM.*xARM'+wLTM.*xLTM';% activity in decision neurons
        
        d       = (y(1,:)>y(2,:)); % noisy WTA decision 
        if p.singlestimQ && t==1
          printf('single stim only. forcing exposure ...\n')
          d=0*ones(1,p.K);
        end
        
        d_tr(t) = mean(d);
        d2D     = [d; 1-d]; % decisions 2xK, e.g. [0 1 0; 1 0 1]
        
        % deal with periodically switching reward
        if p.Rflip_period >0 && mod(t, p.Rflip_period) >= p.Rflip_period/2
          #printf('flipping stim to other arm...\n')
          Rtable_actual = flip(p.Rtable);
          d_tr(t) = 1 - d_tr(t); %  so d_tr tracks #correct choices
        else
          Rtable_actual = p.Rtable;
        end

        % get reward(punish) and energy from choice
        if p.randstimQ # stim uniform between 0 and Etable
          E +=  ones(1,2)*(d2D.*p.Etable'.*rand(2,K));
          R = ones(1,2)*((d2D.*(rand(2,K) < p.pRtable')).*Rtable_actual'.*rand(2,K));
        else
          E += p.Etable*d2D;
          R = Rtable_actual*(d2D.*(rand(2,K) < p.pRtable'));
          # not! : R = Rtable_actual*d2D.*(rand(2,K) < p.pRtable');
        end

        Rexp = sum(Rexpect_arm.*d2D);
        dwLTM   = (R-Rexp).*xLTM';
        dwARM   = (R-Rexp).*xARM';
        
        if p.singlestimQ && t>1 % override
            R=0; % decay of R/Rexp does not matter.
            dwLTM= 0;
            dwARM= 0;
        end
        
        Rexpect_arm += (R - Rexpect_arm).*d2D*(1-p.decayRexpt); % but only update choosen
        Rexpect_arm *= p.decayRexpt; %  decay both arms. Discussable
        
        %learn via ARM or LTM? could add dwLTM and time
        LTMQ= LTMQfun(thrp, E, R-Rexp, R);

        if p.singlestimQ && t>1 % override
            LTMQ = 0*LTMQ; % for M0
        end
        
        ltm_tr(t)= mean(LTMQ); % track
        dwARM .*= p.eta_ARM*d2D.*(1-LTMQ); % only update choosen arm. Aversive -> LTD
        dwLTM .*= p.eta_LTM*d2D.*LTMQ;

        dwLTM   = min( max(wLTM+dwLTM, p.wLTMmin), p.wLTMmax)-wLTM;
       % mean(dwLTM')

        % restrict dw. Needed for correct energy calculation
        wLTM    += dwLTM;

        if p.useM0Q
           E       -= p.cLTM_M0*LTMQ;
           EspentLTM(t) = p.cLTM_M0*mean(LTMQ);
        else
          E       -= p.cLTM*LTMQ.*sum(abs(dwLTM));
          EspentLTM(t) = p.cLTM*mean(LTMQ.*sum(abs(dwLTM)));
        end

        wARM    += dwARM;    % maybe rectify?
        E          += p.dE;  % daily feed
        E           = max(min(E, p.Emax),0);
        hE          = hazardfunE(E,p); % haz from energy
        hstim       = max(-R,0);
        haz(t,:)    = 1-(1-hstim).*(1-hE);
        hE_tr(t,:)  = mean(hE);
        hs_tr(t,:)  = mean(hstim);
    end % time
endfunction

