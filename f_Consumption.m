function c=f_Consumption(aprime,a,z,w,r,lambda,delta,alpha,upsilon)

profit = solve_entre(a,z,w,r,lambda,delta,alpha,upsilon);

% Budget constraint
c=max(w,profit)+(1+r)*a-aprime;

end %end function