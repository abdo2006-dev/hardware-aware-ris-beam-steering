# CST physical audit and experiment contract

## Source versus implemented model

Dimensions are in mm. Source: Goshu et al., EuCAP 2025, Figure 1 and Table I.
Construction history is direct model evidence, but interpretation of the small
published geometry diagram still needs an explicit CAD-to-source comparison.

| Quantity | Published value / description | Existing CST implementation | Status |
|---|---|---|---|
| GL / pitch | 5.35 | square periodic cell, 5.35 | PROVISIONAL mapping |
| PL | 3.5 | patch extent along Y, 3.5 | PROVISIONAL orientation |
| PW | 2.8 | combined patch-pair extent along X, 2.8 | PROVISIONAL interpretation |
| GW | 0.3 | central X gap, 0.3 | PROVISIONAL interpretation |
| SW | 2 | horizontal slot total X span, 2 | PROVISIONAL interpretation |
| SL | 0.4 | slot Y width, 0.4 | PROVISIONAL interpretation |
| Substrate | thickness 0.5; eps_r 2.2; tan delta 0.0009 | same constant material values | PASS history audit; dispersion assumption |
| Copper | thickness not established here | 0.035, sigma 5.8e7 S/m | assumed |
| Ground | interpretation requires source cross section | explicit continuous copper backplane plus electric Zmin | PROVISIONAL; old one-face schematic wrong |
| Diode lands | dimensions not established | 0.1-wide lands, X terminals +/-0.15 | assumed; connectivity concern |
| Excitation | relevant polarization must bridge diode gap | two Floquet modes at Zmax, normal incidence | physical mode mapping unverified |
| XY boundaries | infinite periodic unit cell | periodic in X/Y | PASS history audit; no finite-array claim |
| Zmax | Floquet port above model | expanded open boundary | reference plane requires audit |
| Frequency | design near 28; balance 26.168 GHz | historical 24-30 GHz sweep | actual solved points distinct from 1001 interpolated points |
| ON proxy | PIN diode must be justified separately | series 5.2 ohm + 30 pH, C=0 | PROVISIONAL |
| OFF proxy | bias and junction capacitance must be justified | series 30 pH + assumed 25 fF, R=0 | PROVISIONAL |

## Connectivity concern

The history puts the left upper/lower arms at X [-1,-0.25], Y [0.2,1.75]
and [-1.75,-0.2]. The left diode land occupies X [-0.25,-0.15], Y [-0.2,0.2].
Thus arm and land meet only along vertical edges at the XY corners. There is no
finite-area metal contact. The right side is symmetric. The lumped terminals are
on the diode lands at X +/-0.15, Y=0, Z=0.5175.

This is a physical concern, not yet a verified explanation of the 2.87-degree
ON/OFF contrast. It needs controlled short/open tests of the original and an
explicitly connected topology, both polarizations, and voltage/current evidence.
An enlarged overlap pad is a diagnostic geometry; it is not automatically the
paper's fabrication geometry.

## Diagnostic design

Keep geometry, frequency, mesh and excitation fixed within each comparison:

1. Original topology: approximate short R=0.001 ohm, L=C=0 versus approximate
   open R=1e9 ohm, L=C=0.
2. Connected topology: repeat the exact same two loads after adding overlapping
   copper bridges and unioning each arm, outer patch and diode land.
3. Compare the complex co-polar response of both Floquet modes, monitor current
   and voltage, and establish the electric-field direction of the coupled mode.
4. Only after interpreting these results, introduce justified ON/OFF circuits.

`cst/native_diagnostic.py` uses the supported CST Python interface. Each run gets
a new experiment directory and checkpoint; configuration, VBA and execution events
are retained. `cst/run_diagnostic.ps1` records the alternative COM attempt and the
documented geometry operations. An API return without error is not convergence.

## Numerical acceptance criteria, specified before convergence runs

For two consecutive mesh refinements, require at each directly solved comparison
frequency: complex |Delta Gamma| < 0.01, magnitude difference < 0.005 and wrapped
phase change < 1 degree when |Gamma| > 0.1. Around a resonance, additionally require
resonant frequency displacement < 0.1 GHz with directly solved frequency spacing
no larger than 0.025 GHz in the local bracket. Refine the bracket when necessary.
These are project acceptance thresholds, not universal accuracy guarantees.

Record tetrahedra, adaptive pass, solver residual and actual solved frequencies.
Distinguish interpolated sweep samples. For each incident mode, sum powers of all
propagating outgoing Floquet modes. A value above 1.001 fails the passivity screen.
The grounded model has no transmitted port; 1-reflectance includes loss and numerical
error and is not an independent absorption validation. Verify losses directly when
available. Near-zero co-polar magnitude makes phase an unreliable convergence metric.

## Manufacturer model applicability

The official MACOM page links a Rev V8 datasheet, a 2021 SPICE presentation and a
MA4AGP907 S-parameter ZIP. Datasheet typical resistance 5.2 ohm is specified at
10 mA / 1 GHz; typical total capacitance 0.025 pF is specified at -10 V / 1 MHz.
Neither number alone establishes the packaged small-signal impedance at 26 GHz.

The SPICE presentation describes an AWR PIN RC model with fixture transmission
lines and bias dependence. It shows Cj 0.023 pF, Cpkg 0.0035 pF, Rlim 3.5 ohm and
Lpkg 0 nH, among nonlinear parameters. It is not a ready CST linear RLC netlist.

The linked S2P files cover 2-50 GHz at 0.25 GHz spacing, 50-ohm reference, real /
imaginary format, with 5/10/15 mA forward and 0/-5 V reverse states. Their names
identify MA4AGP907 and their metadata describe a wafer/PCM fixture. Exact variant
equivalence, reference planes and de-embedding to this diode gap are unverified.
Direct insertion as a lumped junction would be unjustified. A future fit must state
the bias, fixture removal, passivity and fit residual; no such fit is claimed here.

Sources: [product page](https://www.macom.com/products/product-detail/MADP-000907-14020P),
[datasheet](https://cdn.macom.com/datasheets/MADP-000907-14020x.pdf),
[SPICE presentation](https://cdn.macom.com/simulation-models/MADP-000907-14020%20SPICE%20Model.pdf),
[S-parameter archive](https://cdn.macom.com/s-parameters/MA4AGP907_SPAR.zip).
