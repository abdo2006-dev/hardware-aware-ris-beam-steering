# Model and methods

## Geometry and material inputs

| Parameter | Value | Basis |
|---|---:|---|
| Lattice pitch GL | 5.35 mm | Source paper Table I; interpreted as square pitch |
| Substrate | RT/duroid 5880 | Source paper / Rogers laminate family |
| Relative permittivity | 2.2 | Nominal material value used in the model |
| Loss tangent | 0.0009 | Nominal material value used in the model |
| Substrate thickness | 0.5 mm | Source paper interpretation |
| Patch length PL | 3.5 mm | Visual interpretation of source Fig. 1 |
| Patch width PW | 2.8 mm | Visual interpretation of source Fig. 1 |
| Central gap GW | 0.3 mm | Source drawing interpretation |
| Slot | 2.0 mm × 0.4 mm | Visual interpretation of source Fig. 1 |
| Copper thickness | 35 µm | Provisional fabrication assumption |
| Terminal width | 0.1 mm | Provisional modeling assumption |

The source does not define every axis assignment and fabrication detail in prose. The visual interpretation of Fig. 1 should be reviewed in CST before the geometry is treated as a source-faithful reproduction.

## Load scenarios

| Scenario | R | L | C | Interpretation |
|---|---:|---:|---:|---|
| Baseline | 5.2 Ω | 30 pH | 0 | Provisional ON proxy; baseline result reused |
| OFF copy | 0 Ω | 30 pH | 25 fF | Illustrative OFF scenario; capacitance assumed |

The 25 fF capacitance is not specified by the paper. A manufacturer datasheet value at low test frequency does not by itself validate a 26 GHz packaged-diode equivalent circuit.

## CST boundaries and solution

- X and Y: periodic boundaries for an infinite periodic sheet approximation.
- Zmin: electric boundary.
- Zmax: expanded-open boundary.
- Excitation: two Floquet modes, normal incidence.
- Solver: high-frequency frequency-domain, adaptive broadband sweep from 24 to 30 GHz.

CST reported eight calculated broadband samples and 1,001 interpolated sweep points for the OFF run. The final mesh contained 4,682 tetrahedra. The available run record documents one adaptive mesh level; it does not establish mesh independence.

## Power-balance check

At each calculated sample, the exported audit compares stimulated, outgoing, accepted, dielectric-loss and metal-loss quantities. For the OFF run:

- Maximum |Pstimulated − Poutgoing − Paccepted|: 2.78e-17 W.
- Maximum |Paccepted − Pdielectric − Pmetal|: 2.25e-6 W.

This check assesses consistency of the exported CST power accounting. It is not a diode-specific loss measurement.

## MATLAB array-factor model

The array model uses N=20, pitch p=5.35 mm, frequency f=26.168 GHz, normal incidence, and target direction (25°,15°). The three compared element-weight cases are ideal continuous phase, ideal one-bit phase states, and hardware-aware one-bit phase assignment using approximate complex state coefficients 0.96∠38° and 0.74∠−156°.

The coefficients were manually digitized approximately from Fig. 2 of the source paper. They are not extracted from the CST state comparison. The model uses an independent-element array factor and excludes mutual coupling, element patterns, structural scattering, and full-wave RCS.

The maximum sidelobe is the largest sampled value on a uniform theta/phi grid outside a 15° target exclusion region. It is a grid-sampled metric, not an integrated power metric.
