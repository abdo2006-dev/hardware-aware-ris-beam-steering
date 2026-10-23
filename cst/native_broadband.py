"""Direct frequency diagnostics from a saved strict checkpoint.

The source results and mesh are copied, not overwritten. Verify actual mesh use
in the new solver log; copying results does not itself prove a frozen mesh.
"""
import os,sys,json,datetime,hashlib
sys.path.insert(0,r'C:\Program Files (x86)\CST Studio Suite 2023\AMD64\python_cst_libraries')
import cst.interface
root=os.path.dirname(os.path.abspath(__file__))
pid=int(sys.argv[1]);experiment=sys.argv[2];source=sys.argv[3]
if not experiment.replace('_','').isalnum():raise ValueError('Invalid id')
folder=os.path.join(root,'experiments',experiment);os.makedirs(folder,exist_ok=False)
source=os.path.abspath(os.path.join(root,source))
if not source.startswith(root+os.sep):raise ValueError('Source outside cst directory')
config={'experiment':experiment,'source':os.path.relpath(source,os.path.dirname(root)),
        'source_sha256':hashlib.sha256(open(source,'rb').read()).hexdigest(),
        'direct_frequencies_GHz':[24,25,26,26.168,27,28,29,30],
        'status':'PREPARED','scope':'Frequency diagnostic; inspect actual mesh and sample logs; physical geometry and diode remain provisional'}
for key in ['R','L','C','topology']:
    original=json.load(open(os.path.join(os.path.dirname(source),'configuration.json')))
    config[key]=original[key]
def save():json.dump(config,open(os.path.join(folder,'configuration.json'),'w'),indent=2)
save()
try:
    de=cst.interface.DesignEnvironment.connect(pid);p=de.open_project(source)
    p.save(os.path.join(folder,experiment+'.cst'),include_results=True)
    code='With FDSolver\n .ResetSampleIntervals "all"\n .MeshAdaptionTet "False"\n .MaxCPUs "6"\n .MaximumNumberOfCPUDevices "1"\nEnd With\n'
    for f in config['direct_frequencies_GHz']:
        code+='FDSolver.AddSampleInterval "{0}", "{0}", "1", "Single", "False"\n'.format(f)
    open(os.path.join(folder,'diagnostic_history.bas'),'w').write(code)
    p.modeler.add_to_history('Direct frequency diagnostics; source load and geometry preserved',code)
    p.save();config['status']='SOLVER_RUNNING';config['started_UTC']=datetime.datetime.utcnow().isoformat()+'Z';save()
    print('Solver started:',experiment,'with source results copied; verify actual mesh',flush=True)
    p.modeler.run_solver();p.save();config['status']='SOLVER_COMPLETED_NOT_YET_VALIDATED';save()
    open(os.path.join(folder,'messages.txt'),'w').write(str(p.get_messages()))
    print('Solver completed:',experiment,flush=True)
except Exception as e:
    config['status']='FAILED';config['error']=str(e);save();raise
