"""Inventory every baseline tracked byte and diagnose historical pipeline differences."""
from pathlib import Path
import csv, hashlib, json, subprocess
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
def main():
    baseline='4d61322a2864f6540cac1c53baa1eb6080cee4db'
    files = subprocess.check_output(['git','ls-tree','-r','--name-only',baseline],cwd=ROOT,text=True).splitlines()
    out = {'baseline_commit':baseline, 'files':[]}
    for name in files:
        p=ROOT/name; b=subprocess.check_output(['git','show',baseline+':'+name],cwd=ROOT)
        rec={'path':name,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
        if p.suffix=='.csv':
            rows=list(csv.DictReader(b.decode('utf-8-sig').splitlines()))
            rec.update(rows=len(rows),columns=list(rows[0]) if rows else [])
        elif p.suffix in ('.m','.md','.svg') or name=='.gitignore':
            rec['text_lines']=len(b.decode('utf-8-sig').splitlines())
        else: rec['signature']=b[:8].hex()
        out['files'].append(rec)
    u=list(csv.DictReader((ROOT/'results/uncertainty_sensitivity.csv').open()))
    out['historical_zero_perturbation']=[r for r in u if float(r['phase_sigma_deg'])==0 and float(r['amplitude_sigma_fraction'])==0]
    d=list(csv.DictReader((ROOT/'results/cst_on_off_comparison.csv').open()))
    r=min(d,key=lambda x:abs(float(x['frequency_GHz'])-26.168))
    a=complex(float(r['ON_S11_real']),float(r['ON_S11_imag'])); b=complex(float(r['OFF_S11_real']),float(r['OFF_S11_imag']))
    out['historical_cst_near_reference']={'frequency_GHz':float(r['frequency_GHz']),'on_abs':abs(a),'off_abs':abs(b),'on_phase_deg':float(np.angle(a,deg=True)),'off_phase_deg':float(np.angle(b,deg=True)),'shortest_phase_separation_deg':float(abs(np.angle(b/a,deg=True)))}
    dest=ROOT/'docs/audit'; dest.mkdir(parents=True,exist_ok=True)
    (dest/'baseline_inventory.json').write_text(json.dumps(out,indent=2)+'\n')
    print(json.dumps({'files':len(files),'baseline':out['baseline_commit'],'historical_cst':out['historical_cst_near_reference']},indent=2))
if __name__=='__main__': main()
