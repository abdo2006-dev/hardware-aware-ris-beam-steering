function filename=convert_diagnostic_pair(root,mode)
%CONVERT_DIAGNOSTIC_PAIR Exact-frequency import of saved strict CST runs.
% Numerical adaptation is evidence; geometry/diode validity remains provisional.
assert(ismember(mode,[1 2]));names={'D009_ON_strict','D010_OFF_strict'};
out=fullfile(root,'data','cst_simulated_hardware');if ~isfolder(out),mkdir(out);end
T=table();sources=struct([]);
for state=0:1
 folder=fullfile(root,'cst','experiments',names{state+1});source=fullfile(folder,'complex_sparameters.csv');
 r=readtable(source);re=r.(sprintf('S%d_%d_real',mode,mode));im=r.(sprintf('S%d_%d_imag',mode,mode));
 assert(height(r)==1&&abs(r.frequency_GHz-26.168)<1e-9);
 assert(hypot(re,im)<=1.001);
 row=table(r.frequency_GHz,state,re,im,mode,string(names{state+1}),string(ris_sha256(source)),"PROVISIONAL", ...
  'VariableNames',{'frequency_GHz','state','real','imag','floquet_mode','checkpoint','source_sha256','validation_status'});
 T=[T;row]; %#ok<AGROW>
 sources(state+1).state=state;sources(state+1).file=source;sources(state+1).sha256=ris_sha256(source);
end
filename=fullfile(out,sprintf('strict_mode%d_26p168.csv',mode));writetable(T,filename);
m.dataset='cst_simulated_hardware';m.generator='matlab/convert_diagnostic_pair.m';m.validation_status='PROVISIONAL';
m.source=sources;m.floquet_mode=mode;m.co_polar_trace=sprintf('SZmax(%d),Zmax(%d)',mode,mode);
m.frequency_GHz=26.168;m.interpolation='Exact single-frequency data; no extrapolation';
m.scope='Both runs meet strict CST all-S adaptation criterion. Source geometry, diode calibration and Cartesian polarization require additional evidence; no full physical validation is implied.';
fid=fopen(strrep(filename,'.csv','_manifest.json'),'w');fwrite(fid,jsonencode(m,PrettyPrint=true));fclose(fid);
end
