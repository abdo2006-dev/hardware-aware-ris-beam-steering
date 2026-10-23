"""Build evidence tables and figures from actual saved CST exports and logs."""
import hashlib,json,pathlib,re
import numpy as np
import pandas as pd
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'results'/'cst_diagnostics';OUT.mkdir(exist_ok=True,parents=True)
rows=[];passes=[]
for folder in sorted((ROOT/'cst'/'experiments').iterdir()):
    csv=folder/'complex_sparameters.csv'
    if not csv.exists():continue
    config=json.loads((folder/'configuration.json').read_text(encoding='utf-8-sig'))
    data=pd.read_csv(csv);raw=json.loads((folder/'raw_1d_results.json').read_text())
    if 'direct_frequencies_GHz' in config:
        frequencies=np.asarray(config['direct_frequencies_GHz'])
        old=data.copy();data=pd.DataFrame({'frequency_GHz':frequencies})
        for column in old.columns:
            if column!='frequency_GHz':data[column]=np.interp(frequencies,old.frequency_GHz,old[column])
    log=folder/folder.name/'Result'/'Model.log'
    if not log.exists():log=folder/'solver_log.txt'
    text=log.read_text(errors='replace') if log.exists() else ''
    # Publish the numerical solver log and construction history, preserving raw
    # originals locally. Redact only the machine identifier in the public copy.
    redacted=re.sub(r'(?im)^.*Computer name[^\r\n]*', '[workstation identifier removed]',text)
    redacted=re.sub(r'(?im)^.*(?:licensed for|license server|license key|license file)[^\r\n]*','[licensing metadata removed]',redacted)
    redacted=re.sub(r'(?im)^.*(?:tbbmalloc_proxy|Success: free|Fail: _msize)[^\r\n]*','[local allocator runtime detail removed]',redacted)
    (folder/'solver_log.txt').write_text(redacted)
    model=folder/folder.name/'Model'/'3D'/'Model.mod'
    if model.exists():(folder/'model_history.bas').write_bytes(model.read_bytes())
    cells=re.findall(r'Number of mesh cells\s*:\s*(\d+)',text)
    deltas=re.findall(r'All S-Parameters\s*:\s*([\d.eE+-]+)',text)
    n_pass=re.findall(r'Adaptive mesh refinement pass\s+(\d+)',text)
    for j,cell in enumerate(cells[:len(n_pass)]):
        passes.append(dict(experiment=folder.name,adaptive_pass=j+1,tetrahedra=int(cell),
                           all_S_delta=float(deltas[j-1]) if j>0 and j-1<len(deltas) else np.nan))
    def val(key):
        curve=raw[key]
        def z(value):return complex(value['real'],value['imag']) if isinstance(value,dict) else value
        if len(curve)==1:return z(curve[0][1])
        x=np.asarray([a[0] for a in curve]);y=np.asarray([z(a[1]) for a in curve])
        return np.interp(float(r.frequency_GHz),x,y)
    def realval(key):
        z=complex(val(key));assert abs(z.imag)<1e-10
        return z.real
    for _,r in data.iterrows():
        for mode in [1,2]:
            prefix=f'1D Results\\Power\\Excitation [Zmax({mode})]\\'
            stimulated=realval(prefix+'Power Stimulated')
            outgoing_reported=realval(prefix+'Power Outgoing all Ports')
            # CST 2023's curve with this label omits the unexcited bottom port
            # in the new two-sided tests. Sum all exported propagating modes.
            outgoing=stimulated*r.get(f'outgoing_power_mode{mode}',r[f'reflected_power_mode{mode}'])
            dielectric=realval(prefix+'Loss in Dielectrics')
            metal=realval(prefix+'Loss in Metals')
            lumped=realval(prefix+'Loss in Lumped Elements')
            V=val(f'1D Results\\Lumped Elements\\Voltages\\PIN_ON_series_RL [Zmax({mode})]')
            I=val(f'1D Results\\Lumped Elements\\Currents\\PIN_ON_series_RL [Zmax({mode})]')
            Z=val(f'1D Results\\Lumped Elements\\Impedances\\PIN_ON_series_RL [Zmax({mode})]')
            rows.append(dict(experiment=folder.name,topology=config['topology'],mode=mode,
                frequency_GHz=r.frequency_GHz,R_ohm=config['R'],L_H=config['L'],C_F=config['C'],
                S_real=r[f'S{mode}_{mode}_real'],S_imag=r[f'S{mode}_{mode}_imag'],
                magnitude=r[f'S{mode}_{mode}_magnitude'],phase_deg=r[f'S{mode}_{mode}_phase_deg'],
                reflected_power=r[f'reflected_power_mode{mode}'],transmitted_power=r.get(f'transmitted_power_mode{mode}',0),outgoing_power=r.get(f'outgoing_power_mode{mode}',r[f'reflected_power_mode{mode}']),voltage_abs_V=abs(V),current_abs_A=abs(I),
                impedance_real_ohm=Z.real,impedance_imag_ohm=Z.imag,
                VI_impedance_relative_error=abs(V-Z*I)/max(abs(V),1e-20),
                power_balance_relative_residual=(stimulated-outgoing-dielectric-metal-lumped)/stimulated,
                raw_CST_labeled_outgoing_power_W=outgoing_reported,
                raw_CST_outgoing_curve_balance_residual=(stimulated-outgoing_reported-dielectric-metal-lumped)/stimulated,
                dielectric_loss_fraction=dielectric/stimulated,metal_loss_fraction=metal/stimulated,lumped_loss_fraction=lumped/stimulated,
                final_tetrahedra=int(cells[-1]) if cells else None,adaptive_passes=len(n_pass),
                final_all_S_delta=float(deltas[-1]) if deltas else np.nan,
                S_sample_status='Interpolated CST curve evaluated at logged solve frequencies' if 'direct_frequencies_GHz' in config else 'Direct single-frequency export',
                status='PROVISIONAL until independent mesh/polarization/geometry gates pass'))
T=pd.DataFrame(rows);T.to_csv(OUT/'simulation_summary.csv',index=False)
pd.DataFrame(passes).to_csv(OUT/'adaptive_mesh_history.csv',index=False)
basis=[]
for experiment,baseline,angle,expected in [('D011_fixed0_short','D003_original_short',0,2),('D012_fixed0_open','D004_original_open',0,2),('D013_fixed90_short','D003_original_short',90,1),('D014_fixed90_open','D004_original_open',90,1)]:
    if experiment not in T.experiment.values:continue
    r=T[(T.experiment==experiment)&(T['mode']==1)].iloc[0]
    b=T[(T.experiment==baseline)&(T['mode']==expected)].iloc[0]
    error=abs(complex(r.S_real,r.S_imag)-complex(b.S_real,b.S_imag))
    basis.append(dict(experiment=experiment,mode1_angle_relative_port_u_deg=angle,matching_original_mode=expected,co_polar_complex_difference=error,status='PASS' if error<1e-6 else 'FAIL',scope='Port u/v basis verified by controlled rotation; global Cartesian field mapping remains provisional'))
pd.DataFrame(basis).to_csv(OUT/'polarization_basis_verification.csv',index=False)
bound=[]
for ex in ['D009_ON_strict','D010_OFF_strict']:
    r=T[(T.experiment==ex)&(T['mode']==1)]
    history=[p for p in passes if p['experiment']==ex]
    if not len(r) or len(history)<3:continue
    last=[h['all_S_delta'] for h in history[-2:]]
    for mode in [1,2]:
        mag=float(T[(T.experiment==ex)&(T['mode']==mode)].iloc[0].magnitude)
        for j,delta in enumerate(last):
            # Reverse triangle inequality and tangent bound for a complex disk.
            radius=mag if j==1 else mag-last[1]
            phase_bound=np.rad2deg(np.arcsin(min(1,delta/radius)))
            bound.append(dict(experiment=ex,mode=mode,adaptive_pass=history[-2+j]['adaptive_pass'],max_complex_change=delta,max_magnitude_change_bound=delta,max_phase_change_bound_deg=phase_bound,status='PASS' if delta<.005 and phase_bound<1 else 'FAIL',method='Upper bounds from CST maximum all-S complex difference, not direct individual per-pass trace readings'))
pd.DataFrame(bound).to_csv(OUT/'strict_convergence_bounds.csv',index=False)
comparisons=[]
for short,opened,topology in [('D003_original_short','D004_original_open','original'),('D005_connected_short','D006_connected_open','connected')]:
    for mode in [1,2]:
        a=T[(T.experiment==short)&(T['mode']==mode)].iloc[0];b=T[(T.experiment==opened)&(T['mode']==mode)].iloc[0]
        za=complex(a.S_real,a.S_imag);zb=complex(b.S_real,b.S_imag)
        comparisons.append(dict(topology=topology,mode=mode,frequency_GHz=a.frequency_GHz,
            short_checkpoint=short,open_checkpoint=opened,complex_delta=abs(za-zb),
            wrapped_phase_difference_deg=abs(np.angle(za/zb,deg=True)),magnitude_difference=abs(a.magnitude-b.magnitude)))
C=pd.DataFrame(comparisons);C.to_csv(OUT/'open_short_comparison.csv',index=False)
# Direct numerical comparison to approximate published curves, no forced fit.
paper=pd.read_csv(ROOT/'data'/'paper_digitized_reference'/'reflection_states.csv')
comparison=[]
for exp,state in [('D007_original_ON_refine8',0),('D008_original_OFF_refine8',1),('D009_ON_strict',0),('D010_OFF_strict',1)]:
    for _,row in T[T.experiment==exp].iterrows():
        r=paper[paper.state==state];z=np.interp(row.frequency_GHz,r.frequency_GHz,r.real)+1j*np.interp(row.frequency_GHz,r.frequency_GHz,r.imag)
        sim=complex(row.S_real,row.S_imag)
        comparison.append(dict(experiment=exp,state=state,mode=row['mode'],frequency_GHz=row.frequency_GHz,paper_magnitude=abs(z),simulated_magnitude=abs(sim),magnitude_error=abs(sim)-abs(z),paper_phase_deg=np.angle(z,deg=True),simulated_phase_deg=np.angle(sim,deg=True),wrapped_phase_error_deg=np.angle(sim/z,deg=True),complex_error=abs(sim-z),status='PROVISIONAL; common absolute phase reference between paper and CST is unverified'))
pd.DataFrame(comparison).to_csv(OUT/'paper_matched_frequency_comparison.csv',index=False)
band=[]
for ex,state in [('D015_ON_direct_band',0),('D016_OFF_direct_band',1)]:
    source=ROOT/'cst'/'experiments'/ex/'complex_sparameters.csv'
    if not source.exists():continue
    curve=pd.read_csv(source);ref=paper[paper.state==state]
    for mode in [1,2]:
        z=np.interp(ref.frequency_GHz,curve.frequency_GHz,curve[f'S{mode}_{mode}_real'])+1j*np.interp(ref.frequency_GHz,curve.frequency_GHz,curve[f'S{mode}_{mode}_imag'])
        zp=ref.real.to_numpy()+1j*ref.imag.to_numpy()
        for f,sim,reference in zip(ref.frequency_GHz,z,zp):band.append(dict(experiment=ex,state=state,mode=mode,frequency_GHz=f,CST_real=sim.real,CST_imag=sim.imag,paper_real=reference.real,paper_imag=reference.imag,magnitude_error=abs(sim)-abs(reference),wrapped_phase_error_deg=np.angle(sim/reference,deg=True),complex_error=abs(sim-reference),status='PROVISIONAL coarse 2910-cell band; 8 directly calculated frequencies, 1006 exported points including interpolated values'))
pd.DataFrame(band).to_csv(OUT/'coarse_broadband_comparison.csv',index=False)
manifest={'generator':'tools/analyze_diagnostics.py','scope':'Actual saved CST diagnostic data; not paper reproduction or physical measurement',
          'files':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'cst'/'experiments').glob('*/complex_sparameters.csv')},
          'maximum_abs_power_balance_relative_residual':float(T.power_balance_relative_residual.abs().max()),
          'maximum_VI_relative_error':float(T.VI_impedance_relative_error.max()),
          'all_two_mode_passivity_screens_pass':bool((T.outgoing_power<=1.001).all()),
          'passivity_definition':'Sum of both reflected and, where present, both transmitted fundamental modes; not a loss estimate from reflection alone'}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2));print(C.to_string(index=False));print(json.dumps(manifest,indent=2))
