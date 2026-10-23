function results=ris_array_model(cstFile,outDir,doSweeps)
%RIS_ARRAY_MODEL Repaired analytical 20x20 model retaining the original phase formula.
% Use run_research() to run the correctness gate and regenerate both datasets.
root=fileparts(fileparts(mfilename('fullpath')));a=ris_core();c=a.config();
if nargin<1||strlength(cstFile)==0,cstFile=fullfile(root,'data','paper_digitized_reference','reflection_states.csv');end
if nargin<2,outDir=fullfile(root,'results','validated_v1','paper_digitized_reference');end
if nargin<3,doSweeps=true;end
if ~isfolder(outDir),mkdir(outDir);end
input=readtable(cstFile,'TextType','string');
if ismember('validation_status',input.Properties.VariableNames),status=char(input.validation_status(1));else,status='PROVISIONAL';end
if contains(cstFile,'paper_digitized_reference'),dataset='paper_digitized_reference';else,dataset='cst_simulated_hardware';end
S=a.load_states(cstFile,c.frequency_Hz/1e9);ph=a.desired_phase(c);op=a.operator(c);
names={'ideal_continuous','ideal_binary_fixed_reference','hardware_fixed_reference','ideal_binary_optimized_reference','hardware_optimized_reference'};
methods={'continuous','nearest_phase','nearest_phase','optimized_reference','optimized_reference'};
stateSets={1,[1 -1],S,[1 -1],S};G=zeros(c.N^2,5);alpha=zeros(1,5);
for j=1:5,[G(:,j),~,alpha(j)]=a.weights(ph,stateSets{j},methods{j},c.reference_grid_deg);a.check(G(:,j),400);end
P=zeros(size(op.E,1),5);for j=1:5,P(:,j)=abs(op.E*G(:,j)).^2;end
results=table();
for j=1:5
 m=a.metrics(G(:,j),c,op,P(:,j));cut=a.cut(G(:,j),c);
 m.principal_cut_secondary_lobe_dB_vs_target_lobe=cut.max_secondary_cut_lobe_dB_vs_target_lobe;
 m.cut_first_minimum_left_deg=cut.first_minimum_left_deg;m.cut_first_minimum_right_deg=cut.first_minimum_right_deg;
 m.common_reference_deg=alpha(j);m.dataset=string(dataset);m.validation_status=string(status);m.model=string(names{j});
 results=[results;struct2table(m)]; %#ok<AGROW>
end
writetable(results,fullfile(outDir,'array_factor_metrics.csv'));
wide=table(op.theta,op.phi,'VariableNames',{'polar_theta_deg','azimuth_phi_deg'});
for j=1:5,wide.(names{j})=P(:,j)/c.N^4;end
writetable(wide,fullfile(outDir,'array_factor_grid.csv'));
cutRows=table();
for j=1:5
 cut=a.cut(G(:,j),c);r=table(cut.psi_deg,cut.power/c.N^4,repmat(string(names{j}),numel(cut.psi_deg),1), ...
 'VariableNames',{'signed_polar_cut_deg','power_vs_ideal_N2','model'});cutRows=[cutRows;r]; %#ok<AGROW>
end
writetable(cutRows,fullfile(outDir,'principal_cut.csv'));
make_figures(outDir,dataset,status,c,op,P,names,results,cutRows);
if doSweeps
 rng(c.seed,'twister');unc=table();base=a.metrics(G(:,3),c,op);zeroMax=0;
 fields={'target_gain_dB_vs_ideal_N2','refined_peak_gain_dB_vs_ideal_N2','pointing_error_deg','max_outside_target_cone_dB_vs_peak','hemisphere_pattern_integral_fraction_outside_cone'};
 for sp=[0 5 10 20]
  for sa=[0 .05 .10]
   coeff=zeros(c.N^2,c.trials);
   for t=1:c.trials,coeff(:,t)=a.perturb(G(:,3),sa,sp);a.check(coeff(:,t),400);end
   if sp==0&&sa==0
    % Use exactly the same deterministic vector evaluator for the identity case.
    pow=repmat(abs(op.E*G(:,3)).^2,1,c.trials);
   else,pow=abs(op.E*coeff).^2;end
   v=zeros(c.trials,numel(fields));
   for t=1:c.trials
    mt=a.metrics(coeff(:,t),c,op,pow(:,t));
    for k=1:numel(fields),v(t,k)=mt.(fields{k});end
   end
   for k=1:numel(fields)
    if sa==0&&sp==0,delta=max(abs(v(:,k)-base.(fields{k})));zeroMax=max(zeroMax,delta);assert(delta<1e-7,'ris:ZeroNoise','Zero-perturbation result differs from deterministic baseline.');end
    sd=std(v(:,k));se=sd/sqrt(c.trials);mu=mean(v(:,k));pct=prctile(v(:,k),[5 95]);
    row=table(sp,sa,string(fields{k}),mu,sd,se,mu-1.96*se,mu+1.96*se,pct(1),pct(2),c.trials,c.seed, ...
      'VariableNames',{'phase_sigma_deg','amplitude_sigma_fraction','metric','mean','std','standard_error_mean','normal_approx_mean_CI95_low','normal_approx_mean_CI95_high','empirical_p05','empirical_p95','trials','seed'});
    unc=[unc;row]; %#ok<AGROW>
   end
  end
 end
 writetable(unc,fullfile(outDir,'uncertainty_sensitivity.csv'));
 sweep=table();targets=[0 0;15 0;25 15;35 30;45 0;45 30];
 for t=1:size(targets,1)
  ct=c;ct.target_deg=targets(t,:);pt=a.desired_phase(ct);
  for j=1:5
   gg=a.weights(pt,stateSets{j},methods{j},c.reference_grid_deg);m=a.metrics(gg,ct,op);
   m.model=string(names{j});sweep=[sweep;struct2table(m)]; %#ok<AGROW>
  end
 end
 writetable(sweep,fullfile(outDir,'target_angle_sweep.csv'));
 sep=table();amp=table();
 for s=140:10:220
  ss=[.96*exp(1i*deg2rad(38)),.74*exp(1i*deg2rad(38+s))];
  for method={'nearest_phase','optimized_reference'}
   gg=a.weights(ph,ss,method{1},c.reference_grid_deg);m=a.metrics(gg,c,op);m.phase_separation_deg=s;m.assignment=string(method{1});sep=[sep;struct2table(m)]; %#ok<AGROW>
  end
 end
 for mag=.5:.1:1
  for method={'nearest_phase','optimized_reference'}
   gg=a.weights(ph,[1 -mag],method{1},c.reference_grid_deg);m=a.metrics(gg,c,op);m.state1_magnitude=mag;m.assignment=string(method{1});amp=[amp;struct2table(m)]; %#ok<AGROW>
  end
 end
 writetable(sep,fullfile(outDir,'phase_separation_sensitivity.csv'));writetable(amp,fullfile(outDir,'amplitude_imbalance_sensitivity.csv'));
 fig=figure('Visible','off','Color','w','Position',[100 100 1150 430]);
 subplot(1,2,1);hold on;grid on;
 for method={'nearest_phase','optimized_reference'},r=sep(sep.assignment==method{1},:);plot(r.phase_separation_deg,r.target_gain_dB_vs_ideal_N2,'-o','DisplayName',method{1});end
 xlabel('State phase separation (deg)');ylabel('Target power / ideal N^2 (dB)');legend('Interpreter','none','Location','best');
 subplot(1,2,2);hold on;grid on;
 for method={'nearest_phase','optimized_reference'},r=amp(amp.assignment==method{1},:);plot(r.state1_magnitude,r.target_gain_dB_vs_ideal_N2,'-o','DisplayName',method{1});end
 xlabel('State 1 magnitude (state 0 = 1)');ylabel('Target power / ideal N^2 (dB)');
 sgtitle(sprintf('Assumed state sweeps | %s | 26.168 GHz | 20x20',dataset),'Interpreter','none');
 exportgraphics(fig,fullfile(outDir,'controlled_state_sweeps.png'),'Resolution',180);close(fig);
 fprintf('Zero-noise maximum metric difference: %.16g\n',zeroMax);
else,zeroMax=NaN;end
manifest.dataset=dataset;manifest.validation_status=status;manifest.source_file=char(cstFile);
manifest.source_sha256=ris_sha256(cstFile);manifest.generator='matlab/ris_array_model.m';
manifest.config=c;manifest.state_magnitude=abs(S);manifest.state_phase_deg=rad2deg(angle(S));
manifest.normalization='Every main pattern is |AF|^2 / 400^2, referenced to ideal continuous coherent power. No element pattern, coupling, radiation efficiency or RCS is modeled.';
manifest.coordinate_system='Array plane XY; polar theta from +Z; azimuth phi about +Z from +X toward +Y. Canonical phi=0 at broadside.';
manifest.peak_method='Full forward hemisphere sampled search; four separated candidate lobes and the target seed local tangential-direction fminsearch. Refined numerical maximum is not a rigorous global-optimum certificate.';
manifest.outside_metric='Maximum sampled power outside a 15-degree spherical target cone; includes mirror beams and other competing main lobes. It is not automatically a conventional sidelobe level.';
manifest.integral='Forward-hemisphere scalar array-factor pattern integral using sin(theta) dtheta dphi. This is not measured power or radiation efficiency.';
manifest.uncertainty='Independent normal phase errors; multiplicative normal magnitude errors clipped to [0,1]. 40 trials/settings, fixed seed. Empirical percentiles and approximate normal mean confidence intervals; no claim of fabrication-calibrated distributions.';
manifest.zero_noise_max_metric_difference=zeroMax;
[~,head]=system('git rev-parse HEAD');manifest.parent_code_commit=strtrim(head);
files=dir(fullfile(fileparts(mfilename('fullpath')),'*.m'));manifest.code=struct();
for j=1:numel(files),manifest.code.(matlab.lang.makeValidName(files(j).name))=ris_sha256(fullfile(files(j).folder,files(j).name));end
manifest.outputs=struct();f=dir(outDir);
for j=1:numel(f),if ~f(j).isdir&&~strcmp(f(j).name,'manifest.json'),manifest.outputs.(matlab.lang.makeValidName(f(j).name))=ris_sha256(fullfile(outDir,f(j).name));end,end
fid=fopen(fullfile(outDir,'manifest.json'),'w');fwrite(fid,jsonencode(manifest,PrettyPrint=true));fclose(fid);
back=readtable(fullfile(outDir,'array_factor_metrics.csv'),'TextType','string');
for j=1:width(results)
 n=results.Properties.VariableNames{j};if isnumeric(results.(n)),assert(all(abs(back.(n)-results.(n))<1e-10|isnan(back.(n))&isnan(results.(n))),'ris:ExportMismatch','Metric CSV does not match computed values.');end
end
disp(results(:,{'model','target_gain_dB_vs_ideal_N2','refined_peak_gain_dB_vs_ideal_N2','pointing_error_deg','max_outside_target_cone_dB_vs_peak'}));
end

function make_figures(out,dataset,status,c,op,P,names,summary,cutRows)
colors=lines(5);fig=figure('Visible','off','Color','w','Position',[100 100 1200 550]);hold on;grid on;
for j=1:5,r=cutRows(cutRows.model==names{j},:);plot(r.signed_polar_cut_deg,10*log10(max(r.power_vs_ideal_N2,1e-10)),'LineWidth',1.5,'Color',colors(j,:),'DisplayName',names{j});end
xlabel('Signed polar cut angle (deg; negative side uses opposite azimuth)');ylabel('Array-factor power / ideal N^2 (dB)');ylim([-45 1]);xlim([-90 90]);legend('Interpreter','none','Location','southoutside','NumColumns',2);
title(sprintf('%s (%s) | %.3f GHz | 20x20 | target polar 25, azimuth 15 deg',dataset,status,c.frequency_Hz/1e9),'Interpreter','none');
exportgraphics(fig,fullfile(out,'principal_cut_ideal_reference.png'),'Resolution',180);close(fig);
fig=figure('Visible','off','Color','w','Position',[100 100 1450 560]);
for j=1:3,subplot(1,3,j);imagesc(c.azimuth_deg,c.polar_deg,reshape(10*log10(max(P(:,j)/c.N^4,1e-4)),op.shape));axis xy;caxis([-40 0]);colorbar;xlabel('Azimuth phi (deg)');ylabel('Polar theta from +Z (deg)');title(names{j},'Interpreter','none');end
sgtitle(sprintf('%s (%s) | 26.168 GHz | common ideal N^2 reference',dataset,status),'Interpreter','none');
exportgraphics(fig,fullfile(out,'hemisphere_common_reference.png'),'Resolution',180);close(fig);
fig=figure('Visible','off','Color','w','Position',[100 100 1050 500]);bar([summary.target_gain_dB_vs_ideal_N2,summary.refined_peak_gain_dB_vs_ideal_N2]);grid on;
xticks(1:5);xticklabels(names);xtickangle(15);set(gca,'TickLabelInterpreter','none');ylabel('Power / ideal N^2 (dB)');legend('Requested target','Refined peak','Location','southoutside');
title(sprintf('%s (%s) | target versus strongest lobe',dataset,status),'Interpreter','none');
exportgraphics(fig,fullfile(out,'target_and_peak_gain.png'),'Resolution',180);close(fig);
end
