function T=run_impedance_example(outDir)
%RUN_IMPEDANCE_EXAMPLE Illustrative reciprocal passive four-port circuit.
% Eq.7 algebra only. No CST-extracted impedances or physical RIS claim.
if ~isfolder(outDir),mkdir(outDir);end
N=4;Z0=50;Rload=5.2;
% Reciprocal positive-definite real part, with symmetric nearest-neighbor
% mutual reactance. Values are deliberately assumed, not fitted hardware.
A=diag(ones(N-1,1),1)+diag(ones(N-1,1),-1);
Zcoupled=50*eye(N)+5*A+1i*(20*eye(N)+12*A);
Zdiagonal=diag(diag(Zcoupled));
zST=exp(1i*(0:N-1)'*.8);zRS=exp(-1i*(0:N-1)*.35);
assert(norm(Zcoupled-Zcoupled.','fro')<1e-12);
assert(min(eig(real(Zcoupled)))>0,'ris:CircuitPassivity','Assumed circuit real part must be positive definite');
T=table();
for coupling=[false true]
 if coupling,Z=Zcoupled;else,Z=Zdiagonal;end
 matched=-zRS*((Z+Z0*eye(N))\zST);
 for X=-200:2:200
  H=-zRS*((Z+(Rload+1i*X)*eye(N))\zST);
  % Exact decomposition around matched loads, not an AF mirror-beam metric.
  controlled=-zRS*(((Z+(Rload+1i*X)*eye(N))\zST)-((Z+Z0*eye(N))\zST));
  assert(abs(H-matched-controlled)<1e-12);
  residual=norm((Z+(Rload+1i*X)*eye(N))*((Z+(Rload+1i*X)*eye(N))\zST)-zST);
  assert(residual<1e-12);
  row=table(coupling,X,real(H),imag(H),abs(H)^2,abs(matched)^2,abs(controlled)^2, ...
      'VariableNames',{'mutual_coupling','common_load_reactance_ohm','H_real','H_imag','H_power_arbitrary','matched_load_term_power','controlled_difference_power'});
  T=[T;row]; %#ok<AGROW>
 end
 % At matched loads Eq.11 is generally nonzero, although load Gamma is zero.
 assert(abs(matched)>1e-8);assert(abs((Z0-Z0)/(Z0+Z0))==0);
end
writetable(T,fullfile(outDir,'four_port_load_sweep.csv'));
f=figure('Visible','off','Color','w','Position',[100 100 950 480]);hold on;grid on;
for coupling=[false true]
 r=T(T.mutual_coupling==coupling,:);plot(r.common_load_reactance_ohm,r.H_power_arbitrary,'LineWidth',1.6,'DisplayName',sprintf('Mutual coupling = %d',coupling));
end
xlabel('Common load reactance X (ohm), fixed R = 5.2 ohm');ylabel('|H|^2 (arbitrary circuit units)');legend('Location','best');
title({'Assumed reciprocal four-port circuit, Eq. (7) algebra','Illustrative impedances; no CST extraction or finite-array validation'});
exportgraphics(f,fullfile(outDir,'four_port_load_sweep.png'),'Resolution',180);close(f);
m.generator='matlab/run_impedance_example.m';m.source_equations='Goshu et al., Eq.7 and matched-load Eq.11; y0=1, ZRT=0';
m.validation_status='PASS algebraic identities; PROVISIONAL illustrative scenario';
m.assumptions='Four-port reciprocal circuit; 50+j20 ohm self impedance; adjacent 5+j12 ohm mutual impedance; all loads share reactance. TX/RX coupling vectors are arbitrary. No physical antenna geometry is assigned.';
m.real_part_min_eigenvalue=min(eig(real(Zcoupled)));m.Z_real=real(Zcoupled);m.Z_imag=imag(Zcoupled);
m.note='The matched-load term can remain nonzero at load Gamma=0. It is a circuit illustration of Eq.11, not a measured structural-scattering level. Controlled and matched powers do not add without their interference term.';
m.code_sha256=ris_sha256(mfilename('fullpath')+".m");
fid=fopen(fullfile(outDir,'manifest.json'),'w');fwrite(fid,jsonencode(m,PrettyPrint=true));fclose(fid);
end
