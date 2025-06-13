function output=f_output(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon)

[profit,kstar,lstar] = solve_entre(a,z1,w,r,lambda,delta,alpha,upsilon);

if w*z2>profit
    output=0; % worker
else
    output=z1*((kstar^alpha)*(lstar^(1-alpha)) )^(1-upsilon); % entrepreneur
end

end %end function