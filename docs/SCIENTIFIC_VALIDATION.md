# Scientific validation and scope

This document supersedes the historical numerical interpretations on the repair
branch. Historical CSVs and CST checkpoints remain unchanged. Software correctness
and electromagnetic validity are separate acceptance gates.

## Coordinate and normalization contract

The array lies in XY with outward surface normal +Z. Polar angle theta is measured
from +Z. Azimuth phi rotates from +X toward +Y. The direction vector is
`[sin(theta) cos(phi), sin(theta) sin(phi), cos(theta)]`. At broadside the canonical
azimuth is zero; pointing error is the spherical angle between unit vectors.

The preserved array factor is
`AF(s) = sum_m Gamma_m exp(j k r_m dot (s - s_inc))`.
The continuous target phase is `-k r_m dot (s_target - s_inc)`.
Every configuration has exactly 400 complex coefficients in a 400-by-1 column.

All main figures use `|AF|^2 / 400^2`. These are scalar array-factor power ratios,
not dBi, realized gain, radiation efficiency, measured power, or RCS. The independent
element approximation omits coupling, embedded element patterns, edge effects,
load-dependent reradiation and structural scattering.

## Metrics

* Target power: evaluated at the exact requested direction.
* Sampled maximum: full forward hemisphere, theta 0:1:90, phi -180:1:179 degrees.
* Refined maximum: local numerical refinement from the four strongest separated
  sampled lobes and target. This is not a proof of the continuous global optimum.
* Pointing error: angular separation of strongest refined direction and target.
  Equivalent maxima are reported; an equally strong mirror beam is not a clean
  single steering solution.
* Outside-cone maximum: largest sampled level outside a 15-degree spherical cone
  around the target. This includes competing main beams and must not automatically
  be called a conventional sidelobe level.
* Principal-cut sidelobe: supplementary signed polar cut at target azimuth; nearest
  sampled minima delimit the target lobe. This cut cannot characterize every lobe.
* Pattern integral fraction: trapezoidal theta quadrature with sin(theta), periodic
  phi quadrature. This is the integral of this scalar pattern over a hemisphere,
  not a full electromagnetic power budget.

## Independent equation audit

For the paper's Eq. (1), `h^H Phi g`, term m is
`|h_m||g_m| exp(j[arg(g_m)-arg(h_m)+phi_m])`.
The triangle-inequality upper bound is attained by
`phi_m = arg(h_m)-arg(g_m)+alpha`, with any common alpha.
The printed Eq. (6) reverses those two arguments. With the same h, g and conjugate
transpose in Eq. (1), the printed rule does not generally align the terms.

The runnable test uses 400 deterministic unit-magnitude complex channels and
directly multiplies `h' * (exp(1i*phi).*g)`. The aligning rule gives magnitude
400; the printed rule gives 8.051739918193988. This demonstrates an inconsistency
under the stated algebraic definitions. A differently defined channel conjugation
could change the rule; the authors' intended convention is unresolved. This is
not a claim that the paper's implementation used the wrong sign.

## Original uncertainty discrepancy

A fresh run of the original MATLAB script reproduced -5.4000021579367 dB target
power at zero perturbation. The suspected 400-by-400 MATLAB expansion was not
observed: indexing the original row state vector with a vector retains row shape,
and its transpose is a column. Explicit reshape and assertions now remove reliance
on that indexing behavior.

The checked-in uncertainty CSV came from a separate Python generator outside the
repository. That generator used a 2-degree uncertainty grid and 1-degree baseline
grid. The repaired pipeline shares its coefficients, operator and metric evaluator
and reports exactly zero maximum difference at zero perturbation. Forty trials per
setting use seed 20261022; distributions are assumed independent normal phase and
multiplicative amplitude errors, with amplitudes clipped to [0,1]. Mean confidence
intervals are approximate and the distributions are not fabrication measurements.

## Interpreting the repaired analytical results

At 26.168 GHz, target polar 25 / azimuth 15 degrees:

| Input / control | Target power (dB) | Refined peak (dB) | Pointing error |
|---|---:|---:|---:|
| Ideal continuous | 0 | 0 | 0 degrees |
| Ideal binary, fixed reference | -3.9296 | -3.9246 | 0.1200 degrees |
| Digitized paper curves, fixed reference | -5.3126 | -5.3124 | 0.0265 degrees |
| Digitized paper curves, optimized reference | -5.3022 | -5.3002 | 0.0734 degrees |
| Historical CST states, fixed reference | -35.999 | -0.07735 | 25 degrees |

All values use the common ideal coherent reference. The binary mirror lobe is
nearly equal to the target lobe. Optimizing the common phase reference marginally
improves target power but does not eliminate that competing lobe. For the historical
CST states the strongest response remains near broadside; attractive paper-state
patterns cannot establish that this CST model steers successfully.

`paper_digitized_reference` contains a new approximate color-curve digitization
of Figure 2, with PDF hash, pixel calibration, legend exclusions and unwrapped
phase resampling. At 26.168 GHz the readings are approximately 0.963831 at 35.0711
degrees and 0.752053 at -131.2758 degrees. Estimated raster reading resolution is
0.004 magnitude and 2 degrees, not a statistical confidence interval. The full
reference covers 24.1-29.9 GHz. It remains provisional.

Historical manual single-point readings (0.96 at 38 degrees; 0.74 at -156 degrees)
are preserved in `data/historical_approx_point` and their outputs in `validated_v1`.
They gave a different strongest mirror-beam choice, emphasizing that pointing-error
statistics are fragile when two competing beams are almost equally strong.

`cst_simulated_hardware` contains actual historical
simulation coefficients, also provisional pending physical and convergence checks.
No simulated hardware is replaced by paper or ideal coefficients.

## Reproduction

From the repository root, in licensed MATLAB R2026b on Windows:

```matlab
addpath(fullfile(pwd,'matlab'));
run_research();
```

The entry point runs the test gate, converts the unchanged CST exports, creates
the explicitly approximate paper dataset and regenerates the analytical figures,
sweeps, CSVs and SHA-256 manifests under `results/validated_v2`. The digitized input
is checked in; regenerate it from a local paper copy using
`tools/digitize_figure2.py --pdf <file> --pdftoppm <executable>` when needed. SHA-256 currently
uses Windows .NET. CST execution is separate and requires licensed CST 2023 plus
its bundled Python runtime. These software tests do not certify CST convergence.
