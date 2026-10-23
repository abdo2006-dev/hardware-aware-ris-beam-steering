'# MWS Version: Version 2023.0 - Sep 12 2022 - ACIS 32.0.1 -

'# length = mm
'# frequency = GHz
'# time = ns
'# frequency range: fmin = 24 fmax = 30
'# created = '[VERSION]2023.0|32.0.1|20220912[/VERSION]


'@ Smoke test parameter

'[VERSION]2023.0|32.0.1|20220912[/VERSION]
StoreDoubleParameter "smoke", 1.0

'@ Remove scratch parameter

'[VERSION]2023.0|32.0.1|20220912[/VERSION]
DeleteParameter "smoke"

'@ Build RIS impedance unit cell and frequency-domain setup

'[VERSION]2023.0|32.0.1|20220912[/VERSION]
DeleteParameter "smoke"
StoreDoubleParameter "pitch", 5.35
StoreDoubleParameter "patch_width", 2.8
StoreDoubleParameter "patch_length", 3.5
StoreDoubleParameter "center_gap", 0.3
StoreDoubleParameter "slot_length", 2.0
StoreDoubleParameter "slot_width", 0.4
StoreDoubleParameter "substrate_thickness", 0.5
StoreDoubleParameter "copper_thickness", 0.035
StoreDoubleParameter "terminal_width", 0.1
StoreDoubleParameter "Rload", 0
StoreDoubleParameter "Lload", 30e-12
StoreDoubleParameter "Cload", 25e-15
SetParameterDescription "pitch", "Unit-cell pitch (paper interpretation), mm"
SetParameterDescription "Rload", "Illustrative PIN OFF series resistance, ideal-open approximation, ohm"
SetParameterDescription "Lload", "Illustrative diode series inductance, H"
SetParameterDescription "Cload", "PIN OFF-state series capacitance, assumed 25 fF; not specified by paper"

With Units
    .Geometry "mm"
    .Frequency "ghz"
    .Time "ns"
End With

With Material
    .Reset
    .Name "RT_duroid_5880"
    .FrqType "hf"
    .Type "Normal"
    .Epsilon "2.2"
    .Mu "1.0"
    .Kappa "0.0"
    .TanD "0.0009"
    .TanDFreq "10"
    .TanDGiven "True"
    .TanDModel "ConstTanD"
    .KappaM "0.0"
    .TanDM "0.0"
    .TanDMFreq "0.0"
    .TanDMGiven "False"
    .DispModelEps "None"
    .DispModelMu "None"
    .Create
End With

With Material
    .Reset
    .Name "Copper_5p8e7S_per_m"
    .FrqType "hf"
    .Type "Normal"
    .Epsilon "1.0"
    .Mu "1.0"
    .Kappa "5.8e7"
    .TanD "0.0"
    .TanDGiven "False"
    .TanDModel "ConstTanD"
    .DispModelEps "None"
    .DispModelMu "None"
    .Create
End With

With Brick
    .Reset
    .Name "duroid_substrate"
    .Component "substrate"
    .Material "RT_duroid_5880"
    .Xrange "-pitch/2", "pitch/2"
    .Yrange "-pitch/2", "pitch/2"
    .Zrange "0", "substrate_thickness"
    .Create
End With

With Brick
    .Reset
    .Name "continuous_backplane"
    .Component "metallization"
    .Material "Copper_5p8e7S_per_m"
    .Xrange "-pitch/2", "pitch/2"
    .Yrange "-pitch/2", "pitch/2"
    .Zrange "-copper_thickness", "0"
    .Create
End With

' Left outer patch region beyond the horizontal slot.
With Brick
    .Reset
    .Name "left_outer"
    .Component "top_patch"
    .Material "Copper_5p8e7S_per_m"
    .Xrange "-patch_width/2", "-slot_length/2"
    .Yrange "-patch_length/2", "patch_length/2"
    .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
    .Create
End With

' Left upper and lower arms; the gap between them is the horizontal slot.
With Brick
    .Reset
    .Name "left_upper"
    .Component "top_patch"
    .Material "Copper_5p8e7S_per_m"
    .Xrange "-slot_length/2", "-center_gap/2-terminal_width"
    .Yrange "slot_width/2", "patch_length/2"
    .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
    .Create
End With
With Brick
    .Reset
    .Name "left_lower"
    .Component "top_patch"
    .Material "Copper_5p8e7S_per_m"
    .Xrange "-slot_length/2", "-center_gap/2-terminal_width"
    .Yrange "-patch_length/2", "-slot_width/2"
    .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
    .Create
End With

' Inner solder land keeps the upper/lower arms connected at the diode terminal.
With Brick
    .Reset
    .Name "left_diode_land"
    .Component "top_patch"
    .Material "Copper_5p8e7S_per_m"
    .Xrange "-center_gap/2-terminal_width", "-center_gap/2"
    .Yrange "-slot_width/2", "slot_width/2"
    .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
    .Create
End With

With Brick
    .Reset
    .Name "right_diode_land"
    .Component "top_patch"
    .Material "Copper_5p8e7S_per_m"
    .Xrange "center_gap/2", "center_gap/2+terminal_width"
    .Yrange "-slot_width/2", "slot_width/2"
    .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
    .Create
End With

With Brick
    .Reset
    .Name "right_upper"
    .Component "top_patch"
    .Material "Copper_5p8e7S_per_m"
    .Xrange "center_gap/2+terminal_width", "slot_length/2"
    .Yrange "slot_width/2", "patch_length/2"
    .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
    .Create
End With
With Brick
    .Reset
    .Name "right_lower"
    .Component "top_patch"
    .Material "Copper_5p8e7S_per_m"
    .Xrange "center_gap/2+terminal_width", "slot_length/2"
    .Yrange "-patch_length/2", "-slot_width/2"
    .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
    .Create
End With
With Brick
    .Reset
    .Name "right_outer"
    .Component "top_patch"
    .Material "Copper_5p8e7S_per_m"
    .Xrange "slot_length/2", "patch_width/2"
    .Yrange "-patch_length/2", "patch_length/2"
    .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
    .Create
End With

' R-L-C series load approximates the diode ON state at the 26.168 GHz reference point.
With LumpedElement
    .Reset
    .SetName "PIN_ON_series_RL"
    .SetType "RLCSerial"
    .SetR "Rload"
    .SetL "Lload"
    .SetC "Cload"
    .SetGs "0"
    .SetI0 "0"
    .SetT "0"
    .SetP1 "False", "-center_gap/2", "0", "substrate_thickness+copper_thickness/2"
    .SetP2 "False", "center_gap/2", "0", "substrate_thickness+copper_thickness/2"
    .SetInvert "False"
    .SetMonitor "False"
    .Create
End With

With Background
    .Type "Normal"
    .Epsilon "1.0"
    .Mu "1.0"
End With

StoreDoubleParameter "theta", 0
StoreDoubleParameter "phi", 0
SetParameterDescription "theta", "Floquet plane-wave incidence angle from broadside, degrees"
SetParameterDescription "phi", "Floquet plane-wave azimuth, degrees"

With Boundary
    .Xmin "unit cell"
    .Xmax "unit cell"
    .Ymin "unit cell"
    .Ymax "unit cell"
    .Zmin "electric"
    .Zmax "expanded open"
    .Xsymmetry "none"
    .Ysymmetry "none"
    .Zsymmetry "none"
    .XPeriodicShift "0.0"
    .YPeriodicShift "0.0"
    .ZPeriodicShift "0.0"
    .PeriodicUseConstantAngles "False"
    .SetPeriodicBoundaryAngles "theta", "phi"
    .SetPeriodicBoundaryAnglesDirection "inward"
    .UnitCellFitToBoundingBox "True"
    .UnitCellDs1 "0.0"
    .UnitCellDs2 "0.0"
    .UnitCellAngle "90.0"
End With

With FloquetPort
    .Reset
    .SetDialogTheta "0"
    .SetDialogPhi "0"
    .SetSortCode "+beta/pw"
    .SetCustomizedListFlag "False"
    .Port "Zmax"
    .SetNumberOfModesConsidered "2"
End With

Solver.FrequencyRange "24", "30"
ChangeSolverType("HF Frequency Domain")
With FDSolver
    .Reset
    .Stimulation "List", "List"
    .ResetExcitationList
    .AddToExcitationList "Zmax", "TE(0,0);TM(0,0)"
    .LowFrequencyStabilization "False"
End With
With Mesh
    .MeshType "Tetrahedral"
End With
' project setup complete; solver is started as a separate checkpoint after validation.
'Use the 24-30 GHz Floquet reflection sweep to check both fundamental polarizations.
'
'AddToHistory returns True only if the model history is accepted by CST.
'This macro uses paper dimensions where available and explicit assumptions for copper and the diode.
'The 5.35 mm pitch, pad lands, copper thickness, and series R-L load need model validation against the drawing.
'No claim of a converged result is made until the solver completes.
SetParameterDescription "patch_width", "Figure 1 patch-pair overall width, mm; interpretation"
SetParameterDescription "patch_length", "Figure 1 patch length, mm; interpretation"
SetParameterDescription "center_gap", "Figure 1 patch separation, mm; interpretation"
SetParameterDescription "slot_length", "Figure 1 horizontal slot length, mm; interpretation"
SetParameterDescription "slot_width", "Figure 1 horizontal slot width, mm; interpretation"
SetParameterDescription "substrate_thickness", "Paper Table I; mm"
SetParameterDescription "copper_thickness", "Engineering assumption; 35 um copper"

'@ define frequency domain solver parameters

'[VERSION]2023.0|32.0.1|20220912[/VERSION]
Mesh.SetCreator "High Frequency" 

With FDSolver
     .Reset 
     .SetMethod "Tetrahedral", "General purpose" 
     .OrderTet "Second" 
     .OrderSrf "First" 
     .Stimulation "List", "List" 
     .ResetExcitationList 
     .AddToExcitationList "Zmax", "TE(0,0);TM(0,0)" 
     .AutoNormImpedance "False" 
     .NormingImpedance "50" 
     .ModesOnly "False" 
     .ConsiderPortLossesTet "True" 
     .SetShieldAllPorts "False" 
     .AccuracyHex "1e-6" 
     .AccuracyTet "1e-4" 
     .AccuracySrf "1e-3" 
     .LimitIterations "False" 
     .MaxIterations "0" 
     .SetCalcBlockExcitationsInParallel "True", "True", "" 
     .StoreAllResults "False" 
     .StoreResultsInCache "False" 
     .UseHelmholtzEquation "True" 
     .LowFrequencyStabilization "False" 
     .Type "Auto" 
     .MeshAdaptionHex "False" 
     .MeshAdaptionTet "True" 
     .AcceleratedRestart "True" 
     .FreqDistAdaptMode "Distributed" 
     .NewIterativeSolver "True" 
     .TDCompatibleMaterials "False" 
     .ExtrudeOpenBC "False" 
     .SetOpenBCTypeHex "Default" 
     .SetOpenBCTypeTet "Default" 
     .AddMonitorSamples "True" 
     .CalcPowerLoss "True" 
     .CalcPowerLossPerComponent "False" 
     .StoreSolutionCoefficients "True" 
     .UseDoublePrecision "False" 
     .UseDoublePrecision_ML "True" 
     .MixedOrderSrf "False" 
     .MixedOrderTet "False" 
     .PreconditionerAccuracyIntEq "0.15" 
     .MLFMMAccuracy "Default" 
     .MinMLFMMBoxSize "0.3" 
     .UseCFIEForCPECIntEq "True" 
     .UseEnhancedCFIE2 "True" 
     .UseFastRCSSweepIntEq "false" 
     .UseSensitivityAnalysis "False" 
     .UseEnhancedNFSImprint "False" 
     .UseFastDirectFFCalc "False" 
     .RemoveAllStopCriteria "Hex"
     .AddStopCriterion "All S-Parameters", "0.01", "2", "Hex", "True"
     .AddStopCriterion "Reflection S-Parameters", "0.01", "2", "Hex", "False"
     .AddStopCriterion "Transmission S-Parameters", "0.01", "2", "Hex", "False"
     .RemoveAllStopCriteria "Tet"
     .AddStopCriterion "All S-Parameters", "0.01", "2", "Tet", "True"
     .AddStopCriterion "Reflection S-Parameters", "0.01", "2", "Tet", "False"
     .AddStopCriterion "Transmission S-Parameters", "0.01", "2", "Tet", "False"
     .AddStopCriterion "All Probes", "0.05", "2", "Tet", "True"
     .RemoveAllStopCriteria "Srf"
     .AddStopCriterion "All S-Parameters", "0.01", "2", "Srf", "True"
     .AddStopCriterion "Reflection S-Parameters", "0.01", "2", "Srf", "False"
     .AddStopCriterion "Transmission S-Parameters", "0.01", "2", "Srf", "False"
     .SweepMinimumSamples "3" 
     .SetNumberOfResultDataSamples "1001" 
     .SetResultDataSamplingMode "Automatic" 
     .SweepWeightEvanescent "1.0" 
     .AccuracyROM "1e-4" 
     .AddSampleInterval "", "", "1", "Automatic", "True" 
     .AddSampleInterval "", "", "", "Automatic", "False" 
     .MPIParallelization "False"
     .UseDistributedComputing "False"
     .NetworkComputingStrategy "RunRemote"
     .NetworkComputingJobCount "3"
     .UseParallelization "True"
     .MaxCPUs "1024"
     .MaximumNumberOfCPUDevices "2"
End With

With IESolver
     .Reset 
     .UseFastFrequencySweep "True" 
     .UseIEGroundPlane "False" 
     .SetRealGroundMaterialName "" 
     .CalcFarFieldInRealGround "False" 
     .RealGroundModelType "Auto" 
     .PreconditionerType "Auto" 
     .ExtendThinWireModelByWireNubs "False" 
     .ExtraPreconditioning "False" 
End With

With IESolver
     .SetFMMFFCalcStopLevel "0" 
     .SetFMMFFCalcNumInterpPoints "6" 
     .UseFMMFarfieldCalc "True" 
     .SetCFIEAlpha "0.500000" 
     .LowFrequencyStabilization "False" 
     .LowFrequencyStabilizationML "True" 
     .Multilayer "False" 
     .SetiMoMACC_I "0.0001" 
     .SetiMoMACC_M "0.0001" 
     .DeembedExternalPorts "True" 
     .SetOpenBC_XY "True" 
     .OldRCSSweepDefintion "False" 
     .SetRCSOptimizationProperties "True", "100", "0.00001" 
     .SetAccuracySetting "Custom" 
     .CalculateSParaforFieldsources "True" 
     .ModeTrackingCMA "True" 
     .NumberOfModesCMA "3" 
     .StartFrequencyCMA "-1.0" 
     .SetAccuracySettingCMA "Default" 
     .FrequencySamplesCMA "0" 
     .SetMemSettingCMA "Auto" 
     .CalculateModalWeightingCoefficientsCMA "True" 
     .DetectThinDielectrics "True" 
End With

'@ Controlled load and connectivity diagnostic

'[VERSION]2023.0|32.0.1|20220912[/VERSION]
With FDSolver
 .ResetSampleIntervals "all"
 .MeshAdaptionTet "False"
 .UseParallelization "True"
 .MaxCPUs "6"
 .MaximumNumberOfCPUDevices "1"
 .UseDoublePrecision "True"
End With
With LumpedElement
 .Reset
 .SetName "PIN_ON_series_RL"
 .SetType "RLCSerial"
 .SetR "0.001"
 .SetL "0"
 .SetC "0"
 .SetGs "0"
 .SetI0 "0"
 .SetT "0"
 .SetP1 "False", "-center_gap/2", "0", "substrate_thickness+copper_thickness/2"
 .SetP2 "False", "center_gap/2", "0", "substrate_thickness+copper_thickness/2"
 .SetInvert "False"
 .SetMonitor "True"
 .Modify
End With
FDSolver.AddSampleInterval "26.167999999999999", "26.167999999999999", "1", "Single", "False"

FloquetPort.SetPolarizationIndependentOfScanAnglePhi "90", "True"

