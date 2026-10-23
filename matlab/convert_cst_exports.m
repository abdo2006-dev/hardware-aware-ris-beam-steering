function manifest=convert_cst_exports(root,outDir,mode,polarization,status)
%CONVERT_CST_EXPORTS Explicit legacy modal-to-state mapping; no wrapped-phase interpolation.
% A mode label is not a verified physical polarization. Supply that separately.
assert(ismember(mode,[1 2]));assert(any(strcmp(status,{'PROVISIONAL','PASS'})));
assert(~isempty(polarization));
if strcmp(status,'PASS'),error('ris:EvidenceGate','These historical checkpoints have not passed the physical audit. PASS is forbidden.');end
names={'cst_baseline_complex_sparameters.csv','cst_off_assumed_25fF_complex_sparameters.csv'};
checkpoints={'baseline_on_proxy.cst','off_assumed_25fF.cst'};
if mode==1,cr='S11_real';ci='S11_imag';trace='SZmax(1),Zmax(1)';else,cr='S22_real';ci='S22_imag';trace='SZmax(2),Zmax(2)';end
tables=cell(1,2);hashes=cell(1,2);
for s=1:2
    file=fullfile(root,'results',names{s});T=readtable(file);
    assert(all(ismember({'frequency_GHz',cr,ci},T.Properties.VariableNames)),'ris:RawColumns','Unexpected raw CST schema.');
    f=T.frequency_GHz;z=T.(cr)+1i*T.(ci);
    assert(all(isfinite(f))&&all(diff(f)>0)&&all(isfinite(z)),'ris:RawGrid','Raw CST samples must be finite and strictly increasing.');
    assert(all(abs(z)<=1.001),'ris:ImportPassivity','Historical co-mode reflection fails passive magnitude screen.');
    tables{s}=T;hashes{s}=ris_sha256(file);
end
lo=max(cellfun(@(t)min(t.frequency_GHz),tables));hi=min(cellfun(@(t)max(t.frequency_GHz),tables));
f=unique([tables{1}.frequency_GHz;tables{2}.frequency_GHz;26.168]);f=f(f>=lo&f<=hi);
allRows=table();
for s=1:2
    T=tables{s};z=interp1(T.frequency_GHz,T.(cr)+1i*T.(ci),f,'linear');n=numel(f);
    rows=table(f,repmat(s-1,n,1),real(z),imag(z),repmat(string(names{s}),n,1), ...
        repmat(string(hashes{s}),n,1),repmat(string(checkpoints{s}),n,1),repmat(mode,n,1), ...
        repmat(string(polarization),n,1),repmat(string(status),n,1), ...
        'VariableNames',{'frequency_GHz','state','real','imag','source_file','source_sha256','checkpoint','floquet_mode','polarization','validation_status'});
    allRows=[allRows;rows]; %#ok<AGROW>
end
if ~isfolder(outDir),mkdir(outDir);end
writetable(allRows,fullfile(outDir,'reflection_states.csv'));
manifest.dataset='cst_simulated_hardware';manifest.validation_status=status;
manifest.source_files=names;manifest.source_sha256=hashes;manifest.checkpoints=checkpoints;
manifest.mode=mode;manifest.polarization=polarization;manifest.cst_trace=trace;
manifest.interpolation='Linear interpolation of real and imaginary coefficients; no extrapolation';
manifest.frequency_grid_GHz=[lo hi];manifest.rows_per_state=numel(f);
manifest.generator='matlab/convert_cst_exports.m';manifest.generator_sha256=ris_sha256(mfilename('fullpath')+".m");
manifest.note='Existing proxies; co-mode identity only. Physical polarization, connectivity, circuit validity and mesh convergence remain unverified. The 1001 raw sweep points are interpolated from 8 calculated adaptive samples.';
fid=fopen(fullfile(outDir,'manifest.json'),'w');fwrite(fid,jsonencode(manifest,PrettyPrint=true));fclose(fid);
end
