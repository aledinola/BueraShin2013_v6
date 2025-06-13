function capitaldemand=f_capitaldemand(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon)

[profit,kstar] = solve_entre(a,z1,w,r,lambda,delta,alpha,upsilon);

if w*z2>profit
    capitaldemand=0; % worker
else
    capitaldemand=kstar; % entrepreneur
end

end %end function