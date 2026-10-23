With FDSolver
 .ResetSampleIntervals "all"
 .MeshAdaptionTet "True"
 .UseParallelization "True"
 .MaxCPUs "6"
 .MaximumNumberOfCPUDevices "1"
 .UseDoublePrecision "True"
End With
With LumpedElement
 .Reset
 .SetName "PIN_ON_series_RL"
 .SetType "RLCSerial"
 .SetR "0"
 .SetL "3e-11"
 .SetC "2.5000000000000001e-14"
 .SetGs "0"
 .SetI0 "0"
 .SetT "0"
 .SetP1 "False", "-center_gap/2", "0", "substrate_thickness+copper_thickness/2"
 .SetP2 "False", "center_gap/2", "0", "substrate_thickness+copper_thickness/2"
 .SetInvert "False"
 .SetMonitor "True"
 .Modify
End With
FDSolver.AddSampleInterval "26.167999999999999", "26.167999999999999", "1", "Single", "True"

Mesh.StepsPerWavelengthTet "8.0"
Mesh.MinimumStepNumberTet "8.0"
