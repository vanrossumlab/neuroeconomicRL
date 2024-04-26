%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pkg load parallel

global EdRhist EdRmeshx EdRmeshy

params=struct();  % structure to keep all settings
params.Emax     = 1;
params.pRtable  = 1 *[1, 1] ;  % reward probability (alternative is zero)
params.Rflip_period = 0;     % periodic stim
params.htable   = [0, 0.05]  ; % hazard of each arm, no actually used
params.Rtable   = -params.htable;  % rewards in either arm
params.Etable   = [0, 0];   % energy provided by each arm
params.mu_x     = 10.0;        % odor input rate
params.si_x     = sqrt(params.mu_x); % Poisson variability
params.dE       = 0.0;       % daily feed(+)/consumption(-) rate (beta)
params.cLTM     = 0.27*params.Emax;    % LTM proportionality, tuned to Mery
params.ch       = 3.9;      % hazard fun exponent (Emax=1, 50 days)
params.useM0Q   = 0;
params.cLTM_M0  = 0.1;
params.randstimQ = 0; % if ==1, stim drawn from uniform between 0 and h or R.

params.decayARM = 0.34; %0.34;   % ARM decay, per day
params.wLTMmax  = 1;      % softmax
params.wLTMmin  = 0;      % hardmin
params.wLTM0    = 0.5;    % initial LTM weight
params.eta_ARM  = 0.6;    % learning rate, set to zero to have no learning.
params.eta_LTM  = params.eta_ARM;    % learning rate, set to zero to have no learning.
params.singlestimQ= 0;    % binary switch to test single trial learning
params.decayRexpt = params.decayARM;
thrparams=struct();

%Simulation settings
params.K        = 10000;        % # parallel runs
params.T        = 50;           % # time steps
% Initial energies will be uniform between min and max.
params.E_init_min   = 0*params.Emax;
params.E_init_max   = 1*params.Emax;% params.E_init_min;

thrparamsLTMonly= setfield(thrparams,'c0',-1);
thrparamsLTMonly.name='Ethr';
thrparamsARMonly= setfield(thrparams,'c0',5);
thrparamsARMonly.name='Ethr';
thrparamsnolearn= setfield(thrparams,'c0',5);
thrparamsnolearn.name='Ethr';

nproc=100; # number of CPUs, maximized anyway
