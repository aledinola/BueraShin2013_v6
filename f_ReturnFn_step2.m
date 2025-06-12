function F=f_ReturnFn_step2(aprime,cash_on_hand,crra)
% Second step of Return Matrix
% INPUTS 
% aprime:       (n_a,1)   vector, future endogenous state
% cash_on_hand: (1,n_a,n_z) array
% parameters...
% OUTPUTS
% F: (n_a,n_a,n_z) array

F=-Inf;

% Budget constraint
c = cash_on_hand-aprime;

if c>0
    F=(c^(1-crra))/(1-crra);
end

end %end function