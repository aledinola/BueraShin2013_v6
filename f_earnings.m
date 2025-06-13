function earnings=f_earnings(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon)

profit = solve_entre(a,z1,w,r,lambda,delta,alpha,upsilon);

% Earnings
earnings = max(w*z2,profit) + r*a;


end %end function