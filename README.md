# Hardware-Aware RIS Beam Steering

I built a CST Studio Suite 2023 unit-cell model and paired it with a MATLAB array-factor study to examine how practical reflection states affect reconfigurable intelligent surface (RIS) steering. The work combines a periodic full-wave cell simulation with a separate analytical 20 × 20 array model.

The main engineering result is a useful negative one: the current provisional CST load pair produces almost no ON/OFF reflection-magnitude contrast. The model documents a working simulation workflow and its limits; it does **not** establish a calibrated PIN-diode model or a validated full-wave array prediction.

## Project at a glance

| Area | Implemented | Evidence |
|---|---|---|
| CST unit cell | Periodic patch cell on RT/duroid 5880; discrete series RLC bridge; two Floquet modes; 24–30 GHz frequency-domain solver | Native CST projects and complex S-parameter exports in [cst/](cst/) and [results/](results/) |
| OFF-state scenario | R=0 ohm, L=30 pH, C=25 fF | 1,001-point interpolated S-parameter export; 8 calculated broadband samples |
| MATLAB array study | 20 × 20 independent-element array, target (theta,phi)=(25°,15°) | MATLAB source, array-factor figures, metrics and sensitivity CSV files |
| Independent numerical check | MATLAB R2026b outputs compared against a separate Python implementation | Maximum absolute difference 3.91e-14 for baseline array-factor outputs |

## What I built

### CST periodic unit cell

I represented the RIS element as a square periodic cell with a 5.35 mm lattice pitch. The cell uses a 0.5 mm RT/duroid 5880 substrate with relative permittivity 2.2 and loss tangent 0.0009. The copper pattern uses two patch regions, a central gap, and a slot. The working dimensions are documented in [docs/model-and-methods.md](docs/model-and-methods.md).

I set periodic boundaries in the in-plane X and Y directions, an electric boundary at Zmin, and an expanded-open boundary at Zmax. The excitation uses two Floquet modes at normal incidence. I used the CST high-frequency frequency-domain solver over 24–30 GHz with an adaptive broadband sweep.

I retained two separate load scenarios:

- **Baseline / ON proxy:** series R=5.2 ohm, L=30 pH, C=0. This is a provisional proxy, not a dedicated measured ON-state diode fit.
- **Illustrative OFF scenario:** series R=0 ohm, L=30 pH, C=25 fF. The 25 fF value is an explicit assumption; the paper does not specify it.

### MATLAB array-factor study

I used MATLAB to compare ideal continuous phase control, ideal one-bit control, and a hardware-aware one-bit case for a 20 × 20 array. The hardware-aware state coefficients were approximately digitized from the source paper’s Fig. 2 near 26.168 GHz:

- State 0: 0.96∠38°
- State 1: 0.74∠−156°

These are approximate figure readings, not complex reflection coefficients calibrated from the CST runs. The MATLAB model is an analytical array factor. It excludes mutual coupling, element patterns, structural scattering, and full-wave array or RCS effects.

## Results

### CST solver and export

For the OFF scenario, CST reported completion of solver and postprocessing. The adaptive broadband run calculated eight frequency samples and produced a 1,001-point interpolated sweep from 24 to 30 GHz. The final displayed mesh contained 4,682 tetrahedra.

The power accounting was internally consistent at the calculated samples: stimulated power equaled outgoing plus accepted power to a maximum absolute residual of 2.78e-17 W. Accepted power differed from dielectric plus metal loss by at most 2.25e-6 W, about 4.6 ppm of the 0.5 W excitation used in the audit.

These checks validate bookkeeping in the exported results. They do not prove mesh independence. Only one adaptive mesh level is documented, so a separate mesh-refinement comparison remains outstanding.

### ON-proxy versus assumed OFF state

At the nearest exported sample to 26.168 GHz (26.166 GHz), the fundamental-mode S11 magnitudes were:

| Quantity | Result |
|---|---:|
| Baseline ON-proxy S11 | −0.0735 dB |
| Assumed OFF S11 | −0.0759 dB |
| OFF minus ON-proxy difference | −0.00238 dB |
| Maximum magnitude difference across 24–30 GHz | 0.00372 dB |

This pair does not show useful reflection-magnitude separation in the current model. Because the OFF capacitance is assumed and the baseline is only an ON proxy, this result should be treated as a modeling diagnostic—not a claim about the actual diode or fabricated RIS.

### Array-factor metrics

At the (25°,15°) target, all three array-factor cases place the sampled peak at the target on the 1° direction grid. The peak gain is normalized to the ideal continuous-phase N² reference.

| Phase-control case | Pointing error | Peak gain vs. ideal N² | Maximum sampled sidelobe |
|---|---:|---:|---:|
| Ideal continuous | 0° | 0.00 dB | −17.64 dB |
| Ideal one-bit | 0° | −3.93 dB | −16.46 dB |
| Approximate hardware-aware one-bit | 0° | −5.40 dB | −10.69 dB |

The sidelobe value is the largest grid-sampled value outside a 15° exclusion region. It is not an integrated sidelobe-power measure. The hardware-aware case has a lower peak and higher sampled sidelobes than the ideal cases, consistent with the unequal amplitudes and non-ideal phase separation of the approximate states.

![Array-factor comparison](figures/array_factor_azimuth_cut.png)

*Normalized azimuth cut at theta=25°, produced by the MATLAB model.*

![Array-factor pattern](figures/array_factor_2d.png)

*Two-dimensional normalized array-factor visualization.*

## Verification performed

I checked the work at several levels:

1. CST completed the OFF-state solver and postprocessing run and exported complex two-mode S-parameters over 24–30 GHz.
2. The CST power-balance identity closed to roundoff at its calculated broadband samples.
3. The array-factor baseline was independently recomputed in Python; its maximum absolute difference from MATLAB R2026b output was 3.91e-14.
4. Six target-angle cases and twelve uncertainty cases were exported. The random uncertainty sweep uses 40 trials per case with a fixed seed for repeatability.
5. The zero-perturbation uncertainty row exposed a direction-grid quantization issue in an earlier 2° grid. I changed the grid to 1° and reran the analysis; the target case then reported zero grid-sampled pointing error. This improves angular sampling, not physical-model accuracy.

## Limitations and next engineering steps

Before making hardware or performance claims, I would:

- Inspect the cell geometry and confirm axis assignments against the source drawing.
- Verify that the lumped RLC terminals bridge the intended pads and that the Floquet mode and polarization assignments match the intended excitation.
- Replace the assumed OFF capacitance and proxy ON load with a frequency-appropriate device/package model or measured complex impedance.
- Refine the mesh around the slot, gap, and lumped bridge, then compare results across at least two independently refined meshes.
- Review CST’s copper-material warning and compare a suitable lossy-metal formulation.
- Re-run an independently saved ON state and compare its complex reflection coefficient against measured or vendor-supported data.
- Use a full-wave array model if mutual coupling, element patterns, or RCS are needed.

CST also reported a reduced-performance tbbmalloc warning and a high-reflection sample at 30 GHz that did not move the mesh-adaptation sample. Those warnings did not prevent the recorded run from completing, but they remain part of the run context.

## Repository contents

- [cst/](cst/) — baseline, OFF-scenario, and mesh-check CST project files.
- [matlab/ris_array_model.m](matlab/ris_array_model.m) — analytical array-factor model.
- [results/](results/) — exported complex S-parameters, state comparison, angle sweep, and sensitivity data.
- [figures/](figures/) — array-factor figures.
- [docs/model-and-methods.md](docs/model-and-methods.md) — geometry, materials, solver setup, definitions, and data provenance.
- [docs/references.md](docs/references.md) — source-paper and manufacturer references.
- [docs/data-dictionary.md](docs/data-dictionary.md) — definitions for the exported result files.



## Reproducing the MATLAB study

With MATLAB R2019b or later, run from the repository root:

    addpath("matlab")
    results = ris_array_model();

The script writes the summary metrics and plots to results/. The default hardware-state coefficients are the approximate paper-figure values described above. To use a CST export, provide a CSV with columns frequency_GHz,state,real,imag containing at least two frequency samples for each state:

    results = ris_array_model("path/to/complex_reflection.csv");

The CST CSV files in this repository contain multi-mode S-parameters. They are not directly in the single-reflection-state input format expected by this optional path; select and map the intended mode and state data before using them.

## References

See [docs/references.md](docs/references.md) for full citations and links.

