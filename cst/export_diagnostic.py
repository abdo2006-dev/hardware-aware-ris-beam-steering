"""Read saved diagnostic data with CST 2023 Python; no solver or model mutation."""
import csv,hashlib,json,math,os,sys,re
sys.path.insert(0,r'C:\Program Files (x86)\CST Studio Suite 2023\AMD64\python_cst_libraries')
import cst.results
folder=os.path.abspath(sys.argv[1]);name=os.path.basename(folder)
filename=os.path.join(folder,name+'.cst')
module=cst.results.ProjectFile(filename,allow_interactive=True).get_3d()
paths=module.get_tree_items();raw={};errors={}
def serial(v):
    if isinstance(v,complex):return {'real':v.real,'imag':v.imag}
    if isinstance(v,(tuple,list)):return [serial(x) for x in v]
    return v
for path in paths:
    if path.startswith('1D Results'):
        try:raw[path]=serial(module.get_result_item(path,1).get_data())
        except Exception as e:errors[path]=str(e)
with open(os.path.join(folder,'raw_1d_results.json'),'w') as f:json.dump(raw,f,indent=2)
traces={}
for receive in [1,2]:
    for excite in [1,2]:
        suffix='SZmax({}),Zmax({})'.format(receive,excite)
        found=[s for s in paths if s.endswith(suffix) and 'Adaptive Meshing' not in s]
        if len(found)!=1:raise ValueError(str(found))
        traces[(receive,excite)]=module.get_result_item(found[0],1).get_data()
first=traces[(1,1)]
transmission={}
for receive in [1,2]:
    for excite in [1,2]:
        suffix='SZmin({}),Zmax({})'.format(receive,excite)
        found=[s for s in paths if s.endswith(suffix) and 'Adaptive Meshing' not in s]
        if len(found)==1:transmission[(receive,excite)]=module.get_result_item(found[0],1).get_data()
if transmission and len(transmission)!=4:raise ValueError('Incomplete bottom-port transmission matrix')
rows=[]
for j,t in enumerate(first):
    row={'frequency_GHz':t[0]}
    for key,curve in traces.items():
        if abs(curve[j][0]-t[0])>1e-10:raise ValueError('Frequency mismatch')
        s=curve[j][1];prefix='S{}_{}'.format(*key)
        row[prefix+'_real']=s.real;row[prefix+'_imag']=s.imag
        row[prefix+'_magnitude']=abs(s);row[prefix+'_phase_deg']=math.degrees(math.atan2(s.imag,s.real))
    for excite in [1,2]:
        row['reflected_power_mode{}'.format(excite)]=sum(abs(traces[(receive,excite)][j][1])**2 for receive in [1,2])
        row['transmitted_power_mode{}'.format(excite)]=sum(abs(transmission[(receive,excite)][j][1])**2 for receive in [1,2]) if transmission else 0.0
        row['outgoing_power_mode{}'.format(excite)]=row['reflected_power_mode{}'.format(excite)]+row['transmitted_power_mode{}'.format(excite)]
    for key,curve in transmission.items():
        s=curve[j][1];prefix='T{}_{}'.format(*key)
        row[prefix+'_real']=s.real;row[prefix+'_imag']=s.imag
    rows.append(row)
with open(os.path.join(folder,'complex_sparameters.csv'),'w',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
logfile=os.path.join(folder,name,'Result','Model.log')
log=open(logfile,errors='replace').read() if os.path.exists(logfile) else ''
calculated=[float(x) for x in re.findall(r'Calculation \d+ of \d+ \(Frequency:\s*([\d.]+) GHz',log)]
if not calculated:calculated=[float(x) for x in re.findall(r'Sample \d+ of \d+ \(([\d.]+) GHz',log)]
meta={'checkpoint':name+'.cst','checkpoint_sha256':hashlib.sha256(open(filename,'rb').read()).hexdigest(),
      'generator':'cst/export_diagnostic.py','run_id':1,'status':'PROVISIONAL',
      'trace_index_definition':'S_receive_excite, both at Zmax',
      'physical_polarization':'Not yet verified from mode field orientation',
      'source_tree':paths,'read_errors':errors,'sample_count':len(rows),
      'direct_calculated_frequencies_GHz':calculated,
      'frequency_samples':'CST interpolated output when the curve has more points than the directly calculated frequencies; exact single-frequency output otherwise',
      'bottom_transmission_included':bool(transmission),
      'passivity_screen_pass':all(r['outgoing_power_mode{}'.format(i)]<=1.001 for r in rows for i in [1,2])}
with open(os.path.join(folder,'export_manifest.json'),'w') as f:json.dump(meta,f,indent=2)
print(json.dumps(rows if len(rows)<10 else {'exported_points':len(rows),'frequency_range_GHz':[rows[0]['frequency_GHz'],rows[-1]['frequency_GHz']],'direct_calculated_frequencies_GHz':calculated},indent=2));print('Read errors:',errors)
