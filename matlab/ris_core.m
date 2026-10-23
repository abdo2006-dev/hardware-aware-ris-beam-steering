function api = ris_core()
%RIS_CORE Shared, tested functions factored from the original RIS array model.
% Array plane XY; +Z surface normal. theta is polar angle from +Z.
api.config=@config; api.coordinates=@coordinates; api.direction=@direction;
api.desired_phase=@desired_phase; api.weights=@weights; api.check=@check;
api.operator=@operator; api.metrics=@metrics; api.perturb=@perturb;
api.load_states=@load_states; api.cut=@principal_cut;
end

function c=config()
c.N=20; c.pitch_m=5.35e-3; c.frequency_Hz=26.168e9; c.c0=299792458;
c.target_deg=[25 15]; c.incident_deg=[0 0];
c.polar_deg=0:1:90; c.azimuth_deg=-180:1:179;
c.exclusion_deg=15; c.reference_grid_deg=0:0.5:359.5;
c.refine_peak=true; c.seed=20261022; c.trials=40;
end

function xy=coordinates(c)
a=((0:c.N-1)-(c.N-1)/2)*c.pitch_m;
[X,Y]=meshgrid(a,a); xy=[X(:),Y(:)];
end

function d=direction(theta,phi)
% Each row is a unit vector. Azimuth is immaterial at theta=0.
theta=theta(:); phi=phi(:);
if isscalar(phi),phi=repmat(phi,size(theta));end
if isscalar(theta),theta=repmat(theta,size(phi));end
assert(isequal(size(theta),size(phi)),'ris:DirectionShape','Angle dimensions differ.');
d=[sind(theta).*cosd(phi),sind(theta).*sind(phi),cosd(theta)];
end

function ph=desired_phase(c)
xy=coordinates(c); st=direction(c.target_deg(1),c.target_deg(2));
si=direction(c.incident_deg(1),c.incident_deg(2));
ph=-(2*pi*c.frequency_Hz/c.c0)*xy*(st(1:2)-si(1:2)).';
assert(isequal(size(ph),[c.N^2,1]));
end

function check(g,M)
assert(isnumeric(g)&&iscolumn(g)&&numel(g)==M,'ris:CoefficientShape', ...
    'Each configuration must contain exactly M complex coefficients in an M-by-1 column.');
assert(all(isfinite(real(g)))&&all(isfinite(imag(g))),'ris:CoefficientFinite','Nonfinite coefficient.');
end

function [g,idx,alpha]=weights(ph,states,method,alphaGrid)
% Retains original nearest-phase assignment; adds a common-reference study.
ph=ph(:); states=reshape(states,1,[]); M=numel(ph); alpha=0;
assert(~isempty(states)&&all(isfinite(states))&&all(abs(states)>0),'ris:States','Invalid states.');
if strcmp(method,'continuous')
    g=exp(1i*ph); idx=zeros(M,1); return
elseif strcmp(method,'nearest_phase')
    dist=abs(angle(exp(1i*(ph-angle(states)))));
    [~,idx]=min(dist,[],2);
elseif strcmp(method,'optimized_reference')
    % For each reference phase maximize the projection of the received field.
    % The same alpha grid and selection objective are used for both binary cases.
    if nargin<4,alphaGrid=0:0.5:359.5;end
    z=exp(-1i*ph)*states;
    [base,bestIdx]=weights(ph,states,'nearest_phase');
    baseField=sum(exp(-1i*ph).*base);best=abs(baseField)^2;alpha=rad2deg(angle(baseField));
    for a=alphaGrid
        [~,ii]=max(real(z*exp(-1i*deg2rad(a))),[],2);
        gg=reshape(states(ii),[],1); val=abs(sum(exp(-1i*ph).*gg))^2;
        if val>best+1e-9,best=val;bestIdx=ii;alpha=a;end
    end
    idx=bestIdx;
else,error('ris:Assignment','Unknown assignment method.');end
g=reshape(states(idx),[],1); check(g,M);
end

function op=operator(c)
xy=coordinates(c); [T,A]=ndgrid(c.polar_deg,c.azimuth_deg);
d=direction(T(:),A(:)); si=direction(c.incident_deg(1),c.incident_deg(2));
op.E=exp(1i*(2*pi*c.frequency_Hz/c.c0)*((d(:,1:2)-si(1:2))*xy.'));
op.directions=d; op.theta=T(:); op.phi=A(:); op.shape=size(T);
% Trapezoidal polar quadrature; periodic uniform azimuth quadrature.
th=deg2rad(c.polar_deg(:)); az=deg2rad(c.azimuth_deg(:));
assert(max(abs(diff(az)-mean(diff(az))))<1e-10,'ris:Grid','Azimuth must be uniform and periodic.');
assert(abs(numel(az)*mean(diff(az))-2*pi)<1e-8,'ris:Grid','Use full periodic azimuth, no duplicated endpoint.');
wt=zeros(size(th)); wt(1)=(th(2)-th(1))/2; wt(end)=(th(end)-th(end-1))/2;
wt(2:end-1)=(th(3:end)-th(1:end-2))/2;
w=repmat(wt.*sin(th)*mean(diff(az)),1,numel(az));op.solid_angle_weights=w(:);
end

function m=metrics(g,c,op,p)
M=c.N^2; check(g,M);
if nargin<4,p=abs(op.E*g).^2;end
assert(isequal(size(p),[numel(op.theta),1]));
st=direction(c.target_deg(1),c.target_deg(2));
err=angle_between(op.directions,st);
targetPower=abs(sum(exp(-1i*desired_phase(c)).*g))^2;
pmax=max(p); ties=find(p>=pmax-max(1e-9,pmax*1e-10));
[~,j]=min(err(ties)); ip=ties(j); peakDir=op.directions(ip,:);peakPower=pmax;
peakCount=size(unique(round(op.directions(ties,:)*1e8)/1e8,'rows'),1);
if c.refine_peak
    [peakDir,peakPower,peakCount]=refine_peak(g,c,op,p,st);
end
peakTheta=acosd(max(-1,min(1,peakDir(3))));
if sind(peakTheta)<1e-8,peakPhi=0;else,peakPhi=atan2d(peakDir(2),peakDir(1));end
outside=err>c.exclusion_deg+1e-8; outsidePower=max(p(outside));
integral=sum(p.*op.solid_angle_weights);
m.target_polar_deg=c.target_deg(1);m.target_azimuth_deg=canonical_phi(c.target_deg);
m.target_gain_dB_vs_ideal_N2=db(targetPower/M^2);
m.sampled_global_peak_gain_dB_vs_ideal_N2=db(pmax/M^2);
m.refined_peak_gain_dB_vs_ideal_N2=db(peakPower/M^2);
m.peak_polar_deg=peakTheta;m.peak_azimuth_deg=peakPhi;
m.pointing_error_deg=angle_between(peakDir,st);m.equivalent_global_peak_directions=peakCount;
m.max_outside_target_cone_dB_vs_ideal_N2=db(outsidePower/M^2);
m.max_outside_target_cone_dB_vs_peak=db(outsidePower/peakPower);
m.hemisphere_pattern_integral_fraction_outside_cone=sum(p(outside).*op.solid_angle_weights(outside))/integral;
m.polar_grid_step_deg=mean(diff(c.polar_deg));m.azimuth_grid_step_deg=mean(diff(c.azimuth_deg));
m.target_exclusion_cone_deg=c.exclusion_deg;
end

function [d,pp,count]=refine_peak(g,c,op,p,st)
% Full-hemisphere sampled search followed by local optimization of several
% distinct candidate lobes. This is numerical peak refinement, not a proof of
% a continuous global optimum.
[~,order]=sort(p,'descend');seeds=[];
for i=1:numel(order)
    q=op.directions(order(i),:);
    if isempty(seeds)||all(angle_between(seeds,q)>5)
        seeds=[seeds;q]; %#ok<AGROW>
    end
    if size(seeds,1)>=4,break,end
end
seeds=[seeds;st]; xy=coordinates(c);si=direction(c.incident_deg(1),c.incident_deg(2));k=2*pi*c.frequency_Hz/c.c0;
val=@(u)abs(sum(g.*exp(1i*k*(xy*(u(:)-si(1:2).')))))^2;
objective=@(u)-val(u)+c.N^4*1e6*max(0,norm(u)-1)^2;
options=optimset('Display','off','TolX',1e-10,'TolFun',1e-8,'MaxIter',350);
dirs=[]; powers=[];
for j=1:size(seeds,1)
    u=fminsearch(objective,seeds(j,1:2),options);
    if norm(u)>1+1e-5,continue,end
    u=u/max(1,norm(u));v=[u,sqrt(max(0,1-sum(u.^2)))];
    dirs=[dirs;v];powers=[powers;val(u)]; %#ok<AGROW>
end
pp=max(powers); ii=find(powers>=pp-max(1e-8,pp*1e-8));
[~,j]=min(angle_between(dirs(ii,:),st));d=dirs(ii(j),:);
distinct=[];
for j=reshape(ii,1,[])
    if isempty(distinct)||all(angle_between(distinct,dirs(j,:))>0.05),distinct=[distinct;dirs(j,:)];end %#ok<AGROW>
end
count=size(distinct,1);
end

function x=angle_between(a,b)
% atan2 avoids acos roundoff at identical directions.
bb=repmat(b,size(a,1),1);
x=atan2d(vecnorm(cross(a,bb,2),2,2),sum(a.*bb,2));
end
function p=canonical_phi(t)
if abs(t(1))<1e-10,p=0;else,p=mod(t(2)+180,360)-180;end
end
function y=db(x),y=10*log10(max(x,1e-300));end

function g=perturb(base,sigmaAmp,sigmaPhaseDeg)
check(base,numel(base));
assert(isscalar(sigmaAmp)&&isscalar(sigmaPhaseDeg)&&sigmaAmp>=0&&sigmaPhaseDeg>=0,'ris:Uncertainty','Invalid uncertainty standard deviation.');
if sigmaAmp==0&&sigmaPhaseDeg==0,g=base;return,end
M=numel(base);amp=min(1,max(0,abs(base).*(1+sigmaAmp*randn(M,1))));
g=amp.*exp(1i*(angle(base)+deg2rad(sigmaPhaseDeg)*randn(M,1)));
check(g,M);
end

function states=load_states(file,fGHz)
T=readtable(file,'TextType','string');
assert(all(ismember({'frequency_GHz','state','real','imag'},T.Properties.VariableNames)),'ris:ImportColumns','Missing reflection input columns.');
states=zeros(1,2);
for s=0:1
    R=T(T.state==s,:);[f,idx]=sort(R.frequency_GHz);z=R.real(idx)+1i*R.imag(idx);
    assert(~isempty(f)&&numel(unique(f))==numel(f),'ris:ImportGrid','Missing state or duplicate frequencies.');
    assert(all(isfinite(f))&&all(isfinite(z)),'ris:ImportFinite','Nonfinite imported sample.');
    assert(all(abs(z)<=1+1e-3),'ris:ImportPassivity','Imported modal reflection exceeds passive tolerance.');
    exact=find(abs(f-fGHz)<1e-10,1);
    if ~isempty(exact),states(s+1)=z(exact);
    else
        assert(numel(f)>=2&&fGHz>=min(f)&&fGHz<=max(f),'ris:ImportRange','Interpolation requires bracketing samples; extrapolation is forbidden.');
        states(s+1)=interp1(f,z,fGHz,'linear');
    end
end
end

function cut=principal_cut(g,c)
psi=(-90:0.1:90).';xy=coordinates(c);si=direction(c.incident_deg(1),c.incident_deg(2));
q=[sind(psi)*cosd(c.target_deg(2)),sind(psi)*sind(c.target_deg(2))];
p=abs(exp(1i*(2*pi*c.frequency_Hz/c.c0)*((q-si(1:2))*xy.'))*g).^2;
[~,it]=min(abs(psi-c.target_deg(1)));mins=find(p(2:end-1)<p(1:end-2)&p(2:end-1)<=p(3:end))+1;
l=mins(find(mins<it,1,'last'));r=mins(find(mins>it,1,'first'));
cut.psi_deg=psi;cut.power=p;cut.first_minimum_left_deg=NaN;cut.first_minimum_right_deg=NaN;cut.max_secondary_cut_lobe_dB_vs_target_lobe=NaN;
if ~isempty(l)&&~isempty(r)
    cut.first_minimum_left_deg=psi(l);cut.first_minimum_right_deg=psi(r);
    cut.max_secondary_cut_lobe_dB_vs_target_lobe=db(max(p([1:l,r:numel(p)]))/max(p(l:r)));
end
end
