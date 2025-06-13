function [Outputs,GE_cond,Policy,StationaryDist,AggVars,ValuesOnGrid] = BueraShin_Fn(do_GE,Params,n_d,n_a,n_z,pi_z,d_grid,a_grid,z_grid,ReturnFn,FnsToEvaluate,GeneralEqmEqns,DiscountFactorParamNames,GEPriceParamNames,heteroagentoptions,simoptions,vfoptions,ReturnFnParamNames)
% Note: The initial guesses for the equilibrium prices r and w are stored
% in Params.r and Params.w

if do_GE==1
    % When doing GE, better not to display intermediate output from VFI
    vfoptions.verbose=0;
end

if do_GE==1
    %% Compute GE
    [p_eqm,~,~]=HeteroAgentStationaryEqm_Case1(n_d, n_a, n_z, 0, pi_z, d_grid, a_grid, z_grid, ReturnFn, FnsToEvaluate, GeneralEqmEqns, Params, DiscountFactorParamNames,ReturnFnParamNames, [], [], GEPriceParamNames,heteroagentoptions, simoptions, vfoptions);

    %% Compute eqm objects
    Params.r=p_eqm.r;
    Params.w=p_eqm.w;
    [~,Policy]=ValueFnIter_Case1(n_d,n_a,n_z,d_grid,a_grid,z_grid,pi_z,ReturnFn,Params,DiscountFactorParamNames,ReturnFnParamNames,vfoptions);
    StationaryDist=StationaryDist_Case1(Policy,n_d,n_a,n_z,pi_z,simoptions);
    AggVars=EvalFnOnAgentDist_AggVars_Case1(StationaryDist, Policy, FnsToEvaluate, Params, [], n_d, n_a, n_z, d_grid, a_grid, z_grid, [], simoptions);
    ValuesOnGrid=EvalFnOnAgentDist_ValuesOnGrid_Case1(Policy, FnsToEvaluate, Params, [], n_d, n_a, n_z, d_grid, a_grid, z_grid, [], simoptions);
else
    [~,Policy]=ValueFnIter_Case1(n_d,n_a,n_z,d_grid,a_grid,z_grid,pi_z,ReturnFn,Params,DiscountFactorParamNames,ReturnFnParamNames,vfoptions);
    StationaryDist=StationaryDist_Case1(Policy,n_d,n_a,n_z,pi_z,simoptions);
    AggVars=EvalFnOnAgentDist_AggVars_Case1(StationaryDist, Policy, FnsToEvaluate, Params, [], n_d, n_a, n_z, d_grid, a_grid, z_grid, [], simoptions);
    ValuesOnGrid=EvalFnOnAgentDist_ValuesOnGrid_Case1(Policy, FnsToEvaluate, Params, [], n_d, n_a, n_z, d_grid, a_grid, z_grid, [], simoptions);
end

%% Compute GE conditions

% Excess demand capital market: capital demand minus capital supply
GE_cond(1) = AggVars.K.Mean-AggVars.A.Mean;
% Excess demand labor market: labor demand minus share of workers
GE_cond(2) = AggVars.L.Mean - (1-AggVars.entrepreneur.Mean);

%% Compute some model moments 

pol_e      = gather(ValuesOnGrid.entrepreneur); % dim: (a,z)
pol_aprime = gather(squeeze(Policy(1,:,:))); % dim: (a,z)

% Compute exit rate
[exit_E_to_W,entry_W_to_E] = fun_entry_exit(StationaryDist,pi_z,pol_e,pol_aprime,n_a,n_z);

% --- Targets using toolkit commands

% More Functions to Evaluate
FnsToEvaluate2 = FnsToEvaluate;
% Entrepreneurial output (zero if worker)
FnsToEvaluate2.Y=@(aprime,a,z,w,r,lambda,delta,alpha,upsilon) f_output(aprime,a,z,w,r,lambda,delta,alpha,upsilon); 
% Enternal finance (zero if worker)
FnsToEvaluate2.extfin=@(aprime,a,z,w,r,lambda,delta,alpha,upsilon) f_extfin(aprime,a,z,w,r,lambda,delta,alpha,upsilon); 
% Earnings 
FnsToEvaluate2.earnings=@(aprime,a,z,w,r,lambda,delta,alpha,upsilon) f_earnings(aprime,a,z,w,r,lambda,delta,alpha,upsilon); 
% Consumption
FnsToEvaluate2.C = @(aprime,a,z,w,r,lambda,delta,alpha,upsilon) f_Consumption(aprime,a,z,w,r,lambda,delta,alpha,upsilon);

% Restrictions for entre (some moments are conditional on entre=1)
simoptions.conditionalrestrictions.ENT = @(aprime,a,z,w,r,lambda,delta,alpha,upsilon) ...
    f_entrepreneur(aprime,a,z,w,r,lambda,delta,alpha,upsilon);
% Other options for AllStats
simoptions.whichstats=zeros(1,7);
simoptions.whichstats(1)=1; %mean
simoptions.whichstats(2)=1; %median
simoptions.whichstats(4)=1; %lorenz curve and gini

AllStats=EvalFnOnAgentDist_AllStats_Case1(StationaryDist,Policy,FnsToEvaluate2,...
    Params,[],n_d,n_a,n_z,d_grid,a_grid,z_grid,simoptions);

top5_earnings = 1-AllStats.earnings.LorenzCurve(95);
top10_empl    = 1-AllStats.ENT.L.LorenzCurve(90);

% Pack Aggregate quantities, GE prices and moments into a structure
Outputs.share_entre = AllStats.entrepreneur.Mean;
Outputs.extfin      = AllStats.extfin.Mean;
Outputs.Y           = AllStats.Y.Mean;
Outputs.C           = AllStats.C.Mean;
Outputs.L           = AllStats.L.Mean;
Outputs.r           = Params.r;
Outputs.w           = Params.w;
Outputs.K           = AllStats.K.Mean;
Outputs.K_Y         = Outputs.K/Outputs.Y;
Outputs.extfin_Y    = Outputs.extfin/Outputs.Y;
Outputs.exit_E_to_W   = exit_E_to_W;
Outputs.entry_W_to_E  = entry_W_to_E;
Outputs.top10_empl    = top10_empl;
Outputs.top5_earnings = top5_earnings;

Outputs.walras = Outputs.C+Params.delta*Outputs.K-Outputs.Y;

end %end function BueraShin_Fn