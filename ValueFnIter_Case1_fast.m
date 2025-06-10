function [VKron,Policy]=ValueFnIter_Case1_fast(n_d,n_a,n_z,d_grid,a_grid,z_grid, pi_z, ReturnFn, Parameters, DiscountFactorParamNames, XXX, vfoptions)

ReturnFnParamNames = {'crra','w','r','lambda','delta','alpha','upsilon'};

ParamCell=cell(numel(ReturnFnParamNames),1);
ReturnFnParamsVec=zeros(numel(ReturnFnParamNames),1);
for ii=1:numel(ReturnFnParamNames)
    name = ReturnFnParamNames{ii};
    ParamCell(ii,1)={Parameters.(name)};
    ReturnFnParamsVec(ii,1) = Parameters.(name);
end

% crra = Parameters.crra;
% w = Parameters.w;
% r = Parameters.r;
% lambda = Parameters.lambda;
% delta = Parameters.delta;
% alpha = Parameters.alpha;
% upsilon = Parameters.upsilon;

disp('Creating return fn matrix')

a_grid = gpuArray(a_grid);
z_grid = gpuArray(z_grid);

aprime1vals = a_grid;              %(a',1,1)
a1vals      = shiftdim(a_grid,-1); %(1,a,1)
z1vals      = shiftdim(z_grid,-2); %(1,1,z)

tic
if vfoptions.separableF==1
    % Cash is (1,a,z)
    cash_on_hand=arrayfun(@(a,z,crra,w,r,lambda,delta,alpha,upsilon) f_ReturnFn_step1(a,z,crra,w,r,lambda,delta,alpha,upsilon), a1vals, z1vals, ParamCell{:});
    % ReturnMatrix is (a',a,z)
    ReturnMatrix=arrayfun(@(aprime,cash_on_hand,crra,w,r,lambda,delta,alpha,upsilon) f_ReturnFn_step2(aprime,cash_on_hand,crra,w,r,lambda,delta,alpha,upsilon), aprime1vals, cash_on_hand, ParamCell{:});
else
    ReturnMatrix=CreateReturnFnMatrix_Case1_Disc_Par2(ReturnFn, n_d, n_a, n_z, d_grid, a_grid, z_grid, ReturnFnParamsVec); 
end
toc

%% VFI

N_z = n_z;
N_a = n_a;
DiscountFactorParamsVec = Parameters.(DiscountFactorParamNames{1});
Tolerance = vfoptions.tolerance;
Howards = vfoptions.howards;
Howards2 = vfoptions.maxhowards;
VKron = zeros(N_a,N_z,'gpuArray');

bbb=reshape(shiftdim(pi_z,-1),[1,N_z*N_z]);
ccc=kron(ones(N_a,1,'gpuArray'),bbb);
aaa=reshape(ccc,[N_a*N_z,N_z]);

addindexforaz=N_a*(0:1:N_a-1)'+N_a*N_a*(0:1:N_z-1);

%%
tempcounter=1;
currdist=Inf;
while currdist>Tolerance

    VKronold=VKron;

    %Calc the condl expectation term (except beta), which depends on z but not on control variables
    EV=VKronold.*shiftdim(pi_z',-1); %kron(ones(N_a,1),pi_z(z_c,:));
    EV(isnan(EV))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
    EV=sum(EV,2); % sum over z', leaving a singular second dimension

    entireRHS=ReturnMatrix+DiscountFactorParamsVec*EV; %aprime by a by z

    %Calc the max and it's index
    [VKron,PolicyIndexes]=max(entireRHS,[],1);

    tempmaxindex=shiftdim(PolicyIndexes,1)+addindexforaz; % aprime index, add the index for a and z

    Ftemp=reshape(ReturnMatrix(tempmaxindex),[N_a,N_z]); % keep return function of optimal policy for using in Howards

    PolicyIndexes=PolicyIndexes(:); % a by z (this shape is just convenient for Howards)
    VKron=shiftdim(VKron,1); % a by z

    VKrondist=VKron(:)-VKronold(:); 
    VKrondist(isnan(VKrondist))=0;
    currdist=max(abs(VKrondist));
    
    % Use Howards Policy Fn Iteration Improvement (except for first few and last few iterations, as it is not a good idea there)
    if isfinite(currdist) && currdist/Tolerance>10 && tempcounter<Howards2 
        for Howards_counter=1:Howards
            EVKrontemp=VKron(PolicyIndexes,:);
            EVKrontemp=EVKrontemp.*aaa;
            EVKrontemp(isnan(EVKrontemp))=0;
            EVKrontemp=reshape(sum(EVKrontemp,2),[N_a,N_z]);
            VKron=Ftemp+DiscountFactorParamsVec*EVKrontemp;
        end
    end

    tempcounter=tempcounter+1;

end %end while
  
Policy=reshape(PolicyIndexes,[N_a,N_z]);
Policy = shiftdim(Policy,-1);

end %end function ValueFnIter_Case1_cpu