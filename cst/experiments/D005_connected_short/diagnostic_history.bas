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
FDSolver.AddSampleInterval "26.168", "26.168", "1", "Single", "False"
With Brick
 .Reset
 .Name "left_bridge_overlap"
 .Component "top_patch"
 .Material "Copper_5p8e7S_per_m"
 .Xrange "-center_gap/2-2*terminal_width", "-center_gap/2"
 .Yrange "-slot_width/2-terminal_width", "slot_width/2+terminal_width"
 .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
 .Create
End With
With Brick
 .Reset
 .Name "right_bridge_overlap"
 .Component "top_patch"
 .Material "Copper_5p8e7S_per_m"
 .Xrange "center_gap/2", "center_gap/2+2*terminal_width"
 .Yrange "-slot_width/2-terminal_width", "slot_width/2+terminal_width"
 .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
 .Create
End With
Solid.Add "top_patch:left_diode_land", "top_patch:left_bridge_overlap"
Solid.Add "top_patch:left_diode_land", "top_patch:left_upper"
Solid.Add "top_patch:left_diode_land", "top_patch:left_lower"
Solid.Add "top_patch:left_diode_land", "top_patch:left_outer"
Solid.Add "top_patch:right_diode_land", "top_patch:right_bridge_overlap"
Solid.Add "top_patch:right_diode_land", "top_patch:right_upper"
Solid.Add "top_patch:right_diode_land", "top_patch:right_lower"
Solid.Add "top_patch:right_diode_land", "top_patch:right_outer"