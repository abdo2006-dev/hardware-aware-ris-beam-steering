# Assumption and uncertainty ledger

| Item | Treatment | Evidence / remaining limit |
|---|---|---|
| Published reflection curves | Approximate raster digitization | Pixel calibration and PDF hash in data/paper_digitized_reference; roughly 0.004 magnitude / 2 degrees reading resolution, additional registration error unknown |
| Geometry parameter mapping | Provisional interpretation | Actual CST history compared to Fig.1; exact PW and slot mapping require source confirmation |
| Backplane | Present in original implementation | D017/D018 test removal as a counterfactual; neither geometry is certified as the paper's intended backing |
| Copper | 35 micrometres, bulk conductivity 5.8e7 S/m | Thickness assumed; native high-conductivity mesh warning remains relevant |
| Substrate | Constant eps_r 2.2 and loss tangent 0.0009 | Dispersion, anisotropy and fabrication variation unmeasured |
| ON load | 5.2 ohm + 30 pH series | Datasheet resistance condition differs from 26.168 GHz; inductance assumed |
| OFF load | 30 pH + 25 fF, zero explicit resistance | Bias-specific capacitance and RF loss uncalibrated |
| Manufacturer fixture models | Reviewed, not substituted | Exact die equivalence and de-embedding to the gap unresolved |
| Original land connectivity | Edge/corner-only contact in XY | Added copper overlaps test sensitivity, not a known fabrication correction |
| Polarization | Port-relative basis swap verified | Valid global Cartesian field evidence still missing |
| Local mesh convergence | Bounded coefficient changes at 26.168 GHz | D009/D010 last two all-S differences <0.005; phase-change bounds <0.224 degrees; does not establish physical correctness |
| Broadband mesh | Coarse, provisional | Eight direct frequencies, 1,006 exported values; 2,910 tetrahedra, no resolved-resonance convergence |
| Ungrounded mesh | Initial diagnostic only | No convergence claim; bottom transmission explicitly included |
| Independent-element array | Scalar array factor, common ideal N squared reference | No element pattern, mutual coupling, finite-edge effects, efficiency, realized gain or RCS validation |
| State assignment | Fixed nearest phase and optimized common reference compared | Nearly equal mirror beam remains; optimized reference is not a full-wave impedance optimization |
| Uncertainty | Independent Gaussian phase / multiplicative amplitude, clipped amplitudes | 40 trials, seed 20261022; assumed distributions, not measured tolerances; SEM and empirical quantiles reported |
| Four-port impedance example | Assumed passive reciprocal circuit | Algebra tested; impedances not extracted from CST; no device structural-scattering level inferred |
| Recording | Offline educational replay | Digital waveform/decode checks pass; live CST screen capture unavailable and acoustic playback not verified |

No current dataset is promoted to physically verified hardware solely because its
software tests, passivity or numerical stopping criteria pass.
