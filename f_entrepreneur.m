function entrepreneur=f_entrepreneur(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon)

profit = solve_entre(a,z1,w,r,lambda,delta,alpha,upsilon);

if w*z2>profit
    entrepreneur=0;
else
    entrepreneur=1;
end

end %end function