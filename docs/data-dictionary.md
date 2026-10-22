# Result data dictionary

| File | Contents |
|---|---|
| cst_baseline_complex_sparameters.csv | Baseline CST complex S-parameter export across the 24–30 GHz sweep |
| cst_off_assumed_25fF_complex_sparameters.csv | OFF-scenario CST complex S-parameter export; 25 fF is assumed |
| cst_on_off_comparison.csv | Interpolated comparison between the baseline ON proxy and assumed OFF scenario |
| array_factor_metrics.csv | Summary metrics for ideal continuous, ideal one-bit and approximate hardware-aware one-bit cases |
| target_angle_sweep.csv | Array-factor target-angle sweep |
| uncertainty_sensitivity.csv | Seeded phase/amplitude perturbation metrics; 40 trials per case |
| phase_separation_sensitivity.csv | Sensitivity to complex-state phase separation |
| frequency_sensitivity.csv | Analytical sensitivity to frequency-dependent coefficient slopes; slopes are hypothetical inputs, not CST-extracted slopes |

## CST S-parameter columns

The complex exports identify frequency and real/imaginary components for the two-port Floquet S-parameter matrix. The values are CST-normalized modal quantities. The 1,001 displayed sweep points are interpolated from eight calculated broadband samples; they are not 1,001 independent full-wave solutions.
