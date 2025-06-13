function c=f_Consumption(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon)

profit = solve_entre(a,z1,w,r,lambda,delta,alpha,upsilon);

% Budget constraint
c=max(w*z2,profit)+(1+r)*a-aprime;

end %end function