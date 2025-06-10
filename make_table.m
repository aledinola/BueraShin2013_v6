function [] = make_table(ResFolder,GE_cond,Outputs,Params)

fid=fopen(fullfile(ResFolder,'targets_model_manual.txt'),'wt');  % overwrite

fprintf(fid,"MODEL PARAMETERS \n");
fprintf(fid,"beta         = %f \n",Params.beta);
fprintf(fid,"eta          = %f \n",Params.eta);
fprintf(fid,"psi          = %f \n",Params.psi);
fprintf(fid,"span_control = %f \n",1-Params.upsilon);
fprintf(fid,"alpha        = %f \n",Params.alpha);
fprintf(fid,"delta        = %f \n",Params.delta);
fprintf(fid,"lambda       = %f \n",Params.lambda);

fprintf(fid,"TARGETED MOMENTS \n");
fprintf(fid,"Top 10 Employment = %f \n",Outputs.top10_empl);
fprintf(fid,"Top 5 Earnings    = %f \n",Outputs.top5_earnings);
fprintf(fid,"Entre exit rate   = %f \n",Outputs.exit_E_to_W);
fprintf(fid,"Interest rate     = %f \n",Outputs.r);
fprintf(fid,"GE cond 1   = %f \n",GE_cond(1));
fprintf(fid,"GE cond 2   = %f \n",GE_cond(2));

fprintf(fid,"OTHER MOMENTS \n");
fprintf(fid,"Share of entre    = %f \n",Outputs.share_entre);
fprintf(fid,"K/Y ratio         = %f \n",Outputs.K_Y);
fprintf(fid,"ExtFin/Y ratio    = %f \n",Outputs.extfin_Y);
fprintf(fid,"K    = %f \n",Outputs.K);
fprintf(fid,"L    = %f \n",Outputs.L);
fprintf(fid,"Y    = %f \n",Outputs.Y);
fprintf(fid,"C    = %f \n",Outputs.C);
fprintf(fid,"w    = %f \n",Outputs.w);
fclose(fid);

fprintf('File %s written to %s \n','targets_model_manual.txt',ResFolder)

end %end function
