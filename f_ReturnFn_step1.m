function cash_on_hand=f_ReturnFn_step1(a,z,crra,w,r,lambda,delta,alpha,upsilon)
% First step of Return Matrix
% INPUTS 
% a: (n_a,1) vector, endogenous state
% z: (1,n_z) vector, exogenous state
% parameters...
% OUTPUTS
% cash_on_hand: (n_a,n_z) array


profit = solve_entre(a,z,w,r,lambda,delta,alpha,upsilon);

% Budget constraint
cash_on_hand = max(w,profit)+(1+r)*a;

end %end function