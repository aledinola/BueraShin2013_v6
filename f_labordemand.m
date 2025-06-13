function labordemand=f_labordemand(aprime,a,z1,z2,w,r,lambda,delta,alpha,upsilon)

[profit,~,lstar] = solve_entre(a,z1,w,r,lambda,delta,alpha,upsilon);


if w*z2>profit
    labordemand=0; % worker
else
    labordemand=lstar; % entrepreneur
end

end %end function