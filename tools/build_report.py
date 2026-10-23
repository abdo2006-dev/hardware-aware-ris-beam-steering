"""Build a truthful validation report from saved machine-readable evidence."""
import json,pathlib,html
import pandas as pd
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet,ParagraphStyle
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,PageBreak,Table,TableStyle,Image,KeepTogether
from PIL import Image as PILImage
R=pathlib.Path(__file__).resolve().parents[1];O=R/'output'/'pdf';O.mkdir(exist_ok=True,parents=True)
S=getSampleStyleSheet();S.add(ParagraphStyle(name='BodyResearch',fontName='Helvetica',fontSize=10,leading=14,spaceAfter=8,textColor=colors.HexColor('#263b50')))
S.add(ParagraphStyle(name='CaptionResearch',fontName='Helvetica',fontSize=8,leading=11,spaceAfter=12,textColor=colors.HexColor('#52677a')))
S.add(ParagraphStyle(name='CellResearch',fontName='Helvetica',fontSize=8,leading=10))
S.add(ParagraphStyle(name='TitleResearch',fontName='Helvetica-Bold',fontSize=28,leading=33,textColor=colors.HexColor('#14334b'),spaceAfter=20))
story=[]
def p(t,style='BodyResearch'):return Paragraph(t,S[style])
def para(t):story.append(p(t))
def heading(t):story.append(p(t,'Heading1'))
def page(t):
 if story:story.append(PageBreak())
 heading(t)
def table(rows,widths=None):
 vals=[[p(html.escape(str(c)),'CellResearch') for c in row] for row in rows]
 t=Table(vals,colWidths=widths,repeatRows=1,hAlign='LEFT');t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#e6eef3')),('VALIGN',(0,0),(-1,-1),'TOP'),('LINEBELOW',(0,0),(-1,0),.7,colors.HexColor('#52677a')),('BOTTOMPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),6),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#f5f8fa')])]))
 story.append(t);story.append(Spacer(1,10))
def image(path,caption,maxh=300):
 path=R/path
 if not path.exists():para('Figure pending: '+html.escape(str(path.relative_to(R))));return
 w,h=PILImage.open(path).size;scale=min(485/w,maxh/h)
 story.append(Image(str(path),width=w*scale,height=h*scale));story.append(p(caption,'CaptionResearch'))
tests=json.loads((R/'results/validated_v2/tests.json').read_text())
M=pd.read_csv(R/'results/validated_v2/paper_digitized_reference/array_factor_metrics.csv')
T=pd.read_csv(R/'results/cst_diagnostics/simulation_summary.csv');C=pd.read_csv(R/'results/cst_diagnostics/open_short_comparison.csv')
V=json.loads((R/'results/cst_diagnostics/manifest.json').read_text())
story.append(Spacer(1,38));story.append(p('Hardware-aware RIS<br/>beam steering','TitleResearch'))
para('Scientific validation, CST diagnostics and research development')
para('Abdulrahman<br/>23 October 2026<br/>Repair branch: research/validation-and-cst-repair')
story.append(Spacer(1,20))
heading('Status and strongest supported result')
para('The analytical software passes all 15 correctness tests. Controlled CST simulations expose a strong difference between the two Floquet-mode sensitivities and substantial mesh sensitivity. Faithful reproduction of the paper remains unverified. No physical hardware measurements or finite-array CST RCS reproduction are claimed.')
table([['Gate','Status'],['MATLAB correctness and exact zero-noise identity','PASS'],['CST open / short experiments and complex export','PASS execution; PROVISIONAL physical interpretation'],['Paper Figure 2 hardware reproduction','FAIL current benchmark; cause not fully resolved'],['Mesh independence, physical polarization and diode calibration','PROVISIONAL / unresolved'],['Illustrative four-port circuit identities','PASS algebra; assumed impedances']],[345,140])
para('Reference: Goshu et al., <i>Realistic Evaluation of Impedance-Based RIS Modeling: Practical Insights and Applications</i>, EuCAP 2025. Author manuscript: https://arxiv.org/abs/2508.07098. This report distinguishes published findings, independently tested software, actual simulations and illustrative assumptions.')

page('1. Original problems and corrective evidence')
table([['Original problem','Action and present conclusion'],
['2.87-degree historical ON/OFF contrast','Retained raw data. Ran original and connected open/short diagnostics, both modes, with voltage/current and power exports. No reproduction claim.'],
['Diode model not calibrated','Reviewed MACOM datasheet, SPICE presentation and linked S2P data. Bias, exact variant and fixture de-embedding remain unresolved.'],
['Zero-noise uncertainty mismatch','Located a separate Python pipeline with a different angular grid. Shared the MATLAB evaluator and obtained exactly zero difference.'],
['Possible 400-by-400 expansion','Original MATLAB runtime actually produced a column. Added explicit reshape and 400-by-1 assertions, including rejection of a 400-by-400 array.'],
['Theta called elevation','Defined polar theta from +Z, canonical azimuth at broadside and vector-angle pointing error.'],
['Target power called peak gain','Separated target, sampled and refined peak power. Added full-hemisphere search and competing-lobe reporting.'],
['Hidden loss and unweighted grid sums','Applied a common ideal coherent reference and sin(theta) solid-angle quadrature.'],
['Missing generators and incompatible CST CSVs','Added one MATLAB entry point, raw-export converter, manifests and hashes. Preserved originals.'],
['Ground omitted from redrawn side view','Construction history and actual CAD identify a backplane. Historical schematic is superseded.'],
['Eq.1 / Eq.6 phase sign','Derived the aligning rule and directly tested both candidates. Reported the convention inconsistency without claiming the authors implemented an error.']],[150,335])

page('2. Coordinates, phase alignment and correctness')
para('Array plane XY. Polar theta is measured from +Z. Azimuth phi rotates from +X toward +Y. The steering vector is [sin(theta)cos(phi), sin(theta)sin(phi), cos(theta)]. At broadside phi=0 by convention. The independent-element array factor preserves the original phase formula.')
para('<b>Common reference:</b> every main pattern is |AF|<super>2</super>/400<super>2</super>. These are scalar array-factor power ratios, not dBi, realized gain, efficiency or RCS. Coupling and structural scattering require additional electromagnetic evidence.')
para('<b>Eq. (1) audit:</b> h<super>H</super>Phi g contains terms with phase arg(g)-arg(h)+phi. Alignment therefore requires phi=arg(h)-arg(g)+alpha. The printed Eq. (6) reverses the arguments under these definitions. Different channel conjugation conventions could change the rule; author intent remains unresolved.')
table([['Direct channel test','Magnitude'],['Aligning rule, 400 unit-magnitude deterministic channels',f"{tests['numeric_evidence']['equation1_optimum_channel_magnitude']:.12g}"],['Printed rule under the same Eq.1 definitions',f"{tests['numeric_evidence']['printed_equation6_channel_magnitude']:.12g}"],['Exact zero-noise maximum metric difference','0'],['Constant hemisphere quadrature, expected 2 pi',f"{tests['numeric_evidence']['constant_hemisphere_integral']:.10f}"]],[355,130])
para('The tests cover shapes, continuous steering, binary quantization, complex state assignment, broadside, off-axis incidence, zero perturbation, fair reference optimization, the binary mirror beam, target versus peak metrics, quadrature, complex interpolation and zero frequency offset, passivity screening, phase alignment and historical gain regressions. results/validated_v2/tests.json records all 15 passing outcomes.')

page('3. Actual CST geometry and assumptions')
views=[]
for filename,caption in [('cst/experiments/D006_connected_open/cad_current_view.png','Connected diagnostic topology: actual native perspective. Copper overlaps test connectivity and remain assumptions.'),('cst/experiments/D009_ON_strict/cad_xy_copper_section.png','Original topology: actual native XY view at the copper midplane. Separate arm, outer-patch and land boundaries remain visible.')]:
    w,h=PILImage.open(R/filename).size
    views.append([Image(str(R/filename),width=230,height=230*h/w),p(caption,'CaptionResearch')])
story.append(Table([[views[0],views[1]]],colWidths=[242.5,242.5],style=[('VALIGN',(0,0),(-1,-1),'TOP')]))
table([['Parameter','Source / implemented value','Qualification'],['Pitch GL','5.35 mm','Periodic cell'],['PL and PW','3.5 and 2.8 mm','Y extent and combined X extent; mapping provisional'],['GW, SW, SL','0.3, 2.0, 0.4 mm','Central gap and slot interpretation'],['Substrate','0.5 mm, eps_r 2.2, tan delta 0.0009','Constant material approximation'],['Copper','35 micrometres, 5.8e7 S/m','Thickness assumption; bulk material warning'],['Ground','Continuous copper plus electric Zmin','Source interpretation unresolved'],['Lumped terminals','X +/-0.15, Y=0, Z=0.5175 mm','Legacy lands touch arms only at edges']],[100,195,190])
para('Periodic X/Y and Floquet Zmax model an infinite unit-cell lattice. They do not validate finite-array edge behavior. The relevant co-polar trace must follow the actual electric-field orientation; mode number alone is insufficient.')

page('4. Controlled load experiments')
para('The four tests change one factor within each comparison. Approximate short: 0.001 ohm. Approximate open: 1e9 ohm. L=C=0. Frequency 26.168 GHz. Both original and connected topologies use the same initial-mesh protocol. These diagnostics deliberately precede tuning.')
table([['Topology','Mode','Complex difference','Phase change (deg)']]+[[r.topology,int(r['mode']),f'{r.complex_delta:.7g}',f'{r.wrapped_phase_difference_deg:.6f}'] for _,r in C.iterrows()],[150,55,140,140])
image(pathlib.Path('results/cst_diagnostics/open_short_polarization.png'),'Source: actual D003-D006 complex CST exports, run ID 1. Initial meshes. The mode sensitivity contrast is tested; Cartesian polarization still requires a verified field interpretation.',220)
para('Mode 1 is almost insensitive to the extreme load change. Mode 2 changes by about 8.46 degrees in the original model and 10.11 degrees after adding copper connections. This evidence contradicts the hypothesis that the pad connection correction alone recovers the large published phase separation. It supports further excitation and geometry investigation.')
para('Four additional explicit 0/90-degree polarization tests, D011-D014, reproduce the expected swap of the original co-polar traces with maximum complex discrepancy below 9e-9. The port u/v basis mapping therefore passes a controlled check. A valid Cartesian field extraction remains provisional; attempted native field plots returned geometry and are excluded as field evidence.')
para(f"Across completed exports, the largest relative power-balance residual is {V['maximum_abs_power_balance_relative_residual']:.3g}. The largest V-ZI relative residual is {V['maximum_VI_relative_error']:.3g}. Both reflected modes satisfy the <=1.001 passivity screen. These algebraic and balance checks do not prove mesh convergence.")

page('5. Mesh refinement and solver evidence')
image(pathlib.Path('results/cst_diagnostics/mesh_refinement.png'),'Actual adaptive history read from CST solver logs. Every point is a mesh refinement comparison at a directly solved 26.168 GHz; it is not a sweep interpolation sample.',275)
sub=T.drop_duplicates('experiment')
table([['Experiment','Tetrahedra','Passes','Final all-S change']]+[[r.experiment,int(r.final_tetrahedra),int(r.adaptive_passes),f'{r.final_all_S_delta:.6g}'] for _,r in sub.iterrows() if r.adaptive_passes>0],[235,85,55,110])
para('Project acceptance requires two consecutive refinements with complex coefficient change below 0.01, magnitude change below 0.005 and wrapped phase change below 1 degree when magnitude exceeds 0.1. The strict solver configuration uses maximum complex all-S change 0.005 for two checks, with a 12-pass cap. Individual per-pass complex traces were not exported; the bound check below certifies the specified local magnitude and phase tolerances.')
para('The final strict runs each used 11 passes: ON 46,198 tetrahedra and OFF 47,811. The last two global complex changes bound each co-polar magnitude change below 0.005. The reverse triangle inequality and a tangent-to-complex-disk phase bound give a maximum phase change below 0.224 degrees. These are derived upper bounds, not direct individual per-pass trace readings. The local numerical gate at 26.168 GHz passes; broadband and physical gates remain open.')
para('The initial adaptive ON result moved mode-1 phase to 109.43 degrees, whereas the historical result was near 87.61 degrees. The coarse mesh therefore cannot support a robust hardware interpretation. Single-frequency runs can produce a broadband sweep warning because the configured 24-30 GHz band has not been sampled; no broadband convergence follows from these runs.')

page('6. Paper benchmark and diode applicability')
image(pathlib.Path('results/cst_diagnostics/paper_reference_curves.png'),'Approximate digitization of the supplied paper, Figure 2. The generator records PDF hash, pixel calibration, legend exclusions and phase unwrapping. This is published reference data, not a CST calculation.',270)
para('At 26.168 GHz, the new approximate readings are ON magnitude 0.96383 at 35.07 degrees and OFF magnitude 0.75205 at -131.28 degrees. Estimated raster reading resolution is about 0.004 magnitude and 2 degrees phase, with additional unknown plotting and registration error. Historical manual point readings remain preserved separately.')
para('The initial adaptive CST ON/OFF mode-1 phases are 109.43 and 93.04 degrees, with magnitudes 0.98840 and 0.99092. Mode-2 phases are -27.61 and -35.57 degrees. Neither pair establishes reproduction of the approximately 166-degree paper separation. Absolute phase comparison also requires matched reference planes. The paired state separation and magnitude mismatch remain meaningful concerns.')
para('The subsequent strict ON/OFF runs give mode-1 phases 110.1873 and 110.3681 degrees, only 0.1808 degrees apart. Mode-2 phases are -27.8632 and -35.5144 degrees, 7.6512 degrees apart. Refinement therefore removes most of the historical mode-1 contrast. This is direct evidence of an unstable earlier interpretation, not recovery of the published behavior.')
para('MACOM lists a 5.2-ohm typical resistance at 10 mA / 1 GHz and 0.025-pF typical capacitance at -10 V / 1 MHz. The linked S2P archive covers 2-50 GHz but uses MA4AGP907 filenames and wafer/PCM metadata. The SPICE presentation includes a fixture and nonlinear AWR model. Exact variant equivalence and de-embedding are unresolved. Direct substitution as a gap junction would lack justification.')
para('Sources: MACOM product page and linked datasheet, SPICE presentation and S-parameter archive. Full links and test-condition notes are in docs/CST_PHYSICAL_AUDIT.md.')

page('7. Broadband and backing diagnostics')
image(pathlib.Path('results/cst_diagnostics/coarse_broadband_comparison.png'),'D015/D016 actual CST curves versus approximate published data, both modes. Eight direct frequencies: 24, 25, 26, 26.168, 27, 28, 29, 30 GHz. The 1,006 exported points include interpolation; 2,910-cell meshes are coarse and do not establish resonance or broadband convergence.',310)
para('Copying the strict checkpoint with results did not retain its adaptive mesh in the new broadband solve. The solver log, rather than the copied filename, determines this scope. Neither these curves nor the historical sweep establish Figure 2 reproduction.')
G=pd.read_csv(R/'results/cst_diagnostics/ungrounded_comparison.csv')
table([['Ground removed, 26.168 GHz','ON magnitude','OFF magnitude','Phase separation']]+[[f'Mode {int(r["mode"])}',f'{r.ON_magnitude:.5f}',f'{r.OFF_magnitude:.5f}',f'{r.phase_separation_deg:.5f} deg'] for _,r in G.iterrows()],[200,85,85,115])
para('D017/D018 remove the backplane and introduce an open bottom Floquet port as a counterfactual test. Mode-2 transmitted power fractions are 0.8895 ON and 0.8486 OFF. The changed backing affects sensitivity but does not recover the published high-reflection state pair. These initial-mesh experiments do not establish the intended paper geometry.')
para('All propagating reflected and transmitted modes enter the independent power sum. In these two-sided exports, the native curve labeled Power Outgoing all Ports omits bottom-port power. Its raw values and resulting residual remain in the CSV; the corrected modal balance includes bottom transmission. Transmission is not absorption.')

page('8. Array-model findings with common normalization')
table([['Control / data','Target (dB)','Refined peak (dB)','Pointing error (deg)']]+[[r.model.replace('_',' '),f'{r.target_gain_dB_vs_ideal_N2:.4f}',f'{r.refined_peak_gain_dB_vs_ideal_N2:.4f}',f'{r.pointing_error_deg:.4f}'] for _,r in M.iterrows()],[240,75,90,80])
image(pathlib.Path('results/validated_v2/paper_digitized_reference/principal_cut_ideal_reference.png'),'MATLAB output, approximate paper coefficients, 20x20 elements, 5.35-mm pitch, 26.168 GHz, target polar 25 / azimuth 15 degrees. Signed negative polar cut uses opposite azimuth. Every curve shares the ideal coherent power reference.',235)
para('The approximate paper states give about -5.313 dB target power compared with -3.930 dB for ideal fixed-reference binary control. Optimizing the common reference gives about -5.302 dB. The improvement is small and the competing mirror beam remains nearly equal. An outside-target-cone maximum must not be described as a conventional sidelobe without identifying competing main beams.')

page('9. Actual historical CST states and uncertainty')
image(pathlib.Path('results/validated_v2/cst_simulated_hardware_provisional/principal_cut_ideal_reference.png'),'Actual historical CST coefficient input, independently labeled provisional. The same array geometry, target and common power normalization apply. These are array-factor consequences of simulated coefficients, not a finite-array full-wave result.',255)
para('With the historical mode-1 state pair, target power is approximately -36.0 dB while the strongest lobe remains near broadside at -0.077 dB, giving about 25 degrees pointing error. Replacing these states with paper coefficients would conceal the model failure. Newly refined coefficients must pass the physical gates before supporting stronger hardware claims.')
para('The newly simulated strict pairs have also been converted with exact state/mode labels and source hashes, then evaluated by the same tested model. Fixed-reference target power is -58.727 dB for mode 1 and -27.273 dB for mode 2; refined peaks are -0.103 and -0.037 dB near broadside. These remain explicitly provisional physical datasets. They demonstrate the consequence of the actual refined coefficients without substituting paper values.')
para('Uncertainty experiments use 40 trials per setting and seed 20261022. Phase errors are independent normal variables with sigma 0, 5, 10 or 20 degrees. Multiplicative amplitude errors use sigma 0, 0.05 or 0.10, clipped to [0,1]. These are assumed sensitivity distributions, not measured fabrication statistics. CSVs include sample standard deviation, standard error, approximate normal mean confidence intervals and empirical 5th/95th percentiles. The zero-noise case reproduces the baseline exactly.')
para('A uniform polar grid requires sin(theta) weighting for a solid-angle integral. The reported hemisphere integral fraction belongs to the scalar pattern model. It does not estimate measured radiated power or device efficiency.')

page('10. Impedance-model extension and defensible scope')
image(pathlib.Path('results/validated_v2/illustrative_impedance_example/four_port_load_sweep.png'),'Illustrative four-port circuit using Eq. (7), y0=1, ZRT=0. Assumed self impedance 50+j20 ohm and adjacent mutual impedance 5+j12 ohm. No CST extraction, antenna geometry or finite-array validation is implied.',260)
para('The four-port example solves H=-zRS (ZSS+Zload)<super>-1</super> zST and compares diagonal versus coupled assumptions. The real part of the assumed reciprocal impedance matrix is positive definite. Direct residual and decomposition tests pass. The matched-load response can remain nonzero even when the load reflection coefficient is zero, illustrating the algebra of Eq. (11). Its arbitrary circuit units cannot quantify this RIS device\'s structural scattering.')
para('<b>Presentation narrative:</b> start with the failed hardware contrast, explain how reproducibility tests corrected the analytical pipeline, show actual controlled CST evidence and mesh sensitivity, then compare ideal and nonideal states using common normalization. End with unresolved physical assumptions and the next discriminating experiment. The paper\'s full-wave impedance optimization remains a distinct benchmark.')
para('<b>Defensible CV wording:</b> Developed and tested a reproducible MATLAB study of nonideal binary RIS reflection states; performed CST 2023 periodic unit-cell load diagnostics, complex S-parameter export and mesh-refinement investigations, with traceable assumptions and numerical evidence.')
para('<b>Limitations:</b> no physical measurements, validated finite-array RCS, calibrated exact diode model, confirmed broadband paper reproduction or demonstrated structural-scattering suppression. The 16-GB laptop constrains large-array work but does not by itself prove a small-array calculation impossible.')

page('11. Reproduction, files and continuation gates')
para('In MATLAB from the repository root: <font face="Courier">addpath(fullfile(pwd,\'matlab\')); run_research();</font>. The test gate runs first. Analytical outputs use results/validated_v2. Original results and validated_v1 remain historical. SHA-256 manifests identify inputs, generators and outputs. The Windows .NET hashing helper is a portability constraint.')
table([['Location','Purpose'],['matlab/ris_core.m and run_validation_tests.m','Shared coefficient, direction, interpolation and metric functions with 15 tests'],['matlab/run_research.m','Single analytical reproduction entry point'],['matlab/convert_cst_exports.m','Historical raw CST exports to complex state schema'],['cst/native_diagnostic.py','Versioned CST automation and controlled experiments'],['cst/export_diagnostic.py','Read saved S, V/I, losses and residual curves'],['tools/digitize_figure2.py','Approximate published curves and calibration metadata'],['tools/analyze_diagnostics.py','CST evidence tables and source hashes'],['docs/CST_PHYSICAL_AUDIT.md','Source mapping, manufacturer qualification and convergence contract'],['docs/SCIENTIFIC_VALIDATION.md','Coordinate, metric, equation and uncertainty audit']],[240,245])
para('New native CST archives remain preserved locally because they embed licensing metadata. The public branch provides construction histories, configurations and numerical exports. Required continuation gates: verify physical Floquet polarization using a valid field extraction; compare strict adaptive coefficients between saved refinements; test material representation if bulk copper remains numerically problematic; bracket and directly solve relevant resonances; resolve source geometry and diode fixture assumptions. Only then promote a CST state dataset to verified hardware input. Main remains unchanged until justified review and validation.')
def footer(c,d):
 c.setFont('Helvetica',8);c.setFillColor(colors.HexColor('#52677a'));c.drawString(48,28,'RIS scientific validation - 23 October 2026');c.drawRightString(A4[0]-48,28,str(d.page))
doc=SimpleDocTemplate(str(O/'RIS_Scientific_Validation_Report.pdf'),pagesize=A4,rightMargin=48,leftMargin=48,topMargin=43,bottomMargin=45,title='RIS Scientific Validation and CST Diagnostics',author='Abdulrahman')
doc.build(story,onFirstPage=footer,onLaterPages=footer)
print(O/'RIS_Scientific_Validation_Report.pdf')
