function results = ris_array_model(cstFile)
%RIS_ARRAY_MODEL Analytical 20x20 RIS array-factor comparison.
% This script models an independent-element array factor. It does not model
% mutual coupling, structural scattering or full-wave RCS.
% Usage: results = ris_array_model();
% Optional CST CSV columns: frequency_GHz,state,real,imag, with state 0 or 1.
% CST rows at 26.168 GHz are interpolated; absent file uses clearly labeled
% approximate manual digitization of Fig. 2 in the supplied paper.

if nargin < 1, cstFile = ''; end
rng(20261021,'twister');
outDir = fullfile(fileparts(mfilename('fullpath')),'..','results');
if ~isfolder(outDir), mkdir(outDir); end
c0 = 299792458; f0 = 26.168e9; lambda0 = c0/f0; pitch = 5.35e-3;
N = 20; target = [25 15]; incident = [0 0];
axisPos = ((0:N-1)-(N-1)/2)*pitch;
[X,Y] = meshgrid(axisPos,axisPos); xy = [X(:),Y(:)];
Ghw = [0.96*exp(1i*deg2rad(38)), 0.74*exp(1i*deg2rad(-156))];
provenance = "Approximate manual Fig. 2 digitization; not CST calibrated";
if strlength(cstFile)>0 && isfile(cstFile)
    T=readtable(cstFile);
    req=["frequency_GHz","state","real","imag"];
    assert(all(ismember(req,string(T.Properties.VariableNames))), 'CST CSV needs frequency_GHz,state,real,imag columns.');
    for s=0:1
        rows=T(T.state==s,:); assert(height(rows)>=2,'Need >=2 CST samples for each state.');
        Ghw(s+1)=interp1(rows.frequency_GHz*1e9,rows.real+1i*rows.imag,f0,'linear','extrap');
    end
    provenance="Complex CST export interpolated at 26.168 GHz";
end
k=2*pi*f0/c0; si=uv(incident(1),incident(2)); st=uv(target(1),target(2));
phiTarget=-k*(xy*(st-si).');
gammaContinuous=exp(1i*phiTarget);
gammaIdeal=exp(1i*pi*(cos(phiTarget)<0));
phaseDistance=abs(angle(exp(1i*(phiTarget(:)-angle(Ghw)))));
[~,stateIdx]=min(phaseDistance,[],2); gammaHardware=Ghw(stateIdx).';

theta=0:1:60; az=-60:1:60;
[P0,d0]=af(gammaContinuous,xy,theta,az,k,si,N,target);
[P1,d1]=af(gammaIdeal,xy,theta,az,k,si,N,target);
[P2,d2]=af(gammaHardware,xy,theta,az,k,si,N,target);
figure('Name','RIS normalized array-factor cut'); hold on; grid on;
it=find(theta==target(1),1);
plot(az,10*log10(max(P0(it,:)/max(P0(:)),1e-8)),'LineWidth',1.5);
plot(az,10*log10(max(P1(it,:)/max(P1(:)),1e-8)),'LineWidth',1.5);
plot(az,10*log10(max(P2(it,:)/max(P2(:)),1e-8)),'LineWidth',1.5);
xlabel('Azimuth phi (deg)'); ylabel('Normalized power (dB)');
legend('Ideal continuous','Ideal 1-bit','Hardware-aware 1-bit','Location','best');
title('Array-factor cut at theta = 25 deg'); ylim([-40 0]);
print(gcf,fullfile(outDir,'matlab_array_factor_cut.png'),'-dpng','-r300');

results=table(["Ideal continuous";"Ideal 1-bit";"Hardware-aware 1-bit"], ...
    [d0.pointError;d1.pointError;d2.pointError], ...
    [d0.gainDb;d1.gainDb;d2.gainDb], ...
    [d0.sideDb;d1.sideDb;d2.sideDb], ...
    'VariableNames',{'model','pointingError_deg','peakGain_dB_vs_ideal','maxSidelobe_dB'});
disp(results); fprintf('Hardware-state source: %s\n',provenance);
writetable(results,fullfile(outDir,'matlab_metrics.csv'));
fprintf('f0 %.3f GHz, pitch/lambda %.4f, array %dx%d\n',f0/1e9,pitch/lambda0,N,N);

% Controlled target-angle sweep. All results remain independent-element array factors.
targetGrid=[0 0;15 0;25 15;35 30;45 0;45 30];
targetRows=table();
for a=1:size(targetGrid,1)
    tar=targetGrid(a,:); st=uv(tar(1),tar(2)); ph=-k*(xy*(st-si).');
    gc=exp(1i*ph); gi=exp(1i*pi*(cos(ph)<0));
    pd=abs(angle(exp(1i*(ph(:)-angle(Ghw)))));
    [~,ix]=min(pd,[],2); gh=Ghw(ix).';
    [~,dc]=af(gc,xy,theta,az,k,si,N,tar);
    [~,di]=af(gi,xy,theta,az,k,si,N,tar);
    [~,dh]=af(gh,xy,theta,az,k,si,N,tar);
    targetRows=[targetRows; table(tar(1),tar(2),dc.pointError,di.pointError,dh.pointError, ...
        dc.gainDb,di.gainDb,dh.gainDb,'VariableNames', ...
        {'targetTheta_deg','targetPhi_deg','continuousError_deg','ideal1bitError_deg', ...
        'hardware1bitError_deg','continuousGain_dB','ideal1bitGain_dB','hardware1bitGain_dB'})]; %#ok<AGROW>
end
writetable(targetRows,fullfile(outDir,'target_angle_sweep_matlab.csv'));

% Two-dimensional direction maps, normalized separately to each model's peak.
fig2=figure('Name','RIS two-dimensional array-factor maps','Color','w');
patterns={P0,P1,P2}; labels={'Ideal continuous','Ideal 1-bit','Hardware-aware 1-bit'};
for q=1:3
    subplot(1,3,q);
    imagesc(az,theta,10*log10(max(patterns{q}/max(patterns{q}(:)),1e-4)));
    axis xy; caxis([-40 0]); colorbar; xlabel('Azimuth phi (deg)');
    if q==1, ylabel('Elevation theta (deg)'); end
    title(labels{q});
end
print(fig2,fullfile(outDir,'matlab_array_factor_2d.png'),'-dpng','-r300');

% Controlled uncertainty sweep; array-factor estimates only.
phaseSigma=[0 5 10 20]; ampSigma=[0 0.05 0.10]; trials=40;
rows=[];
for sp=phaseSigma
  for sa=ampSigma
    err=zeros(trials,1); gain=zeros(trials,1);
    for r=1:trials
      gr=gammaHardware.*max(0,1+sa*randn(N*N,1)).*exp(1i*deg2rad(sp)*randn(N*N,1));
      [pr,dr]=af(gr,xy,0:1:60,-60:1:60,k,si,N,target);
      err(r)=dr.pointError; gain(r)=dr.gainDb;
    end
    rows=[rows; table(sp,sa,mean(err),std(err),mean(gain),std(gain),trials)]; %#ok<AGROW>
  end
end
rows.Properties.VariableNames={'phaseSigma_deg','amplitudeSigma_fraction','meanPointError_deg','stdPointError_deg','meanGain_dB','stdGain_dB','trials'};
writetable(rows,fullfile(outDir,'uncertainty_sensitivity_matlab.csv'));
save(fullfile(outDir,'matlab_results.mat'),'results','targetRows','rows');
end

function v=uv(t,p)
t=deg2rad(t);p=deg2rad(p);v=[sin(t)*cos(p),sin(t)*sin(p)];
end

function [P,d]=af(g,xy,theta,az,k,si,N,target)
% Use ndgrid for theta rows and azimuth columns.
[T,Phi]=ndgrid(deg2rad(theta),deg2rad(az));
dirs=[sin(T(:)).*cos(Phi(:)),sin(T(:)).*sin(Phi(:))];
z=exp(1i*k*((dirs-si)*xy.'))*g(:); P=reshape(abs(z).^2,numel(theta),numel(az));
[~,ix]=max(P(:)); [it,ip]=ind2sub(size(P),ix); peak=[theta(it),az(ip)];
[~,it0]=min(abs(theta-target(1)));[~,ip0]=min(abs(az-target(2)));
dtheta=deg2rad(peak(1)); dtar=deg2rad(target(1));
dphi=deg2rad(peak(2)-target(2));
dotPeak=sin(dtheta)*sin(dtar)*cos(dphi)+cos(dtheta)*cos(dtar);
d.pointError=acosd(max(-1,min(1,dotPeak)));
d.gainDb=10*log10(max(P(it0,ip0)/(N*N)^2,1e-12));
[T,Phi]=ndgrid(deg2rad(theta),deg2rad(az));
dtar=deg2rad(target(1)); ptar=deg2rad(target(2));
dotGrid=sin(T).*sin(dtar).*cos(Phi-ptar)+cos(T).*cos(dtar);
mask=acosd(max(-1,min(1,dotGrid)))>15; Q=P/max(P(:)); d.sideDb=10*log10(max(Q(mask),[],'all'));
end

