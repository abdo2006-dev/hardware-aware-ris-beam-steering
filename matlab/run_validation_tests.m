function report=run_validation_tests(outDir)
%RUN_VALIDATION_TESTS Toolbox-independent assertions with machine-readable evidence.
a=ris_core();tests={};values=struct();
record('400 coefficient invariant and original MATLAB indexing',@shape_test);
record('Independent rectangular-array phase alignment',@alignment_test);
record('Binary quantization and 180 degree unit-state equivalence',@binary_test);
record('Complex hardware assignment retains magnitudes and phases',@assignment_test);
record('Uniform phase, unity amplitude, broadside and azimuth degeneracy',@broadside_test);
record('Off-axis steering and incident phase compensation',@offaxis_test);
record('Exact zero-perturbation coefficient and metric reproduction',@zero_test);
record('Common-reference optimization uses fair objective and does not degrade target',@reference_test);
record('Full-hemisphere scan detects binary mirror lobe',@mirror_test);
record('Distinct target and global-peak metrics',@gain_test);
record('Solid-angle quadrature for constant hemisphere pattern',@quadrature_test);
record('Complex interpolation across phase wrap, exact frequency and zero offset',@import_test);
record('Passive input screening and forbidden extrapolation',@invalid_import_test);
record('Equation 1 phase optimum versus printed Equation 6',@channel_test);
record('Historical target-gain regression under corrected metric names',@regression_test);
report.tests=vertcat(tests{:});report.passed=all([report.tests.passed]);
report.MATLAB=version;report.numeric_evidence=values;report.generated_UTC=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd HH:mm:ss'));
if ~isfolder(outDir),mkdir(outDir);end
fid=fopen(fullfile(outDir,'tests.json'),'w');fwrite(fid,jsonencode(report,PrettyPrint=true));fclose(fid);
disp(struct2table(report.tests));assert(report.passed,'ris:TestsFailed','Research generation is gated by failing tests.');

function record(name,fn)
 t.name=name;t.passed=false;t.error='';
 try,fn();t.passed=true;catch e,t.error=getReport(e,'extended','hyperlinks','off');end
 tests{end+1}=t;
end
function c=small()
 c=a.config();c.N=4;c.polar_deg=0:2:90;c.azimuth_deg=-180:2:178;
end
function shape_test()
 c=a.config();ph=a.desired_phase(c);S=[.96*exp(1i*.2),.74*exp(-1i*2)];
 [~,ix]=min(abs(angle(exp(1i*(ph-angle(S))))),[],2);original=S(ix).';
 assert(isequal(size(original),[400 1]));values.original_MATLAB_coefficient_shape=size(original);
 for stateTable={S,S.'}
  g=a.weights(ph,stateTable{1},'nearest_phase');a.check(g,400);
  rng(9);g=a.perturb(g,.05,5);a.check(g,400);
 end
 rejected=false;try,a.check(ones(400,400),400);catch,rejected=true;end;assert(rejected);
end
function alignment_test()
 c=small();xy=a.coordinates(c);ph=a.desired_phase(c);g=exp(1i*ph);st=a.direction(25,15);si=a.direction(0,0);k=2*pi*c.frequency_Hz/c.c0;
 field=0;for j=1:size(xy,1),field=field+g(j)*exp(1i*k*dot(xy(j,:),st(1:2)-si(1:2)));end
 assert(abs(field-c.N^2)<1e-11);
 % Uniform rectangular array has a separable finite geometric series.
 q=[.21 -.13];positions=((0:c.N-1)-(c.N-1)/2)*c.pitch_m;
 sep=sum(exp(1i*k*positions*q(1)))*sum(exp(1i*k*positions*q(2)));
 direct=sum(exp(1i*k*(xy*q.')));assert(abs(sep-direct)<1e-11);
end
function binary_test()
 ph=[0;.2;2;-2;pi];g=a.weights(ph,[1 -1],'nearest_phase');
 expected=exp(1i*pi*(cos(ph)<0));assert(max(abs(g-expected))<1e-14);
 g2=a.weights(ph,[exp(1i*0),exp(1i*pi)],'nearest_phase');assert(max(abs(g-g2))<1e-14);
 assert(all(abs(angle(g.*exp(-1i*ph)))<=pi/2+1e-12));
end
function assignment_test()
 ph=linspace(-pi,pi,400).';S=[.96*exp(1i*.3),.74*exp(-1i*2.7)];[g,ix]=a.weights(ph,S,'nearest_phase');
 for j=1:400,[~,k]=min([abs(angle(exp(1i*(ph(j)-angle(S(1)))))),abs(angle(exp(1i*(ph(j)-angle(S(2))))))]);assert(ix(j)==k&&abs(g(j)-S(k))<1e-14);end
end
function broadside_test()
 c=small();c.target_deg=[0 137];op=a.operator(c);g=ones(c.N^2,1);m=a.metrics(g,c,op);
 assert(abs(m.target_gain_dB_vs_ideal_N2)<1e-12&&m.pointing_error_deg<1e-5&&m.peak_azimuth_deg==0);
 assert(m.equivalent_global_peak_directions==1);assert(abs(m.refined_peak_gain_dB_vs_ideal_N2)<1e-8);
end
function offaxis_test()
 c=small();c.target_deg=[26 16];c.incident_deg=[10 -20];op=a.operator(c);g=exp(1i*a.desired_phase(c));m=a.metrics(g,c,op);
 assert(abs(m.target_gain_dB_vs_ideal_N2)<1e-12&&m.pointing_error_deg<1e-4);
end
function zero_test()
 c=small();c.target_deg=[26 16];op=a.operator(c);g=a.weights(a.desired_phase(c),[.96*exp(1i*.66),.74*exp(-1i*2.72)],'nearest_phase');
 base=a.metrics(g,c,op);z=a.perturb(g,0,0);assert(isequal(g,z));b=a.metrics(z,c,op);assert(isequaln(base,b));
 values.zero_noise_max_metric_difference=0;
end
function reference_test()
 c=a.config();ph=a.desired_phase(c);
 for S={[1 -1],[.96*exp(1i*.66),.74*exp(-1i*2.72)]}
  g=a.weights(ph,S{1},'nearest_phase');h=a.weights(ph,S{1},'optimized_reference',c.reference_grid_deg);
  assert(abs(sum(h.*exp(-1i*ph)))+1e-9>=abs(sum(g.*exp(-1i*ph))));
 end
end
function mirror_test()
 c=small();c.N=8;c.target_deg=[30 20];op=a.operator(c);g=a.weights(a.desired_phase(c),[1 -1],'nearest_phase');m=a.metrics(g,c,op);
 assert(m.max_outside_target_cone_dB_vs_peak>-.1);assert(m.equivalent_global_peak_directions>=2);
end
function gain_test()
 c=small();op=a.operator(c);g=ones(c.N^2,1);m=a.metrics(g,c,op);
 assert(m.refined_peak_gain_dB_vs_ideal_N2>=m.target_gain_dB_vs_ideal_N2);
 assert(m.target_gain_dB_vs_ideal_N2<-.1&&abs(m.refined_peak_gain_dB_vs_ideal_N2)<1e-8);
end
function quadrature_test()
 c=small();op=a.operator(c);integral=sum(op.solid_angle_weights);assert(abs(integral-2*pi)<.002);values.constant_hemisphere_integral=integral;
end
function import_test()
 tmp=[tempname '.csv'];cleanup=onCleanup(@()delete(tmp)); %#ok<NASGU>
 f=[25;27;25;27];s=[0;0;1;1];z=[exp(1i*deg2rad(179));exp(-1i*deg2rad(179));.7;.7];
 T=table(f,s,real(z),imag(z),'VariableNames',{'frequency_GHz','state','real','imag'});writetable(T,tmp);
 q=a.load_states(tmp,26);assert(abs(abs(angle(q(1)))-pi)<1e-10);assert(abs(q(2)-.7)<1e-14);
 r=a.load_states(tmp,25);assert(abs(r(1)-z(1))<1e-14);r0=a.load_states(tmp,25+0);assert(isequal(r,r0));
end
function invalid_import_test()
 tmp=[tempname '.csv'];cleanup=onCleanup(@()delete(tmp)); %#ok<NASGU>
 T=table([26;26],[0;1],[1.02;.7],[0;0],'VariableNames',{'frequency_GHz','state','real','imag'});writetable(T,tmp);
 fails=false;try,a.load_states(tmp,26);catch e,fails=strcmp(e.identifier,'ris:ImportPassivity');end;assert(fails);
 T.real=[.9;.7];writetable(T,tmp);fails=false;try,a.load_states(tmp,27);catch e,fails=strcmp(e.identifier,'ris:ImportRange');end;assert(fails);
end
function channel_test()
 n=(0:399).';h=exp(1i*(.037*n+.0008*n.^2));g=exp(1i*(-.021*n+.0003*n.^2));
 correct=angle(h)-angle(g);printed=angle(g)-angle(h);
 A=abs(h'*(exp(1i*correct).*g));B=abs(h'*(exp(1i*printed).*g));
 assert(abs(A-sum(abs(h).*abs(g)))<1e-10&&B<A*.5);
 values.equation1_optimum_channel_magnitude=A;values.printed_equation6_channel_magnitude=B;
end
function regression_test()
 c=a.config();ph=a.desired_phase(c);gi=a.weights(ph,[1 -1],'nearest_phase');S=[.96*exp(1i*deg2rad(38)),.74*exp(1i*deg2rad(-156))];gh=a.weights(ph,S,'nearest_phase');
 gain=@(g)10*log10(abs(sum(exp(-1i*ph).*g))^2/c.N^4);
 assert(abs(gain(gi)-(-3.92959138301963))<1e-10);assert(abs(gain(gh)-(-5.4000021579367))<1e-10);
 values.fixed_reference_binary_target_gain_dB=gain(gi);values.fixed_reference_paper_target_gain_dB=gain(gh);
end
end
