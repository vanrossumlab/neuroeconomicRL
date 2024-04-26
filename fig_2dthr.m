% Sep22. Code refresh, based on my old tl.m code and Jiamu's additions.
close all
clear all

% TODO:
% - whether or not to include death flies in means. (NaN)
% - unclear how to set ARM bound and initial value
%
% To try
% - daily feed/cost
% - suboptimal, fixed threshold (as in Preat)
% - effect of thresholding dw update.
% - effect of decay/stim interval (trivial)
% Extensions: multiple arms, stochastic and non-stat. rewards
% Poisson time stim.
%
% 8/23: clean up. 
% define threshold function; no ARM cost; decay definition; always Rexp per arm
%
addpath('../src/')
source('../src/setparams.m')

    saveQ=1

    params.E_init_min   = 0*params.Emax;
    params.E_init_max   = 1*params.Emax;
    params.K        = 25e3; % 1e5 nice plots.. % # flies
    hs_ar = [0:0.01:0.2];
    ps_ar = [0:0.05:1];
    dE_ar = [-0.2:0.04:0.2];

    parstr='hs' % {"hs", "ps", "dE" } which parameter to vary

    if parstr == 'hs'
        par_ar = hs_ar;
    elseif parstr == 'ps'
        par_ar = ps_ar;
    elseif parstr == 'dE'
        par_ar = dE_ar;
    else
        error("no such parstr")
    end
    Npar = length(par_ar)
    params.useM0Q = 0;

    thrparams.name='2ORpar';
    c0min= 0.;
    c0max= 1.5;
    c1min= -0;
    c1max= 20;
    ngrid= 35

    c0range = linspace(c0min, c0max, ngrid);
    c1range = linspace(c1min, c1max, ngrid);
    [c0_ar,c1_ar] = meshgrid(c0range,c1range);
    meanlt_across_par = 0*c0_ar;
    meanlt3D= zeros(Npar, length(c0range) ,length(c1range));
    ltARM = zeros(1,Npar); ltLTM = zeros(1,Npar);  lt_nolearn = zeros(1,Npar);
    for ipar = 1:Npar
        if parstr == 'hs'
            hs = hs_ar(ipar)
            ps = 1;
            dE = 0;
        elseif parstr == 'ps'
            hs = 0.1;
            ps = ps_ar(ipar)
            dE = 0;
        elseif parstr == 'dE'
            hs = 0.1;
            ps = 1;
            dE = dE_ar(ipar)
        else
            error("no such parstr")
        end
        params.htable   = [0, hs]  ; % hazard of each arm
        params.Rtable   = -params.htable;  % rewards in either arm
        params.pRtable  = ps*[1 1];
        params.dE       = dE;

        % 2parfinal:  if c1=0: LTM if E>1/c0
        %ARM c1=-1, c0 =-1
        %LTM c1=100, c0= 100
        lt_LTM(ipar) = mean(getlifetimes_theory(runsimwrapper_thr(params,100,100,0,thrparams)));
        lt_ARM(ipar) = mean(getlifetimes_theory(runsimwrapper_thr(params,-1,-1,0,thrparams)));

        paramsnolearn   = setfield(params,'eta_ARM',0);
        paramsnolearn.eta_LTM=0;
        lt_nolearn(ipar)= mean(getlifetimes_theory(runsimwrapper_thr(paramsnolearn,-1,-1,0,thrparams)));

        haz = pararrayfun(nproc, @(x,y) runsimwrapper_thr(params,x,y,0,thrparams), c0_ar,c1_ar,"UniformOutput",false);
        lt = parcellfun(nproc,"getlifetimes_theory",haz, "UniformOutput", false);
        meanlt = cellfun("mean",lt);
        lt_2D(ipar) = max(max(meanlt));
        meanlt3D(ipar,:,:) = meanlt;
        meanlt_across_par += meanlt;
    end
    meanlt_across_par /= length(hs_ar);

    [ltbest, im] = max (reshape(meanlt_across_par,1, []));
    ltbest
    [best_idx2_x, best_idx2_y] = ind2sub(size(meanlt_across_par), im)
    c0opt = c0_ar(best_idx2_x, best_idx2_y)
    c1opt = c1_ar(best_idx2_x, best_idx2_y)
    % fix params to best mean:
    lt2parbest = meanlt3D(:, best_idx2_x, best_idx2_y)'; % lt at fixed, opt thr
    
    figure(100)
    surf(c0_ar, c1_ar, meanlt_across_par)
    xlabel('cM'); ylabel('cR')
    title(parstr)
    print fig100.epsc

    figure(101)
    contourf(c0_ar, c1_ar, meanlt_across_par,20)
    xlabel('cM'); ylabel('cR')
    colorbar
    title(parstr)
    print fig101.epsc

    % plot best solutions
    figure(1)
    plot(par_ar,lt_nolearn,';no learn;')
    hold on
    plot(par_ar,lt_ARM,';ARM;')
    plot(par_ar,lt_LTM,';LTM;')
    plot(par_ar,lt_2D,';2D;')
    plot(par_ar,lt2parbest,';2D-fixed;')
    xlabel(parstr); ylabel('lt')
    title(parstr)
    print fig1.epsc

    if saveQ
        save 'lt3D.dat' meanlt3D
        save 'lt2D_across_par.dat' meanlt_across_par
        res=[par_ar;lt_nolearn; lt_ARM; lt_LTM; lt_2D; lt2parbest]';
        save 'lt_vs_par.dat' res
    end

