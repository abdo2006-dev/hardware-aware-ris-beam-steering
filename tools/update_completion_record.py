"""Assemble the dated continuation record from saved diagnostic evidence."""
from pathlib import Path
import json
import pandas as pd
R=Path(__file__).resolve().parents[1]
T=pd.read_csv(R/'results/cst_diagnostics/simulation_summary.csv')
a=T[T.experiment=='D017_ungrounded_ON'];b=T[T.experiment=='D018_ungrounded_OFF']
rows=[]
import numpy as np
for mode in [1,2]:
 x=a[a['mode']==mode].iloc[0];y=b[b['mode']==mode].iloc[0]
 rows.append(dict(mode=mode,frequency_GHz=x.frequency_GHz,ON_magnitude=x.magnitude,OFF_magnitude=y.magnitude,ON_phase_deg=x.phase_deg,OFF_phase_deg=y.phase_deg,phase_separation_deg=abs(np.angle(complex(x.S_real,x.S_imag)/complex(y.S_real,y.S_imag),deg=True)),ON_transmitted_fraction=x.transmitted_power,OFF_transmitted_fraction=y.transmitted_power,status='PROVISIONAL counterfactual geometry; initial mesh only'))
pd.DataFrame(rows).to_csv(R/'results/cst_diagnostics/ungrounded_comparison.csv',index=False)
for name in ['README.md','docs/VERIFICATION_STATUS.md']:
 p=R/name;s=p.read_text(encoding='utf-8');s=s.replace('22 October 2026','23 October 2026').replace('5.3×10⁻⁸','7.3×10⁻⁷').replace('about 2×10⁻¹⁶','below 3×10⁻¹⁶').replace('below 5.3e-8','below 7.3e-7').replace('below 2e-16','below 3e-16')
 s=s.replace('All directly solve 26.168 GHz and excite both legacy fundamental Floquet modes:','All excite both legacy fundamental Floquet modes. D003-D014 and D017-D018 directly solve 26.168 GHz; D015-D016 directly solve eight frequencies:')
 s=s.replace('| D014_fixed90_open | Matching fixed-90-degree open test |','| D014_fixed90_open | Matching fixed-90-degree open test |\n| D015_ON_direct_band | ON, eight direct frequencies from 24 to 30 GHz, coarse 2,910-cell mesh |\n| D016_OFF_direct_band | Matching OFF coarse broadband diagnostic |\n| D017_ungrounded_ON | ON, counterfactual removal of copper backplane and open bottom port |\n| D018_ungrounded_OFF | Matching OFF ground-removal diagnostic |')
 s=s.replace('Not established by these single-frequency solves; historical interpolated sweep is not a convergence study','D015/D016 add eight direct frequencies on a coarse mesh; resonance and broadband convergence remain unverified')
 p.write_text(s,encoding='utf-8',newline='\n')
section='''
## Additional diagnostics, 23 October 2026

I completed **16 new CST simulations, D003-D018**, preserving each checkpoint,
configuration, native complex exports and solver log. Preparation failures D000-D002
are excluded from that count.

![Coarse broadband comparison](results/cst_diagnostics/coarse_broadband_comparison.png)

**Broadband diagnostic, D015/D016.** Solid curves show actual CST output; dashed
curves show approximate paper digitization. Both Floquet modes use consistent
magnitude and unwrapped phase axes. Direct frequencies are 24, 25, 26, 26.168, 27,
28, 29 and 30 GHz. The 1,006 exported points include interpolation. Copying the
strict project with results did **not** retain its refined mesh in the new solve:
the logs report 2,910 tetrahedra. These curves therefore do not establish broadband
convergence or resolved resonances. The strict operating-point evidence above
remains a separate dataset.

**Ground-removal test, D017/D018.** I removed the copper backplane, changed the
bottom boundary to expanded open and added a bottom Floquet port. This is a
counterfactual backing test, not an established reconstruction of the paper.
Mode 1 changes by about 0.00049 degrees between states. Mode 2 changes by about
88.70 degrees, but its reflection magnitudes are only 0.1153 ON and 0.3882 OFF,
with transmitted fractions 0.8895 and 0.8486. The backing affects the response
substantially; removing it does not recover the paper benchmark. Initial meshes
make this a diagnostic observation, not a converged physical conclusion.

For these two-sided cells I sum both reflected and both transmitted modes.
The native curve labeled `Power Outgoing all Ports` omits bottom-port power in
these exports; its raw values and residuals remain in the evidence table.
The independently summed modal balance, including reported material and lumped
losses, has maximum relative residual below 7.3e-7 across all completed runs.
Transmission is never counted as absorption.

See [ground-test numbers](results/cst_diagnostics/ungrounded_comparison.csv),
[verification and next gates](docs/VERIFICATION_STATUS.md),
[assumption ledger](docs/ASSUMPTIONS.md) and [exact change index](docs/FILE_INDEX.md).
'''
p=R/'README.md';p.write_text(p.read_text(encoding='utf-8').split('\n## Additional diagnostics,')[0]+section,encoding='utf-8',newline='\n')
p=R/'docs/VERIFICATION_STATUS.md';p.write_text(p.read_text().split('\n## Additional diagnostics,')[0]+section.replace('(results/','(../results/').replace('(docs/','('),encoding='utf-8',newline='\n')
p=R/'docs/audit/repair_log.md';p.write_text(p.read_text()+'''\n## 23 October 2026 continuation\n\n- Completed D015/D016 eight-frequency coarse-band diagnostics and D017/D018 ground-removal tests: 16 new simulations total.\n- Confirmed copied results do not preserve the refined mesh in the band solver; retained the 2,910-cell scope explicitly.\n- Exported bottom-port transmission and corrected modal power summation for two-sided cells. Preserved CST's misleadingly labeled outgoing curve separately.\n- All modal passivity screens pass; worst balance residual <7.3e-7 and V-ZI residual <3e-16.\n- Ground removal changes mode-2 separation to 88.70 degrees but introduces strong transmission and low reflection magnitudes. It does not reproduce the benchmark.\n- Final educational replay decodes without ffmpeg errors. Digital quality checks cannot establish acoustic quality at the user's speakers.\n''',encoding='utf-8',newline='\n')
print('Updated evidence record for',T.experiment.nunique(),'completed simulations')
