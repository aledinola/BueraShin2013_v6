function F=f_ReturnFn(aprime,a,z1,z2,crra,w,r,lambda,delta,alpha,upsilon)

F=-Inf;

profit = solve_entre(a,z1,w,r,lambda,delta,alpha,upsilon);

% Budget constraint
c=max(w*z2,profit)+(1+r)*a-aprime;

if c>0
    F=(c^(1-crra))/(1-crra);
end

end %end function