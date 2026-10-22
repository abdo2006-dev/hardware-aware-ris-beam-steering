# Hardware-Aware RIS Beam Steering

I built a periodic unit-cell model in CST Studio Suite 2023 and paired it with a MATLAB array-factor study to examine how practical reflection states affect reconfigurable intelligent surface (RIS) beam steering. The project connects a full-wave periodic-cell simulation with a separate analytical 20 × 20 array model.

> **Main finding:** The provisional CST ON-proxy and assumed OFF load pair produces almost no reflection-magnitude contrast. The present model is a documented simulation study, not a calibrated PIN-diode design or a validated full-wave array prediction.

## Study overview

| Workstream | Model | Key result |
|---|---|---|
| CST unit cell | Periodic patch cell on RT/duroid 5880; series RLC bridge; two Floquet modes; 24–30 GHz frequency-domain solver | OFF run completed with 8 calculated broadband samples, 1,001 interpolated sweep points, and a 4,682-tetrahedron final mesh |
| ON/OFF comparison | Baseline R=5.2 Ω, L=30 pH, C=0 proxy versus assumed OFF R=0 Ω, L=30 pH, C=25 fF | At 26.166 GHz, S11 magnitudes differ by −0.00238 dB; maximum difference across the sweep is 0.00372 dB |
| MATLAB array factor | 20 × 20 independent-element array, target (theta,phi)=(25°,15°) | Hardware-aware one-bit case has −5.40 dB peak gain relative to ideal N² and a −10.69 dB maximum sampled sidelobe |
| Numerical cross-check | MATLAB R2026b compared with an independent Python implementation | Maximum absolute baseline output difference: 3.91 × 10⁻¹⁴ |

## CST unit-cell model

I represented the element as a square periodic cell with a 5.35 mm pitch on a 0.5 mm RT/duroid 5880 substrate (relative permittivity 2.2, loss tangent 0.0009). The pattern consists of two patch regions, a central gap, and a slot. The model uses PL=3.5 mm, PW=2.8 mm, GW=0.3 mm, a 2.0 mm × 0.4 mm slot, 35 µm copper, and a 0.1 mm terminal width. The patch-axis mapping is a visual interpretation of the source figure; copper thickness and terminal dimensions are provisional where the source does not provide fabrication detail.

I used periodic boundaries in X and Y, an electric boundary at Zmin, and an expanded-open boundary at Zmax. The excitation uses two Floquet modes at normal incidence. I ran the CST high-frequency frequency-domain solver over 24–30 GHz with an adaptive broadband sweep.

Two series-load scenarios are retained:

- **Baseline / ON proxy:** R=5.2 Ω, L=30 pH, C=0. It reuses the baseline result and is not a separately measured or fitted diode ON state.
- **Illustrative OFF scenario:** R=0 Ω, L=30 pH, C=25 fF. The 25 fF capacitance is an assumption; the source paper does not specify it.

### CST checks and interpretation

CST reported that solver and postprocessing completed for the OFF scenario. At the eight calculated samples, stimulated power equaled outgoing plus accepted power to a maximum residual of 2.78 × 10⁻¹⁷ W. Accepted power differed from dielectric plus metal loss by at most 2.25 × 10⁻⁶ W (about 4.6 ppm of the 0.5 W excitation).

These checks show that the exported power accounting is internally consistent. They do not establish mesh independence: only one adaptive mesh level is documented. The 1,001 plotted sweep points are interpolated from eight calculated samples, not 1,001 independent full-wave solutions.

At the sample nearest 26.168 GHz, the baseline S11 magnitude is −0.0735 dB and the assumed OFF S11 magnitude is −0.0759 dB. Their difference is too small to demonstrate useful switching contrast in this implementation. Because the OFF capacitance is assumed and the baseline is only a proxy, this is a model diagnostic rather than a claim about a physical diode or fabricated surface.

## MATLAB array-factor study

I compared ideal continuous phase control, ideal one-bit control, and a hardware-aware one-bit assignment for a 20 × 20 array at 26.168 GHz with a 5.35 mm pitch, normal incidence, and target direction (25°,15°). The hardware-aware coefficients were approximately digitized from Fig. 2 of the source paper near 26.168 GHz: state 0 is 0.96∠38° and state 1 is 0.74∠−156°. These figure readings are not calibrated from the CST state comparison.

| Phase-control case | Pointing error on 1° grid | Peak gain vs. ideal N² | Maximum sampled sidelobe |
|---|---:|---:|---:|
| Ideal continuous | 0° | 0.00 dB | −17.64 dB |
| Ideal one-bit | 0° | −3.93 dB | −16.46 dB |
| Approximate hardware-aware one-bit | 0° | −5.40 dB | −10.69 dB |

The sidelobe is the largest grid-sampled value outside a 15° exclusion region; it is not an integrated sidelobe-power metric. The independent-element array factor excludes mutual coupling, element patterns, structural scattering, and full-wave array or RCS effects.

The seeded uncertainty sweep uses 40 trials for each case. I also corrected a 2° angular sampling grid to 1° after its zero-perturbation case showed grid quantization. The corrected target case reports zero grid-sampled pointing error; this improves angular resolution, not physical-model accuracy.

## Limitations and next steps

Before making hardware or performance claims, I would confirm the patch-axis assignment and lumped-element terminal connectivity in CST, verify Floquet polarization and mode assignments, replace the assumed OFF capacitance and proxy ON load with a frequency-appropriate device/package model or measured impedance, and compare at least two independently refined meshes. I would also review the CST copper-material warning against an appropriate lossy-metal formulation and rerun an independently saved ON state. A full-wave array model is needed for mutual coupling, element patterns, or RCS.

CST reported a reduced-performance tbbmalloc warning and a high-reflection sample at 30 GHz that did not move the mesh-adaptation sample. The run completed, but those warnings remain part of its context.

## References

1. A. L. Goshu, P. Mursia, V. Sciancalepore, M. Di Renzo, and X. Costa-Pérez, “Realistic Evaluation of Impedance-Based RIS Modeling: Practical Insights and Applications,” *2025 19th European Conference on Antennas and Propagation (EuCAP)*, 2025. [DOI: 10.23919/EuCAP63536.2025.10999979](https://doi.org/10.23919/EuCAP63536.2025.10999979); [arXiv:2508.07098](https://arxiv.org/abs/2508.07098). The paper itself is not redistributed here.
2. MACOM, [MADP-000907-14020x data sheet](https://cdn.macom.com/datasheets/MADP-000907-14020x.pdf). Its test-condition values do not by themselves establish a packaged-diode equivalent circuit at 26 GHz.
3. Rogers Corporation, [RT/duroid 5870/5880 data sheet](https://www.rogerscorp.com/-/media/project/rogerscorp/documents/advanced-electronics-solutions/english/data-sheets/rt-duroid-5870---5880-data-sheet.pdf).
4. Dassault Systèmes, [CST Studio Suite](https://www.3ds.com/products/simulia/cst-studio-suite).
