"""Run with CST 2023 bundled Python 3.6. Preserves the source checkpoint.

Example: python native_diagnostic.py D001_original_short --pid 24424
Every run needs a new experiment id. Solver completion is not convergence.
"""
import argparse, datetime, hashlib, json, os, sys, traceback
sys.path.insert(0, r'C:\Program Files (x86)\CST Studio Suite 2023\AMD64\python_cst_libraries')
import cst.interface

def main():
    p=argparse.ArgumentParser()
    p.add_argument('experiment');p.add_argument('--pid',type=int)
    p.add_argument('--topology',choices=['original','connected'],default='original')
    p.add_argument('--R',type=float,default=.001);p.add_argument('--L',type=float,default=0)
    p.add_argument('--C',type=float,default=0);p.add_argument('--prepare-only',action='store_true')
    p.add_argument('--mesh-steps',type=float)
    p.add_argument('--frequency',type=float,default=26.168)
    p.add_argument('--adaptive',action='store_true')
    p.add_argument('--source',default='off_assumed_25fF.cst')
    p.add_argument('--strict-adaptive',action='store_true')
    p.add_argument('--polarization-angle',type=float)
    p.add_argument('--ungrounded',action='store_true')
    a=p.parse_args()
    if not a.experiment.replace('_','').replace('-','').isalnum():raise ValueError('Invalid experiment id')
    root=os.path.dirname(os.path.abspath(__file__))
    out=os.path.join(root,'experiments',a.experiment)
    os.makedirs(out,exist_ok=False)
    filename=os.path.join(out,a.experiment+'.cst')
    def event(stage,detail):
        record={'utc':datetime.datetime.utcnow().isoformat()+'Z','stage':stage,'detail':detail}
        with open(os.path.join(out,'execution_events.jsonl'),'a') as f:f.write(json.dumps(record)+'\n')
        print(stage,detail,flush=True)
    config=vars(a).copy();config.update(frequency_GHz=a.frequency,status='PREPARED',
        source='cst/'+a.source,mesh='Source checkpoint tetrahedral mesh; adaptation disabled for initial controlled diagnostic')
    def saveconfig():
        with open(os.path.join(out,'configuration.json'),'w') as f:json.dump(config,f,indent=2)
    saveconfig()
    try:
        de=cst.interface.DesignEnvironment.connect(a.pid) if a.pid else cst.interface.DesignEnvironment()
        event('native_interface_connected',str(cst.interface.running_design_environments()))
        # Open the immutable source only to save a new independent checkpoint.
        source=os.path.abspath(os.path.join(root,a.source))
        if not source.lower().startswith((root+os.sep).lower()):raise ValueError('Source must stay inside cst directory')
        project=de.open_project(source)
        config['source_sha256']=hashlib.sha256(open(source,'rb').read()).hexdigest()
        project.save(filename,include_results=False)
        event('isolated_checkpoint_saved',filename)
        driver=open(os.path.join(root,'run_diagnostic.ps1'),encoding='utf-8-sig').read()
        import re
        blocks=re.findall(r"@'\n(.*?)\n'@",driver,re.S)
        if len(blocks)!=2:raise ValueError('Expected two documented diagnostic VBA blocks')
        # Diagnostics change the element's literal values, not geometry parameters.
        # Never invoke Rebuild from inside an AddToHistory block: that recursively
        # re-enters history processing. Legacy Rload/Lload/Cload parameters remain
        # historical; the final element Modify block is authoritative for this run.
        history=blocks[0]+'\nFDSolver.AddSampleInterval "26.168", "26.168", "1", "Single", "False"\n'
        for name,value in [('R',a.R),('L',a.L),('C',a.C)]:
            history=history.replace('.Set{} "{}load"'.format(name,name),'.Set{} "{:.17g}"'.format(name,value))
        history=history.replace('"26.168", "26.168"','"{0:.17g}", "{0:.17g}"'.format(a.frequency))
        if a.mesh_steps:
            history+='\nMesh.StepsPerWavelengthTet "{0}"\nMesh.MinimumStepNumberTet "{0}"\n'.format(a.mesh_steps)
            config['mesh']='Manual global refinement: wavelength and diagonal divisions '+str(a.mesh_steps)
        if a.adaptive:
            history=history.replace('.MeshAdaptionTet "False"','.MeshAdaptionTet "True"')
            history=history.replace('"1", "Single", "False"','"1", "Single", "True"')
            config['mesh']+='; adaptive tetrahedral refinement enabled'
        if a.strict_adaptive:
            if not a.adaptive:raise ValueError('--strict-adaptive requires --adaptive')
            history+='\nWith MeshAdaption3D\n .SetType "HighFrequencyTet"\n .MaxPasses "12"\n .MaxDeltaS "0.005"\n .NumberOfDeltaSChecks "2"\nEnd With\n'
            config['mesh']+='; max complex Delta S 0.005 for two checks, max 12 passes'
        if a.polarization_angle is not None:
            history+='\nFloquetPort.SetPolarizationIndependentOfScanAnglePhi "{:.17g}", "True"\n'.format(a.polarization_angle)
            config['polarization']='Mode 1 fixed at {} degrees relative to port u axis; normal incidence'.format(a.polarization_angle)
        if a.ungrounded:
            history+='\nSolid.Delete "metallization:continuous_backplane"\nBoundary.Zmin "expanded open"\nBackground.ZminSpace "2.5"\nWith FloquetPort\n .Port "Zmin"\n .SetNumberOfModesConsidered "2"\nEnd With\n'
            config['backing']='Counterfactual ground removal: no copper backplane, open bottom Floquet port with 2.5 mm air; not established as the published geometry'
        config['load_values_location']='Literal values in final diagnostic LumpedElement.Modify history block; legacy Rload/Lload/Cload parameters are not used by that block'
        if a.topology=='connected':history+=blocks[1]
        open(os.path.join(out,'diagnostic_history.bas'),'w').write(history)
        project.modeler.add_to_history('Controlled load and connectivity diagnostic',history)
        project.save()
        event('configuration_applied',config)
        if not a.prepare_only:
            event('solver_started','Single solved frequency; both legacy Floquet modes')
            project.modeler.run_solver()
            event('solver_returned','No API exception; inspect results before accepting')
            project.save()
            config['status']='SOLVER_COMPLETED_NOT_YET_VALIDATED'
        else:config['status']='PREPARED_NO_SOLVE'
        try:
            messages=project.get_messages()
            open(os.path.join(out,'messages.txt'),'w').write(str(messages))
        except Exception as e:event('message_export_exception',str(e))
        config['checkpoint_sha256']=hashlib.sha256(open(filename,'rb').read()).hexdigest()
        saveconfig()
    except Exception as e:
        config['status']='FAILED';config['error']=str(e);saveconfig()
        event('exception',traceback.format_exc());raise

if __name__=='__main__':main()
