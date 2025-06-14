%% v6
clear,clc,close all
% Haomin laptop
%addpath(genpath('C:\Users\haomi\Documents\GitHub\VFIToolkit-matlab'))
% Ale laptop
addpath(genpath('C:\Users\aledi\Documents\GitHub\VFIToolkit-matlab\VFIToolkit-matlab'));
% Desktop
%addpath(genpath('C:\Users\aledi\OneDrive\Documents\GitHub\VFIToolkit-matlab'));
% Buera & Shin (2013) - Financial Frictions and the Persistence of History: 
% A Quantitative Exploration

%% Set folders
ResFolder = 'results'; % Folder to save results
InpFolder = 'inputs';  % Folder where model inputs are saved

if ~isfolder(ResFolder)
    warning('Subfolder for results does not exist.. creating it now')
    mkdir(ResFolder)
end
if ~isfolder(InpFolder)
    warning('Subfolder for inputs does not exist..')
end

%% Flags and numerical options
CreateFigures  = 0; % Flag 0/1 plot figures of initial steady-state
do_GE          = 0; % 0 = partial equilibrium, 1 = general equilibrium
do_replication = 0; % Flag 0/1 to replicate Figure 2 of BS 2013. This 
                    % requires repeatedly solving the s.s. for different
                    % lambdas
% Options for value function iteration:
vfoptions                   = struct();
vfoptions.verbose           = 0;
vfoptions.lowmemory         = 0;
vfoptions.separableReturnFn = 1; % NEW
vfoptions.tolerance         = 1e-9;
vfoptions.howards           = 80;
vfoptions.maxhowards        = 500;
% Options for stationary distribution:
simoptions                 = struct();
% Options for GE loop:
heteroagentoptions.fminalgo=1;
heteroagentoptions.maxiter=50;
heteroagentoptions.verbose=1;
heteroagentoptions.toleranceGEprices=10^(-3);
heteroagentoptions.toleranceGEcondns=10^(-3);

%% Parameters

% Preferences
Params.crra = 1.5;   % CRRA utility param
Params.beta = 0.904; % Discount factor

% Production fn
Params.delta   =0.06; % Capital depreciation rate
Params.alpha   =0.33; % Capital coefficient
Params.upsilon =0.21; % 1 minus span of control parameter

% Entrepreneurial ability shocks
Params.psi     =0.894; %stochastic process: persistence
Params.eta     =4.15;  %stochastic process: dispersion

% Collateral constraint
Params.lambda  =inf; % Calibration of steady-state done for US economy

% Initial values for general eqm parameters: good for lambda=inf
Params.r = 0.0476;
Params.w = 0.172;

%% Grid for assets
d_grid = []; % No grid for static choice d
n_d    = 0;  % No grid for static choice d
% grid on assets
n_a    = 1001; % Num of grid points
a_min  = 1e-6; % Lower bound
a_max  = 4000; % Upper bound
% a_scale>1 puts more points near zero
a_scale = 2;   % "Curvature" of asset grid
a_grid  = a_min+(a_max-a_min)*linspace(0,1,n_a)'.^a_scale;

%% Stochastic process

z1_grid  = importdata(fullfile(InpFolder,'support.dat'));
n_z1     = length(z1_grid);
pi_z_vec = importdata(fullfile(InpFolder,'dist.dat'));
% See my notes on Buera and Shin paper
pi_z1 = Params.psi*eye(n_z1)+(1-Params.psi)*ones(n_z1,1)*pi_z_vec';
pi_z1 = pi_z1./sum(pi_z1,2);

z2_grid = 1;%[1,1,1]';
pi_z2 = 1;%[0.2, 0.4,0.4;
         %0.2, 0.4,0.4;
         %0.2, 0.4,0.4];

z_grid = [z1_grid;z2_grid];
pi_z = kron(pi_z2,pi_z1);

n_z = [n_z1,length(z2_grid)]; % Num of grid points for exo state z

%% Return fn
DiscountFactorParamNames={'beta'};
% Required inputs:
% (aprime,a,z) in this order, than any parameter

% --- ALL IN ONE
if vfoptions.separableReturnFn==0
    ReturnFn=@(aprime,a,z1,z2,crra,w,r,lambda,delta,alpha,upsilon) ...
        f_ReturnFn(aprime,a,z1,z2,crra,w,r,lambda,delta,alpha,upsilon);
    ReturnFnParamNames = [];

else
    % --- SPLIT IN TWO BLOCKS
    ReturnFnParamNames = [];
    ReturnFn.R1=@(a,z1,z2,w,r,lambda,delta,alpha,upsilon) f_ReturnFn_step1(a,z1,z2,w,r,lambda,delta,alpha,upsilon);
    %ReturnFnParamNames.R1 = {'w','r','lambda','delta','alpha','upsilon'};

    ReturnFn.R2=@(aprime,cash_on_hand,crra) f_ReturnFn_step2(aprime,cash_on_hand,crra);
    %ReturnFnParamNames.R2 = {'crra'};
end

%% Create some FnsToEvaluate
FnsToEvaluate.A=@(aprime,a,z1,z2) a; % assets
% Capital demand by entre (zero if worker)
FnsToEvaluate.K=@(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon) f_capitaldemand(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon); 
% Labor demand by entre (zero if worker)
FnsToEvaluate.L=@(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon) f_labordemand(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon); 
% 1 if entrepreneur, 0 if worker
FnsToEvaluate.entrepreneur=@(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon) f_entrepreneur(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon);

%% Set up general equilibrium
% heteroagentoptions.fminalgo=5;
% % Need to explain to heteroagentoptions how to use the GeneralEqmEqns to update the general eqm prices.
% heteroagentoptions.fminalgo5.howtoupdate={...  % a row is: GEcondn, price, add, factor
%     'capitalmarket','r',1,0.03;...  % capitalmarket GE condition will be positive if r is too big, so subtract
%     'labormarket','w',1,0.1;... % labormarket GE condition will be positive if w is too small, so add
% };

% There are two prices to be determined in GE and two GE conditions
GEPriceParamNames={'r','w'};
heteroagentoptions.constrainpositive={'w'};
% GE(1): capital demand minus capital supply
GeneralEqmEqns.capitalmarket=@(K,A) K-A; 
% GE(2): labor demand minus labor supply, suppy is just fraction of workers (who each exogneously supply endowment 1 of labor)
GeneralEqmEqns.labormarket=@(L,entrepreneur) L-(1-entrepreneur); 

%% Compute the model once, either in partial or general equilibrium

if do_GE==1
    disp('Solving initial stationary general eqm')
else
    disp('Solving initial partial eqm')
end

[Outputs,GE_cond,Policy_init,StationaryDist_init,AggVars_init,ValuesOnGrid] = BueraShin_Fn(do_GE,Params,n_d,n_a,n_z,pi_z,d_grid,a_grid,z_grid,ReturnFn,FnsToEvaluate,GeneralEqmEqns,DiscountFactorParamNames,GEPriceParamNames,heteroagentoptions,simoptions,vfoptions,ReturnFnParamNames);

%% Analyse results from model solution and make plots
Params.r=Outputs.r;
Params.w=Outputs.w;

workerORentrepreneur_init=ValuesOnGrid.entrepreneur;
clear ValuesOnGrid

if CreateFigures==1
    % take another a look at cdf over asset grid to make sure not hitting top of grid
    figure
    plot(a_grid,cumsum(sum(sum(sum(StationaryDist_init,4),3),2)))
    title('cdf of asset to make sure grid on assets seems okay (init eqm)')

    just10thasset=1:10:n_a;
    figure
    temp1=gather(workerORentrepreneur_init(just10thasset,:,1,1)); % heatmap only works with cpu
    heatmap(z_grid,a_grid(just10thasset),temp1)
    grid off
    title('Initial eqm, with tax: Who becomes entrepreneur')
end

%% Replicate Table 1 of BS2013

make_table(ResFolder,GE_cond,Outputs,Params);

%% Replicate Figure 2 of BS2013

if do_replication==1
%ii_bench    = 1;
lambda_vec = [inf,2.0,1.75,1.5,1.25,1.0]';
NN = length(lambda_vec);
do_GE = 1;

%Pre-allocate arrays or structures where you want to store the output
share_entre_vec = zeros(NN,1);
extfin_vec      = zeros(NN,1);
extfin_Y_vec    = zeros(NN,1);
Y_vec           = zeros(NN,1);
r_vec           = zeros(NN,1);
w_vec           = zeros(NN,1);
K_vec           = zeros(NN,1);
K_Y_vec         = zeros(NN,1);

for ii=1:length(lambda_vec)

    %Assign lambda:
    Params.lambda = lambda_vec(ii);

    disp('***************************************************************')
    fprintf('Doing experiment %d of %d \n',ii,length(lambda_vec));
    fprintf('lambda = %.3f \n',lambda_vec(ii));
    disp('***************************************************************')

    if ii==1
        Params.r = 0.0472;
        Params.w = 0.171;
    elseif ii>1
        Params.r = r_vec(ii-1) ;
        Params.w = w_vec(ii-1);
    end

    tic
    [Outputs] = BueraShin_Fn(do_GE,Params,n_d,n_a,n_z,pi_z,d_grid,a_grid,z_grid,ReturnFn,FnsToEvaluate,GeneralEqmEqns,DiscountFactorParamNames,GEPriceParamNames,heteroagentoptions,simoptions,vfoptions);
    toc

    %Aggregate quantities and prices
    share_entre_vec(ii) = Outputs.share_entre;
    extfin_vec(ii)      = Outputs.extfin;
    Y_vec(ii)           = Outputs.Y;
    r_vec(ii)           = Outputs.r;
    w_vec(ii)           = Outputs.w;
    K_vec(ii)           = Outputs.K;
    K_Y_vec(ii)         = Outputs.K_Y;
    extfin_Y_vec(ii)    = Outputs.extfin/Outputs.Y;

end

%Add "_norm" to denote change wrt benchmark
ii_bench    = 1;
Y_vec_norm  = zeros(NN,1);

for ii=1:NN
    Y_vec_norm(ii) = (Y_vec(ii)/Y_vec(ii_bench));
end

%% Plots for Figure 2 of the paper

ldw = 2;
fts = 14;

figure
plot(extfin_Y_vec,Y_vec_norm,'linewidth',ldw)
xlabel('External Finance to GDP','FontSize',fts)
ylabel('GDP relative to benchmark','FontSize',fts)
title('GDP and TFP','FontSize',fts)
print('fig2a_BS2013','-dpng')

figure
plot(extfin_Y_vec,r_vec,'linewidth',ldw)
xlabel('External Finance to GDP','FontSize',fts)
ylabel('Interest rate','FontSize',fts)
title('Interest Rate','FontSize',fts)
print(fullfile(ResFolder,'fig2b_BS2013'),'-dpng')

figure
subplot(1,2,1)
    plot(extfin_Y_vec,Y_vec_norm,'linewidth',ldw)
    xlabel('External Finance to GDP','FontSize',fts)
    ylabel('GDP relative to benchmark','FontSize',fts)
    title('GDP and TFP','FontSize',fts)
subplot(1,2,2)
    plot(extfin_Y_vec,r_vec,'linewidth',ldw)
    xlabel('External Finance to GDP','FontSize',fts)
    ylabel('Interest rate','FontSize',fts)
    title('Interest Rate','FontSize',fts)
print(fullfile(ResFolder,'fig2_BS2013'),'-dpng')

save (fullfile(ResFolder,"data_all.mat")) 

end %end if do_replication