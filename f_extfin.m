function extfin=f_extfin(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon)

[profit,kstar] = solve_entre(a,z1,w,r,lambda,delta,alpha,upsilon);


if w*z2>profit
    extfin=0; % worker
else
    extfin=max(0,kstar-a); % entrepreneur
end

end %end function