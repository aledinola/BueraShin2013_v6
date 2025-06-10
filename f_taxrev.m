function taxrev=f_taxrev(aprime,a,z,w,r,lambda,delta,alpha,upsilon,tau_k)
% Capital income taxes are imposed on interest income r*a and on business
% profit 

profit = solve_entre(a,z,w,r,lambda,delta,alpha,upsilon);

if w>profit
    taxrev=tau_k*r*a; % worker
else
    taxrev=tau_k*r*a+tau_k*profit; % entrepreneur
end

end %end function "f_taxrev"