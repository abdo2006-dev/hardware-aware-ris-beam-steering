# Verification status and continuation record

## Evidence gates, 23 October 2026

| Requirement | Status | Evidence and limit |
|---|---|---|
| Preserve original project and main | PASS | Baseline inventory; archive outside clone; historical commits retained in consolidated main; original CST files unchanged |
| Analytical shapes, steering and limiting cases | PASS | 15 MATLAB tests, including rejecting 400-by-400 coefficients |
| Exact zero perturbation and zero frequency offset | PASS | Shared evaluator gives zero noise difference; exact-frequency importer regression |
| Coordinate and metric corrections | PASS | Polar-angle convention, full hemisphere, target/peak split, solid-angle weights |
| Eq.1 optimum audit | PASS | Direct complex channel magnitude 400 versus 8.051739918 for the printed opposite rule |
| Original and connected short/open tests | PASS execution | D003-D006, both modes, one changed factor within each comparison |
| Explicit polarization-basis checks | PASS | D011-D014; fixed 0/90-degree mode swap, maximum complex discrepancy below 9e-9 |
| Cartesian electric-field mapping | PROVISIONAL | Port u/v basis is confirmed; attempted raw field reading and plot extraction did not yield valid field evidence |
| Strict numerical adaptation at 26.168 GHz | PASS bounded changes | D009/D010, 11 passes, last two complex all-S changes below 0.005; magnitude/phase upper bounds in CSV |
| Broadband/resonance convergence | PROVISIONAL | D015/D016 add eight direct frequencies on a coarse mesh; resonance and broadband convergence remain unverified |
| Power balance, V/I and reflected-mode passivity | PASS numerical screens | Maximum relative balance residual below 7.3e-7; V-ZI residual below 3e-16; no reflected fraction above 1.001 |
| Paper Figure 2 reproduction | FAIL current benchmark | Strict mode-1 separation 0.1808 degrees; mode-2 separation 7.6512 degrees versus approximate published 166 degrees |
| Exact diode calibration | BLOCKED source applicability | Linked fixture data and exact variant equivalence/de-embedding are unresolved; no calibrated junction model established |
| Geometry interpretation | PROVISIONAL | Dimensions mapped, backplane present, edge-only original land contact; exact pad/ground interpretation unresolved |
| Newly simulated coefficients used in MATLAB | PASS pipeline / PROVISIONAL physics | Both strict mode pairs converted with source hashes, exact frequency and state labels |
| Coupling-aware extension | PASS algebra / PROVISIONAL scenario | Assumed passive reciprocal four-port example; not CST-derived impedances |
| Finite-array full-wave RCS | PROVISIONAL feasibility | No finite-array solve executed; 16-GB resource constraint recorded without claiming impossibility |
| Educational screen recording | BLOCKED display capture | Desktop helper repeatedly reports window crop outside captured monitor; native viewport export works; timestamped explanation retained locally |

PASS applies only to the stated gate. A software test, numerical stopping rule or
power-balance identity does not establish the physical source model.

## Actual new simulations

All excite both legacy fundamental Floquet modes. D003-D014 and D017-D018 directly solve 26.168 GHz; D015-D016 directly solve eight frequencies:

| Checkpoint | Controlled configuration |
|---|---|
| D003_original_short | Original topology, R=0.001 ohm, L=C=0, initial mesh |
| D004_original_open | Original topology, R=1e9 ohm, L=C=0, initial mesh |
| D005_connected_short | Added copper overlaps/unions, short, initial mesh |
| D006_connected_open | Same connected topology, open, initial mesh |
| D007_original_ON_refine8 | Original, 5.2 ohm + 30 pH, initial adaptive protocol |
| D008_original_OFF_refine8 | Original, 30 pH + 25 fF, initial adaptive protocol |
| D009_ON_strict | ON, strict two-check 0.005 all-S adaptation, 46,198 tetrahedra |
| D010_OFF_strict | OFF, strict two-check 0.005 all-S adaptation, 47,811 tetrahedra |
| D011_fixed0_short | Original short, first mode fixed at 0 degrees to port u |
| D012_fixed0_open | Matching fixed-0-degree open test |
| D013_fixed90_short | Original short, first mode fixed at 90 degrees to port u |
| D014_fixed90_open | Matching fixed-90-degree open test |
| D015_ON_direct_band | ON, eight direct frequencies from 24 to 30 GHz, coarse 2,910-cell mesh |
| D016_OFF_direct_band | Matching OFF coarse broadband diagnostic |
| D017_ungrounded_ON | ON, counterfactual removal of copper backplane and open bottom port |
| D018_ungrounded_OFF | Matching OFF ground-removal diagnostic |

D000 and D001 failed during preparation; D002 did not complete preparation before
recovery. None is counted as a simulation. They remain local failure evidence.
The recursive rebuild inside the first diagnostic history caused a stall; the
corrected driver modifies literal load values without invoking a nested rebuild.
The original project remains untouched.

## Numerical convergence bound

CST reports the maximum complex all-S difference delta between successive meshes.
The reverse triangle inequality gives a magnitude-change upper bound delta. For
a final co-polar magnitude r and delta<r, a disk tangent gives phase bound
asin(delta/r). For the previous comparison, r is conservatively reduced by the
last delta. The final two bounds are below 0.005 magnitude and 0.224 degrees for
both modes and both states. These are mathematically derived upper bounds, not
direct individual per-pass trace readings. The check is local to 26.168 GHz.

## Unresolved physical questions and next discriminating work

1. Obtain valid Cartesian port-field samples or an explicit port-coordinate
   definition. Native field-plot exports returned geometry, so they are excluded
   from evidence rather than labeled as mode fields.
2. Resolve the copper volume/surface representation warning. A controlled change
   must preserve geometry and load and repeat the numerical gates.
3. Resolve the paper's ground interpretation, exact pad geometry, diode bias and
   fixture de-embedding. Do not fit unrelated dimensions merely to match Figure 2.
4. After establishing a physical candidate, directly sample 24-30 GHz, bracket any
   resonance and refine the local spacing to at most 0.025 GHz. Compare mesh levels
   at the operating frequency and resonant features.
5. Promote a hardware dataset to verified only after those gates. The current
   converter and array outputs intentionally retain PROVISIONAL status.

The original model's mode sensitivity and mesh dependence are established. A
single complete causal explanation for the paper mismatch has not been proven.

## Additional diagnostics, 23 October 2026

I completed **16 new CST simulations, D003-D018**, preserving each checkpoint,
configuration, native complex exports and solver log. Preparation failures D000-D002
are excluded from that count.

![Coarse broadband comparison](../results/cst_diagnostics/coarse_broadband_comparison.png)

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

See [ground-test numbers](../results/cst_diagnostics/ungrounded_comparison.csv),
[verification and next gates](VERIFICATION_STATUS.md),
[assumption ledger](ASSUMPTIONS.md) and [exact change index](FILE_INDEX.md).

## Public native-file restriction

Automatic publication review rejected new native CST archives because they embed license-identifying metadata. All 16 native checkpoints remain preserved locally. Their configurations, construction histories, source hashes, numerical exports and redacted solver logs are public. No archive bytes or private native result folders are published in the repair snapshot. Original baseline files remain unchanged.


## Repository consolidation, 24 October 2026

The completed research repair work and expanded README with actual CST captures are consolidated into main. This publication change does not alter the physical acceptance gates above. Earlier main and repair commits remain in history.
